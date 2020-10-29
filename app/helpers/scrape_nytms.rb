require 'faraday'

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
          :id => hintNumber.to_s + '-down',
          :number => hintNumber,
          :humanNumber => hintNumber,
          :clue => downHints.shift(),
          :direction => 'down',
          :length => word.length,
          :group => [hintNumber.to_s + '-down'],
          :position => { :x => col, :y => row},
          :separatorLocations => {},
          :solution => word
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
          :id => hintNumber.to_s + '-across',
          :number => hintNumber,
          :humanNumber => hintNumber,
          :clue => acrossHints.shift(),
          :direction => 'across',
          :length => word.length,
          :group => [hintNumber.to_s + '-across'],
          :position => { :x => col, :y => row},
          :separatorLocations => {},
          :solution => word
        }
        entries.push(entry)
        addHint = true
        if addHint then
          hintNumber += 1
        end
      end
    end
  end
  return entries
end