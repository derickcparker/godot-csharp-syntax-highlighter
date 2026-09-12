@tool
extends EditorSyntaxHighlighter

## Lightweight, regex-free C# tokenizer for Godot's built-in script editor.
##
## This is NOT a full C# parser (no Roslyn, no semantic analysis of types).
## It's a single-pass lexer, similar in spirit to a TextMate grammar: it
## recognizes keywords, built-in types, strings (including verbatim/raw/
## interpolated), comments, numbers and preprocessor directives, plus a
## PascalCase heuristic for user-defined type names. Multi-line constructs
## (block comments, verbatim/raw strings) are tracked via a small state
## machine cached per line.

const COLOR_DEFAULT := Color(0.85, 0.85, 0.87)
const COLOR_COMMENT := Color(0.5, 0.52, 0.55)
const COLOR_STRING := Color(0.94, 0.83, 0.53)
const COLOR_NUMBER := Color(0.63, 0.86, 0.68)
const COLOR_KEYWORD := Color(1.0, 0.44, 0.52)
const COLOR_TYPE := Color(0.36, 0.75, 0.94)
const COLOR_PREPROCESSOR := Color(0.72, 0.58, 0.95)
const COLOR_FUNCTION := Color(0.42, 0.76, 0.95)

const KEYWORDS := {
	"abstract": true, "as": true, "async": true, "await": true, "base": true, "break": true,
	"case": true, "catch": true, "checked": true, "class": true, "const": true, "continue": true,
	"default": true, "delegate": true, "do": true, "else": true, "enum": true, "event": true,
	"explicit": true, "extern": true, "finally": true, "fixed": true, "for": true, "foreach": true,
	"goto": true, "if": true, "implicit": true, "in": true, "interface": true, "internal": true,
	"is": true, "lock": true, "namespace": true, "new": true, "null": true, "operator": true,
	"out": true, "override": true, "params": true, "private": true, "protected": true, "public": true,
	"readonly": true, "record": true, "ref": true, "return": true, "sealed": true, "sizeof": true,
	"stackalloc": true, "static": true, "struct": true, "switch": true, "this": true, "throw": true,
	"try": true, "typeof": true, "unchecked": true, "unsafe": true, "using": true, "virtual": true,
	"volatile": true, "while": true, "yield": true, "get": true, "set": true, "value": true,
	"init": true, "with": true, "when": true, "where": true, "nameof": true, "partial": true,
	"select": true, "from": true, "orderby": true, "group": true, "into": true, "let": true,
	"on": true, "equals": true, "join": true, "ascending": true, "descending": true, "and": true,
	"or": true, "not": true, "global": true, "required": true, "true": true, "false": true,
	"add": true, "remove": true,
}

const TYPE_KEYWORDS := {
	"bool": true, "byte": true, "sbyte": true, "char": true, "decimal": true, "double": true,
	"dynamic": true, "float": true, "int": true, "long": true, "object": true, "short": true,
	"string": true, "uint": true, "ulong": true, "ushort": true, "var": true, "void": true,
	"nint": true, "nuint": true,
}

# Array<Dictionary{highlight: Dictionary, end_state: String}>, indexed by line number.
var _line_cache: Array = []


func _get_name() -> String:
	return "C# Syntax Highlighter"


func _get_supported_languages() -> PackedStringArray:
	return PackedStringArray(["C#"])


func _clear_highlighting_cache() -> void:
	_line_cache.clear()


func _get_line_syntax_highlighting(line: int) -> Dictionary:
	var te := get_text_edit()
	if te == null:
		return {}

	while _line_cache.size() <= line:
		var idx: int = _line_cache.size()
		var start_state := "normal"
		if idx > 0:
			start_state = _line_cache[idx - 1]["end_state"]
		var text := ""
		if idx < te.get_line_count():
			text = te.get_line(idx)
		_line_cache.append(_tokenize_line(text, start_state))

	return _line_cache[line]["highlight"]


