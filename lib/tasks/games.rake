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
    Game.all.each_with_index do |game, index|
      seconds = index + 1
      UpdateGameMessageWorker.perform_in(seconds.seconds, game.id)
    end
  end
end
