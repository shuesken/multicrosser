require 'oj'

class RoomsController < ApplicationController
  def show
    raise ActionController::RoutingError.new('Source not Found') unless params[:source].in?(['guardian', 'nyt', 'zeit'])
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
    elsif params[:source] == 'zeit' then
      get_zeit
    end
  end

  def url
    "https://www.theguardian.com/crosswords/#{params[:series]}/#{params[:identifier]}"
  end

  def redis
    @redis ||= Redis.new
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
      'id' => date,
      'number' => date,
      'name' =>'NYT',
      'date' => 1542326400000,
      'entries' => entries,
      'solutionAvailable'=>true, # no clue what these do
      'dateSolutionAvailable' =>1603670400000, # no clue what these do
      'dimensions'=> {
        'cols'=>solutions.length,
        'rows'=>solutions[0].length
      }, 
      'crosswordType'=>'everyman' # review this, needs to be one of the guardian ones to work in chrome/safari
    }
    Oj.dump data
  end

  def get_zeit
    json = %q|{
  "id": 2562,
  "number": 2562,
  "name": "Zeit",
  "date": 1542326400000,
  "entries": [
    {
      "id": "1-down",
      "number": "1",
      "humanNumber": "1",
      "clue": "Nicht aufgeben: Wie ernten Torwarte Jubel? ",
      "direction": "down",
      "length": 11,
      "group": [
        "1-down"
      ],
      "position": {
        "x": 2,
        "y": 0
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "2-down",
      "number": "2",
      "humanNumber": "2",
      "clue": "VespasiAnknüpfer ",
      "direction": "down",
      "length": 5,
      "group": [
        "2-down"
      ],
      "position": {
        "x": 5,
        "y": 0
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "3-down",
      "number": "3",
      "humanNumber": "3",
      "clue": "Wer’s robust mag, lässt sich einen Strick daraus drehen ",
      "direction": "down",
      "length": 5,
      "group": [
        "3-down"
      ],
      "position": {
        "x": 7,
        "y": 0
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "4-down",
      "number": "4",
      "humanNumber": "4",
      "clue": "In der Lese: keine Männergruppe ",
      "direction": "down",
      "length": 5,
      "group": [
        "4-down"
      ],
      "position": {
        "x": 10,
        "y": 0
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "5-down",
      "number": "5",
      "humanNumber": "5",
      "clue": "Rasch: den 29 waagerecht nachgesagt als Revierbegrünung ",
      "direction": "down",
      "length": 5,
      "group": [
        "5-down"
      ],
      "position": {
        "x": 13,
        "y": 0
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "6-down",
      "number": "6",
      "humanNumber": "6",
      "clue": "Kräftigste Verstärkung für der Donau kräftigste Verstärkung ",
      "direction": "down",
      "length": 5,
      "group": [
        "6-down"
      ],
      "position": {
        "x": 15,
        "y": 0
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "7-across",
      "number": "7",
      "humanNumber": "7",
      "clue": "Ihr ist nichts Medienkonsumweltliches fremd ",
      "direction": "across",
      "length": 11,
      "group": [
        "7-across"
      ],
      "position": {
        "x": 1,
        "y": 1
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "7-down",
      "number": "7",
      "humanNumber": "7",
      "clue": "Fordern im Koch die Bäckertalente ",
      "direction": "down",
      "length": 8,
      "group": [
        "7-down"
      ],
      "position": {
        "x": 1,
        "y": 1
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "8-down",
      "number": "8",
      "humanNumber": "8",
      "clue": "Stationen im Dienstwegenetz ",
      "direction": "down",
      "length": 9,
      "group": [
        "8-down"
      ],
      "position": {
        "x": 3,
        "y": 1
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "9-down",
      "number": "9",
      "humanNumber": "9",
      "clue": "Die Welt, im Bau befindlich, nutzt nichts mehr als ihn ",
      "direction": "down",
      "length": 6,
      "group": [
        "9-down"
      ],
      "position": {
        "x": 6,
        "y": 1
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "10-down",
      "number": "10",
      "humanNumber": "10",
      "clue": "Die Liebe schenkt ohne Fordern, empfängt ohne ..., verzeiht ohne Zögern (Peter Lippert) ",
      "direction": "down",
      "length": 9,
      "group": [
        "10-down"
      ],
      "position": {
        "x": 8,
        "y": 1
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "11-down",
      "number": "11",
      "humanNumber": "11",
      "clue": "An mehreren ... zu ..., das kann notwendig werden im Rahmen einer Komplettagenda ",
      "direction": "down",
      "length": 5,
      "group": [
        "11-down"
      ],
      "position": {
        "x": 9,
        "y": 1
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "12-down",
      "number": "12",
      "humanNumber": "12",
      "clue": "Gletscher-Andenken, passt gut in den Pappton ",
      "direction": "down",
      "length": 3,
      "group": [
        "12-down"
      ],
      "position": {
        "x": 11,
        "y": 1
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "13-across",
      "number": "13",
      "humanNumber": "13",
      "clue": "Klingt nämlich fast wie Stimmungsaufhella-Wort aus dem Wertabericht ",
      "direction": "across",
      "length": 5,
      "group": [
        "13-across"
      ],
      "position": {
        "x": 12,
        "y": 1
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "13-down",
      "number": "13",
      "humanNumber": "13",
      "clue": "Kundenkreisförmiges Gebilde ",
      "direction": "down",
      "length": 8,
      "group": [
        "13-down"
      ],
      "position": {
        "x": 12,
        "y": 1
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "14-across",
      "number": "14",
      "humanNumber": "14",
      "clue": "Gut Ding will Weile haben und ihm unterzogen sein ",
      "direction": "across",
      "length": 9,
      "group": [
        "14-across"
      ],
      "position": {
        "x": 0,
        "y": 2
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "15-down",
      "number": "15",
      "humanNumber": "15",
      "clue": "..., Geschwätzigkeit, Eitelkeit sind von der gleichen Art. In jedem Lande, zu jeder Zeit sind sie mit Dummheit gepaart (Jean de La Fontaine) ",
      "direction": "down",
      "length": 7,
      "group": [
        "15-down"
      ],
      "position": {
        "x": 4,
        "y": 2
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "16-across",
      "number": "16",
      "humanNumber": "16",
      "clue": "Die Spiegel in den Räumlichkeiten der Sprache ",
      "direction": "across",
      "length": 9,
      "group": [
        "16-across"
      ],
      "position": {
        "x": 9,
        "y": 2
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "17-down",
      "number": "17",
      "humanNumber": "17",
      "clue": "Kurz: sorgt für Kassenklingeln bei Musikschaffenden ",
      "direction": "down",
      "length": 4,
      "group": [
        "17-down"
      ],
      "position": {
        "x": 14,
        "y": 2
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "18-down",
      "number": "18",
      "humanNumber": "18",
      "clue": "Mehr als aufmerkwürdig, geradezu insaugesprunghaft ",
      "direction": "down",
      "length": 8,
      "group": [
        "18-down"
      ],
      "position": {
        "x": 16,
        "y": 2
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "19-across",
      "number": "19",
      "humanNumber": "19",
      "clue": "Distanz-Überwinder darf’s nicht sein ",
      "direction": "across",
      "length": 5,
      "group": [
        "19-across"
      ],
      "position": {
        "x": 1,
        "y": 3
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "20-across",
      "number": "20",
      "humanNumber": "20",
      "clue": "Garniertem fehlt nichts, um — wohlgeordnet — Gärten aufzuhübschen ",
      "direction": "across",
      "length": 10,
      "group": [
        "20-across"
      ],
      "position": {
        "x": 6,
        "y": 3
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "21-across",
      "number": "21",
      "humanNumber": "21",
      "clue": "Im Korrespondentenfokus oft insbesondere jenes in White ",
      "direction": "across",
      "length": 5,
      "group": [
        "21-across"
      ],
      "position": {
        "x": 2,
        "y": 4
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "22-across",
      "number": "22",
      "humanNumber": "22",
      "clue": "Leere Töpfe machen den größten ... (Sprichwort) ",
      "direction": "across",
      "length": 5,
      "group": [
        "22-across"
      ],
      "position": {
        "x": 7,
        "y": 4
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "23-down",
      "number": "23",
      "humanNumber": "23",
      "clue": "Auf Kalkdünger mag verzichten, wer solchen Boden bebaut ",
      "direction": "down",
      "length": 6,
      "group": [
        "23-down"
      ],
      "position": {
        "x": 11,
        "y": 4
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "24-across",
      "number": "24",
      "humanNumber": "24",
      "clue": "Erstreckt sich von Mittag bis Mittag, für Seemeilensammler ",
      "direction": "across",
      "length": 5,
      "group": [
        "24-across"
      ],
      "position": {
        "x": 12,
        "y": 4
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "25-across",
      "number": "25",
      "humanNumber": "25",
      "clue": "Liebe und Ehe sind voll Honig und ... (Sprichwort) ",
      "direction": "across",
      "length": 4,
      "group": [
        "25-across"
      ],
      "position": {
        "x": 0,
        "y": 5
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "26-across",
      "number": "26",
      "humanNumber": "26",
      "clue": "Erweist sich als durchaus erfolgreich in Fluganstrengungen ",
      "direction": "across",
      "length": 4,
      "group": [
        "26-across"
      ],
      "position": {
        "x": 4,
        "y": 5
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "27-down",
      "number": "27",
      "humanNumber": "27",
      "clue": "Fabelhafte Weltbürgerin der glücksbringenden Pläne ",
      "direction": "down",
      "length": 6,
      "group": [
        "27-down"
      ],
      "position": {
        "x": 5,
        "y": 5
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "28-down",
      "number": "28",
      "humanNumber": "28",
      "clue": "Das macht 22 waagerecht, sei’s im Wald, sei’s im Bett ",
      "direction": "down",
      "length": 6,
      "group": [
        "28-down"
      ],
      "position": {
        "x": 7,
        "y": 5
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "29-across",
      "number": "29",
      "humanNumber": "29",
      "clue": "Wo welche auftauchen, bemerkt man gleich die Verwandtschaft zur 26 waagerecht ",
      "direction": "across",
      "length": 5,
      "group": [
        "29-across"
      ],
      "position": {
        "x": 8,
        "y": 5
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "30-down",
      "number": "30",
      "humanNumber": "30",
      "clue": "Schein, aus Beweisgründen zu wahren ",
      "direction": "down",
      "length": 6,
      "group": [
        "30-down"
      ],
      "position": {
        "x": 10,
        "y": 5
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "31-across",
      "number": "31",
      "humanNumber": "31",
      "clue": "Gern angesprochen vom enfant — nicht nur des Reimes wegen ",
      "direction": "across",
      "length": 5,
      "group": [
        "31-across"
      ],
      "position": {
        "x": 13,
        "y": 5
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "31-down",
      "number": "31",
      "humanNumber": "31",
      "clue": "Allzu sehr im Freien saß seine Frühstückerin, fand das Publikum ",
      "direction": "down",
      "length": 6,
      "group": [
        "31-down"
      ],
      "position": {
        "x": 13,
        "y": 5
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "32-down",
      "number": "32",
      "humanNumber": "32",
      "clue": "Rest von Alphabetes Schluss, in Millionenfach-Verwendung ",
      "direction": "down",
      "length": 4,
      "group": [
        "32-down"
      ],
      "position": {
        "x": 15,
        "y": 5
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "33-across",
      "number": "33",
      "humanNumber": "33",
      "clue": "Strömt sehr meerfern, kann kein Meer erreichen ",
      "direction": "across",
      "length": 5,
      "group": [
        "33-across"
      ],
      "position": {
        "x": 1,
        "y": 6
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "34-across",
      "number": "34",
      "humanNumber": "34",
      "clue": "Quillt recht altmühlnah, strebt ganz anderen Gewässern zu ",
      "direction": "across",
      "length": 6,
      "group": [
        "34-across"
      ],
      "position": {
        "x": 6,
        "y": 6
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "35-down",
      "number": "35",
      "humanNumber": "35",
      "clue": "Qualität der Welt, die Schwarzweiß-Denker fürchten ",
      "direction": "down",
      "length": 4,
      "group": [
        "35-down"
      ],
      "position": {
        "x": 9,
        "y": 6
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "36-across",
      "number": "36",
      "humanNumber": "36",
      "clue": "Heimlichtuer ist leicht aufgebracht, wird was draufgebracht ",
      "direction": "across",
      "length": 5,
      "group": [
        "36-across"
      ],
      "position": {
        "x": 12,
        "y": 6
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "37-down",
      "number": "37",
      "humanNumber": "37",
      "clue": "Übersee-Übergröße-Miezen ",
      "direction": "down",
      "length": 4,
      "group": [
        "37-down"
      ],
      "position": {
        "x": 14,
        "y": 6
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "38-across",
      "number": "38",
      "humanNumber": "38",
      "clue": "Schafft schlängellineare Verbindung zwischen Seenplattenseen ",
      "direction": "across",
      "length": 4,
      "group": [
        "38-across"
      ],
      "position": {
        "x": 1,
        "y": 7
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "39-across",
      "number": "39",
      "humanNumber": "39",
      "clue": "Feuerberg auf Eiskontinent ",
      "direction": "across",
      "length": 6,
      "group": [
        "39-across"
      ],
      "position": {
        "x": 5,
        "y": 7
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "40-down",
      "number": "40",
      "humanNumber": "40",
      "clue": "Fachmanns Kürzel für die Zeit nachtaktiver Augen ",
      "direction": "down",
      "length": 3,
      "group": [
        "40-down"
      ],
      "position": {
        "x": 6,
        "y": 7
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "41-across",
      "number": "41",
      "humanNumber": "41",
      "clue": "Sprichwörtlich: Zeit hätte man wohl ..., wenn man sie nur wohl anlegte ",
      "direction": "across",
      "length": 5,
      "group": [
        "41-across"
      ],
      "position": {
        "x": 11,
        "y": 7
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "42-across",
      "number": "42",
      "humanNumber": "42",
      "clue": "Platzdeckenverwendung wie auch Platziertenstatus ",
      "direction": "across",
      "length": 10,
      "group": [
        "42-across"
      ],
      "position": {
        "x": 0,
        "y": 8
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "43-across",
      "number": "43",
      "humanNumber": "43",
      "clue": "Fernseh-Mitarbeiter? Ba-Rockstar! ",
      "direction": "across",
      "length": 8,
      "group": [
        "43-across"
      ],
      "position": {
        "x": 10,
        "y": 8
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "44-across",
      "number": "44",
      "humanNumber": "44",
      "clue": "Aus dem Mitleid mit anderen erwächst die feurige, die muntere Barmherzigkeit; aus dem Mitleid mit uns selbst die weichliche, feige ....(M. v. Ebner-Eschenbach) ",
      "direction": "across",
      "length": 3,
      "group": [
        "44-across"
      ],
      "position": {
        "x": 1,
        "y": 9
      },
      "separatorLocations": {},
      "solution": null
    }
  ],
  "solutionAvailable": false,
  "dateSolutionAvailable": 1603670400000,
  "dimensions": {
    "cols": 18,
    "rows": 11
  },
  "crosswordType": "everyman"
}|
  cw = JSON.parse(json)
  Oj.dump cw
  end
end

