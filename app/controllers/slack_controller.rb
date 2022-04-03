class SlackController < ApplicationController
  skip_before_action :verify_authenticity_token

  def auth
    url = root_url
    if params[:code].present?
      slack = Slack.new
      token = slack.get_access_token(code: params[:code], redirect_uri: auth_url)
      if token[:ok]
        access_token = token[:access_token]
        team_id = token.dig(:team, :id)
        team = Team.find_or_create_by(slack_id: team_id)
        team.access_token = access_token
        if team.save
          logger.info "Team #{team_id} authenticated with the following scopes: #{token[:scope]}"
          notice = nil
          url = success_url
        else
          notice = 'Oh no, something went wrong. Please try again!'
        end
      else
        logger.error "Authentication failed for the following reason: #{token[:error]}"
        notice = "Oh no, something went wrong. Please try again!"
      end
    elsif params[:error].present?
      logger.error "Authentication failed for the following reason: #{params[:error]}"
      notice = "Trebekbot was not added to your Slack. Please try again!"
    end
    redirect_to url, notice: notice
  end

  def events
    return render plain: "Unauthorized", status: 401 if params[:token] != ENV['SLACK_VERIFICATION_TOKEN']
    event_type = params.dig(:event, :type) || params[:type]
    case event_type
    when 'url_verification'
      verify_url
    when 'app_mention'
      app_mention
    end
  end

  def interactions
    begin
      payload = JSON.parse(params[:payload], symbolize_names: true)
    rescue
      return render plain: "Bad Request", status: 400
    end
    return render plain: "Unauthorized", status: 401 if payload[:token] != ENV['SLACK_VERIFICATION_TOKEN']

    user = payload.dig(:user, :id)
    team = payload.dig(:team, :id)
    channel = payload.dig(:channel, :id)
    ts = payload.dig(:message, :ts)
    answer = payload.dig(:actions)&.find { |a| a[:action_id] == "answer" }.dig(:value)

    ProcessAnswerWorker.perform_async(team, channel, ts, user, answer)

    render plain: "OK", status: 200
  end

  private

  def verify_url
    render plain: params[:challenge], status: 200
  end

  def app_mention
    text = params.dig(:event, :text)
    team = params[:team_id]
    channel = params.dig(:event, :channel)
    user = params.dig(:event, :user)

    if text =~ /(play|game|go)/i
      StartGameWorker.perform_async(team, channel)
    elsif text =~ /help/i
      show_help(team: team, channel: channel)
    elsif text =~ /scores/i
      PostLeaderboardWorker.perform_async(team, channel)
    elsif text =~ /my score/i
      show_user_score(team: team, channel: channel, user: user)
    else
      PostMessageWorker.perform_async(Trebek.sample, team, channel)
    end

    render plain: "OK", status: 200
  end

  def show_user_score(team:, channel:, user:)
    player = User.find_by(slack_id: user)
    reply = if player.present?
      "Your score is #{player.pretty_score}, #{player.mention}."
    else
      "You haven’t played yet, <@#{user}>, so your score is $0."
    end
    PostMessageWorker.perform_async(reply, team, channel)
  end

  def show_help(team:, channel:)
    reply = <<~HELP
      • Say `@trebekbot go` or `@trebekbot play` or `@trebekbot new game` to start a new round of Jeopardy!
      • Say `@trebekbot my score` to see your current score
      • Say `@trebekbot scores` to see the top 10 scores
    HELP
    PostMessageWorker.perform_async(reply, team, channel)
  end
end
