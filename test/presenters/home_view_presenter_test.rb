require "test_helper"

class HomeViewPresenterTest < ActiveSupport::TestCase
  test "renders blocks" do
    user = users(:one)
    view = HomeViewPresenter.new(user).to_view

    assert_equal "home", view[:type]
    assert_equal "section", view[:blocks][0][:type]
  end
end
