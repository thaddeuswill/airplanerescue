extends Control
## The C85-12 / J-3 Cub service manual as a period shop book, same paper and type as catalog.gd.
## Spread 0 is the contents; then one spread per procedure (left: what you need, right: picture
## and steps); then one spread per exploded figure (left: drawing, right: parts index).
## Pages: A / D, Left / Right or Page Up / Down. Esc is handled by main.gd (close_requested).
##
## var data := ManualUI.load_data("res://data/c85_manual.json")
## m.setup(data, sfx, "oil_change")   # third arg opens straight to that job's page ("" = contents)

signal close_requested

const INK := Color("1E1B17")
const RED := Color("A8261F")
const CREAM := Color("EEE6CF")
const MUSTARD := Color("D9A62E")
const FADED := Color("6B5E4B")
const BOOK := Vector2(1320, 800)
const PAGE_W := 660.0

static var SCRIPT := _font_file("res://fonts/Yellowtail-Regular.ttf")
static var BLOCK := _block(800)
static var BLACK := _block(900)
static var BODY := _block(600)
static var _last := 0  # remembers the open spread between visits

var _data := {}
var _pages: Array = []  # [{kind: "contents"|"page"|"figure", ...}]
var _parts := {}  # part id -> part (from c85_parts.json, optional)
var _spread := 0
var _sfx := Callable()
var _book: Control


static func _font_file(path: String) -> Font:
	if ResourceLoader.exists(path):
		return load(path)
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Bahnschrift", "Arial Narrow", "sans-serif"])
	return f


static func _block(weight: int) -> FontVariation:
	var v := FontVariation.new()
	v.base_font = _font_file("res://fonts/BigShouldersDisplay.ttf")
	v.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	return v


static func load_data(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("manual: can't open " + path)
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}


## data: c85_manual.json. parts: c85_parts.json (optional; adds part numbers to the parts lists).
func setup(data: Dictionary, sfx := Callable(), open_to := "", parts := {}) -> void:
	_data = data
	_sfx = sfx
	for p in parts.get("parts", []):
		_parts[p.id] = p
	_pages = [{"kind": "contents"}]
	for p in data.get("pages", []):
		_pages.append({"kind": "page", "p": p})
	var figs: Dictionary = data.get("figures", {})
	for id in figs:
		_pages.append({"kind": "figure", "id": id, "f": figs[id]})
	_spread = clampi(_last, 0, _pages.size() - 1)
	if open_to != "":
		var i := _find_job(open_to)
		if i >= 0:
			_spread = i


func _find_job(job: String) -> int:
	for i in _pages.size():
		if _pages[i].kind == "page" and (_pages[i].p.get("job", "") == job or _pages[i].p.id == job):
			return i
	return -1


func _find_figure(id: String) -> int:
	for i in _pages.size():
		if _pages[i].kind == "figure" and _pages[i].id == id:
			return i
	return -1


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.04, 0.03, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_book = Control.new()
	_book.size = BOOK
	add_child(_book)
	_build()
	_fit.call_deferred()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _book:
		_fit()


func fade_in() -> void:
	modulate.a = 0.0
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "modulate:a", 1.0, 0.18)


func _fit() -> void:
	var area := size if size.x >= 1 and size.y >= 1 else get_viewport_rect().size
	var s := minf(area.x / (BOOK.x + 40), area.y / (BOOK.y + 40))
	_book.scale = Vector2(s, s)
	_book.position = (area - BOOK * s) / 2


func _unhandled_key_input(e: InputEvent) -> void:
	if not (e is InputEventKey and e.pressed and not e.echo):
		return
	match e.keycode:
		KEY_A, KEY_LEFT, KEY_PAGEUP:
			go(_spread - 1)
		KEY_D, KEY_RIGHT, KEY_PAGEDOWN:
			go(_spread + 1)
		KEY_HOME, KEY_C:
			go(0)
		_:
			return
	get_viewport().set_input_as_handled()


func go(i: int) -> void:
	i = clampi(i, 0, _pages.size() - 1)
	if i == _spread:
		return
	_spread = i
	_last = i
	if _sfx.is_valid():
		_sfx.call()
	_build()


# ---------------- spreads ----------------

func _build() -> void:
	for c in _book.get_children():
		c.queue_free()
	var shadow := Panel.new()
	shadow.position = Vector2(10, 14)
	shadow.size = BOOK
	shadow.add_theme_stylebox_override("panel", _flat(Color(0, 0, 0, 0.45), 6))
	_book.add_child(shadow)
	var L := _page(0)
	var R := _page(1)
	var spine := ColorRect.new()
	spine.color = Color(0.1, 0.07, 0.04, 0.28)
	spine.position = Vector2(PAGE_W - 3, 0)
	spine.size = Vector2(6, BOOK.y)
	spine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_book.add_child(spine)
	var sp: Dictionary = _pages[_spread]
	match sp.kind:
		"contents":
			_contents(L, R)
		"page":
			_procedure(L, R, sp.p)
		"figure":
			_figure(L, R, sp.id, sp.f)
	_footer(L, 0)
	_footer(R, 1)


