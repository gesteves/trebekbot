class HomeViewPresenter < SimpleDelegator
  def to_view
    blocks = []

    blocks << {
      type: "section",
      text: {
        type: "mrkdwn",
        text: ":wave: Hi #{display_name},"
      }
    }

    if answers.present?
      score = "Your score is *#{pretty_score}*"
      score += ", your current streak is *#{current_streak}* correct answers" if current_streak > 1
      score += ", and your longest streak so far is *#{longest_streak}* correct answers" if longest_streak > 1
      score += "."
      blocks << {
        type: "section",
        text: {
          "type": "mrkdwn",
          "text": "#{score}\n\n"
        }
      }
    else
      blocks << {
        type: "section",
        text: {
          "type": "mrkdwn",
          "text": "Welcome to #{team.bot_name}! You haven’t played yet, but getting started is very easy:"
        }
      }
      blocks << {
        type: "section",
        text: {
          type: "mrkdwn",
          text: ":one: Invite me into a channel by typing `/invite #{team.bot_mention}`, or join one in which I’m already invited \n\n :two: Mention me, typing `#{team.bot_mention}`, to start a new game \n\n :three: Submit your answer (in the form of a question) in the text input within the game message \n\n :four: View all available commands by typing `#{team.bot_mention} help`"
        }
      }
      blocks << {
        type: "section",
        text: {
          "type": "mrkdwn",
          "text": "And that’s it! Come back here after you’ve played a few rounds and I’ll show you your current score.\n\n"
        }
      }
    end

    scoreboard = ScoreboardPresenter.new(team).to_blocks(limit: 100)
    blocks += scoreboard if scoreboard.present?

    {
      type: "home",
      blocks: blocks
    }
  end
end
