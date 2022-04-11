require "test_helper"

class GameTest < ActiveSupport::TestCase
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