func _page(side: int) -> Control:
	var page := Control.new()
	page.position = Vector2(side * PAGE_W, 0)
	page.size = Vector2(PAGE_W, BOOK.y)
	page.clip_contents = true
	var bg := Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_theme_stylebox_override("panel", _flat(CREAM, 4))
	page.add_child(bg)
	if ResourceLoader.exists("res://textures/paper_catalog.png"):
		var paper := TextureRect.new()
		paper.texture = load("res://textures/paper_catalog.png")
		paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		paper.stretch_mode = TextureRect.STRETCH_TILE
		paper.set_anchors_preset(Control.PRESET_FULL_RECT)
		paper.modulate = Color(1, 1, 1, 0.55)
		paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.add_child(paper)
	_book.add_child(page)
	return page


func _contents(L: Control, R: Control) -> void:
	var band := Panel.new()
	band.size = Vector2(PAGE_W, 78)
	band.add_theme_stylebox_override("panel", _flat(RED, 0))
	L.add_child(band)
	_put(L, _label("SERVICE MANUAL", BLACK, 40, CREAM), 30, 12)
	var brand := _label(String(_data.get("aircraft", "")), SCRIPT, 46, RED)
	brand.add_theme_color_override("font_shadow_color", INK)
	brand.add_theme_constant_override("shadow_offset_x", 2)
	brand.add_theme_constant_override("shadow_offset_y", 2)
	_put(L, brand, 30, 84)
	_put(L, _label(String(_data.get("engine", "")).to_upper() + "  ·  CONTENTS", BLOCK, 20, INK), 32, 148)
	_put(L, _rule(3, INK, PAGE_W - 60), 30, 180)
	_put(R, _label("PROCEDURES BY CHAPTER", BLACK, 26, INK), 30, 24)
	_put(R, _rule(3, INK, PAGE_W - 60), 30, 64)
	# chapter headings with their pages as links, flowing from the left page to the right
	var rows := []
	for ch in _data.get("chapters", []):
		var items := []
		for i in _pages.size():
			if _pages[i].kind == "page" and _pages[i].p.ata == ch.ata:
				items.append(i)
		if items.is_empty():
			continue
		rows.append({"head": "%s  %s" % [ch.ata, String(ch.title).to_upper()]})
		for i in items:
			rows.append({"link": i})
	var figs := []
	for i in _pages.size():
		if _pages[i].kind == "figure":
			figs.append(i)
	if figs.size() > 0:
		rows.append({"head": "ILLUSTRATED PARTS"})
		for i in figs:
			rows.append({"link": i})
	var y := 196.0
	var page := L
	var x := 34.0
	for r in rows:
		var h := 28.0 if r.has("head") else 21.0
		if y + h > BOOK.y - 86:
			if page == L:
				page = R
				y = 78.0
			elif x < 300:
				x = 340.0
				y = 78.0
		if r.has("head"):
			_put(page, _label(r.head, BLACK, 19, RED), x, y + 4)
		else:
			var b := _link(_title_of(r.link), r.link)
			_put(page, b, x + 12, y)
		y += h


func _title_of(i: int) -> String:
	var sp: Dictionary = _pages[i]
	if sp.kind == "page":
		return String(sp.p.title)
	if sp.kind == "figure":
		return String(sp.f.title)
	return "Contents"


func _link(text: String, i: int) -> Button:
	var b := Button.new()
	b.text = text
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_override("font", BODY)
	b.add_theme_font_size_override("font_size", 17)
	for s in ["font_color", "font_focus_color"]:
		b.add_theme_color_override(s, INK)
	b.add_theme_color_override("font_hover_color", RED)
	b.add_theme_color_override("font_pressed_color", RED)
	var empty := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(s, empty)
	b.custom_minimum_size = Vector2(0, 20)
	b.pressed.connect(go.bind(i))
	return b


