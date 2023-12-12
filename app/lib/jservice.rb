module Jservice
  QUESTION_BLOCKLIST = %w{
    seen here
    audio clue
    clue crew
  }

  def self.get_question
    uri = "http://jservice.io/api/random?count=1"
    request = HTTParty.get(uri)
    return if response.code != 200
    response = JSON.parse(request.body, symbolize_names: true).first
    question = response[:question]

    if QUESTION_BLOCKLIST.any? { |phrase| question.downcase.include?(phrase) } || response[:invalid_count].to_i > 0
      response = get_question
    end

    response[:value] = 200 if response[:value].blank?
    response[:question] = Sanitize.fragment(response[:question].gsub(/\\/, ""))
    response[:category][:title] = Sanitize.fragment(response[:category][:title].gsub(/\\/, ""))
    response[:answer] = Sanitize.fragment(response[:answer].gsub(/\\/, ""))
    response
  end
end
