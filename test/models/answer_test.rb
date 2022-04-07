require "test_helper"

class AnswerTest < ActiveSupport::TestCase
  test "does not accept answers not in the form of a question" do
    game = games(:one)
    user = users(:one)
    answer = Answer.new(answer: game.answer, game: game, user: user)
    answer.save!

    assert answer.is_answer_correct?
    assert_not answer.is_in_question_format?
    assert_not answer.is_correct?
  end

  test "accepts answers in the form of a question" do
    game = games(:one)
    user = users(:one)
    answer = Answer.new(answer: "Who is #{game.answer}?", game: game, user: user)
    answer.save!
    assert answer.is_answer_correct?
    assert answer.is_in_question_format?
    assert answer.is_correct?

    answer.answer = "who's #{game.answer}"
    answer.save!
    assert answer.is_answer_correct?
    assert answer.is_in_question_format?
    assert answer.is_correct?

    answer.answer = "whos #{game.answer}"
    answer.save!
    assert answer.is_answer_correct?
    assert answer.is_in_question_format?
    assert answer.is_correct?

    answer.answer = "whats #{game.answer}"
    answer.save!
    assert answer.is_answer_correct?
    assert answer.is_in_question_format?
    assert answer.is_correct?

    answer.answer = "where is #{game.answer}"
    answer.save!
    assert answer.is_answer_correct?
    assert answer.is_in_question_format?
    assert answer.is_correct?

    answer.answer = "what is a #{game.answer}?"
    answer.save!
    assert answer.is_answer_correct?
    assert answer.is_in_question_format?
    assert answer.is_correct?
  end

  test "accepts reasonable misspellings in answers" do
    game = games(:one)
    user = users(:one)
    answer = Answer.new(answer: "Who is #{game.answer}?", game: game, user: user)
    answer.save!
    assert answer.is_answer_correct?
    assert answer.is_in_question_format?
    assert answer.is_correct?

    answer.answer = "who is walther mathau"
    answer.save!
    assert answer.is_answer_correct?
    assert answer.is_in_question_format?
    assert answer.is_correct?

    answer.answer = "whos a waltter mathau"
    answer.save!
    assert answer.is_answer_correct?
    assert answer.is_in_question_format?
    assert answer.is_correct?

    answer.answer = "whats wallter mathau"
    answer.save!
    assert answer.is_answer_correct?
    assert answer.is_in_question_format?
    assert answer.is_correct?

    answer.answer = "where is walltther mathau"
    answer.save!
    assert answer.is_answer_correct?
    assert answer.is_in_question_format?
    assert answer.is_correct?

    answer.answer = "what is a walther mathhau?"
    answer.save!
    assert answer.is_answer_correct?
    assert answer.is_in_question_format?
    assert answer.is_correct?
  end

  test "considers text in parentheses as optional" do
    game = games(:parentheses)
    user = users(:one)

    answer = Answer.new(answer: "What is #{game.answer}?", game: game, user: user)
    answer.save!
    assert answer.is_correct?

    answer.answer = "What is why cant I?"
    answer.save!

    assert answer.is_correct?
  end

  test "considers either option correct in answers that contain 'or'" do
    game = games(:or)
    user = users(:one)

    answer = Answer.new(answer: "Who are #{game.answer}?", game: game, user: user)
    answer.save!
    assert answer.is_correct?

    answer.answer = "Who is Seinfeld?"
    answer.save!
    assert answer.is_correct?


    answer.answer = "Who is Kramer?"
    answer.save!
    assert answer.is_correct?
  end

  test "accepts numeric answers" do
    game = games(:four)
    user = users(:one)

    answer = Answer.new(answer: "What is 4?", game: game, user: user)
    answer.save!
    assert answer.is_correct?
  end

  test "accepts answers with accents" do
    game = games(:cremebrulee)
    user = users(:one)

    answer = Answer.new(answer: "What is creme brulee", game: game, user: user)
    answer.save!
    assert answer.is_correct?
  end
end
