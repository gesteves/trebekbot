namespace :teams do
  desc 'Updates all messages'
  task :update_bot_id => [:environment] do
    slack = Slack.new
    Team.find_each do |team|
      response = slack.auth_test(access_token: team.access_token)
      p "Updating bot ID for team #{team.slack_id}: #{response.dig(:bot_id)}"
      team.bot_id = response.dig(:bot_id)
      team.save!
    end
  end
end
