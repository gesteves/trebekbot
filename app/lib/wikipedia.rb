module Wikipedia
  def self.search(text)
    uri = "https://en.wikipedia.org/w/api.php"
    query = {
      action: "opensearch",
      search: text,
      format: "json",
      limit: 1
    }
    body = HTTParty.get("https://en.wikipedia.org/w/api.php", query: query).body
    response = JSON.parse(body, symbolize_names: true)
    response&.last&.first
  end
end
