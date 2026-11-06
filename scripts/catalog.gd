extends Control
## The parts counter as a mid-century tool catalog: "Field Service Catalog No. 1".
## A two-page spread on aged paper, three items a page, section tabs along the top.
## main.gd builds the entries (prices, stock, what you have) and owns buying; this only shows
## them and calls each entry's buy Callable. Pages: A / D, Left / Right or Page Up / Down.
##
## setup(title, town, money, sections, note, sfx):
##   sections: [{"id": "parts", "tab": "Parts", "head": "Section A: Aircraft parts", "items": [entry...]}]
##   entry: {"name", "no", "blurb", "icon" (res:// path or ""), "price" (int), "mail" (bool),
##           "have" (String), "needed" (bool), "owned" (bool), "can" (bool), "buy" (Callable)}

signal close_requested

const INK := Color("1E1B17")
const RED := Color("A8261F")
const RED_DK := Color("7E1C16")
const CREAM := Color("EEE6CF")
const MUSTARD := Color("D9A62E")
const GREEN := Color("2E5339")
const FADED := Color("6B5E4B")
const BACKDROP := Color("4D594D")  # the green baize the book lies on
const PER_PAGE := 3
const BOOK := Vector2(1320, 800)  # design size; scaled to fit the screen

static var SCRIPT := _font_file("res://fonts/Yellowtail-Regular.ttf")
static var BLOCK := _block(800)
static var BLACK := _block(900)
static var BODY := _block(600)
static var _remember := {}  # catalog title -> [section index, spread], so buying keeps your page

var _title := ""
var _town := ""
var _money := 0
var _sections: Array = []
var _note := ""
var _sfx := Callable()
var _sec := 0
var _spread := 0
var _book: Control
var _pages: Array[Control] = []


static func _font_file(path: String) -> Font:
	if ResourceLoader.exists(path):
		return load(path)
	var f := SystemFont.new()  # fonts folder missing: fall back to something condensed
	f.font_names = PackedStringArray(["Bahnschrift", "Arial Narrow", "sans-serif"])
	return f


static func _block(weight: int) -> FontVariation:
	var v := FontVariation.new()
	v.base_font = _font_file("res://fonts/BigShouldersDisplay.ttf")
	v.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	return v


func setup(title: String, town: String, money: int, sections: Array, note := "", sfx := Callable()) -> void:
	_title = title
	_town = town
	_money = money
	_sections = sections.filter(func(s): return s.items.size() > 0)
	_note = note
	_sfx = sfx
	var mem: Array = _remember.get(title, [0, 0])
	_sec = clampi(mem[0], 0, maxi(0, _sections.size() - 1))
	_spread = clampi(mem[1], 0, maxi(0, _spread_count() - 1))


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # the plain preset keeps a size of zero
	mouse_filter = Control.MOUSE_FILTER_STOP
	var backdrop := ColorRect.new()
	backdrop.color = BACKDROP
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	_book = Control.new()
	_book.size = BOOK
	add_child(_book)
	_build()
	_fit.call_deferred()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _book:
		_fit()


## Fades the book in; skipped when a purchase swaps one catalog for the next.
func fade_in() -> void:
	_fit()  # centered first: the slide below ends where it starts from
	modulate.a = 0.0
	_book.position.y += 24
	var tw := create_tween().set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "modulate:a", 1.0, 0.18)
	tw.tween_property(_book, "position:y", _book.position.y - 24, 0.18)


func _fit() -> void:
	var area := size if size.x >= 1 and size.y >= 1 else get_viewport_rect().size
	var s := minf(area.x / (BOOK.x + 40), area.y / (BOOK.y + 40))
	_book.scale = Vector2(s, s)
	_book.position = (area - BOOK * s) / 2


func _spread_count() -> int:
	if _sections.is_empty():
		return 1
	return maxi(1, ceili(_sections[_sec].items.size() / float(PER_PAGE * 2)))


