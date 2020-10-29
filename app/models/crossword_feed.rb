class CrosswordFeed
  def self.load
    self.load_nyt
    # self.load_guardian
  end

  def self.redis
    @redis ||= Rails.env.production? ? Redis.new(path: ENV['REDIS_PATH']) : Redis.new
  end

  def self.load_nyt
    today = Date.today
    for i in 0...35 do
      date = today - i
      identifier = date.strftime('%y%m%d')
      response = Faraday.get 'https://nytsyn.pzzl.com/nytsyn-crossword/nytsyncrossword?date=' + identifier
      next if response.status != 200

      day = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'][date.wday]

      crossword = Crossword.new(
      "title" => day,
      "source" => 'nyt',
      "series" => day,
      "identifier" => identifier,
      "date" => date.to_datetime.xmlschema
    )
    crossword.save
    end
  end

  def self.load_guardian 
    response = Faraday.get "https://www.theguardian.com/crosswords/rss"
    xml = Nokogiri::XML(response.body)
    xml.css('item').each do |element|
      link = element.css('link').text
      series, identifier = link.split('/').last(2)
      next unless series.in?(Series::SERIES)

      crossword = Crossword.new(
        "title" => element.css('title').text,
        "source" => 'guardian',
        "series" => series,
        "identifier" => identifier,
        "date" => element.at('dc|date').text
      )
      crossword.save
    end
  end
end
