require "test_helper"

class ScoreboardPresenterTest < ActiveSupport::TestCase
  test "renders blocks" do
    team = teams(:one)
    blocks = ScoreboardPresenter.new(team).to_blocks

    assert_equal "section", blocks[0][:type]
    assert_equal "divider", blocks[1][:type]
  end
end