func _unhandled_key_input(e: InputEvent) -> void:
	if not (e is InputEventKey and e.pressed and not e.echo):
		return
	match e.keycode:
		KEY_A, KEY_LEFT, KEY_PAGEUP:
			_turn(-1)
		KEY_D, KEY_RIGHT, KEY_PAGEDOWN:
			_turn(1)
		KEY_TAB:
			_tab((_sec + (-1 if e.shift_pressed else 1) + _sections.size()) % maxi(1, _sections.size()))
		_:
			return
	get_viewport().set_input_as_handled()


func _turn(d: int) -> void:
	var n := clampi(_spread + d, 0, _spread_count() - 1)
	if n == _spread:
		return
	_spread = n
	_remember[_title] = [_sec, _spread]
	if _sfx.is_valid():
		_sfx.call()
	_build()


func _tab(i: int) -> void:
	if i == _sec or i < 0 or i >= _sections.size():
		return
	_sec = i
	_spread = 0
	_remember[_title] = [_sec, _spread]
	if _sfx.is_valid():
		_sfx.call()
	_build()


# ---------------- building the spread ----------------

func _build() -> void:
	for c in _book.get_children():
		c.queue_free()
	_pages.clear()
	var focus_first: Button = null
	# drop shadow, then the two pages either side of the spine
	var shadow := Panel.new()
	shadow.position = Vector2(10, 14)
	shadow.size = BOOK
	shadow.add_theme_stylebox_override("panel", _flat(Color(0, 0, 0, 0.45), 6))
	_book.add_child(shadow)
	for side in 2:
		var page := _page(side)
		_book.add_child(page)
		_pages.append(page)
	var spine := TextureRect.new()
	spine.texture = _spine_tex()
	spine.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spine.stretch_mode = TextureRect.STRETCH_SCALE
	spine.position = Vector2(BOOK.x / 2 - 40, 0)
	spine.size = Vector2(80, BOOK.y)
	spine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_book.add_child(spine)
	# left page: masthead; right page: section head and tabs
	_masthead(_pages[0])
	_section_head(_pages[1])
	var items: Array = _sections[_sec].items if _sections.size() > 0 else []
	for side in 2:
		var box := VBoxContainer.new()
		box.position = Vector2(34, 196 if side == 0 else 172)
		box.size = Vector2(BOOK.x / 2 - 68, 0)
		box.add_theme_constant_override("separation", 0)
		_pages[side].add_child(box)
		for k in PER_PAGE:
			var i := _spread * PER_PAGE * 2 + side * PER_PAGE + k
			if i >= items.size():
				break
			if k > 0:
				box.add_child(_rule(1.5, Color(INK, 0.55)))
			var b := _card(items[i], i)
			box.add_child(b[0])
			if focus_first == null and b[1] != null:
				focus_first = b[1]
		if side == 0 and items.is_empty():
			box.add_child(_label("Nothing on this page.", BODY, 22, FADED))
	_footer(_pages[0], 0)
	_footer(_pages[1], 1)
	if focus_first:
		focus_first.grab_focus.call_deferred()


func _page(side: int) -> Control:
	var page := Control.new()
	page.position = Vector2(side * BOOK.x / 2, 0)
	page.size = Vector2(BOOK.x / 2, BOOK.y)
	page.clip_contents = true
	var bg := Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb := _flat(CREAM, 4)
	sb.corner_radius_top_right = 4 if side == 1 else 0
	sb.corner_radius_bottom_right = 4 if side == 1 else 0
	sb.corner_radius_top_left = 4 if side == 0 else 0
	sb.corner_radius_bottom_left = 4 if side == 0 else 0
	bg.add_theme_stylebox_override("panel", sb)
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
	return page