func _procedure(L: Control, R: Control, p: Dictionary) -> void:
	# ---- left: header, what it's about, specs, tools, parts, caution
	var tag := _label("ATA %s" % p.ata, BLOCK, 18, CREAM)
	var sb := _flat(INK, 0)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	tag.add_theme_stylebox_override("normal", sb)
	_put(L, tag, 30, 26)
	_put(L, _label(_chapter_name(p.ata).to_upper(), BLOCK, 18, RED), 120, 26)
	var t := _label(String(p.title).to_upper(), BLACK, 34, INK)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size = Vector2(PAGE_W - 60, 0)
	_put(L, t, 30, 56)
	var col := VBoxContainer.new()
	col.position = Vector2(30, 150 if t.get_line_count() < 2 else 190)
	col.size = Vector2(PAGE_W - 60, 0)
	col.add_theme_constant_override("separation", 6)
	L.add_child(col)
	col.add_child(_para(String(p.summary), 19, Color(INK, 0.9)))
	var specs: Dictionary = p.get("specs", {})
	if specs.size() > 0:
		col.add_child(_head("Specifications"))
		for k in specs:
			col.add_child(_row(String(k), String(specs[k])))
	if p.get("tools", []).size() > 0:
		col.add_child(_head("Tools"))
		col.add_child(_para(", ".join(PackedStringArray(p.tools)), 17, INK))
	if p.get("parts", []).size() > 0:
		col.add_child(_head("Parts"))
		for id in p.parts:
			var part: Dictionary = _parts.get(id, {})
			col.add_child(_row(String(part.get("no", "")), String(part.get("name", id))))
	if String(p.get("caution", "")) != "":
		var box := PanelContainer.new()
		var cb := _flat(Color(RED, 0.1), 2)
		cb.set_border_width_all(2)
		cb.border_color = RED
		cb.set_content_margin_all(10)
		box.add_theme_stylebox_override("panel", cb)
		var c := _para("CAUTION  " + String(p.caution), 17, Color("7E1C16"))
		c.add_theme_font_override("font", BLOCK)
		box.add_child(c)
		col.add_child(_spacer(4))
		col.add_child(box)
	# ---- right: picture, then numbered steps
	var y := 26.0
	var pic_path := String(p.get("picture", ""))
	var fig_id := String(p.get("figure", ""))
	if pic_path == "" or not ResourceLoader.exists(pic_path):
		var figs: Dictionary = _data.get("figures", {})
		pic_path = String(figs[fig_id].image) if figs.has(fig_id) else ""
	if pic_path != "" and ResourceLoader.exists(pic_path):
		var frame := Panel.new()
		var fb := _flat(Color(1, 1, 1, 0.0), 0)
		fb.set_border_width_all(2)
		fb.border_color = INK
		frame.add_theme_stylebox_override("panel", fb)
		frame.position = Vector2(30, y)
		frame.size = Vector2(PAGE_W - 60, 336)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		R.add_child(frame)
		var pic := TextureRect.new()
		pic.texture = load(pic_path)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.position = Vector2(36, y + 6)
		pic.size = Vector2(PAGE_W - 72, 324)
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		R.add_child(pic)
		y += 346
	if fig_id != "" and _find_figure(fig_id) >= 0:
		var fl := _link("See " + String(_data.figures[fig_id].title) + "  >", _find_figure(fig_id))
		fl.add_theme_font_override("font", BLOCK)
		fl.add_theme_color_override("font_color", RED)
		_put(R, fl, 30, y - 4)
		y += 22
	_put(R, _head("Procedure"), 30, y)
	var steps := VBoxContainer.new()
	steps.position = Vector2(30, y + 40)
	steps.size = Vector2(PAGE_W - 60, 0)
	steps.add_theme_constant_override("separation", 5)
	R.add_child(steps)
	var n := 1
	for s in p.get("steps", []):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var num := _label("%d." % n, BLACK, 19, RED)
		num.custom_minimum_size = Vector2(26, 0)
		num.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(num)
		var tx := _para(String(s), 18, INK)
		tx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(tx)
		steps.add_child(row)
		n += 1


func _figure(L: Control, R: Control, id: String, f: Dictionary) -> void:
	_put(L, _label(String(f.title).to_upper(), BLACK, 26, INK), 30, 24)
	_put(L, _rule(3, INK, PAGE_W - 60), 30, 62)
	if ResourceLoader.exists(String(f.image)):
		var pic := TextureRect.new()
		pic.texture = load(String(f.image))
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.position = Vector2(14, 76)
		pic.size = Vector2(PAGE_W - 28, BOOK.y - 170)
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		L.add_child(pic)
	_put(R, _label("INDEX", BLACK, 26, INK), 30, 24)
	_put(R, _label(String(_data.get("engine", "")).to_upper(), BLOCK, 18, RED), 130, 30)
	_put(R, _rule(3, INK, PAGE_W - 60), 30, 62)
	var hdr := _table_row("FIG.", "PART NO.", "DESCRIPTION", "QTY", true)
	_put(R, hdr, 30, 74)
	var y := 104.0
	for it in f.get("items", []):
		_put(R, _table_row(str(int(it.index)), String(it.no), String(it.name), str(int(it.qty)), false), 30, y)
		y += 26
		_put(R, _rule(1, Color(INK, 0.25), PAGE_W - 60), 30, y - 3)


