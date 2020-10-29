require 'oj'

class RoomsController < ApplicationController
  def show
    raise ActionController::RoutingError.new('Source not Found') unless params[:source].in?(['guardian', 'nyt'])
    raise ActionController::RoutingError.new('Series not Found') unless params[:series].in?(Series::SERIES)
    @crossword = crossword
    @parsed_crossword = JSON.parse(crossword)
    @url = url
  end

  def crossword_identifier
    [params[:source], params[:series], params[:identifier]].join('/')
  end
  helper_method :crossword_identifier

  def crossword
    if redis.exists(crossword_identifier)
      redis.get(crossword_identifier)
    else
      get_crossword_data.tap {|data| redis.set(crossword_identifier, data) }
    end
  end

  def get_crossword_data
    if params[:source] == 'guardian' then
      response = Faraday.get(url)
      html = Nokogiri::HTML(response.body)
      crossword_element = html.css('.js-crossword')
      raise ActionController::RoutingError.new('Element not Found') unless crossword_element.any?
      crossword_element.first['data-crossword-data']
    elsif params[:source] == 'nyt' then
      get_nyt_data(params[:identifier])
    end
  end

  def url
    "https://www.theguardian.com/crosswords/#{params[:series]}/#{params[:identifier]}"
  end

  def redis
    @redis ||= Rails.env.production? ? Redis.new(path: ENV['REDIS_PATH']) : Redis.new
  end

  def get_nyt_data(date)
    url = 'https://nytsyn.pzzl.com/nytsyn-crossword/nytsyncrossword?date=' + date

    response = Faraday.get(url)
    text = response.body
    sections = text.split(/\n\n/)

    solutionsText = sections[8]
    acrossText = sections[9]
    downText = sections[10]

    solutionsText.gsub! '%', ''
    solutions = solutionsText.split(/\n/)
    solutions.map! { |row| row.split('')}

    acrossHints = acrossText.split(/\n/)
    downHints = downText.split(/\n/)

    entries = []
    hintNumber = 1

    solutions.each_with_index do |val, row|
      val.each_with_index do |field, col|
        next if field == '#'
        addHint = false
        if row == 0 || solutions[row-1][col] == '#' then
          word = ''
          i = 0
          while row + i < solutions.length && solutions[row+i][col] != '#' do
            word += solutions[row+i][col]
            i += 1
          end
          entry = {
            'id' => hintNumber.to_s + '-down',
            'number' => hintNumber,
            'humanNumber' => hintNumber,
            'clue' => downHints.shift(),
            'direction' => 'down',
            'length' => word.length,
            'group' => [hintNumber.to_s + '-down'],
            'position' => { 'x' => col, 'y' => row},
            'separatorLocations' => {},
            'solution' => word
          }
          entries.push(entry)
          addHint = true
        end
        if col == 0 || solutions[row][col-1] == '#' then
            word = ''
            i = 0
          while col + i < solutions[0].length && solutions[row][col+i] != '#' do
            word += solutions[row][col+i]
            i += 1
          end
          entry = {
            'id' => hintNumber.to_s + '-across',
            'number' => hintNumber,
            'humanNumber' => hintNumber,
            'clue' => acrossHints.shift(),
            'direction' => 'across',
            'length' => word.length,
            'group' => [hintNumber.to_s + '-across'],
            'position' => { 'x' => col, 'y' => row},
            'separatorLocations' => {},
            'solution' => word
          }
          entries.push(entry)
          addHint = true
        end
        if addHint then
          hintNumber += 1
        end
      end
    end
    data = {
      'id' => 'simple/1',
      'number' => 1,
      'name' =>'NYT',
      'date' => 1542326400000,
      'entries' => entries,
      'solutionAvailable'=>true, # no clue what these do
      'dateSolutionAvailable' =>1603670400000, # no clue what these do
      'dimensions'=> {
        'cols'=>solutions.length,
        'rows'=>solutions[0].length
      }, 
      'crosswordType'=>'nyt'
    }
    Oj.dump data
  end
end

