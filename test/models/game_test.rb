require "test_helper"

class GameTest < ActiveSupport::TestCase
  test "renders Slack blocks" do
    game = games(:cremebrulee)
    blocks = game.to_blocks

    assert_equal "*Desserts & Stuff* | $100 | Aired April 2, 2022", blocks[0][:elements][0][:text]
    assert_equal "It's the 2-word French name for a custard dessert with a hard, caramelized sugar topping", blocks[1][:label][:text]
  end
end
