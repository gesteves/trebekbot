require "test_helper"

class GameTest < ActiveSupport::TestCase
  test "renders Slack blocks" do
    game = games(:cremebrulee)
    blocks = game.to_blocks

    assert_equal "*Desserts & Stuff* | $100 | Aired April 2, 2022", blocks[0][:elements][0][:text]
    assert_equal "It's the 2-word French name for a custard dessert with a hard, caramelized sugar topping", blocks[1][:label][:text]
  end

  test "returns if it has answer by a given user" do
    game = games(:one)
    user = users(:three)

    assert_not game.has_answer_by_user?(user)

    answer = Answer.new(answer: "Who is #{game.answer}?", game: game, user: user)
    answer.save!

    assert game.has_answer_by_user?(user)
  end

  test "returns array of accepted answers" do
    game = games(:or)

    assert_equal ['jerry seinfeld or cosmo kramer', 'jerry seinfeld', 'cosmo kramer'], game.accepted_answers
  end
end
