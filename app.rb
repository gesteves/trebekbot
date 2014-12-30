# encoding: utf-8
require "sinatra"
require "json"
require "httparty"
require "redis"
require "dotenv"
require "text"
require "sanitize"

configure do
  # Load .env vars
  Dotenv.load
  # Disable output buffering
  $stdout.sync = true
  
  # Set up redis
  case settings.environment
  when :development
    uri = URI.parse(ENV["LOCAL_REDIS_URL"])
  when :production
    uri = URI.parse(ENV["REDISCLOUD_URL"])
  end
  $redis = Redis.new(host: uri.host, port: uri.port, password: uri.password)
end

# params:
# token=abc123
# team_id=T0001
# channel_id=C123456
# channel_name=test
# timestamp=1355517523.000005
# user_id=U123456
# user_name=Steve
# text=trebekbot jeopardy me
# trigger_word=trebekbot
post "/" do
  params[:text] = params[:text].sub(params[:trigger_word], "").strip 
  if params[:token] != ENV["OUTGOING_WEBHOOK_TOKEN"]
    response = "Invalid token"
  elsif params[:text].match(/^jeopardy me/i)
    response = respond_with_question(params)
  elsif params[:text].match(/my score$/i)
    response = respond_with_user_score(params[:user_id])
  elsif params[:text].match(/^help$/i)
    response = respond_with_help
  elsif params[:text].match(/^show (me\s+)?(the\s+)?leaderboard$/i)
    response = respond_with_leaderboard
  else
    response = process_answer(params)
  end

  status 200
  body response
end

def get_question
  uri = "http://jservice.io/api/random?count=1"
  request = HTTParty.get(uri)
  response = JSON.parse(request.body).first
  if response["question"].nil? || response["question"].strip == ""
    response = get_question
  end
  response
end

def respond_with_question(params)
  channel_id = params[:channel_id]
  unless $redis.exists("shush:#{channel_id}")
    response = get_question
    response["value"] = 200 if response["value"].nil?
    response["answer"] = Sanitize.fragment(response["answer"].gsub(/\s+(&nbsp;|&)\s+/i, " and "))
    response["expiration"] = params["timestamp"].to_f + ENV["SECONDS_TO_ANSWER"].to_f
    key = "current_question:#{channel_id}"
    question = ""
    previous_question = $redis.get(key)
    if !previous_question.nil?
      previous_question = JSON.parse(previous_question)["answer"]
      question = "The answer is, of course, `#{previous_question}`.\n"
    end
    question += "The category is `#{response["category"]["title"]}` for #{currency_format(response["value"])}: `#{response["question"]}`"
    puts "[LOG] ID: #{response["id"]} | Category: #{response["category"]["title"]} | Question: #{response["question"]} | Answer: #{response["answer"]} | Value: #{response["value"]}"
    $redis.pipelined do
      $redis.set(key, response.to_json)
      $redis.setex("shush:#{channel_id}", 5, "true")
    end
    json_response_for_slack(question)
  end
end

def process_answer(params)
  channel_id = params[:channel_id]
  key = "current_question:#{channel_id}"
  current_question = $redis.get(key)
  if current_question.nil? && !$redis.exists("shush:#{channel_id}")
    reply = trebek_me
  else
    current_question = JSON.parse(current_question)
    current_answer = current_question["answer"]
    user_answer = params[:text]
    if params["timestamp"].to_f > current_question["expiration"]
      reply = "Time's up, #{get_slack_name(params[:user_id])}! Remember, you have #{ENV["SECONDS_TO_ANSWER"]} seconds to answer."
      reply += " The correct answer is `#{current_question["answer"]}`." if !is_correct_answer?(current_answer, user_answer)
      mark_question_as_answered(params[:channel_id])
    elsif is_question_format?(user_answer) && is_correct_answer?(current_answer, user_answer)
      score = update_score(params[:user_id], current_question["value"])
      reply = "That is the correct answer, #{get_slack_name(params[:user_id])}. Your total score is #{currency_format(score)}."
      mark_question_as_answered(params[:channel_id])
    elsif is_correct_answer?(current_answer, user_answer)
      score = update_score(params[:user_id], (current_question["value"] * -1))
      reply = "That is correct, #{get_slack_name(params[:user_id])}, but responses have to be in the form of a question. Your total score is #{currency_format(score)}."
    else
      score = update_score(params[:user_id], (current_question["value"] * -1))
      reply = "That is incorrect, #{get_slack_name(params[:user_id])}. Your score is now #{currency_format(score)}."
    end
  end
  json_response_for_slack(reply)
end

def is_question_format?(answer)
  answer.gsub(/[^\w\s]/i, "").match(/^(what|whats|where|wheres|who|whos) /i)
end