func _masthead(p: Control) -> void:
	var band := Panel.new()
	band.position = Vector2(0, 0)
	band.size = Vector2(p.size.x, 78)
	band.add_theme_stylebox_override("panel", _flat(RED, 0))
	p.add_child(band)
	var t := _label("FIELD SERVICE CATALOG", BLACK, 40, CREAM)
	t.position = Vector2(30, 12)
	p.add_child(t)
	var no := _label("No. 1", BLOCK, 26, CREAM)
	no.position = Vector2(p.size.x - 96, 22)
	p.add_child(no)
	var sun := Halftone.new()
	sun.position = Vector2(p.size.x - 190, 70)
	sun.size = Vector2(170, 120)
	sun.radius = 60
	p.add_child(sun)
	var brand := _label("Airplane Rescue", SCRIPT, 50, RED)
	brand.position = Vector2(30, 84)
	brand.add_theme_color_override("font_outline_color", INK)
	brand.add_theme_constant_override("outline_size", 6)
	brand.add_theme_color_override("font_shadow_color", INK)
	brand.add_theme_constant_override("shadow_offset_x", 3)
	brand.add_theme_constant_override("shadow_offset_y", 3)
	p.add_child(brand)
	var strap := _label(_title.to_upper(), BLOCK, 19, CREAM)
	var sb := _flat(INK, 0)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	strap.add_theme_stylebox_override("normal", sb)
	strap.position = Vector2(32, 150)
	p.add_child(strap)
	var r := _rule(3, INK)
	r.position = Vector2(30, 184)
	r.size = Vector2(p.size.x - 60, 3)
	p.add_child(r)


func _section_head(p: Control) -> void:
	var tabs := HBoxContainer.new()
	tabs.position = Vector2(30, 18)
	tabs.add_theme_constant_override("separation", 6)
	p.add_child(tabs)
	for i in _sections.size():
		var b := Button.new()
		b.text = String(_sections[i].tab).to_upper()
		b.focus_mode = Control.FOCUS_NONE
		var on := i == _sec
		_style_button(b, INK if on else Color(INK, 0.12), CREAM if on else INK, 22)
		b.pressed.connect(_tab.bind(i))
		tabs.add_child(b)
	var head: String = _sections[_sec].head if _sections.size() > 0 else ""
	var h := _label(head.to_upper(), BLACK, 32, INK)
	h.position = Vector2(30, 76)
	p.add_child(h)
	var town := _label(_town, BODY, 19, RED)
	town.position = Vector2(30, 116)
	p.add_child(town)
	var r := _rule(3, INK)
	r.position = Vector2(30, 152)
	r.size = Vector2(p.size.x - 60, 3)
	p.add_child(r)


func _footer(p: Control, side: int) -> void:
	var y := BOOK.y - 74
	var r := _rule(1.5, INK)
	r.position = Vector2(30, y)
	r.size = Vector2(p.size.x - 60, 1.5)
	p.add_child(r)
	var num := _label("- %d -" % (_spread * 2 + side + 1), BLOCK, 18, FADED)
	num.position = Vector2(p.size.x / 2 - 18, BOOK.y - 34)
	p.add_child(num)
	if side == 0:
		var cash := _label("CASH ON HAND  $%s" % _commas(_money), BLOCK, 24, INK)
		cash.position = Vector2(30, y + 10)
		p.add_child(cash)
		if _note != "":
			var n := _label(_note, BODY, 16, FADED)
			n.position = Vector2(30, y + 40)
			n.size = Vector2(p.size.x / 2 - 50, 0)  # stops short of the page number
			n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			p.add_child(n)
	else:
		var row := HBoxContainer.new()
		row.position = Vector2(30, y + 10)
		row.size = Vector2(p.size.x - 60, 40)
		row.add_theme_constant_override("separation", 10)
		p.add_child(row)
		var prev := Button.new()
		prev.text = "< PREV"
		prev.disabled = _spread == 0
		_style_button(prev, Color(INK, 0.12), INK, 20)
		prev.pressed.connect(_turn.bind(-1))
		row.add_child(prev)
		var next := Button.new()
		next.text = "NEXT >"
		next.disabled = _spread >= _spread_count() - 1
		_style_button(next, Color(INK, 0.12), INK, 20)
		next.pressed.connect(_turn.bind(1))
		row.add_child(next)
		var gap := Control.new()
		gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(gap)
		var close := Button.new()
		close.text = "CLOSE (ESC)"
		_style_button(close, INK, CREAM, 20)
		close.pressed.connect(_close)
		row.add_child(close)


