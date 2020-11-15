const parse = require('csv-parse/lib/sync')

const csv = `99x;99x;1d;99x;99x;2d;99x;99x;3d;99x;99x;4d;99x;5d;99x;6d;99x;99x;99x
99x;7x;;;8d;;9d;;;10d;;;11x;;12d;;13x;99x;99x
14a;;;15d;;;16a;17d;;;18d;;;;;;;;99x
99x;19a;;;;;;20a;;;;;;;21a;;;99x;99x
99x;22a;;;23d;;24d;;25x;;;26d;;27d;;;99a;99x;99x
28a;;;;;;;29a;;;30a;;;31a;;32d;;;99x
99x;;33a;;;34d;35a;;;36d;;37a;;;38d;;;99x;99x
99x;39a;;;;;;;;;40a;;;;;;;99x;99x
41a;;;;;;;42a;;;;;43a;;;;;;99x
99x;44x;;;99d;;;;;;99d;;99d;45a;99d;;;99x;99x
99x;99x;99x;;99x;99x;99x;99x;99x;;99x;;99x;;99x;99x;99x;99x;99x
99x;99x;99x;99x;99x;99x;99x;99x;99x;99x;99x;99x;99x;99x;99x;99x;99x;99x;99x
`

const options = {
  delimiter: ';'
}

const cw = parse(csv, options)

const acrossText = `
Waagerecht: 7 Worte, mit Gewicht belegt, der Welt zur Beach-
tung in Schallwellen formen 11 Baumlanger Abschnitt der Leibes-
übungen 14 Ohne wäre der Tornado kein Tornado 16 Wie Glocke
immer wieder, so der Bazillenträger zur Infektionshochsaison
19 Malheur: Wer ... ging, also machte, der ist’s 20 Sinnt auf Sinnes-
verwöhnung 21 Einstufung der Dinge im Falle von viel Wenigkeit
22 Anbahner des Wegs des Erdöls durch die Wüste 25 Die neigen
zu Verhedderung, das wirkt wie Entblätterung 28 Waltet, wo in
uns der Automat erwachte? 29 Ersatzbezeichnung für eine wie 38
senkrecht 30 Motiv im Rahmen des Familienfotomachens 31 Wer
erst ... gekostet, dem schmeckt der Honig umso süßer (Sprichwort)
33 Aufpustewort jenseits der Kilo-Sphäre 35 Sprichwörtlich: Die
Kuh sagt nicht ... zur Weide 37 Ein Moment im Häuschen: Was-
serwegnutzer 39 Schärfstens: wacht über den Bundestag 40 Sollten
wachsen mit geleisteten Aufgaben, gemeisterten Pflichten 41 Ob
wir etwas als angenehm oder unangenehm empfinden, hängt größ-
tenteils davon ab, wie wir uns dazu ... (M. de Montaigne) 42 Be-
sonderer Tritt im Spiel, Sonderfall von Rat im Spaß 43 Lieblingsre-
viere der Bequemradler 44 Der jagt hoch, was die Kundschaft gern
unten sähe 45 Aus dem Portlandumland ein Knabe
`

const downText = `
Senkrecht: 1 Nichtiges Gold stiehlt der Dieb, warme Herzen der ... (russ.
Sprichwort) 2 Die des Erdmantels ziehen Bergsteiger an 3 Wo Geld
vorangeht, sind alle ... offen (Shakespeare) 4 Als Teillänge beim
Weihnachtenklauer abzulesen 5 Das ist Kult beim ...: viel Bein-
freiheit 6 So wird gelebt, wo nur Flora den Tisch deckt 7 Kulti-
viere die Kunst, Kollisionen der Kulturen zu vermeiden 8 Felsen-
festes Zubehör einer oder vieler 9 Die Lady, die den buchstäblichen
Unterschied ausmacht zwischen nördlichen Zeichen und südöst-
lichem Volk 10 Kein Angebot allerdings nach nachhaltiger Nach-
frage 11 Haben alle mal Ja — und also Nein zum 25-senkrecht-Sein
— gesagt 12 Hat ausgelacht, wird ausgelacht in der Zeit der Domi-
nanz der Karten 13 Die meisten Menschen brauchen mehr Liebe,
als sie ... (M. v. Ebner-Eschenbach) 15 Hegt den Vorsatz, was für
den Umsatz anderer zu tun 17 Ein Benehmen wie ein solcher — so
kommt man in die Chroniken als Känguru 18 Viele Leute auch, in
gewisser HaZweiOrientierung 23 Zu kurz das Zeichen, um Brief-
Beiwerk zu sein 24 Genau der, der exakt erklären kann, warum
er so 27 senkrecht ist 25 Auf-der-Suche-Lebensform, mehr oder
weniger 26 Mit vielen winzigen Beiträgen macht sie summa sum-
marum ein Geschäft 27 Wie einer wirkt, für den alles sein muss,
wie es sein muss 32 Das nutzen Schnellhörer als -notierer 34 Eine
Sache auf Anglo-Lateinisch? Ein Gewaltbereiter auf Altgriechisch!
36 Ein Standardartikel aus der Milchgetränkefirma 38 Zwei Nach-
barbuchstaben, eine Dame
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
  id: 2563,
  number: 2563,
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
    while (!['x', 'd'].includes(cw[row + i][col].slice(-1))) {
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
