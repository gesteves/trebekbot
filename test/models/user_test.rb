require "test_helper"

class UserTest < ActiveSupport::TestCase

  test "longest streaks are counted correctly" do
    user = users(:one)
    game = games(:one)

    assert_equal 0, user.longest_streak

    answer = Answer.new(answer: "Who is John Doe?", game: game, user: user)
    answer.save!

    assert_equal 0, user.longest_streak

    game = games(:two)
    answer = Answer.new(answer: "What is Plymouth Rock?", game: game, user: user)
    answer.save!

    assert_equal 1, user.longest_streak

    game = games(:parentheses)
    answer = Answer.new(answer: "What is why can't I?", game: game, user: user)
    answer.save!

    assert_equal 2, user.longest_streak

    game = games(:or)
    answer = Answer.new(answer: "Who is george costanza?", game: game, user: user)
    answer.save!

    assert_equal 2, user.longest_streak
  end
end
