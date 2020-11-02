const parse = require('csv-parse/lib/sync')

const csv = `99x;99x;1d;99x;99x;2d;99x;99x;99x;3d;99x;99x;4d;99x;99x;5d;99x;99x;99x
99x;6x;;;7d;;;8d;9d;10a;11d;;;12d;13d;;;99x;99x
14a;;;15d;;;16x;;;;;17d;;;;;18d;;99x
99x;19a;;;;;;;;;20a;;;;;;;99x;99x
99x;;21a;;;;22a;;23d;;24d;25a;;;;;;99x;99x
99x;26a;;;;27a;;;;;28a;;;;;;;99x;99x
29a;;;30a;31d;;32a;;;33d;;34a;35d;;36a;37d;;;99x
99x;38a;;;;39x;;;;;;;;40a;41d;;;99x;99x
42a;;;;;;;;43a;;;;44a;;;;;;99x
99x;;45a;;;;;46x;;;;99d;;;;99d;99a;99x;99x
99x;99x;99x;;99x;;99x;99x;99x;;99x;99x;;99x;;99x;99x;99x;99x
99x;99x;99x;99x;99x;99x;99x;99x;99x;99x;99x;99x;99x;99x;99x;99x;99x;99x;99x
`

const options = {
  delimiter: ';'
}

const cw = parse(csv, options)

const acrossText = `
Waagerecht: 6 Gezüchtet für zugigen Garten? Gemacht für Rich-
tungsentscheidungen! 10 Moderne Mäuse sind mitunter reich ...:
händisches Handeln 14 Der Veredelung wegen geht dabei Lecke-
rei tauchen 16 Per Kreuzung erhältlich — und guter Friseur kann’s
auf den ... genau 19 Das Talent zu ... täuscht oft über den Man-
gel an anderen Talenten (M. v. Ebner-Eschenbach) 20 Nicht im-
mer fest einbetoniert: Manche geht mit mir, indem ich mit ihr gehe
21 Hier über der Glut, da Namensgeber für einen Ton der Farbe
des Feuers 22 Der erzählte was vom Pferd, das böse Überraschung
brachte 25 Eine umgängliche Variante des Ruhenlassens der Lider
26 Mancherorts schnell, hier aber nicht ganz 27 Ward mitgedacht
bei Ole-Rufen an den Biathlonpisten 28 Der Plan, den man nicht ...
kann, ist schlecht (Sallust) 29 Das lange, schlanke Ende vom groß-
volumigen Raum 30 Heimisches Verkehrsmittel im Raleigh-Umland
32 Regieren ist eine ..., keine Wissenschaft (L. Börne) 34 A very
British way of Hochgenuss 36 Tippe, die kann immer nur Teilant-
wort in der Schuldenfrage sein 38 Das Senfhäubchen auf dem Mal-
heur des Pechvogels 39 Stimmhaft und stimmungsvoll: dargebracht
schon als Barockmusik 40 Fügt sich stadtlich ein zwischen Okto und
acht, wenn's um die Zeit von Halloween geht 42 Wer’s mag, vermisst
nicht laufend das feste Dach überm Kopf 43 Alter Kämpe, eingangs
zentralasiatischer Hauptstadt erwähnt 44 Vorwiegend Armarbeit für
den Redenschwinger 45 Die volle Beschreibung dessen, was sie kann:
gähnen! 46 Nicht lustig, nur lästig: schafft andauernde Wegvorgabe
`

const downText = `
Senkrecht: 1 Polit-Frage: Muss es immer das sein, das unsere 6 senk-
recht absichert — bis zum letzten Tropfen? 2 Kann mehr als Reste:
Manche brennen darauf, ihn weiterzuverwenden 3 Der wäre Gefah-
renentschärfer? Das trägt Botschaft! 4 Sind für die 13 senkrecht da,
und zwar eher für die munteren als für die ... 5 Auf seiner Bahn zu
sehen, aber auch im Laden zu haben, wenn man sich beeilt 6 Staats-
vorsatz, und dabei ist nicht nur an Komfortzug und Bequemkarosse
gedacht 7 Seinetwegen wird öfter mal die Brause, selten der Dusch-
kopf bemühr 8 Besonderes Stammareal auch: Idee in Fortführung
des Abnutzschutzgedankens 9 Sprichwörtlich: Die Liebe ist blind,
die ... ist hellsichtig 11 Fremdlingsfluss in der Philippinenkapitale
12 So darf man einen nennen, dem das Moos nicht in der Tasche
festgewachsen 13 Eine war längst über alle city limits hinaus be-
kannt, als andere eine Stark wurde 15 Waren Wegeerlediger schon zu
pferdestärkeren Zeiten 16 Wer kein Cash hat, hat schon alle Zeichen
jener Frustbereiterin 17 Spielen häufig eine Rolle fürs Räumekostüm
18 Niemand ist ohne ... außer dem, der keine Fragen stellt (Sprich-
wort) 23 Romeo sieht man dorthin fliehen, und Rigolerto ist schon
da 24 Seine Verwendung ist eng verflochten mit Möblierung 31 Ist
stets in Gedanken, die Dame 33 Gehört da zu heiligem Franz, sind
dort businessman’s Stolz 35 Mehr als der Argumentiereifer können
oft deren Zungen gewinnen 37 Weise: 32 waagerecht, wo der 34 waa-
gerecht auf den Tisch kommt 39 Die Dorn im Auge des »Tatort«-
Betrachters 41 Es ist ein ..., wer mit einem ... streitet (Sprichwort)
`

