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
        team = Team.find_or_create_by(team_id: team_id)
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
    return render plain: "Unauthorized", status: 401 if params[:token] != ENV['SLACK_VERIFICATION_TOKEN']

    render plain: "OK", status: 200
  end

  private

  def verify_url
    render plain: params[:challenge], status: 200
  end

  def app_mention
    render plain: "OK", status: 200
  end
end
