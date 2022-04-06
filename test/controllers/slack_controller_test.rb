require "test_helper"

class SlackControllerTest < ActionDispatch::IntegrationTest
  test "events should return 401 if token is wrong" do
    challenge = Digest::MD5.hexdigest(Time.now.to_i.to_s)
    post events_url, params: { token: "WRONG_TOKEN", challenge: challenge, type: 'url_verification' }
    assert_response 401
  end

  test "events should return challenge for url_verification" do
    challenge = Digest::MD5.hexdigest(Time.now.to_i.to_s)
    post events_url, params: { token: ENV["SLACK_VERIFICATION_TOKEN"], challenge: challenge, type: 'url_verification' }
    assert_response :success
    assert_equal challenge, response.body
  end

  test "app_mention event should start a game" do
    params = {
      token: ENV["SLACK_VERIFICATION_TOKEN"],
      team_id: "T061EG9R6",
      event: {
        type: 'app_mention',
        user: "U061F7AUR",
        text: "<@U0LAN0Z89> go",
        ts: "1515449522.000016",
        channel: "C0LAN2Q65",
        event_ts: "1515449522000016"
      }
    }
    post events_url, params: params
    assert_equal 1, StartGameWorker.jobs.size
    assert_response :success
    assert_equal "OK", response.body
  end

  test "app_mention event should send leaderboard" do
    params = {
      token: ENV["SLACK_VERIFICATION_TOKEN"],
      team_id: "T061EG9R6",
      event: {
        type: 'app_mention',
        user: "U061F7AUR",
        text: "<@U0LAN0Z89> leaderboard",
        ts: "1515449522.000016",
        channel: "C0LAN2Q65",
        event_ts: "1515449522000016"
      }
    }
    post events_url, params: params
    assert_equal 1, PostLeaderboardWorker.jobs.size
    assert_response :success
    assert_equal "OK", response.body
  end

  test "app_mention event should send player score" do
    params = {
      token: ENV["SLACK_VERIFICATION_TOKEN"],
      team_id: "T061EG9R6",
      event: {
        type: 'app_mention',
        user: "U061F7AUR",
        text: "<@U0LAN0Z89> my score",
        ts: "1515449522.000016",
        channel: "C0LAN2Q65",
        event_ts: "1515449522000016"
      }
    }
    post events_url, params: params
    assert_equal 1, PostMessageWorker.jobs.size
    assert_response :success
    assert_equal "OK", response.body
  end

  test "app_mention event should send help" do
    params = {
      token: ENV["SLACK_VERIFICATION_TOKEN"],
      team_id: "T061EG9R6",
      event: {
        type: 'app_mention',
        user: "U061F7AUR",
        text: "<@U0LAN0Z89> help",
        ts: "1515449522.000016",
        channel: "C0LAN2Q65",
        event_ts: "1515449522000016"
      }
    }
    post events_url, params: params
    assert_equal 1, PostMessageWorker.jobs.size
    assert_response :success
    assert_equal "OK", response.body
  end

  test "app_uninstalled event should destroy team" do
    slack_id = "T01234ABC"
    team = Team.new(slack_id: slack_id, access_token: 'whatever')
    team.save!

    params = {
      token: ENV["SLACK_VERIFICATION_TOKEN"],
      team_id: slack_id,
      event: {
        type: 'app_uninstalled'
      }
    }

    assert Team.find_by(slack_id: slack_id).present?

    post events_url, params: params
    assert_response :success
    assert_equal "OK", response.body

    assert_not Team.find_by(slack_id: slack_id).present?
  end

  test "interaction should process answer" do
    payload = {
      token: ENV["SLACK_VERIFICATION_TOKEN"],
      team: {
        id: "T9TK3CUKW"
      },
      user: {
        id: "UA8RXUSPL"
      },
      channel: {
        id: "CBR2V3XEX"
      },
      message: {
        ts: "1548261231.000200"
      },
      actions: [
        {
          action_id: "answer",
          value: "foobar"
        }
      ]
    }
    post interactions_url, params: { payload: payload.to_json }
    assert_equal 1, ProcessAnswerWorker.jobs.size
    assert_response :success
    assert_equal "OK", response.body
  end
end
