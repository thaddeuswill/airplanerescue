extends Control
## The shop radio on the hangar workbench: a walnut set with a tuning dial and push-button stations.
## sound.gd plays the stations; on "Your Music" the buttons drive whatever music app runs on this PC.
## A / D or Left / Right tune it.

signal close_requested

const Catalog := preload("res://scripts/catalog.gd")
const CABINET := Vector2(920, 560)  # design size; scaled to fit the screen
const WALNUT := Color("4A2E1C")
const WALNUT_DK := Color("2E1B10")

var _sound
var _media := Callable()  # virtual key code -> presses that media key
var _saved := Callable()  # station index -> remembers it
var _face: Face
var _name: Label
var _hint: Label
var _transport: HBoxContainer
var _buttons: Array[Button] = []


func setup(sound, media: Callable, saved: Callable) -> void:
	_sound = sound
	_media = media
	_saved = saved


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var backdrop := ColorRect.new()
	backdrop.color = Catalog.BACKDROP
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	_face = Face.new()
	_face.size = CABINET
	_face.stations = _sound.STATIONS
	_face.needle = _dial(_sound.station)
	add_child(_face)
	_build()
	_show_station()
	_fit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _face:
		_fit()


func _fit() -> void:
	var area := size if size.x >= 1 and size.y >= 1 else get_viewport_rect().size
	var s := minf(area.x / (CABINET.x + 80), area.y / (CABINET.y + 80))
	_face.scale = Vector2(s, s)
	_face.position = (area - CABINET * s) / 2


func _dial(i: int) -> float:
	return float(i) / (_sound.STATIONS.size() - 1)


func _build() -> void:
	var brand := _label("Shop Radio", Catalog.SCRIPT, 44, Catalog.CREAM)
	brand.position = Vector2(44, 478)
	_face.add_child(brand)
	_name = _label("", Catalog.BLACK, 42, Catalog.CREAM)
	_name.position = Vector2(330, 226)
	_face.add_child(_name)
	_hint = _label("", Catalog.BODY, 21, Color(Catalog.CREAM, 0.75))
	_hint.position = Vector2(332, 278)
	_face.add_child(_hint)
	_transport = HBoxContainer.new()
	_transport.position = Vector2(330, 318)
	_transport.add_theme_constant_override("separation", 10)
	_face.add_child(_transport)
	for b in [["< PREV", 177], ["PLAY / PAUSE", 179], ["NEXT >", 176]]:  # the Windows media key codes
		var key := Button.new()
		key.text = b[0]
		key.focus_mode = Control.FOCUS_NONE
		Catalog._style_button(key, Catalog.MUSTARD, Catalog.INK, 22)
		key.pressed.connect(_press.bind(b[1]))
		_transport.add_child(key)
	var row := HBoxContainer.new()
	row.position = Vector2(44, 396)
	row.size = Vector2(CABINET.x - 88, 56)
	row.add_theme_constant_override("separation", 10)
	_face.add_child(row)
	for i in _sound.STATIONS.size():
		var b := Button.new()
		b.text = String(_sound.STATIONS[i].key).to_upper()
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(tune.bind(i))
		row.add_child(b)
		_buttons.append(b)
	var close := Button.new()
	close.text = "CLOSE (ESC)"
	close.focus_mode = Control.FOCUS_NONE
	Catalog._style_button(close, Catalog.INK, Catalog.CREAM, 22)
	close.custom_minimum_size = Vector2(150, 44)
	close.position = Vector2(CABINET.x - 44 - 150, 484)
	close.pressed.connect(func(): close_requested.emit())
	_face.add_child(close)


func _unhandled_key_input(e: InputEvent) -> void:
	if not (e is InputEventKey and e.pressed and not e.echo):
		return
	match e.keycode:
		KEY_A, KEY_LEFT:
			tune(maxi(_sound.station - 1, 0))
		KEY_D, KEY_RIGHT:
			tune(mini(_sound.station + 1, _sound.STATIONS.size() - 1))
		_:
			return
	get_viewport().set_input_as_handled()


func tune(i: int) -> void:
	if i == _sound.station:
		return
	_sound.tune(i)
	_saved.call(i)
	_show_station()
	var sweep := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	sweep.tween_property(_face, "needle", _dial(i), 0.35)


func _press(key: int) -> void:
	_sound.sfx("click")
	_media.call(key)


func _show_station() -> void:
	var s: Dictionary = _sound.STATIONS[_sound.station]
	_name.text = String(s.name).to_upper()
	_hint.text = s.hint
	_transport.visible = s.get("yours", false)
	for i in _buttons.size():
		var on: bool = i == _sound.station
		Catalog._style_button(_buttons[i], Catalog.RED if on else Catalog.CREAM, Catalog.CREAM if on else Catalog.INK, 21)


func _label(t: String, f: Font, s: int, c: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", s)
	l.add_theme_color_override("font_color", c)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## The cabinet: walnut case, speaker cloth, and the lit tuning dial with its red needle.
class Face extends Control:
	var stations: Array
	var needle := 0.0:
		set(v):
			needle = v
			queue_redraw()

	func _draw() -> void:
		var case_ := StyleBoxFlat.new()
		case_.set_corner_radius_all(26)
		case_.bg_color = Color(0, 0, 0, 0.45)
		draw_style_box(case_, Rect2(Vector2(10, 14), size))
		case_.bg_color = WALNUT
		case_.set_border_width_all(6)
		case_.border_color = WALNUT_DK
		draw_style_box(case_, Rect2(Vector2.ZERO, size))
		var cloth := Rect2(44, 44, 250, 330)
		draw_rect(cloth, WALNUT_DK)
		var y := cloth.position.y + 14
		while y < cloth.end.y - 8:
			draw_line(Vector2(cloth.position.x + 12, y), Vector2(cloth.end.x - 12, y), Color("C8B99A", 0.5), 3.0)
			y += 16
		var dial := Rect2(330, 44, 546, 160)
		draw_rect(dial, Color("F0E2B6"))
		draw_rect(dial, WALNUT_DK, false, 5.0)
		var font := Catalog.BLOCK
		var left := dial.position.x + 44
		var span := dial.size.x - 88
		for t in 51:
			var x := left + span * t / 50.0
			var tall := 26.0 if t % 10 == 0 else 12.0
			draw_line(Vector2(x, dial.end.y - 18), Vector2(x, dial.end.y - 18 - tall), Catalog.INK, 2.0)
		for i in stations.size():
			var x := left + span * i / (stations.size() - 1.0)
			var text: String = stations[i].freq
			var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
			draw_string(font, Vector2(x - w / 2, dial.position.y + 44), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Catalog.INK)
		var at := left + span * needle
		draw_line(Vector2(at, dial.position.y + 8), Vector2(at, dial.end.y - 8), Catalog.RED, 5.0)