func _tokenize_line(text: String, start_state: String) -> Dictionary:
	var highlight := {0: {"color": COLOR_DEFAULT}}
	var n := text.length()
	var i := 0
	var end_state := "normal"

	if start_state == "block_comment":
		highlight[0] = {"color": COLOR_COMMENT}
		var close := text.find("*/")
		if close == -1:
			return {"highlight": highlight, "end_state": "block_comment"}
		i = close + 2
		highlight[i] = {"color": COLOR_DEFAULT}
	elif start_state == "verbatim_string":
		highlight[0] = {"color": COLOR_STRING}
		var res := _scan_verbatim_body(text, 0)
		if not res["closed"]:
			return {"highlight": highlight, "end_state": "verbatim_string"}
		i = res["end"]
		highlight[i] = {"color": COLOR_DEFAULT}
	elif start_state == "raw_string":
		highlight[0] = {"color": COLOR_STRING}
		var close2 := text.find("\"\"\"")
		if close2 == -1:
			return {"highlight": highlight, "end_state": "raw_string"}
		i = close2 + 3
		highlight[i] = {"color": COLOR_DEFAULT}

	while i < n:
		var c := text.substr(i, 1)

		if c == "#" and _is_line_start(text, i):
			highlight[i] = {"color": COLOR_PREPROCESSOR}
			break

		if c == "/" and i + 1 < n and text.substr(i + 1, 1) == "/":
			highlight[i] = {"color": COLOR_COMMENT}
			break

		if c == "/" and i + 1 < n and text.substr(i + 1, 1) == "*":
			highlight[i] = {"color": COLOR_COMMENT}
			var close3 := text.find("*/", i + 2)
			if close3 == -1:
				end_state = "block_comment"
				break
			i = close3 + 2
			highlight[i] = {"color": COLOR_DEFAULT}
			continue

		if c == "@" and i + 1 < n and text.substr(i + 1, 1) == "\"":
			highlight[i] = {"color": COLOR_STRING}
			var res2 := _scan_verbatim_body(text, i + 2)
			if not res2["closed"]:
				end_state = "verbatim_string"
				break
			i = res2["end"]
			highlight[i] = {"color": COLOR_DEFAULT}
			continue

		if c == "\"" and i + 2 < n and text.substr(i + 1, 1) == "\"" and text.substr(i + 2, 1) == "\"":
			highlight[i] = {"color": COLOR_STRING}
			var close4 := text.find("\"\"\"", i + 3)
			if close4 == -1:
				end_state = "raw_string"
				break
			i = close4 + 3
			highlight[i] = {"color": COLOR_DEFAULT}
			continue

		if c == "$" and i + 1 < n and text.substr(i + 1, 1) == "\"":
			highlight[i] = {"color": COLOR_STRING}
			i = _scan_simple_string(text, i + 2, "\"")
			highlight[i] = {"color": COLOR_DEFAULT}
			continue

		if c == "\"":
			highlight[i] = {"color": COLOR_STRING}
			i = _scan_simple_string(text, i + 1, "\"")
			highlight[i] = {"color": COLOR_DEFAULT}
			continue

		if c == "'":
			highlight[i] = {"color": COLOR_STRING}
			i = _scan_simple_string(text, i + 1, "'")
			highlight[i] = {"color": COLOR_DEFAULT}
			continue

		if _is_digit(c) or (c == "." and i + 1 < n and _is_digit(text.substr(i + 1, 1))):
			var start := i
			i += 1
			while i < n and (_is_ident_char(text.substr(i, 1)) or text.substr(i, 1) == "."):
				i += 1
			highlight[start] = {"color": COLOR_NUMBER}
			highlight[i] = {"color": COLOR_DEFAULT}
			continue

		if _is_ident_start(c):
			var start2 := i
			i += 1
			while i < n and _is_ident_char(text.substr(i, 1)):
				i += 1
			var word := text.substr(start2, i - start2)
			if KEYWORDS.has(word):
				highlight[start2] = {"color": COLOR_KEYWORD}
			elif TYPE_KEYWORDS.has(word):
				highlight[start2] = {"color": COLOR_TYPE}
			elif i < n and text.substr(i, 1) == "(":
				highlight[start2] = {"color": COLOR_FUNCTION}
			elif _is_upper(word.substr(0, 1)):
				highlight[start2] = {"color": COLOR_TYPE}
			else:
				highlight[start2] = {"color": COLOR_DEFAULT}
			highlight[i] = {"color": COLOR_DEFAULT}
			continue

		i += 1

	return {"highlight": highlight, "end_state": end_state}


func _scan_simple_string(text: String, start: int, quote: String) -> int:
	var n := text.length()
	var i := start
	while i < n:
		var c := text.substr(i, 1)
		if c == "\\" and i + 1 < n:
			i += 2
			continue
		if c == quote:
			return i + 1
		i += 1
	return n


func _scan_verbatim_body(text: String, start: int) -> Dictionary:
	var n := text.length()
	var i := start
	while i < n:
		if text.substr(i, 1) == "\"":
			if i + 1 < n and text.substr(i + 1, 1) == "\"":
				i += 2
				continue
			return {"closed": true, "end": i + 1}
		i += 1
	return {"closed": false, "end": n}


func _is_line_start(text: String, i: int) -> bool:
	return text.substr(0, i).strip_edges() == ""


func _is_digit(ch: String) -> bool:
	return ch >= "0" and ch <= "9"


func _is_upper(ch: String) -> bool:
	return ch >= "A" and ch <= "Z"


func _is_ident_start(ch: String) -> bool:
	return ch == "_" or (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z")


func _is_ident_char(ch: String) -> bool:
	return _is_ident_start(ch) or _is_digit(ch)
