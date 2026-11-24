extends Control
## The cockpit checklist card, bottom left on frosted glass (C1), from ferry.card(): before start, the run-up, and (for your
## first two deliveries) the take-off itself. Every item shows its key from your bindings and what
## it reads now; a done item is ticked. Something gone wrong (flooded, hung, starter hot) goes on
## a red band at the top with the fix, so a failed start tells you what to do instead of only that
## it failed.
##
## Coached (your first two deliveries, with the apprentice checklist setting on): the item you're on
## says why, and the card stays up through the take-off roll. After that it's the bare checklist a
## pilot keeps on the panel, and it goes away once the engine runs.

const Tutorial := preload("res://scripts/tutorial.gd")
const W := 300.0  # was 380 on cream paper at the top left; smaller and in the corner (C1, Thad)

var main
var _was := {}  # item text -> seconds since it ticked, for the check drawing itself in
var _prev := {}
var last_rect := Rect2()  # where the card was last drawn, for the self-test
var _glass: Panel  # the frosted panel behind the drawing (show_behind_parent)


func setup(m) -> void:
	main = m
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_glass = Panel.new()
	_glass.show_behind_parent = true  # the parent's drawing (the text) goes over it
	_glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Style.COLOR_SURFACE_GLASS
	sb.set_corner_radius_all(Style.RADIUS_MD * 2)
	sb.set_border_width_all(1)
	sb.border_width_top = 2
	sb.border_color = Style.COLOR_GLASS_EDGE
	sb.anti_aliasing = true
	_glass.add_theme_stylebox_override("panel", sb)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/glass.gdshader")
	_glass.material = mat
	add_child(_glass)


## Your first two planes get the explanations and the take-off; then you know it.
func coached() -> bool:
	return main.rescued < 2 and main.settings.get("checklist", true)


## Up while there's a checklist to run: before start, the run-up, and a coached take-off.
func wanted() -> bool:
	var f = main.ferry
	if f == null or main.panel != null or f.done or f._result != "":
		return false
	return f.state != "run" or f.mode == "runup" or coached()


func _process(delta: float) -> void:
	visible = wanted()
	if not visible:
		_prev.clear()
		return
	for k in _was.keys():
		_was[k] += delta
	for st in main.ferry.card().steps:
		if st.ok and not _prev.get(st.text, false):
			_was[st.text] = 0.0
		_prev[st.text] = st.ok
	queue_redraw()