def is_correct_answer?(correct, answer)
  correct = correct.gsub(/[^\w\s]/i, "")
            .gsub(/^(the|a|an) /i, "")
            .strip
            .downcase
  answer = answer
           .gsub(/\s+(&nbsp;|&)\s+/i, " and ")
           .gsub(/[^\w\s]/i, "")
           .gsub(/^(what|whats|where|wheres|who|whos) /i, "")
           .gsub(/^(is|are|was|were) /, "")
           .gsub(/^(the|a|an) /i, "")
           .gsub(/\?+$/, "")
           .strip
           .downcase
  white = Text::WhiteSimilarity.new
  similarity = white.similarity(correct, answer)
  puts "[LOG] Correct answer: #{correct} | User answer: #{answer} | Similarity: #{similarity}"
  correct == answer || similarity >= ENV["SIMILARITY_THRESHOLD"].to_f
end

def mark_question_as_answered(channel_id)
  $redis.pipelined do
    $redis.del("current_question:#{channel_id}")
    $redis.setex("shush:#{channel_id}", 5, "true")
  end
end

def respond_with_user_score(user_id)
  user_score = get_user_score(user_id)
  reply = "#{get_slack_name(user_id)}, your score is #{currency_format(user_score)}."
  json_response_for_slack(reply)
end

def get_user_score(user_id)
  key = "user_score:#{user_id}"
  user_score = $redis.get(key)
  if user_score.nil?
    $redis.set(key, 0)
    user_score = 0
  end
  user_score.to_i
end

def update_score(user_id, score = 0)
  key = "user_score:#{user_id}"
  user_score = $redis.get(key)
  if user_score.nil?
    $redis.set(key, score)
    score
  else
    new_score = user_score.to_i + score
    $redis.set(key, new_score)
    new_score
  end
end

def get_slack_name(user_id, options = {})
  options = { :use_real_name => false }.merge(options)
  key = "slack_user_names:2:#{user_id}"
  names = $redis.get(key)
  if names.nil?
    names = get_slack_names_hash(user_id)
    $redis.setex(key, 60*60*24*30, names.to_json)
  else
    names = JSON.parse(names)
  end
  if options[:use_real_name]
    name = names["real_name"].nil? ? names["name"] : names["real_name"]
  else
    name = names["first_name"].nil? ? names["name"] : names["first_name"]
  end
  name
end

def get_slack_names_hash(user_id)
  uri = "https://slack.com/api/users.list?token=#{ENV["API_TOKEN"]}"
  request = HTTParty.get(uri)
  response = JSON.parse(request.body)
  if response["ok"]
    user = response["members"].find { |u| u["id"] == user_id }
    names = { :id => user_id, :name => user["name"]}
    unless user["profile"].nil?
      names["real_name"] = user["profile"]["real_name"] unless user["profile"]["real_name"].nil? || user["profile"]["real_name"] == ""
      names["first_name"] = user["profile"]["first_name"] unless user["profile"]["first_name"].nil? || user["profile"]["first_name"] == ""
      names["last_name"] = user["profile"]["last_name"] unless user["profile"]["last_name"].nil? || user["profile"]["last_name"] == ""
    end
  else
    names = { :id => user_id, :name => "Sean Connery" }
  end
  names
end

def respond_with_leaderboard
  key = "leaderboard:1"
  response = $redis.get(key)
  if response.nil?
    leaders = []
    get_score_leaders.each_with_index do |leader, i|
      user_id = leader[:user_id]
      name = get_slack_name(leader[:user_id], { :use_real_name => true })
      score = currency_format(get_user_score(user_id))
      leaders << "#{i + 1}. #{name}: #{score}"
    end
    if leaders.size > 0
      response = "Let's take a look at the top scores:\n\n#{leaders.join("\n")}"
    else
      response = "There are no scores yet!"
    end
    $redis.setex(key, 60*5, response)
  end
  json_response_for_slack(response)
end

def get_score_leaders(options = {})
  options = { :limit => 10 }.merge(options)
  leaders = []
  $redis.scan_each(:match => "user_score:*"){ |key| user_id = key.gsub("user_score:", ""); leaders << { :user_id => user_id, :score => get_user_score(user_id) } }
  puts "[LOG] Leaderboard: #{leaders.to_s}"
  if leaders.size > 1
    leaders = leaders.uniq{ |l| l[:user_id] }.sort{ |a, b| b[:score] <=> a[:score] }.slice(0, options[:limit])
  else
    leaders
  end
end

