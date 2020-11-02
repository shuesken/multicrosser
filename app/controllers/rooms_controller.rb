require 'oj'

class RoomsController < ApplicationController
  def show
    raise ActionController::RoutingError.new('Source not Found') unless params[:source].in?(['guardian', 'nyt', 'zeit'])
    raise ActionController::RoutingError.new('Series not Found') unless params[:series].in?(Series::SERIES)
    @crossword = crossword
    puts 'here is the crossword'
    puts crossword
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
    puts 'assigning json'
    json = %q|{
  "id": 2561,
  "number": 2561,
  "name": "Zeit",
  "date": 1542326400000,
  "entries": [
    {
      "id": "1-down",
      "number": "1",
      "humanNumber": "1",
      "clue": "Polit-Frage: Muss es immer das sein, das unsere 6 senkrecht absichert — bis zum letzten Tropfen? ",
      "direction": "down",
      "length": 4,
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
      "clue": "Kann mehr als Reste: Manche brennen darauf, ihn weiterzuverwenden ",
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
      "clue": "Der wäre Gefahrenentschärfer? Das trägt Botschaft! ",
      "direction": "down",
      "length": 1,
      "group": [
        "3-down"
      ],
      "position": {
        "x": 9,
        "y": 0
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "4-down",
      "number": "4",
      "humanNumber": "4",
      "clue": "Sind für die 13 senkrecht da, und zwar eher für die munteren als für die ... ",
      "direction": "down",
      "length": 8,
      "group": [
        "4-down"
      ],
      "position": {
        "x": 12,
        "y": 0
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "5-down",
      "number": "5",
      "humanNumber": "5",
      "clue": "Auf seiner Bahn zu sehen, aber auch im Laden zu haben, wenn man sich beeilt ",
      "direction": "down",
      "length": 10,
      "group": [
        "5-down"
      ],
      "position": {
        "x": 15,
        "y": 0
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "6-across",
      "number": "6",
      "humanNumber": "6",
      "clue": "Gezüchtet für zugigen Garten? Gemacht für Richtungsentscheidungen! ",
      "direction": "across",
      "length": 8,
      "group": [
        "6-across"
      ],
      "position": {
        "x": 1,
        "y": 1
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "6-down",
      "number": "6",
      "humanNumber": "6",
      "clue": "Staatsvorsatz, und dabei ist nicht nur an Komfortzug und Bequemkarosse gedacht ",
      "direction": "down",
      "length": 2,
      "group": [
        "6-down"
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
      "clue": "Seinetwegen wird öfter mal die Brause, selten der Duschkopf bemühr ",
      "direction": "down",
      "length": 9,
      "group": [
        "7-down"
      ],
      "position": {
        "x": 4,
        "y": 1
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "8-down",
      "number": "8",
      "humanNumber": "8",
      "clue": "Besonderes Stammareal auch: Idee in Fortführung des Abnutzschutzgedankens ",
      "direction": "down",
      "length": 8,
      "group": [
        "8-down"
      ],
      "position": {
        "x": 7,
        "y": 1
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "9-down",
      "number": "9",
      "humanNumber": "9",
      "clue": "Sprichwörtlich: Die Liebe ist blind, die ... ist hellsichtig ",
      "direction": "down",
      "length": 7,
      "group": [
        "9-down"
      ],
      "position": {
        "x": 8,
        "y": 1
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "10-across",
      "number": "10",
      "humanNumber": "10",
      "clue": "Moderne Mäuse sind mitunter reich ...: händisches Handeln ",
      "direction": "across",
      "length": 8,
      "group": [
        "10-across"
      ],
      "position": {
        "x": 9,
        "y": 1
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "11-down",
      "number": "11",
      "humanNumber": "11",
      "clue": "Fremdlingsfluss in der Philippinenkapitale ",
      "direction": "down",
      "length": 2,
      "group": [
        "11-down"
      ],
      "position": {
        "x": 10,
        "y": 1
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "12-down",
      "number": "12",
      "humanNumber": "12",
      "clue": "So darf man einen nennen, dem das Moos nicht in der Tasche festgewachsen ",
      "direction": "down",
      "length": 6,
      "group": [
        "12-down"
      ],
      "position": {
        "x": 13,
        "y": 1
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "13-down",
      "number": "13",
      "humanNumber": "13",
      "clue": "Eine war längst über alle city limits hinaus bekannt, als andere eine Stark wurde ",
      "direction": "down",
      "length": 5,
      "group": [
        "13-down"
      ],
      "position": {
        "x": 14,
        "y": 1
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "14-across",
      "number": "14",
      "humanNumber": "14",
      "clue": "Der Veredelung wegen geht dabei Leckerei tauchen ",
      "direction": "across",
      "length": 6,
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
      "clue": "Waren Wegeerlediger schon zu pferdestärkeren Zeiten ",
      "direction": "down",
      "length": 4,
      "group": [
        "15-down"
      ],
      "position": {
        "x": 3,
        "y": 2
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "16-across",
      "number": "16",
      "humanNumber": "16",
      "clue": "Per Kreuzung erhältlich — und guter Friseur kann’s auf den ... genau ",
      "direction": "across",
      "length": 12,
      "group": [
        "16-across"
      ],
      "position": {
        "x": 6,
        "y": 2
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "16-down",
      "number": "16",
      "humanNumber": "16",
      "clue": "Wer kein Cash hat, hat schon alle Zeichen jener Frustbereiterin ",
      "direction": "down",
      "length": 2,
      "group": [
        "16-down"
      ],
      "position": {
        "x": 6,
        "y": 2
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "17-down",
      "number": "17",
      "humanNumber": "17",
      "clue": "Spielen häufig eine Rolle fürs Räumekostüm ",
      "direction": "down",
      "length": 2,
      "group": [
        "17-down"
      ],
      "position": {
        "x": 11,
        "y": 2
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "18-down",
      "number": "18",
      "humanNumber": "18",
      "clue": "Niemand ist ohne ... außer dem, der keine Fragen stellt (Sprichwort) ",
      "direction": "down",
      "length": 7,
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
      "clue": "Das Talent zu ... täuscht oft über den Mangel an anderen Talenten (M. v. Ebner-Eschenbach) ",
      "direction": "across",
      "length": 9,
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
      "clue": "Nicht immer fest einbetoniert: Manche geht mit mir, indem ich mit ihr gehe ",
      "direction": "across",
      "length": 7,
      "group": [
        "20-across"
      ],
      "position": {
        "x": 10,
        "y": 3
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "21-across",
      "number": "21",
      "humanNumber": "21",
      "clue": "Hier über der Glut, da Namensgeber für einen Ton der Farbe des Feuers ",
      "direction": "across",
      "length": 4,
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
      "clue": "Der erzählte was vom Pferd, das böse Überraschung brachte ",
      "direction": "across",
      "length": 5,
      "group": [
        "22-across"
      ],
      "position": {
        "x": 6,
        "y": 4
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "23-down",
      "number": "23",
      "humanNumber": "23",
      "clue": "Romeo sieht man dorthin fliehen, und Rigolerto ist schon da ",
      "direction": "down",
      "length": 4,
      "group": [
        "23-down"
      ],
      "position": {
        "x": 8,
        "y": 4
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "24-down",
      "number": "24",
      "humanNumber": "24",
      "clue": "Seine Verwendung ist eng verflochten mit Möblierung ",
      "direction": "down",
      "length": 1,
      "group": [
        "24-down"
      ],
      "position": {
        "x": 10,
        "y": 4
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "25-across",
      "number": "25",
      "humanNumber": "25",
      "clue": "Eine umgängliche Variante des Ruhenlassens der Lider ",
      "direction": "across",
      "length": 6,
      "group": [
        "25-across"
      ],
      "position": {
        "x": 11,
        "y": 4
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "26-across",
      "number": "26",
      "humanNumber": "26",
      "clue": "Mancherorts schnell, hier aber nicht ganz ",
      "direction": "across",
      "length": 4,
      "group": [
        "26-across"
      ],
      "position": {
        "x": 1,
        "y": 5
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "27-across",
      "number": "27",
      "humanNumber": "27",
      "clue": "Ward mitgedacht bei Ole-Rufen an den Biathlonpisten ",
      "direction": "across",
      "length": 5,
      "group": [
        "27-across"
      ],
      "position": {
        "x": 5,
        "y": 5
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "28-across",
      "number": "28",
      "humanNumber": "28",
      "clue": "Der Plan, den man nicht ... kann, ist schlecht (Sallust) ",
      "direction": "across",
      "length": 7,
      "group": [
        "28-across"
      ],
      "position": {
        "x": 10,
        "y": 5
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "29-across",
      "number": "29",
      "humanNumber": "29",
      "clue": "Das lange, schlanke Ende vom großvolumigen Raum ",
      "direction": "across",
      "length": 3,
      "group": [
        "29-across"
      ],
      "position": {
        "x": 0,
        "y": 6
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "30-across",
      "number": "30",
      "humanNumber": "30",
      "clue": "Heimisches Verkehrsmittel im Raleigh-Umland ",
      "direction": "across",
      "length": 3,
      "group": [
        "30-across"
      ],
      "position": {
        "x": 3,
        "y": 6
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "31-down",
      "number": "31",
      "humanNumber": "31",
      "clue": "Ist stets in Gedanken, die Dame ",
      "direction": "down",
      "length": 4,
      "group": [
        "31-down"
      ],
      "position": {
        "x": 4,
        "y": 6
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "32-across",
      "number": "32",
      "humanNumber": "32",
      "clue": "Regieren ist eine ..., keine Wissenschaft (L. Börne) ",
      "direction": "across",
      "length": 5,
      "group": [
        "32-across"
      ],
      "position": {
        "x": 6,
        "y": 6
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "33-down",
      "number": "33",
      "humanNumber": "33",
      "clue": "Gehört da zu heiligem Franz, sind dort businessman’s Stolz ",
      "direction": "down",
      "length": 5,
      "group": [
        "33-down"
      ],
      "position": {
        "x": 9,
        "y": 6
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "34-across",
      "number": "34",
      "humanNumber": "34",
      "clue": "A very British way of Hochgenuss ",
      "direction": "across",
      "length": 3,
      "group": [
        "34-across"
      ],
      "position": {
        "x": 11,
        "y": 6
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "35-down",
      "number": "35",
      "humanNumber": "35",
      "clue": "Mehr als der Argumentiereifer können oft deren Zungen gewinnen ",
      "direction": "down",
      "length": 2,
      "group": [
        "35-down"
      ],
      "position": {
        "x": 12,
        "y": 6
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "36-across",
      "number": "36",
      "humanNumber": "36",
      "clue": "Tippe, die kann immer nur Teilantwort in der Schuldenfrage sein ",
      "direction": "across",
      "length": 4,
      "group": [
        "36-across"
      ],
      "position": {
        "x": 14,
        "y": 6
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "37-down",
      "number": "37",
      "humanNumber": "37",
      "clue": "Weise: 32 waagerecht, wo der 34 waagerecht auf den Tisch kommt ",
      "direction": "down",
      "length": 4,
      "group": [
        "37-down"
      ],
      "position": {
        "x": 15,
        "y": 6
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "38-across",
      "number": "38",
      "humanNumber": "38",
      "clue": "Das Senfhäubchen auf dem Malheur des Pechvogels ",
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
      "clue": "Stimmhaft und stimmungsvoll: dargebracht schon als Barockmusik ",
      "direction": "across",
      "length": 8,
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
      "id": "39-down",
      "number": "39",
      "humanNumber": "39",
      "clue": "Die Dorn im Auge des »Tatort«Betrachters ",
      "direction": "down",
      "length": 4,
      "group": [
        "39-down"
      ],
      "position": {
        "x": 5,
        "y": 7
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "40-across",
      "number": "40",
      "humanNumber": "40",
      "clue": "Fügt sich stadtlich ein zwischen Okto und acht, wenn's um die Zeit von Halloween geht ",
      "direction": "across",
      "length": 4,
      "group": [
        "40-across"
      ],
      "position": {
        "x": 13,
        "y": 7
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "41-down",
      "number": "41",
      "humanNumber": "41",
      "clue": "Es ist ein ..., wer mit einem ... streitet (Sprichwort) ",
      "direction": "down",
      "length": 4,
      "group": [
        "41-down"
      ],
      "position": {
        "x": 14,
        "y": 7
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "42-across",
      "number": "42",
      "humanNumber": "42",
      "clue": "Wer’s mag, vermisst nicht laufend das feste Dach überm Kopf ",
      "direction": "across",
      "length": 8,
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
      "clue": "Alter Kämpe, eingangs zentralasiatischer Hauptstadt erwähnt ",
      "direction": "across",
      "length": 4,
      "group": [
        "43-across"
      ],
      "position": {
        "x": 8,
        "y": 8
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "44-across",
      "number": "44",
      "humanNumber": "44",
      "clue": "Vorwiegend Armarbeit für den Redenschwinger ",
      "direction": "across",
      "length": 6,
      "group": [
        "44-across"
      ],
      "position": {
        "x": 12,
        "y": 8
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "45-across",
      "number": "45",
      "humanNumber": "45",
      "clue": "Die volle Beschreibung dessen, was sie kann: gähnen! ",
      "direction": "across",
      "length": 5,
      "group": [
        "45-across"
      ],
      "position": {
        "x": 2,
        "y": 9
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "46-across",
      "number": "46",
      "humanNumber": "46",
      "clue": "Nicht lustig, nur lästig: schafft andauernde Wegvorgabe ",
      "direction": "across",
      "length": 9,
      "group": [
        "46-across"
      ],
      "position": {
        "x": 7,
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
  "crosswordType": "quiptic"
}|
  puts 'here is json'
  puts json
  cw = JSON.parse(json)
  Oj.dump cw
  end
end

