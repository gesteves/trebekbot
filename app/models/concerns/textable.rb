module Textable
  extend ActiveSupport::Concern
  include ActiveSupport::Inflector

  QUESTION_REGEX = /^(what|where|when|who)/i

  private
  # Normalizes text to make it easier to compare,
  # by removing punctuation, question words and marks, etc.
  def normalize(text)
    transliterate(text)
      .gsub(QUESTION_REGEX, "")
      .gsub(/['"“”‘’_-]/, "")
      .gsub(/^\s*+(is|are|was|were|s) /, "")
      .gsub(/^\s*+(the|a|an) /i, "")
      .gsub(/\s+(&amp;|&)\s+/i, " and ")
      .gsub(/\?+$/, "")
      .strip
      .downcase
  end

  def is_question?(text)
    text.strip.match? QUESTION_REGEX
  end

  def decode_html_entities(text)
    coder = HTMLEntities.new
    coder.decode(text)
  end
end
