require "test_helper"

class GamePresenterTest < ActiveSupport::TestCase
  test "renders blocks" do
    game = games(:cremebrulee)
    blocks = GamePresenter.new(game).to_blocks

    assert_equal "*Desserts & Stuff* | $100 | Aired April 2, 2022", blocks[0][:elements][0][:text]
    assert_equal "It's the 2-word French name for a custard dessert with a hard, caramelized sugar topping", blocks[1][:label][:text]
  end
end
