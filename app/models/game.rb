class Game < ApplicationRecord
  belongs_to :team
  has_many :answers, -> { order 'created_at DESC' }, dependent: :destroy

  validates :category, presence: true
  validates :question, presence: true
  validates :answer, presence: true
  validates :value, presence: true
  validates :air_date, presence: true

  def post_to_slack
    blocks = to_blocks
    text = "The category is #{category}, for $#{value}: “#{question}”"
    response = team.post_in_channel(channel_id: channel, text: text, blocks: blocks)
    self.ts = response.dig(:message, :ts)
    self.save!
  end

  def has_correct_answer?
    answers.any?(&:is_correct?)
  end

  def replace_message(url)
    params = {
      replace_original: true,
      text: "The category is #{category}, for $#{value}: “#{question}”",
      blocks: to_blocks
    }
    HTTParty.post(url, body: params.to_json, headers: { 'Content-Type': 'application/json' })
  end

  private

  def to_blocks
    blocks = []
    blocks << {
			type: "context",
			elements: [
				{
					type: "plain_text",
					text: "$#{value}"
				},
				{
					"type": "plain_text",
					"text": category.titleize
				}
			]
		}

    if has_correct_answer?
      blocks << {
        type: "section",
        text: {
          type: "mrkdwn",
          text: "*#{question}*"
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
            text: "Your answer, in the form of a question"
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
        "type": "divider"
      }
      answers.each do |a|
        blocks << {
          type: "context",
          elements: [
            {
              type: "plain_text",
              text: a.emoji,
              emoji: true
            },
            {
              type: "image",
              image_url: a.user.avatar,
              alt_text: a.user.name
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
      "type": "divider"
    }
    blocks << {
			type: "context",
			elements: [
				{
					type: "plain_text",
					text: "Originally aired on #{air_date.strftime('%A, %B %-d, %Y')}"
				}
			]
		}
    blocks
  end
end
