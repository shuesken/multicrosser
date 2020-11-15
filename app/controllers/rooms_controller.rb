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
  "id": 2563,
  "number": 2563,
  "name": "Zeit",
  "date": 1542326400000,
  "entries": [
    {
      "id": "1-down",
      "number": "1",
      "humanNumber": "1",
      "clue": "Nichtiges Gold stiehlt der Dieb, warme Herzen der ... (russ. Sprichwort) ",
      "direction": "down",
      "length": 10,
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
      "clue": "Die des Erdmantels ziehen Bergsteiger an ",
      "direction": "down",
      "length": 6,
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
      "clue": "Wo Geld vorangeht, sind alle ... offen (Shakespeare) ",
      "direction": "down",
      "length": 4,
      "group": [
        "3-down"
      ],
      "position": {
        "x": 8,
        "y": 0
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "4-down",
      "number": "4",
      "humanNumber": "4",
      "clue": "Als Teillänge beim Weihnachtenklauer abzulesen ",
      "direction": "down",
      "length": 4,
      "group": [
        "4-down"
      ],
      "position": {
        "x": 11,
        "y": 0
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "5-down",
      "number": "5",
      "humanNumber": "5",
      "clue": "Das ist Kult beim ...: viel Beinfreiheit ",
      "direction": "down",
      "length": 4,
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
      "clue": "So wird gelebt, wo nur Flora den Tisch deckt ",
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
      "clue": "Worte, mit Gewicht belegt, der Welt zur Beachtung in Schallwellen formen ",
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
      "clue": "Kultiviere die Kunst, Kollisionen der Kulturen zu vermeiden ",
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
      "clue": "Felsenfestes Zubehör einer oder vieler ",
      "direction": "down",
      "length": 3,
      "group": [
        "8-down"
      ],
      "position": {
        "x": 4,
        "y": 1
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "9-down",
      "number": "9",
      "humanNumber": "9",
      "clue": "Die Lady, die den buchstäblichen Unterschied ausmacht zwischen nördlichen Zeichen und südöstlichem Volk ",
      "direction": "down",
      "length": 3,
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
      "clue": "Kein Angebot allerdings nach nachhaltiger Nachfrage ",
      "direction": "down",
      "length": 5,
      "group": [
        "10-down"
      ],
      "position": {
        "x": 9,
        "y": 1
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "11-across",
      "number": "11",
      "humanNumber": "11",
      "clue": "Baumlanger Abschnitt der Leibesübungen ",
      "direction": "across",
      "length": 4,
      "group": [
        "11-across"
      ],
      "position": {
        "x": 12,
        "y": 1
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "11-down",
      "number": "11",
      "humanNumber": "11",
      "clue": "Haben alle mal Ja — und also Nein zum 25-senkrecht-Sein — gesagt ",
      "direction": "down",
      "length": 8,
      "group": [
        "11-down"
      ],
      "position": {
        "x": 12,
        "y": 1
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "12-down",
      "number": "12",
      "humanNumber": "12",
      "clue": "Hat ausgelacht, wird ausgelacht in der Zeit der Dominanz der Karten ",
      "direction": "down",
      "length": 5,
      "group": [
        "12-down"
      ],
      "position": {
        "x": 14,
        "y": 1
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "13-down",
      "number": "13",
      "humanNumber": "13",
      "clue": "Die meisten Menschen brauchen mehr Liebe, als sie ... (M. v. Ebner-Eschenbach) ",
      "direction": "down",
      "length": 9,
      "group": [
        "13-down"
      ],
      "position": {
        "x": 16,
        "y": 1
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "14-across",
      "number": "14",
      "humanNumber": "14",
      "clue": "Ohne wäre der Tornado kein Tornado ",
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
      "clue": "Hegt den Vorsatz, was für den Umsatz anderer zu tun ",
      "direction": "down",
      "length": 9,
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
      "clue": "Wie Glocke immer wieder, so der Bazillenträger zur Infektionshochsaison ",
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
      "id": "17-down",
      "number": "17",
      "humanNumber": "17",
      "clue": "Ein Benehmen wie ein solcher — so kommt man in die Chroniken als Känguru ",
      "direction": "down",
      "length": 8,
      "group": [
        "17-down"
      ],
      "position": {
        "x": 7,
        "y": 2
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "18-down",
      "number": "18",
      "humanNumber": "18",
      "clue": "Viele Leute auch, in gewisser HaZweiOrientierung ",
      "direction": "down",
      "length": 7,
      "group": [
        "18-down"
      ],
      "position": {
        "x": 10,
        "y": 2
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "19-across",
      "number": "19",
      "humanNumber": "19",
      "clue": "Malheur: Wer ... ging, also machte, der ist’s ",
      "direction": "across",
      "length": 6,
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
      "clue": "Sinnt auf Sinnesverwöhnung ",
      "direction": "across",
      "length": 7,
      "group": [
        "20-across"
      ],
      "position": {
        "x": 7,
        "y": 3
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "21-across",
      "number": "21",
      "humanNumber": "21",
      "clue": "Einstufung der Dinge im Falle von viel Wenigkeit ",
      "direction": "across",
      "length": 3,
      "group": [
        "21-across"
      ],
      "position": {
        "x": 14,
        "y": 3
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "22-across",
      "number": "22",
      "humanNumber": "22",
      "clue": "Anbahner des Wegs des Erdöls durch die Wüste ",
      "direction": "across",
      "length": 7,
      "group": [
        "22-across"
      ],
      "position": {
        "x": 1,
        "y": 4
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "23-down",
      "number": "23",
      "humanNumber": "23",
      "clue": "Zu kurz das Zeichen, um BriefBeiwerk zu sein ",
      "direction": "down",
      "length": 5,
      "group": [
        "23-down"
      ],
      "position": {
        "x": 4,
        "y": 4
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "24-down",
      "number": "24",
      "humanNumber": "24",
      "clue": "Genau der, der exakt erklären kann, warum er so 27 senkrecht ist ",
      "direction": "down",
      "length": 6,
      "group": [
        "24-down"
      ],
      "position": {
        "x": 6,
        "y": 4
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "25-across",
      "number": "25",
      "humanNumber": "25",
      "clue": "Die neigen zu Verhedderung, das wirkt wie Entblätterung ",
      "direction": "across",
      "length": 8,
      "group": [
        "25-across"
      ],
      "position": {
        "x": 8,
        "y": 4
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "25-down",
      "number": "25",
      "humanNumber": "25",
      "clue": "Auf-der-Suche-Lebensform, mehr oder weniger ",
      "direction": "down",
      "length": 6,
      "group": [
        "25-down"
      ],
      "position": {
        "x": 8,
        "y": 4
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "26-down",
      "number": "26",
      "humanNumber": "26",
      "clue": "Mit vielen winzigen Beiträgen macht sie summa summarum ein Geschäft ",
      "direction": "down",
      "length": 7,
      "group": [
        "26-down"
      ],
      "position": {
        "x": 11,
        "y": 4
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "27-down",
      "number": "27",
      "humanNumber": "27",
      "clue": "Wie einer wirkt, für den alles sein muss, wie es sein muss ",
      "direction": "down",
      "length": 7,
      "group": [
        "27-down"
      ],
      "position": {
        "x": 13,
        "y": 4
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "28-across",
      "number": "28",
      "humanNumber": "28",
      "clue": "Waltet, wo in uns der Automat erwachte? ",
      "direction": "across",
      "length": 7,
      "group": [
        "28-across"
      ],
      "position": {
        "x": 0,
        "y": 5
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "29-across",
      "number": "29",
      "humanNumber": "29",
      "clue": "Ersatzbezeichnung für eine wie 38 senkrecht ",
      "direction": "across",
      "length": 3,
      "group": [
        "29-across"
      ],
      "position": {
        "x": 7,
        "y": 5
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "30-across",
      "number": "30",
      "humanNumber": "30",
      "clue": "Motiv im Rahmen des Familienfotomachens ",
      "direction": "across",
      "length": 3,
      "group": [
        "30-across"
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
      "clue": "Wer erst ... gekostet, dem schmeckt der Honig umso süßer (Sprichwort) ",
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
      "id": "32-down",
      "number": "32",
      "humanNumber": "32",
      "clue": "Das nutzen Schnellhörer als -notierer ",
      "direction": "down",
      "length": 5,
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
      "clue": "Aufpustewort jenseits der Kilo-Sphäre ",
      "direction": "across",
      "length": 4,
      "group": [
        "33-across"
      ],
      "position": {
        "x": 2,
        "y": 6
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "34-down",
      "number": "34",
      "humanNumber": "34",
      "clue": "Eine Sache auf Anglo-Lateinisch? Ein Gewaltbereiter auf Altgriechisch! ",
      "direction": "down",
      "length": 4,
      "group": [
        "34-down"
      ],
      "position": {
        "x": 5,
        "y": 6
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "35-across",
      "number": "35",
      "humanNumber": "35",
      "clue": "Sprichwörtlich: Die Kuh sagt nicht ... zur Weide ",
      "direction": "across",
      "length": 5,
      "group": [
        "35-across"
      ],
      "position": {
        "x": 6,
        "y": 6
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "36-down",
      "number": "36",
      "humanNumber": "36",
      "clue": "Ein Standardartikel aus der Milchgetränkefirma ",
      "direction": "down",
      "length": 5,
      "group": [
        "36-down"
      ],
      "position": {
        "x": 9,
        "y": 6
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "37-across",
      "number": "37",
      "humanNumber": "37",
      "clue": "Ein Moment im Häuschen: Wasserwegnutzer ",
      "direction": "across",
      "length": 6,
      "group": [
        "37-across"
      ],
      "position": {
        "x": 11,
        "y": 6
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "38-down",
      "number": "38",
      "humanNumber": "38",
      "clue": "Zwei Nachbarbuchstaben, eine Dame ",
      "direction": "down",
      "length": 3,
      "group": [
        "38-down"
      ],
      "position": {
        "x": 14,
        "y": 6
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "39-across",
      "number": "39",
      "humanNumber": "39",
      "clue": "Schärfstens: wacht über den Bundestag ",
      "direction": "across",
      "length": 9,
      "group": [
        "39-across"
      ],
      "position": {
        "x": 1,
        "y": 7
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "40-across",
      "number": "40",
      "humanNumber": "40",
      "clue": "Sollten wachsen mit geleisteten Aufgaben, gemeisterten Pflichten ",
      "direction": "across",
      "length": 7,
      "group": [
        "40-across"
      ],
      "position": {
        "x": 10,
        "y": 7
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "41-across",
      "number": "41",
      "humanNumber": "41",
      "clue": "Ob wir etwas als angenehm oder unangenehm empfinden, hängt größtenteils davon ab, wie wir uns dazu ... (M. de Montaigne) ",
      "direction": "across",
      "length": 7,
      "group": [
        "41-across"
      ],
      "position": {
        "x": 0,
        "y": 8
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "42-across",
      "number": "42",
      "humanNumber": "42",
      "clue": "Besonderer Tritt im Spiel, Sonderfall von Rat im Spaß ",
      "direction": "across",
      "length": 5,
      "group": [
        "42-across"
      ],
      "position": {
        "x": 7,
        "y": 8
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "43-across",
      "number": "43",
      "humanNumber": "43",
      "clue": "Lieblingsreviere der Bequemradler ",
      "direction": "across",
      "length": 6,
      "group": [
        "43-across"
      ],
      "position": {
        "x": 12,
        "y": 8
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "44-across",
      "number": "44",
      "humanNumber": "44",
      "clue": "Der jagt hoch, was die Kundschaft gern unten sähe ",
      "direction": "across",
      "length": 12,
      "group": [
        "44-across"
      ],
      "position": {
        "x": 1,
        "y": 9
      },
      "separatorLocations": {},
      "solution": null
    },
    {
      "id": "45-across",
      "number": "45",
      "humanNumber": "45",
      "clue": "Aus dem Portlandumland ein Knabe ",
      "direction": "across",
      "length": 4,
      "group": [
        "45-across"
      ],
      "position": {
        "x": 13,
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
}
|
  cw = JSON.parse(json)
  Oj.dump cw
  end
end

