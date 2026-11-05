extends Control
## One round cockpit dial, drawn into a SubViewport whose texture sits in a hole of the Cub's
## panel. Needle sweeps clockwise from 7:30 (lo) to 4:30 (hi), or a full turn when `full_turn`.

var title := ""
var unit := ""
var lo := 0.0
var hi := 100.0
var marks := 10  # numbered ticks
var label_scale := 1.0  # number shown = tick value * label_scale
var full_turn := false  # altimeter: one turn per 1000 ft, readout in the middle
var green := Vector2(-1, -1)  # value range painted as a green arc, (-1,-1) = none
var value := 0.0:
	set(v):
		value = v
		queue_redraw()


func _angle(v: float) -> float:
	var t := clampf((v - lo) / (hi - lo), 0.0, 1.0) if not full_turn else fposmod(v, hi) / hi
	return (deg_to_rad(135.0) + t * TAU) if full_turn else deg_to_rad(135.0 + 270.0 * t)


func _draw() -> void:
	var c := size / 2
	var r := minf(size.x, size.y) / 2
	var font := ThemeDB.fallback_font
	draw_circle(c, r, Color(0.55, 0.5, 0.42))  # brass bezel
	draw_circle(c, r * 0.9, Color(0.06, 0.06, 0.06))
	if green.x >= 0:
		draw_arc(c, r * 0.74, _angle(green.x), _angle(green.y), 24, Color(0.2, 0.7, 0.25), r * 0.08)
	for i in marks + (0 if full_turn else 1):
		var v := lo + (hi - lo) * i / marks
		var a := _angle(v) if not full_turn else deg_to_rad(135.0) + TAU * i / marks
		var dir := Vector2.from_angle(a)
		draw_line(c + dir * r * 0.68, c + dir * r * 0.84, Color(0.95, 0.93, 0.85), 2.0)
		var txt := str(roundi(v * label_scale)) if not full_turn else str(i)
		var sz := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, int(r * 0.2))
		draw_string(font, c + dir * r * 0.52 - Vector2(sz.x / 2, -sz.y / 3), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, int(r * 0.2), Color(0.95, 0.93, 0.85))
	var tsz := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, int(r * 0.15))
	draw_string(font, c + Vector2(-tsz.x / 2, r * 0.45), title, HORIZONTAL_ALIGNMENT_LEFT, -1, int(r * 0.15), Color(0.85, 0.82, 0.7))
	if full_turn:
		var rd := "%d ft" % roundi(value)
		var rsz := font.get_string_size(rd, HORIZONTAL_ALIGNMENT_LEFT, -1, int(r * 0.16))
		draw_string(font, c + Vector2(-rsz.x / 2, -r * 0.2), rd, HORIZONTAL_ALIGNMENT_LEFT, -1, int(r * 0.16), Color(0.95, 0.85, 0.5))
	var na := Vector2.from_angle(_angle(value))
	draw_line(c - na * r * 0.15, c + na * r * 0.8, Color(1, 1, 0.95), r * 0.05)
	draw_circle(c, r * 0.07, Color(0.2, 0.2, 0.2))


## Builds the dial in its own little viewport and returns a quad showing it (radius in m).
static func make(parent: Node3D, pos: Vector3, radius: float, setup: Callable) -> Control:
	var vp := SubViewport.new()
	vp.size = Vector2i(160, 160)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var g = load("res://scripts/gauge.gd").new()
	g.size = Vector2(160, 160)
	setup.call(g)
	vp.add_child(g)
	parent.add_child(vp)
	var q := QuadMesh.new()
	q.size = Vector2.ONE * radius * 2.0
	var m := StandardMaterial3D.new()
	m.albedo_texture = vp.get_texture()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true  # faint glow so the dials read in the cabin shadow
	m.emission_texture = vp.get_texture()
	m.emission_energy_multiplier = 0.35
	q.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.position = pos  # QuadMesh faces +Z: toward the pilot
	parent.add_child(mi)
	return g