const acrossHints = parseHints(acrossText)
const downHints = parseHints(downText)

const entries = []

for (let row = 0; row < cw.length; row++) {
  for (let col = 0; col < cw[0].length; col++) {
    const cell = cw[row][col]
    if (cell === '') {
      // do nothing
    } else if (cell.slice(-1) === 'x') {
      const a = generateAcrossEntry(row, col, cell.slice(0, -1), cw, acrossHints)
      const d = generateDownEntry(row, col, cell.slice(0, -1), cw, downHints)
      if (a) entries.push(a)
      if (d) entries.push(d)
    } else if (cell.slice(-1) === 'a') {
      const a = generateAcrossEntry(row, col, cell.slice(0, -1), cw, acrossHints)
      if (a) entries.push(a)
    } else if (cell.slice(-1) === 'd') {
      const d = generateDownEntry(row, col, cell.slice(0, -1), cw, downHints)
      if (d) entries.push(d)
    }
  }
}
const crossword = {
  id: 2561,
  number: 2561,
  name: 'Zeit',
  date: 1542326400000,
  entries: entries,
  solutionAvailable: false,
  dateSolutionAvailable: 1603670400000,
  dimensions: {
    cols: 18,
    rows: 11
  },
  crosswordType: 'quiptic'
}
console.log(JSON.stringify(crossword, null, 2))

function generateAcrossEntry (row, col, number, cw, hints) {
  if (hints[number]) {
    let i = 1
    try {
      while (!['x', 'a'].includes(cw[row][col + i].slice(-1))) {
        i++
      }
    } catch (e) {
      console.log(row, col, number, i)
    }
    const entry = {
      id: number + '-across',
      number,
      humanNumber: number,
      clue: hints[number],
      direction: 'across',
      length: i,
      group: [number + '-across'],
      position: { x: col, y: row },
      separatorLocations: {},
      solution: null
    }
    return entry
  } else {
    return null
  }
}

function generateDownEntry (row, col, number, cw, hints) {
  if (hints[number]) {
    let i = 1
    while (!['x', 'a'].includes(cw[row + i][col].slice(-1))) {
      i++
    }
    const entry = {
      id: number + '-down',
      number,
      humanNumber: number,
      clue: hints[number],
      direction: 'down',
      length: i,
      group: [number + '-down'],
      position: { x: col, y: row },
      separatorLocations: {},
      solution: null
    }
    return entry
  } else {
    return null
  }
}

function parseHints (text) {
  const noBreaks = text.split('\n').join(' ')
  const noHyphens = noBreaks.split('- ').join('')
  const start = noHyphens.search(/\d/)
  const work = noHyphens.substring(start)
  let remaining = work
  let nextNumber = remaining.slice(2).search(/\d+/) + 2

  let hints = []
  while (true) {
    while (remaining.slice(nextNumber).search(/waagerecht|senkrecht/) < 5 && remaining.slice(nextNumber).search(/waagerecht|senkrecht/) > 0) {
      nextNumber = remaining.slice(nextNumber + 2).search(/\d/) + nextNumber + 2
    }
    const hint = remaining.slice(0, nextNumber)
    hints.push(hint)
    remaining = remaining.slice(nextNumber)
    if (remaining.slice(2).search(/\d+/) < 0) {
      hints.push(remaining)
      break
    }
    nextNumber = remaining.slice(2).search(/\d+/) + 2
  }
  const hintsObject = {}
  hints = hints.forEach(h => {
    const firstSpace = h.indexOf(' ')
    hintsObject[h.slice(0, firstSpace)] = h.slice(firstSpace + 1)
  })
  return hintsObject
}
