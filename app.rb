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

post "/" do
  params[:text] = params[:text].sub(params[:trigger_word], '').strip 
  if params[:token] != ENV["OUTGOING_WEBHOOK_TOKEN"]
    response = "Invalid token"
  elsif params[:text].match(/^jeopardy me/i)
    response = get_question(params)
  elsif params[:text].match(/my score$/i)
    response = get_user_score(params)
  elsif params[:text].match(/^(what|where|who|when)/i)
    response = get_answer(params)
  else
    response = get_other_response(params)
  end

  status 200
  body response
end

def get_question(params)
  uri = "http://jservice.io/api/random?count=1"
  request = HTTParty.get(uri)
  response = JSON.parse(request.body).first
  question = "The category is `#{response["category"]["title"]}` for $#{response["value"]}: `#{response["question"]}`"
  key = "current_question:#{params[:channel_id]}"
  $redis.setex(key, ENV["SECONDS_TO_ANSWER"].to_i, response.to_json)
  json_response_for_slack(question)
end

def get_answer(params)
  key = "current_question:#{params[:channel_id]}"
  current_question = $redis.get(key)
  if current_question.nil?
    reply = trebek_me
  else
    current_question = JSON.parse(current_question)
    current_answer = current_question["answer"]
    user_answer = params[:text]
    if is_correct_answer?(current_answer, user_answer)
      score = update_score(params[:user_id], current_question["value"])
      reply = "That is the correct answer, #{get_slack_name(params[:user_id], params[:user_name])}. Your total score is #{format_score(score)}."
      $redis.del(key)
    else
      score = update_score(params[:user_id], (current_question["value"] * -1))
      reply = "Sorry, #{get_slack_name(params[:user_id], params[:user_name])}, the correct answer is `#{Sanitize.fragment(current_question["answer"])}`. Your score is now #{format_score(score)}."
      $redis.del(key)
    end
  end
  json_response_for_slack(reply)
end

def get_other_response(params)
  key = "current_question:#{params[:channel_id]}"
  current_question = $redis.get(key)
  if current_question.nil?
    reply = trebek_me
  else
    current_question = JSON.parse(current_question)
    current_answer = current_question["answer"]
    user_answer = params[:text]
    if is_correct_answer?(current_answer, user_answer)
      score = update_score(params[:user_id], (current_question["value"] * -1))
      reply = "That is correct, #{get_slack_name(params[:user_id], params[:user_name])}, but responses have to be in the form of a question. Your total score is #{format_score(score)}."
      $redis.del(key)
    else
      score = update_score(params[:user_id], (current_question["value"] * -1))
      reply = "Sorry, #{get_slack_name(params[:user_id], params[:user_name])}, the correct answer is `#{Sanitize.fragment(current_question["answer"])}`. Your score is now #{format_score(score)}."
      $redis.del(key)
    end
  end
  json_response_for_slack(reply)
end

def is_correct_answer?(correct, answer)
  correct = Sanitize.fragment(correct)
  correct = correct.gsub(/[^\w\d\s]/i, "").gsub(/^(the|a|an) /i, "").strip.downcase
  answer = answer.gsub(/[^\w\d\s]/i, "").gsub(/^(what|whats|where|wheres|who|whos) /i, "").gsub(/^(is|are|was|were) /, "").gsub(/^(the|a) /i, "").gsub(/\?+$/, "").strip.downcase
  white = Text::WhiteSimilarity.new
  similarity = white.similarity(correct, answer)
  puts "[LOG] Correct answer: #{correct} | User answer: #{answer} | Similarity: #{similarity}"
  similarity >= 0.5
end

def get_user_score(params)
  key = "user_score:#{params[:user_id]}"
  user_score = $redis.get(key)
  if user_score.nil?
    $redis.set(key, 0)
    user_score = 0
  end
  reply = "#{get_slack_name(params[:user_id], params[:user_name])}, your score is #{format_score(user_score.to_i)}."
  json_response_for_slack(reply)
end

def update_score(user_id, score = 0)
  key = "user_score:#{user_id}"
  user_score = $redis.get(key)
  if user_score.nil?
    $redis.set(key, score)
    score
  else
    $redis.set(key, user_score.to_i + score)
    user_score.to_i + score
  end
end

def format_score(score)
  if score >= 0
    "$#{score}"
  else
    "-$#{score * -1}"
  end
end

def get_slack_name(user_id, username)
  key = "user_names:#{user_id}"
  name = $redis.get(key)
  if name.nil?
    uri = "https://slack.com/api/users.list?token=#{ENV["API_TOKEN"]}"
    request = HTTParty.get(uri)
    response = JSON.parse(request.body)
    if response["ok"]
      user = response["members"].find { |u| u["id"] == user_id }
      name = user["profile"]["first_name"].nil? ? "@#{username}" : user["profile"]["first_name"]
      $redis.setex(key, 3600, name)
    end
  end
  name
end

def trebek_me
  responses = [ "Welcome back to _Slack Jeopardy_. Before we begin this Jeopardy round, I'd like to ask our contestants once again to please refrain from using ethnic slurs.",
    "Okay. Turd Ferguson.",
    "I hate my job.",
    "That is incorrect.",
    "Let's just get this over with.",
    "Do you have an answer?",
    "I don't believe this. Where did you get that magic marker? We frisked you in on the way in here.",
    "What a ride it has been, but boy, oh boy, these Slack users did not know the right answers to any of the questions.",
    "Back off. I don't have to take that from you.",
    "That is _awful_.",
    "Okay, for the sake of tradition, let's take a look at the answers.",
    "Beautiful. Just beautiful.",
    "Good for you. Well, as always, three perfectly good charities have been deprived of money, here on Slack Jeopardy. I'm Alex Trebek, and all of you should be ashamed of yourselves! Good night!",
    "And welcome back to Slack Jeopardy. Because of what just happened before during the commercial, I'd like to apologize to all blind people and children.",
    "Thank you, thank you. Moving on.",
    "I really thought that was going to work.",
    "Wonderful. Let's take a look at the categories. They are: Potent Potables, Point to your own head, Letters or Numbers, Will this hurt if you put it in your mouth, An album cover, Make any noise, and finally, Famous Muppet Frogs. I should add that the answer to every question in that category is Kermit.",
    "For the last time, that is not a category.",
    "Unbelievable.",
    "Great. Let's take a look at the final board. And the categories are: Potent Potables; Sharp Things; Movies That Start with the Word Jaws; A Petit Déjeuner - that category is about French phrases, so let's just skip it.",
    "Enough. Let's just get this over with. Here are the categories, they are: Potent Potables, Countries Between Mexico and Canada, Members of Simon and Garfunkel, I Have a Chardonnay - you choose this category, you automatically get the points and I get to have a glass of wine. Things You Do With a Pencil Sharpener, Tie Your Shoe, and finally, Toast.",
    "Better luck to all of you, in the next round. It's time for Slack Jeopardy, let's take a look at the board. And the categories are: Potent Potables, Literature - which is just a big word for books - Therapists, Current U.S. Presidents, Show and Tell, Household Objects, and finally, One-Letter Words."]
    responses.sample
end

def json_response_for_slack(reply)
  response = { text: reply, link_names: 1 }
  response[:username] = ENV["BOT_USERNAME"] unless ENV["BOT_USERNAME"].nil?
  response[:icon_emoji] = ENV["BOT_ICON"] unless ENV["BOT_ICON"].nil?
  response.to_json
end