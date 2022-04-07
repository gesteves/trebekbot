class Game < ApplicationRecord
  include Textable

  belongs_to :team
  has_many :answers, -> { order 'created_at DESC' }, dependent: :destroy

  validates :category, presence: true
  validates :question, presence: true
  validates :answer, presence: true
  validates :value, presence: true
  validates :air_date, presence: true

  after_commit :enqueue_message_update, if: :saved_change_to_is_closed?

  # Posts the game to Slack, and stores the resulting message's timestamp (ts)
  # so it can be looked up later.
  def post_to_slack
    blocks = to_blocks
    text = "The category is #{category}, for $#{value}: “#{question}”"
    response = team.post_message(channel_id: channel, text: text, blocks: blocks)
    self.ts = response.dig(:message, :ts)
    self.save!
  end

  # Updates the message posted for a game, when an answer is submitted or the game is closed.
  def update_message
    return if team.has_invalid_token?
    blocks = to_blocks
    text = "The category is #{category}, for $#{value}: “#{question}”"
    response = team.update_message(ts: ts, channel_id: channel, text: text, blocks: blocks)
  end

  # Closes the game, which shows the correct answer and prevents players from submitting more answers.
  def close!
    self.is_closed = true
    save!
  end

  # Returns if any of the answers submitted for this game is correct.
  def has_correct_answer?
    answers.where(is_correct: true).present?
  end

  # Returns if the given user has submitted an answer for this game.
  def has_answer_by_user?(user)
    answers.where(user: user).present?
  end

  # A representation of the game as Slack "blocks",
  # which are sent as part of the Slack message.
  def to_blocks
    blocks = []
    blocks << {
			type: "context",
			elements: [
				{
					type: "mrkdwn",
					text: "*#{decode_html_entities(category.titleize)}* | $#{value} | Aired #{air_date.strftime('%B %-d, %Y')}"
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
              text: a.emoji,
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

  private

  # Enqueues a background job to update the game's message in Slack.
  def enqueue_message_update
    UpdateGameMessageWorker.perform_async(id)
  end
end