func _draw() -> void:
	if not wanted():
		_glass.visible = false
		return
	var c: Dictionary = main.ferry.card()
	var teach := coached()
	var pad := 12.0
	var head := Style.caps(800, Style.SIZE_XS)
	var body := Style.display(700)
	var light := Style.display(600)
	var figs := Style.figures(true)
	var step_px := Style.SIZE_SM
	var row := 22.0
	var text_w := W - pad * 2 - 24 - 84  # room left of the key and the reading
	var wrap_w := W - pad * 2 - 24
	var steps: Array = c.steps
	var cur := -1
	for i in steps.size():
		if not steps[i].ok:
			cur = i
			break
	# height first: the card sits in the bottom-left corner, so its top depends on it
	var h := pad + 12 + 24
	if c.alert != "":
		h += body.get_multiline_string_size(c.alert, HORIZONTAL_ALIGNMENT_LEFT, W - pad * 2 - 12, Style.SIZE_SM).y + 14
	for i in steps.size():
		h += row
		if teach and i == cur:
			h += light.get_multiline_string_size(steps[i].how, HORIZONTAL_ALIGNMENT_LEFT, wrap_w, Style.SIZE_XS).y + 4
	var foot_h := 0.0
	if c.foot != "":  # wraps: it used to be cut off at the card's edge (U6)
		foot_h = light.get_multiline_string_size(c.foot, HORIZONTAL_ALIGNMENT_LEFT, W - pad * 2, Style.SIZE_XS).y
		h += foot_h + 10
	h += pad
	var x := 16.0
	var y := size.y - 16.0 - h
	var r := Rect2(x, y, W, h)
	last_rect = r
	_glass.visible = true
	_glass.position = r.position
	_glass.size = r.size
	var cy := y + pad + 10
	draw_string(head, Vector2(x + pad, cy), "CHECKLIST", HORIZONTAL_ALIGNMENT_LEFT, -1, Style.SIZE_XS, Style.COLOR_TEXT_HUD_MUTED)
	cy += 22
	draw_string(Style.caps(900, Style.SIZE_MD), Vector2(x + pad, cy), c.title, HORIZONTAL_ALIGNMENT_LEFT, -1, Style.SIZE_MD, Style.COLOR_TEXT_HUD)
	if c.alert != "":  # the fix for what just went wrong, first and in red
		var ah := body.get_multiline_string_size(c.alert, HORIZONTAL_ALIGNMENT_LEFT, W - pad * 2 - 12, Style.SIZE_SM).y
		var band := Rect2(x + pad - 4, cy + 6, W - pad * 2 + 8, ah + 8)
		draw_rect(band, Color(Style.COLOR_TEXT_LOSS, 0.14 + 0.06 * sin(Time.get_ticks_msec() * 0.006)))
		draw_rect(Rect2(band.position, Vector2(3, band.size.y)), Style.COLOR_TEXT_LOSS)
		draw_multiline_string(body, Vector2(band.position.x + 10, band.position.y + 16), c.alert, HORIZONTAL_ALIGNMENT_LEFT,
			W - pad * 2 - 12, Style.SIZE_SM, -1, Style.COLOR_TEXT_LOSS)
		cy += ah + 14
	cy += 4
	for i in steps.size():
		var s: Dictionary = steps[i]
		cy += row
		var box := Rect2(x + pad, cy - 13, 14, 14)
		var now := i == cur
		draw_rect(box, Color(Style.COLOR_TEXT_HUD, 0.7 if now else 0.3), false, 1.5)
		if s.ok:
			Tutorial.draw_check(self, box, clampf(_was.get(s.text, 9.0) / 0.35, 0.0, 1.0), Style.COLOR_TEXT_GAIN)
		if now:  # the step you're on: the focus bar at the card's edge
			draw_rect(Rect2(x, cy - 15, 3, 19), Color(Style.COLOR_FOCUS, 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.003)))
		var ink: Color = Style.COLOR_TEXT_HUD_MUTED if s.ok else (Style.COLOR_TEXT_HUD if now else Color(Style.COLOR_TEXT_HUD, 0.7))
		draw_string(body if now else light, Vector2(x + pad + 24, cy), s.text, HORIZONTAL_ALIGNMENT_LEFT, text_w, step_px, ink)
		# the reading (what it says now), then the key, right-aligned
		var kx := x + W - pad
		if s.key != "":
			var kw := head.get_string_size(s.key.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, Style.SIZE_XS).x + 8
			var kr := Rect2(kx - kw, cy - 13, kw, 16)
			draw_rect(kr, Color(Style.COLOR_TEXT_HUD, 0.85 if now else 0.18))
			draw_string(head, kr.position + Vector2(4, 12), s.key.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, Style.SIZE_XS,
				Style.COLOR_SURFACE_HUD if now else Style.COLOR_TEXT_HUD)
			kx -= kw + 6
		if s.read != "":
			draw_string(figs, Vector2(kx - 64, cy), s.read, HORIZONTAL_ALIGNMENT_RIGHT, 64, Style.SIZE_XS,
				Style.COLOR_TEXT_HUD if now else Style.COLOR_TEXT_HUD_MUTED)
		if teach and now:
			var hh := light.get_multiline_string_size(s.how, HORIZONTAL_ALIGNMENT_LEFT, wrap_w, Style.SIZE_XS).y
			draw_multiline_string(light, Vector2(x + pad + 24, cy + 16), s.how, HORIZONTAL_ALIGNMENT_LEFT, wrap_w,
				Style.SIZE_XS, -1, Style.COLOR_TEXT_HUD_MUTED)
			cy += hh + 4
	if c.foot != "":
		cy += 22
		draw_multiline_string(light, Vector2(x + pad, cy), c.foot, HORIZONTAL_ALIGNMENT_LEFT, W - pad * 2, Style.SIZE_XS, -1,
			Style.COLOR_TEXT_HUD_MUTED)
