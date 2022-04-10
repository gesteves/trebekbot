class SlackController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :no_cache
  before_action :parse_event, only: :events
  before_action :parse_interaction, only: :interactions
  before_action :check_token, only: [:events, :interactions]
  before_action :verify_url, only: :events

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
        team.bot_id = token.dig(:bot_user_id)
        if team.save
          logger.info "[LOG] [Team #{team_id}] Installed"
          notice = nil
          url = success_url
        else
          notice = 'Oh no, something went wrong. Please try again!'
        end
      else
        logger.error "[LOG] Authentication failed for the following reason: #{token[:error]}"
        notice = "Oh no, something went wrong. Please try again!"
      end
    elsif params[:error].present?
      logger.error "[LOG] Authentication failed for the following reason: #{params[:error]}"
      notice = "Trebekbot was not added to your Slack. Please try again!"
    end
    redirect_to url, notice: notice, allow_other_host: true
  end

  def events
    case @event_type
    when 'app_mention'
      app_mention
    when 'app_home_opened'
      app_home_opened
    when 'app_uninstalled'
      app_uninstalled
    end

    render plain: "OK", status: 200
  end

  def interactions
    process_answer if @answer.present?
    render plain: "OK", status: 200
  end

  private

  def check_token
    render plain: "Unauthorized", status: 401 if @token != ENV['SLACK_VERIFICATION_TOKEN']
  end

  def parse_event
    @token = params[:token]
    @event_type = params.dig(:event, :type) || params[:type]
    @text = params.dig(:event, :text)
    @team = params[:team_id]
    @channel = params.dig(:event, :channel)
    @user = params.dig(:event, :user)
    @thread_ts = params.dig(:event, :thread_ts)
  end

  def parse_interaction
    begin
      payload = JSON.parse(params[:payload], symbolize_names: true)
    rescue
      return render plain: "Bad Request", status: 400
    end

    @token = payload[:token]
    @user = payload.dig(:user, :id)
    @team = payload.dig(:team, :id)
    @channel = payload.dig(:channel, :id)
    @ts = payload.dig(:message, :ts)
    @answer = payload.dig(:actions)&.find { |a| a[:action_id] == "answer" }.dig(:value)
  end

  # EVENT HANDLERS

  def verify_url
    render plain: params[:challenge], status: 200 if @event_type == 'url_verification'
  end

  def app_mention
    if @text =~ /help/i
      show_help
    elsif @text =~ /(scores|leaderboard|scoreboard)/i
      show_leaderboard
    elsif @text =~ /my score/i
      show_user_score
    elsif @text =~ /debug/i
      show_debug_info
    else
      start_game
    end
  end

  def app_home_opened
    UpdateAppHomeWorker.perform_async(@team, @user)
  end

  def start_game
    StartGameWorker.perform_async(@team, @channel, @user) unless @thread_ts.present?
  end

  def show_help
    team = Team.find_by(slack_id: @team)
    reply = <<~HELP
      • Say `#{team.bot_mention}` to start a new game
      • Say `#{team.bot_mention} my score` to see your current score
      • Say `#{team.bot_mention} scores`, `#{team.bot_mention} scoreboard`, or `#{team.bot_mention} leaderboard` to see the top scores
    HELP
    PostMessageWorker.perform_async(reply, @team, @channel, @thread_ts)
  end

  def show_leaderboard
    PostLeaderboardWorker.perform_async(@team, @channel, @thread_ts)
  end

  def show_user_score
    t = Team.find_by(slack_id: @team)
    player = User.find_or_create_by(team_id: t.id, slack_id: @user)
    PostMessageWorker.perform_async(player.current_score_message, @team, @channel, @thread_ts)
  end

  def show_debug_info
    if @thread_ts.present?
      PostDebugWorker.perform_async(@team, @channel, @thread_ts)
    else
      PostMessageWorker.perform_async("I can only show debug information in a thread for a game message.", @team, @channel)
    end
  end

  def app_uninstalled
    team = Team.find_by(slack_id: @team)
    team.destroy
    logger.info "[LOG] [Team #{@team}] Uninstalled"
  end

  # INTERACTION HANDLERS

  def process_answer
    ProcessAnswerWorker.perform_async(@team, @channel, @ts, @user, @answer)
  end
end
