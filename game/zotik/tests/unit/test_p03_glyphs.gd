extends TestCase
## Every player-visible string (string literals in game scripts and all
## data JSON) must be renderable with the fonts the UI uses (U01: Exo 2 for
## text, Cinzel for titles; plus the engine font as fallback): the web
## build has no system font fallback, missing glyphs show as boxes.

const DIRS := ["res://core/", "res://scenes/"]


func _scripts(dir: String, out: Array) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir + f)
	for d in DirAccess.get_directories_at(dir):
		_scripts(dir + d + "/", out)


func _json_strings(v: Variant, out: Array) -> void:
	if v is String:
		out.append(v)
	elif v is Array:
		for x in v:
			_json_strings(x, out)
	elif v is Dictionary:
		for k in v:
			_json_strings(v[k], out)


func test_all_visible_strings_render_with_builtin_font() -> void:
	var fonts: Array[Font] = [ThemeDB.fallback_font, UiStyle.body_font(), UiStyle.title_font()]
	var strings := []
	var files := []
	for d in DIRS:
		_scripts(d, files)
	var re := RegEx.create_from_string("\"((?:[^\"\\\\]|\\\\.)*)\"")
	for path in files:
		for line in FileAccess.get_file_as_string(path).split("\n"):
			if line.strip_edges().begins_with("#"):
				continue
			for m in re.search_all(line):
				strings.append(m.get_string(1))
	for f in DirAccess.get_files_at("res://data/"):
		if f.ends_with(".json"):
			_json_strings(JSON.parse_string(FileAccess.get_file_as_string("res://data/" + f)), strings)
	check(strings.size() > 200, "collected %d strings" % strings.size())
	var bad := {}
	for s in strings:
		for i in s.length():
			var c: int = s.unicode_at(i)
			for font in fonts:
				if c > 127 and not font.has_char(c):
					bad[String.chr(c)] = s
	eq(bad.size(), 0, "unsupported glyphs: %s" % [bad])
