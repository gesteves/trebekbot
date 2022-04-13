module Wikipedia
  def self.search(text)
    regex = Regexp.new(/#{text}/i)
    query = {
      action: "opensearch",
      search: text,
      format: "json"
    }
    body = HTTParty.get("https://en.wikipedia.org/w/api.php", query: query).body
    response = JSON.parse(body, symbolize_names: true)
    response&.last&.first
  end
end
