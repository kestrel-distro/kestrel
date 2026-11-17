.pragma library

// Query prefixes follow the launcher convention: a leading "=" forces the
// calculator, "?" the web search, "/" the action catalogue. A bare query
// searches apps first and falls back to actions, then the web.
var ACTIONS = [
  { id: "lock", name: "Lock screen", subtext: "Session", glyph: "\uf023", command: "kestrel-shell shell lock" },
  { id: "power", name: "Power menu", subtext: "Session", glyph: "\uf011", command: "kestrel-menu toggle system" },
  { id: "capture", name: "Screenshot", subtext: "Capture", glyph: "\uf030", command: "kestrel-capture-screenrecording --stop-recording || kestrel-screenshot" },
  { id: "theme", name: "Theme menu", subtext: "Appearance", glyph: "\uf53f", command: "kestrel-menu toggle theme" },
  { id: "settings", name: "Settings", subtext: "System", glyph: "\uf013", command: "kestrel-settings" },
  { id: "terminal", name: "Terminal", subtext: "Apps", glyph: "\uf120", command: "kestrel-launch-terminal" },
  { id: "files", name: "Files", subtext: "Apps", glyph: "\uf07b", command: "kestrel-launch-file-manager" },
  { id: "browser", name: "Browser", subtext: "Apps", glyph: "\uf0ac", command: "kestrel-launch-browser" }
]

function sortedActions(query) {
  var q = String(query || "").replace(/^\//, "").trim().toLowerCase()
  if (!q) return ACTIONS.slice()
  var out = []
  for (var i = 0; i < ACTIONS.length; i++) {
    var a = ACTIONS[i]
    if ((a.name + " " + a.subtext).toLowerCase().indexOf(q) >= 0) out.push(a)
  }
  return out
}

// Safe arithmetic: digits, spaces and the four operators only, parsed by a
// small recursive-descent evaluator. Anything else (a letter, a function name,
// a variable) falls through to the web search rather than being evaluated.
function tokenize(q) {
  var tokens = []
  var i = 0
  while (i < q.length) {
    var c = q.charAt(i)
    if (c === " ") { i++; continue }
    if ("+-*/()".indexOf(c) >= 0) { tokens.push(c); i++; continue }
    var t = q.slice(i).match(/^\d+(?:\.\d+)?/)
    if (!t) return null
    tokens.push(Number(t[0]))
    i += t[0].length
  }
  return tokens
}

function evaluate(tokens) {
  var at = 0
  function peek() { return tokens[at] }
  function next() { return tokens[at++] }
  function primary() {
    if (peek() === "(") { next(); var v = expr(); if (next() !== ")") return NaN; return v }
    if (peek() === "-") { next(); return -primary() }
    if (peek() === "+") { next(); return primary() }
    var n = next()
    return typeof n === "number" ? n : NaN
  }
  function term() {
    var v = primary()
    while (peek() === "*" || peek() === "/") {
      var op = next()
      var r = primary()
      v = op === "*" ? v * r : v / r
    }
    return v
  }
  function expr() {
    var v = term()
    while (peek() === "+" || peek() === "-") {
      var op = next()
      var r = term()
      v = op === "+" ? v + r : v - r
    }
    return v
  }
  var value = expr()
  return at === tokens.length ? value : NaN
}

function calculate(query) {
  var q = String(query || "").replace(/^=/, "").trim()
  if (!q || !/[0-9]/.test(q) || !/[-+*/]/.test(q)) return ""
  if (!/^[-+*/(). 0-9]+$/.test(q)) return ""
  var tokens = tokenize(q)
  if (!tokens || tokens.length === 0) return ""
  var value = evaluate(tokens)
  if (typeof value !== "number" || !isFinite(value)) return ""
  return String(Math.round(value * 1e10) / 1e10)
}

function webQuery(query) {
  var q = String(query || "")
  if (q.charAt(0) === "?") q = q.slice(1)
  return q.trim()
}