func _table_row(a: String, b: String, c: String, d: String, head: bool) -> Control:
	var row := Control.new()
	row.size = Vector2(PAGE_W - 60, 24)
	var f: Font = BLACK if head else BODY
	var col := INK if not head else RED
	var xs := [0.0, 60.0, 190.0, PAGE_W - 110]
	var texts := [a, b, c, d]
	for k in 4:
		var l := _label(texts[k], f if k != 1 or head else BLOCK, 17, col)
		l.position = Vector2(xs[k], 0)
		if k == 2:
			l.size = Vector2(PAGE_W - 320, 24)
			l.clip_text = true
		row.add_child(l)
	return row


func _footer(p: Control, side: int) -> void:
	var y := BOOK.y - 74
	_put(p, _rule(1.5, INK, PAGE_W - 60), 30, y)
	_put(p, _label("- %d -" % (_spread * 2 + side + 1), BLOCK, 18, FADED), PAGE_W / 2 - 18, BOOK.y - 34)
	if side == 0:
		var hint := _label("A / D TURN PAGES   ·   C CONTENTS", BLOCK, 17, FADED)
		_put(p, hint, 30, y + 16)
		return
	var row := HBoxContainer.new()
	row.position = Vector2(30, y + 10)
	row.size = Vector2(PAGE_W - 60, 40)
	row.add_theme_constant_override("separation", 10)
	p.add_child(row)
	var prev := Button.new()
	prev.text = "< PREV"
	prev.disabled = _spread == 0
	_style_button(prev, Color(INK, 0.12), INK)
	prev.pressed.connect(func(): go(_spread - 1))
	row.add_child(prev)
	var next := Button.new()
	next.text = "NEXT >"
	next.disabled = _spread >= _pages.size() - 1
	_style_button(next, Color(INK, 0.12), INK)
	next.pressed.connect(func(): go(_spread + 1))
	row.add_child(next)
	var contents := Button.new()
	contents.text = "CONTENTS"
	contents.disabled = _spread == 0
	_style_button(contents, Color(INK, 0.12), INK)
	contents.pressed.connect(go.bind(0))
	row.add_child(contents)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(gap)
	var close := Button.new()
	close.text = "CLOSE (ESC)"
	_style_button(close, INK, CREAM)
	close.pressed.connect(_close)
	row.add_child(close)


func _chapter_name(ata: String) -> String:
	for ch in _data.get("chapters", []):
		if ch.ata == ata:
			return String(ch.title)
	return ""


func _close() -> void:
	if close_requested.get_connections().is_empty():
		queue_free()
	else:
		close_requested.emit()


# ---------------- helpers ----------------

func _put(parent: Control, c: Control, x: float, y: float) -> void:
	c.position = Vector2(x, y)
	parent.add_child(c)


func _label(t: String, f: Font, s: int, c: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", s)
	l.add_theme_color_override("font_color", c)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _para(t: String, s: int, c: Color) -> Label:
	var l := _label(t, BODY, s, c)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(PAGE_W - 100, 0)
	return l


func _head(t: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.add_child(_spacer(4))
	box.add_child(_label(t.to_upper(), BLACK, 20, RED))
	box.add_child(_rule(1.5, INK, PAGE_W - 60))
	return box


func _row(a: String, b: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var is_no := a.contains("-") or (a.length() > 0 and a.substr(0, 1).is_valid_int())
	var l := _label(a, BLOCK, 17, RED if is_no else INK)
	l.custom_minimum_size = Vector2(150, 0)
	row.add_child(l)
	var r := _label(b, BODY, 17, INK)
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(r)
	return row


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _rule(h: float, c: Color, w := 0.0) -> Control:
	var r := ColorRect.new()
	r.color = c
	r.custom_minimum_size = Vector2(w, h)
	r.size = Vector2(w, h)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _flat(c: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(radius)
	return sb


func _style_button(b: Button, bg: Color, fg: Color) -> void:
	b.add_theme_font_override("font", BLOCK)
	b.add_theme_font_size_override("font_size", 20)
	b.focus_mode = Control.FOCUS_NONE
	var states := {"normal": bg, "hover": bg.lightened(0.15) if bg.a > 0.5 else Color(INK, 0.25),
		"pressed": bg.darkened(0.2), "disabled": Color(bg, bg.a * 0.35)}
	for s in states:
		var sb := _flat(states[s], 3)
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		b.add_theme_stylebox_override(s, sb)
	for s in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(s, fg if bg.a > 0.5 else INK)
	b.add_theme_color_override("font_disabled_color", Color(fg if bg.a > 0.5 else INK, 0.4))
