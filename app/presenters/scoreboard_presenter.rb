class ScoreboardPresenter < SimpleDelegator
  def to_blocks(limit: 10)
    users = top_users(limit: limit)
    return if users.blank?

    blocks = []

    blocks << {
      type: "section",
      text: {
        type: "mrkdwn",
        text: "*Here are the top scores for #{name}:*"
      }
    }

    blocks << {
      type: "divider"
    }

    if users.present?
      users.each do |user|
        text = "#{user.real_name || user.username} | *#{user.pretty_score}* | Answers: *#{user.total_answers}* | Correct: *#{number_to_percentage(user.correct_percentage, precision: 0)}*"
        text += " | Longest streak: *#{user.longest_streak}*" if user.longest_streak > 1
        text += " | Current streak: *#{user.current_streak}*" if user.current_streak > 1
        blocks << {
          type: "context",
          elements: [
            {
              type: "image",
              image_url: user.avatar,
              alt_text: user.display_name
            },
            {
              type: "mrkdwn",
              text: text
            }
          ]
        }
      end
    else
      blocks << {
        type: "context",
        elements: [
          {
            type: "plain_text",
            text: "Nobody has played yet.",
            emoji: true
          }
        ]
      }
    end

    blocks
  end
end
