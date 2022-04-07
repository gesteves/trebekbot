module Jservice
  QUESTION_BLOCKLIST = %w{
    seen here
    audio clue
  }

  def self.get_question
    uri = "http://jservice.io/api/random?count=1"
    request = HTTParty.get(uri)
    response = JSON.parse(request.body, symbolize_names: true).first
    question = response[:question]

    if question.strip.blank? || QUESTION_BLOCKLIST.any? { |phrase| question.include?(phrase) }
      response = get_question
    end

    response[:value] = 200 if response[:value].blank?
    response[:question] = Sanitize.fragment(response[:question].gsub(/\\/, "").gsub(/\s+&amp;\s+/i, " & "))
    response[:category][:title] = Sanitize.fragment(response[:category][:title].gsub(/\\/, "").gsub(/\s+&amp;\s+/i, " & "))
    response[:answer] = Sanitize.fragment(response[:answer].gsub(/\\/, "").gsub(/\s+&amp;\s+/i, " & "))
    response
  end
end
