require "test_helper"

class SlackControllerTest < ActionDispatch::IntegrationTest
  test "should return 401 if token is wrong" do
    challenge = Digest::MD5.hexdigest(Time.now.to_i.to_s)
    post events_url, params: { token: "WRONG_TOKEN", challenge: challenge, type: 'url_verification' }
    assert_response 401
  end

  test "should return challenge for url_verification" do
    challenge = Digest::MD5.hexdigest(Time.now.to_i.to_s)
    post events_url, params: { token: ENV["SLACK_VERIFICATION_TOKEN"], challenge: challenge, type: 'url_verification' }
    assert_response :success
    assert_equal challenge, response.body
  end
end