## One catalog listing: picture on a halftone sun, name and copy, stock line, price tag, button.
## Returns [row, buy button or null].
func _card(e: Dictionary, index: int) -> Array:
	var row := Control.new()
	row.custom_minimum_size = Vector2(0, 168)
	var sun := Halftone.new()
	sun.position = Vector2(0, 14)
	sun.size = Vector2(140, 140)
	sun.radius = 64
	sun.color = Color(MUSTARD, 0.8)
	row.add_child(sun)
	var icon_path: String = e.get("icon", "")
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var pic := TextureRect.new()
		pic.texture = load(icon_path)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # before size, or size snaps to the image
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.position = Vector2(14, 28)
		pic.size = Vector2(112, 112)
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(pic)
	var x := 156.0
	var name_l := _label(String(e.name).to_upper(), BLACK, 30, INK)
	name_l.position = Vector2(x, 12)
	name_l.size = Vector2(300, 0)
	name_l.clip_text = true
	row.add_child(name_l)
	var no := _label("No. " + String(e.get("no", "")), BLOCK, 17, RED)
	no.position = Vector2(x, 48)
	row.add_child(no)
	var blurb := _label(e.get("blurb", ""), BODY, 18, Color(INK, 0.85))
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.max_lines_visible = 2
	blurb.custom_minimum_size = Vector2(286, 0)
	blurb.position = Vector2(x, 72)
	blurb.size = Vector2(286, 48)
	row.add_child(blurb)
	var stock: String
	var stock_col := GREEN
	if e.get("owned", false):
		stock = "IN YOUR TOOL ROLL"
	elif e.get("mail", false):
		stock = "MAIL ORDER  -  ARRIVES IN 1 DAY"
		stock_col = RED_DK
	else:
		stock = "IN STOCK AT THIS COUNTER"
	if e.get("have", "") != "" and not e.get("owned", false):
		stock += "   |   YOU HAVE " + String(e.have).to_upper()
	var st := _label(stock, BLOCK, 16, stock_col)
	st.position = Vector2(x, 128)
	row.add_child(st)
	# price tag and button down the right side
	var tag := PriceTag.new()
	tag.text = "OWNED" if e.get("owned", false) else "$" + _commas(int(e.get("price", 0)))
	tag.font = BLACK
	tag.position = Vector2(452, 14)
	tag.size = Vector2(130, 62)
	tag.rotation = -0.06
	row.add_child(tag)
	var buy: Button = null
	if not e.get("owned", false):
		buy = Button.new()
		buy.text = "ORDER" if e.get("mail", false) else "BUY"
		buy.disabled = not e.get("can", false)
		buy.tooltip_text = "" if e.get("can", false) else "Not enough cash."
		_style_button(buy, RED, CREAM, 24)
		buy.position = Vector2(462, 96)
		buy.size = Vector2(118, 46)
		var cb: Callable = e.get("buy", Callable())
		buy.pressed.connect(func():
			if cb.is_valid():
				cb.call())
		row.add_child(buy)
	if e.get("needed", false):
		var stamp := Stamp.new()
		stamp.text = "NEEDED"
		stamp.font = BLACK
		stamp.position = Vector2(318, 6)
		stamp.size = Vector2(124, 44)
		stamp.rotation = 0.12
		row.add_child(stamp)
	return [row, buy]


func _close() -> void:
	if close_requested.get_connections().is_empty():
		queue_free()
	else:
		close_requested.emit()


# ---------------- small helpers ----------------

