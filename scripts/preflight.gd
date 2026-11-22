extends Control
## The cockpit checklist card, top left, from ferry.card(): before start, the run-up, and (for your
## first two deliveries) the take-off itself. Every item shows its key from your bindings and what
## it reads now; a done item is ticked. Something gone wrong (flooded, hung, starter hot) goes on
## a red band at the top with the fix, so a failed start tells you what to do instead of only that
## it failed.
##
## Coached (your first two deliveries, with the apprentice checklist setting on): the item you're on
## says why, and the card stays up through the take-off roll. After that it's the bare checklist a
## pilot keeps on the panel, and it goes away once the engine runs.

const Tutorial := preload("res://scripts/tutorial.gd")
const W := 380.0

var main
var _was := {}  # item text -> seconds since it ticked, for the check drawing itself in
var _prev := {}


func setup(m) -> void:
	main = m
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


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
		return
	var c: Dictionary = main.ferry.card()
	var teach := coached()
	var pad := 14.0
	var x := 16.0
	var y := 16.0
	var head := Style.caps(800, Style.SIZE_XS)
	var body := Style.display(700)
	var light := Style.display(600)
	var figs := Style.figures(true)
	var text_w := W - pad * 2 - 28 - 96  # room left of the key and the reading
	var steps: Array = c.steps
	var cur := -1
	for i in steps.size():
		if not steps[i].ok:
			cur = i
			break
	# height first
	var h := pad + 14 + 30
	if c.alert != "":
		h += body.get_multiline_string_size(c.alert, HORIZONTAL_ALIGNMENT_LEFT, W - pad * 2 - 12, Style.SIZE_MD).y + 16
	for i in steps.size():
		h += 26
		if teach and i == cur:
			h += light.get_multiline_string_size(steps[i].how, HORIZONTAL_ALIGNMENT_LEFT, W - pad * 2 - 28, Style.SIZE_SM).y + 4
	if c.foot != "":
		h += 26
	h += pad - 6
	var r := Rect2(x, y, W, h)
	draw_rect(r.grow(2), Color(0, 0, 0, 0.3))
	draw_rect(r, Style.COLOR_SURFACE_PAPER)
	draw_rect(Rect2(x, y, W, 4), Style.COLOR_TEXT_PAPER_ACCENT)
	var cy := y + pad + 12
	draw_string(head, Vector2(x + pad, cy), "CHECKLIST", HORIZONTAL_ALIGNMENT_LEFT, -1, Style.SIZE_XS, Style.COLOR_TEXT_PAPER_ACCENT)
	cy += 26
	draw_string(Style.caps(900, Style.SIZE_LG), Vector2(x + pad, cy), c.title, HORIZONTAL_ALIGNMENT_LEFT, -1, Style.SIZE_LG, Style.COLOR_TEXT_PAPER)
	if c.alert != "":  # the fix for what just went wrong, first and in red
		var ah := body.get_multiline_string_size(c.alert, HORIZONTAL_ALIGNMENT_LEFT, W - pad * 2 - 12, Style.SIZE_MD).y
		var band := Rect2(x + pad - 4, cy + 8, W - pad * 2 + 8, ah + 10)
		draw_rect(band, Color(Style.COLOR_TEXT_PAPER_ACCENT, 0.12 + 0.06 * sin(Time.get_ticks_msec() * 0.006)))
		draw_rect(Rect2(band.position, Vector2(4, band.size.y)), Style.COLOR_TEXT_PAPER_ACCENT)
		draw_multiline_string(body, Vector2(band.position.x + 12, band.position.y + 20), c.alert, HORIZONTAL_ALIGNMENT_LEFT,
			W - pad * 2 - 12, Style.SIZE_MD, -1, Style.COLOR_STATUS_WARN)
		cy += ah + 16
	cy += 6
	for i in steps.size():
		var s: Dictionary = steps[i]
		cy += 26
		var box := Rect2(x + pad, cy - 15, 16, 16)
		var now := i == cur
		draw_rect(box, Color(Style.COLOR_TEXT_PAPER, 0.7 if now else 0.35), false, 1.5)
		if s.ok:
			Tutorial.draw_check(self, box, clampf(_was.get(s.text, 9.0) / 0.35, 0.0, 1.0))
		if now:
			draw_rect(Rect2(x, cy - 17, 4, 22), Color(Style.COLOR_TEXT_PAPER_ACCENT, 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.003)))
		var ink: Color = Style.COLOR_TEXT_PAPER_MUTED if s.ok else (Style.COLOR_TEXT_PAPER if now else Color(Style.COLOR_TEXT_PAPER, 0.6))
		draw_string(body if now else light, Vector2(x + pad + 28, cy), s.text, HORIZONTAL_ALIGNMENT_LEFT, text_w, Style.SIZE_MD, ink)
		# the reading (what it says now), then the key, right-aligned
		var kx := x + W - pad
		if s.key != "":
			var kw := head.get_string_size(s.key.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, Style.SIZE_XS).x + 10
			var kr := Rect2(kx - kw, cy - 15, kw, 18)
			draw_rect(kr, Color(Style.COLOR_TEXT_PAPER, 0.85 if now else 0.25))
			draw_string(head, kr.position + Vector2(5, 13), s.key.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, Style.SIZE_XS,
				Style.COLOR_SURFACE_PAPER if now else Style.COLOR_TEXT_PAPER)
			kx -= kw + 8
		if s.read != "":
			draw_string(figs, Vector2(kx - 70, cy), s.read, HORIZONTAL_ALIGNMENT_RIGHT, 70, Style.SIZE_SM,
				Style.COLOR_TEXT_PAPER if now else Style.COLOR_TEXT_PAPER_MUTED)
		if teach and now:
			var hh := light.get_multiline_string_size(s.how, HORIZONTAL_ALIGNMENT_LEFT, W - pad * 2 - 28, Style.SIZE_SM).y
			draw_multiline_string(light, Vector2(x + pad + 28, cy + 18), s.how, HORIZONTAL_ALIGNMENT_LEFT, W - pad * 2 - 28,
				Style.SIZE_SM, -1, Style.COLOR_TEXT_PAPER_MUTED)
			cy += hh + 4
	if c.foot != "":
		cy += 26
		draw_string(light, Vector2(x + pad, cy), c.foot, HORIZONTAL_ALIGNMENT_LEFT, W - pad * 2, Style.SIZE_SM, Style.COLOR_TEXT_PAPER_MUTED)
