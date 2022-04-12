class GamePresenter < SimpleDelegator
  def to_blocks
    blocks = []
    blocks << {
			type: "context",
			elements: [
				{
					type: "mrkdwn",
					text: "*#{decode_html_entities(category).titleize}* | $#{pretty_value} | Aired #{air_date.strftime('%B %-d, %Y')}"
				}
			]
		}

    if is_closed?
      blocks << {
        type: "section",
        text: {
          type: "mrkdwn",
          text: "*#{decode_html_entities(question)}*"
        }
      }
      blocks << {
        type: "section",
        text: {
          type: "mrkdwn",
          text: "The answer is “#{decode_html_entities(answer)}”"
        }
      }
    else
      blocks << {
        type: "input",
        dispatch_action: true,
        element: {
          type: "plain_text_input",
          action_id: "answer",
          placeholder: {
            type: "plain_text",
            text: "Your answer, in the form of a question…"
          },
          dispatch_action_config: {
            trigger_actions_on: [
              "on_enter_pressed"
            ]
          }
        },
        label: {
          type: "plain_text",
          text: question
        }
      }
    end

    if answers.present?
      blocks << {
        type: "divider"
      }
      answers.each do |a|
        blocks << {
          type: "context",
          elements: [
            {
              type: "plain_text",
              text: a.to_emoji,
              emoji: true
            },
            {
              type: "image",
              image_url: a.user.avatar,
              alt_text: a.user.real_name || a.user.username
            },
            {
              type: "plain_text",
              text: a.answer,
              emoji: true
            }
          ]
        }
      end
    end
    blocks << {
      type: "divider"
    }
    blocks
  end

  def debug
    if answers.blank?
      <<~DEBUG
      ```
      No answers to debug yet.
      ```
      DEBUG
    else
      <<~DEBUG
      ```
      #{answers.map(&:debug).join("\n")}
      ```
      DEBUG
    end
  end

  private
  def decode_html_entities(text)
    coder = HTMLEntities.new
    coder.decode(text)
  end
end
