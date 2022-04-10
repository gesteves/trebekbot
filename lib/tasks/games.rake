namespace :games do
  desc 'Prints stats'
  task :stats => [:environment] do
    puts "#{Team.all.count} teams"
    puts "#{Game.all.count} games"
    puts "#{User.all.count} users"
    puts "#{Answer.all.count} answers"

    Team.find_each do |team|
      puts "Team #{team.slack_id}:"
      puts "  #{team.games.count} games"
      puts "  #{team.users.count} users"
      puts "\n"
    end
  end

  desc 'Updates all messages'
  task :update => [:environment] do
    Game.find_each do |game|
      p "Updating game #{game.id}"
      game.update_message
      sleep 2
    end
  end
end