func _label(t: String, f: Font, s: int, c: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", s)
	l.add_theme_color_override("font_color", c)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _rule(h: float, c: Color) -> Control:
	var r := ColorRect.new()
	r.color = c
	r.custom_minimum_size = Vector2(0, h)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func _flat(c: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(radius)
	return sb


static func _style_button(b: Button, bg: Color, fg: Color, size_px: int) -> void:
	b.add_theme_font_override("font", BLOCK)
	b.add_theme_font_size_override("font_size", size_px)
	var states := {"normal": bg, "hover": bg.lightened(0.15) if bg.a > 0.5 else Color(INK, 0.25),
		"pressed": bg.darkened(0.2), "focus": bg, "disabled": Color(bg, bg.a * 0.35)}
	for s in states:
		var sb := _flat(states[s], 3)
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		if s == "focus":
			sb.draw_center = false
			sb.set_border_width_all(3)
			sb.border_color = MUSTARD
		b.add_theme_stylebox_override(s, sb)
	for s in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(s, fg if bg.a > 0.5 else INK)
	b.add_theme_color_override("font_disabled_color", Color(fg if bg.a > 0.5 else INK, 0.45))


func _commas(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out


static var _spine: GradientTexture2D


static func _spine_tex() -> GradientTexture2D:
	if _spine:
		return _spine
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.42, 0.5, 0.58, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0.2, 0.14, 0.08, 0.22), Color(0.1, 0.07, 0.04, 0.45),
		Color(0.2, 0.14, 0.08, 0.22), Color(0, 0, 0, 0)])
	_spine = GradientTexture2D.new()
	_spine.gradient = g
	_spine.width = 64
	_spine.height = 4
	return _spine


## A printed halftone sun: dots that shrink toward the edge of a circle.
class Halftone extends Control:
	var radius := 60.0
	var color := Color(0.85, 0.65, 0.18, 0.9)

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size / 2
		var step := 8.0
		var y := -radius
		while y <= radius:
			var x := -radius + (fmod(y / step, 2.0) * step * 0.5)
			while x <= radius:
				var d := Vector2(x, y).length() / radius
				if d < 1.0:
					draw_circle(c + Vector2(x, y), (1.0 - d * 0.75) * step * 0.42, color)
				x += step
			y += step


## A mustard hang tag with the price lettered on it.
class PriceTag extends Control:
	var text := ""
	var font: Font

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var pts := PackedVector2Array([Vector2(22, 0), Vector2(w, 0), Vector2(w, h), Vector2(22, h), Vector2(0, h / 2)])
		var sh := PackedVector2Array()
		for p in pts:
			sh.append(p + Vector2(4, 4))
		draw_colored_polygon(sh, Color(0.12, 0.1, 0.09, 1.0))
		draw_colored_polygon(pts, Color("D9A62E"))
		var loop := pts.duplicate()
		loop.append(pts[0])
		draw_polyline(loop, Color("1E1B17"), 2.5)
		draw_circle(Vector2(16, h / 2), 5.5, Color("EEE6CF"))
		draw_arc(Vector2(16, h / 2), 5.5, 0, TAU, 16, Color("1E1B17"), 2.0)
		if font:
			var fs := 34
			while fs > 14 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > w - 40:
				fs -= 2
			var sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
			draw_string(font, Vector2(28 + (w - 34 - sz.x) / 2, h / 2 + fs * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("1E1B17"))


## A red rubber stamp, slightly broken up like it was pressed by hand.
class Stamp extends Control:
	var text := ""
	var font: Font

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var red := Color("A8261F", 0.88)
		draw_rect(Rect2(Vector2.ZERO, size), red, false, 3.0)
		draw_rect(Rect2(Vector2(5, 5), size - Vector2(10, 10)), red, false, 1.2)
		if font:
			var fs := 26
			var sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
			draw_string(font, Vector2((size.x - sz.x) / 2, size.y / 2 + fs * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, red)
		var r := RandomNumberGenerator.new()
		r.seed = hash(text)
		for i in 26:  # worn spots where the ink didn't take
			draw_circle(Vector2(r.randf() * size.x, r.randf() * size.y), r.randf_range(0.8, 2.2), Color("EEE6CF", 0.85))
