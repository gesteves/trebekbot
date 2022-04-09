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

  test "current streaks are counted correctly" do
    user = users(:three)
    game = games(:one)

    assert_equal 0, user.current_streak

    answer = Answer.new(answer: "Who is John Doe?", game: game, user: user)
    answer.save!

    assert_equal 0, user.current_streak

    game = games(:two)
    answer = Answer.new(answer: "What is Plymouth Rock?", game: game, user: user)
    answer.save!

    assert_equal 1, user.current_streak

    game = games(:parentheses)
    answer = Answer.new(answer: "What is why can't I?", game: game, user: user)
    answer.save!

    assert_equal 2, user.current_streak

    game = games(:or)
    answer = Answer.new(answer: "Who is george costanza?", game: game, user: user)
    answer.save!

    assert_equal 0, user.current_streak
  end

  test "answers are counted correctly" do
    user = users(:three)
    game = games(:one)

    assert_equal 0, user.correct_answers
    assert_equal 0, user.incorrect_answers
    assert_equal 0.0, user.correct_percentage

    answer = Answer.new(answer: "Who is John Doe?", game: game, user: user)
    answer.save!

    assert_equal 0, user.correct_answers
    assert_equal 1, user.incorrect_answers
    assert_equal 0.0, user.correct_percentage

    game = games(:two)
    answer = Answer.new(answer: "What is Plymouth Rock?", game: game, user: user)
    answer.save!

    assert_equal 1, user.correct_answers
    assert_equal 1, user.incorrect_answers
    assert_equal 50.0, user.correct_percentage

    game = games(:parentheses)
    answer = Answer.new(answer: "What is why can't I?", game: game, user: user)
    answer.save!

    assert_equal 2, user.correct_answers
    assert_equal 1, user.incorrect_answers
    assert_equal 2 * (100.0/3), user.correct_percentage
  end
end
