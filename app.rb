# encoding: utf-8
require "sinatra"
require "json"
require "httparty"
require "redis"
require "dotenv"

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
  command = params[:text].sub(params[:trigger_word], '').strip
  if params[:token] != ENV["OUTGOING_WEBHOOK_TOKEN"]
    response = "Invalid token"
  elsif command.match(/^jeopardy me/i)
    response = get_question(params)
  elsif command.match(/my score$/i)
    response = get_user_score(params)
  elsif command.match(/^(what|where|who|when)/i)
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
  question = "`#{response["category"]["title"]}` for $#{response["value"]}: `#{response["question"]}`"
  key = "current_question:#{params[:channel_id]}"
  $redis.setex(key, ENV["SECONDS_TO_ANSWER"].to_i, response.to_json)
  puts response
  json_response_for_slack(question)
end

def get_answer(params)
  key = "current_question:#{params[:channel_id]}"
  current_question = $redis.get(key)
  if current_question.nil?
    reply = ""
  else
    current_question = JSON.parse(current_question)
    if params[:text].downcase.match(current_question["answer"].downcase)
      score = update_score(params[:user_id], current_question["value"])
      reply = "That is the correct answer, #{get_slack_name(params[:user_id], params[:user_name])}. Your total score is #{format_score(score)}."
      $redis.del(key)
    else
      score = update_score(params[:user_id], (current_question["value"] * -1))
      reply = "Sorry, #{get_slack_name(params[:user_id], params[:user_name])}, the correct answer is `#{current_question["answer"]}`. Your score is now #{format_score(score)}."
      $redis.del(key)
    end
  end
  json_response_for_slack(reply)
end

def get_other_response(params)
  key = "current_question:#{params[:channel_id]}"
  current_question = $redis.get(key)
  if current_question.nil?
    reply = ""
  else
    current_question = JSON.parse(current_question)
    if params[:text].downcase.match(current_question["answer"].downcase)
      score = update_score(params[:user_id], (current_question["value"] * -1))
      reply = "That is correct, #{get_slack_name(params[:user_id], params[:user_name])}, but responses have to be in the form of a question. Your total score is #{format_score(score)}."
      $redis.del(key)
    else
      score = update_score(params[:user_id], (current_question["value"] * -1))
      reply = "Sorry, #{get_slack_name(params[:user_id], params[:user_name])}, the correct answer is `#{current_question["answer"]}`. Your score is now #{format_score(score)}."
      $redis.del(key)
    end
  end
  json_response_for_slack(reply)
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
      user = response["members"].find { |u| u["id"] == slack_id }
      name = user.nil? ? username : "@#{user["name"]}"
      $redis.setex(key, 3600, name)
    end
  end
  name
end

def json_response_for_slack(reply)
  response = { text: reply, link_names: 1 }
  response[:username] = ENV["BOT_USERNAME"] unless ENV["BOT_USERNAME"].nil?
  response[:icon_emoji] = ENV["BOT_ICON"] unless ENV["BOT_ICON"].nil?
  response.to_json
end