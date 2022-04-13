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
    index = response[1].index { |e| e =~ regex }
    return if index.blank?
    response.last[index]
  end
end