def trebek_me
  responses = [ "Welcome back to Slack Jeopardy. Before we begin this Jeopardy round, I'd like to ask our contestants once again to please refrain from using ethnic slurs.",
    "Okay, Turd Ferguson.",
    "I hate my job.",
    "That is incorrect.",
    "Let's just get this over with.",
    "Do you have an answer?",
    "I don't believe this. Where did you get that magic marker? We frisked you on the way in here.",
    "What a ride it has been, but boy, oh boy, these Slack users did not know the right answers to any of the questions.",
    "Back off. I don't have to take that from you.",
    "That is _awful_.",
    "Okay, for the sake of tradition, let's take a look at the answers.",
    "Beautiful. Just beautiful.",
    "Good for you. Well, as always, three perfectly good charities have been deprived of money, here on Slack Jeopardy. I'm #{ENV["BOT_USERNAME"]}, and all of you should be ashamed of yourselves! Good night!",
    "And welcome back to Slack Jeopardy. Because of what just happened before during the commercial, I'd like to apologize to all blind people and children.",
    "Thank you, thank you. Moving on.",
    "I really thought that was going to work.",
    "Wonderful. Let's take a look at the categories. They are: `Potent Potables`, `Point to your own head`, `Letters or Numbers`, `Will this hurt if you put it in your mouth`, `An album cover`, `Make any noise`, and finally, `Famous Muppet Frogs`. I should add that the answer to every question in that category is `Kermit`.",
    "For the last time, that is not a category.",
    "Unbelievable.",
    "Great. Let's take a look at the final board. And the categories are: `Potent Potables`, `Sharp Things`, `Movies That Start with the Word Jaws`, `A Petit Déjeuner` -- that category is about French phrases, so let's just skip it.",
    "Enough. Let's just get this over with. Here are the categories, they are: `Potent Potables`, `Countries Between Mexico and Canada`, `Members of Simon and Garfunkel`, `I Have a Chardonnay` -- you choose this category, you automatically get the points and I get to have a glass of wine -- `Things You Do With a Pencil Sharpener`, `Tie Your Shoe`, and finally, `Toast`.",
    "Better luck to all of you, in the next round. It's time for Slack Jeopardy, let's take a look at the board. And the categories are: `Potent Potables`, `Literature` -- which is just a big word for books -- `Therapists`, `Current U.S. Presidents`, `Show and Tell`, `Household Objects`, and finally, `One-Letter Words`.",
    "Uh, I see. Get back to your podium.",
    "You look pretty sure of yourself. Think you've got the right answer?",
    "Welcome back to Slack Jeopardy. We've got a real barnburner on our hands here.",
    "And welcome back to Slack Jeopardy. I'd like to once again remind our contestants that there are proper bathroom facilities located in the studio.",
    "Welcome back to Slack Jeopardy. Once again, I'm going to recommend that our viewers watch something else.",
    "Great. Better luck to all of you in the next round. It's time for Slack Jeopardy. Let's take a look at the board. And the categories are: `Potent Potables`, `The Vowels`, `Presidents Who Are On the One Dollar Bill`, `Famous Titles`, `Ponies`, `The Number 10`, and finally: `Foods That End In \"Amburger\"`.",
    "Let's take a look at the board. The categories are: `Potent Potables`, `The Pen is Mightier` -- that category is all about quotes from famous authors, so you'll all probably be more comfortable with our next category -- `Shiny Objects`, continuing with `Opposites`, `Things you Shouldn't Put in Your Mouth`, `What Time is It?`, and, finally, `Months That Start With Feb`."
  ]
    responses.sample
end

def respond_with_help
  reply = <<help
Type `#{ENV["BOT_USERNAME"]} jeopardy me` to start a new round of Slack Jeopardy. I will pick the category and price. Anyone in the channel can respond.
Type `#{ENV["BOT_USERNAME"]} [what|where|who] [is|are] [answer]?` to respond to the active round. You have #{ENV["SECONDS_TO_ANSWER"]} seconds to answer. Remember, responses must be in the form of a question, e.g. `#{ENV["BOT_USERNAME"]} what is dirt?`.
Type `#{ENV["BOT_USERNAME"]} what is my score` to see your current score.
Type `#{ENV["BOT_USERNAME"]} show the leaderboard` to see the top scores.
help
  json_response_for_slack(reply)
end

def currency_format(number, currency = "$")
  prefix = number >= 0 ? currency : "-#{currency}"
  moneys = number.abs.to_s
  while moneys.match(/(\d+)(\d\d\d)/)
    moneys.to_s.gsub!(/(\d+)(\d\d\d)/, "\\1,\\2")
  end
  "#{prefix}#{moneys}"
end

def json_response_for_slack(reply)
  response = { text: reply, link_names: 1 }
  response[:username] = ENV["BOT_USERNAME"] unless ENV["BOT_USERNAME"].nil?
  response[:icon_emoji] = ENV["BOT_ICON"] unless ENV["BOT_ICON"].nil?
  response.to_json
end