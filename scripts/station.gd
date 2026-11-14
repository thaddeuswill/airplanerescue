extends Control
## A spot on the plane, opened up: every place you can get into from here (the engine has 27),
## as tiles with the place's own picture. Click one to work there; Esc or Back in that scene
## brings you back here, not out to the walk-around. Labels name the place, never the fault.

const Work := preload("res://scripts/work.gd")
const COLS := 6
const TILE := Vector2(156, 87)  # the scenes' own 1000x560 shape; 5 rows fit under 720 px
const GAP := 10.0
const FALLBACK := {"engine": "spark_plugs", "cabin": "avionics", "tail": "control_cables", "prop": "propeller"}

var main
var zone: String
var places: Array = []  # scene ids
var hover := -1
var font := Style.display(600)
var _tex := {}


func setup(m, z: String) -> void:
	main = m
	zone = z
	places = m.station_places(z)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _origin() -> Vector2:
	return Vector2(maxf(0, (size.x - Work.W) / 2), 96)


func _rect(i: int) -> Rect2:
	return Rect2(Vector2(i % COLS, i / COLS) * (TILE + Vector2(GAP, GAP + 18)), TILE)


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		var h := _hit(ev.position - _origin())
		if h != hover:
			hover = h
			queue_redraw()
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var h := _hit(ev.position - _origin())
		if h >= 0:
			main.station_open(zone, places[h])


func _hit(p: Vector2) -> int:
	for i in places.size():
		if _rect(i).has_point(p):
			return i
	return -1


func _picture(id: String) -> Texture2D:
	if not _tex.has(id):
		var art: String = Work.scenes()[id].get("art", id)
		var p := "res://textures/work/%s_bg.png" % art
		if not ResourceLoader.exists(p):  # no painting of its own yet: the spot's general view
			p = "res://textures/work/%s_bg.png" % FALLBACK.get(zone, "")
		_tex[id] = load(p) if ResourceLoader.exists(p) else null
	return _tex[id]


func _draw() -> void:
	if main.current_job == null:  # the owner gave up while it was open: it's closing
		return
	var o := _origin()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.09, 0.08, 0.07))
	draw_string(font, Vector2(o.x, 34), main.station_title(zone), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.98, 0.94, 0.85))
	draw_string(font, Vector2(o.x, 60), main.station_status(zone), HORIZONTAL_ALIGNMENT_LEFT, Work.W, 14, Color(0.85, 0.82, 0.75))
	draw_string(font, Vector2(o.x, 80), "Click a place to work there. Esc there brings you back here; Esc here steps away.",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.7, 0.66, 0.6))
	for i in places.size():
		var r := _rect(i)
		r.position += o
		var t := _picture(places[i])
		if t:
			draw_texture_rect(t, r, false)
		else:
			draw_rect(r, Color(0.22, 0.2, 0.17))
		draw_rect(r, Color(1, 0.9, 0.6, 0.9 if i == hover else 0.25), false, 3.0 if i == hover else 1.0)
		var label: String = main.PLACES.get(places[i], places[i])
		draw_string(font, Vector2(r.position.x, r.end.y + 15), label, HORIZONTAL_ALIGNMENT_LEFT, TILE.x, 13,
			Color(1, 0.9, 0.6) if i == hover else Color(0.9, 0.86, 0.78))
		var mark: String = main.station_mark(places[i])
		if mark != "":
			var mr := Rect2(r.position + Vector2(r.size.x - 26, 4), Vector2(22, 22))
			draw_rect(mr, Color(0.1, 0.08, 0.05, 0.85))
			draw_string(font, mr.position + Vector2(6, 17), mark, HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
				Color(0.45, 0.9, 0.45) if mark == "OK" else Color(1.0, 0.55, 0.15))
