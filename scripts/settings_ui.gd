extends Control
## The settings sheet: five tabs on one paper form (graphics and video, audio, controls,
## gameplay and interface, accessibility). Every change applies at once and is saved to
## user://settings.cfg by main.set_setting(). Opened from the title screen and the pause menu.

const SHEET := Vector2(1060, 660)
const TABS := [["video", "Graphics & video"], ["audio", "Audio"], ["controls", "Controls"],
	["game", "Gameplay & interface"], ["access", "Accessibility"]]
## Keys you can rebind, grouped by where they're used. A key may repeat across groups (W walks
## on foot and opens the throttle in the cockpit); inside a group it's flagged.
const BINDS := [
	["On foot", [["move_forward", "Walk forward"], ["move_back", "Walk back"], ["move_left", "Step left"],
		["move_right", "Step right"], ["jump", "Jump"], ["interact", "Use / inspect"]]],
	["Pockets", [["wallet", "Wallet"], ["clipboard", "Clipboard"], ["logbook", "Logbook"], ["manual", "Service manual"]]],
	["Cockpit", [["throttle_up", "Throttle up"], ["throttle_down", "Throttle down"], ["rudder_left", "Left rudder"],
		["rudder_right", "Right rudder"], ["stick_forward", "Stick forward"], ["stick_back", "Stick back"],
		["starter", "Starter (hold)"], ["fuel_valve", "Fuel valve"], ["master", "Master switch"], ["primer", "Primer"],
		["mags", "Magneto switch"], ["carb_heat", "Carb heat"]]],
]

var main
var back: Callable
var tab := "video"
var rows: VBoxContainer
var _tabs: HBoxContainer
var _waiting := ""  # the action waiting for a key press ("" = not rebinding)
var _wait_button: Button


func setup(m, back_to: Callable, start := "video") -> void:
	main = m
	back = back_to
	tab = start
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()  # the hangar stays visible behind the form, dimmed
	dim.color = Color(Style.COLOR_SURFACE_HUD, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var sheet := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Style.COLOR_SURFACE_PAPER
	sb.set_corner_radius_all(Style.RADIUS_MD)
	sb.set_content_margin_all(Style.SPACE_6)
	sheet.add_theme_stylebox_override("panel", sb)
	sheet.custom_minimum_size = SHEET
	sheet.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	sheet.position -= SHEET / 2
	add_child(sheet)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", Style.SPACE_3)
	sheet.add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	var title := Style.label("SETTINGS", "body", Style.SIZE_2XL, 900)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(Style.label("Changes apply at once and are saved.", "muted", Style.SIZE_SM))
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", Style.SPACE_2)
	col.add_child(_tabs)
	var rule := ColorRect.new()
	rule.color = Style.COLOR_TEXT_PAPER_ACCENT
	rule.custom_minimum_size.y = 2
	col.add_child(rule)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", Style.SPACE_2)
	scroll.add_child(rows)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", Style.SPACE_3)
	col.add_child(foot)
	var reset := Button.new()
	reset.text = "Restore this tab's defaults"
	Style.button(reset, "quiet")
	reset.custom_minimum_size.y = 44
	reset.pressed.connect(func():
		main.reset_settings(tab)
		_build())
	foot.add_child(reset)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(spacer)
	var close := Button.new()
	close.text = "BACK (ESC)"
	Style.button(close, "exit")
	close.custom_minimum_size = Vector2(150, 44)
	close.pressed.connect(func(): back.call())
	foot.add_child(close)
	_build()


func _build() -> void:
	for c in _tabs.get_children():
		c.queue_free()
	for t in TABS:
		var b := Button.new()
		b.text = t[1].to_upper()
		Style.button(b, "primary" if t[0] == tab else "quiet")
		b.custom_minimum_size.y = 44
		b.pressed.connect(func():
			tab = t[0]
			_build())
		_tabs.add_child(b)
	for c in rows.get_children():
		c.queue_free()
	_waiting = ""
	call("_tab_" + tab)


# ---------- the tabs ----------

func _tab_video() -> void:
	var s: Dictionary = main.settings
	_section("Display")
	_choice("Display mode", "display_mode", [["windowed", "Window"], ["borderless", "Full screen (borderless)"], ["exclusive", "Full screen (exclusive)"]])
	_choice("Window size", "resolution", main.resolution_choices(), s.display_mode != "windowed",
		"Full screen always uses your screen's own resolution.")
	_choice("VSync", "vsync", [["on", "On (no tearing)"], ["adaptive", "Adaptive"], ["off", "Off"]])
	_choice("Frame rate cap", "max_fps", [[0, "No cap"], [30, "30"], [60, "60"], [120, "120"], [144, "144"], [240, "240"]])
	_section("Quality")
	_choice("Preset", "quality", [["low", "Low"], ["medium", "Medium"], ["high", "High"], ["ultra", "Ultra"], ["custom", "Custom"]],
		false, "Sets everything below. Changing one of them makes it Custom.")
	var fsr_ok: bool = main.renderer_has_fsr()
	_slider("3D render scale", "render_scale", 0.5, 1.0, 0.05, "%d%%", 100.0)
	_choice("Upscaling", "upscaler", [["bilinear", "Bilinear"], ["fsr", "AMD FSR 1.0"], ["fsr2", "AMD FSR 2.2 (also smooths edges)"]],
		not fsr_ok, "FSR needs the Vulkan or Metal renderer." if not fsr_ok else "Used when the render scale is under 100%.")
	_choice("Anti-aliasing", "aa", [["off", "Off"], ["fxaa", "FXAA (fast)"], ["smaa", "SMAA"], ["msaa2", "MSAA 2x"], ["msaa4", "MSAA 4x"], ["taa", "TAA"]],
		s.upscaler == "fsr2" and s.render_scale < 1.0, "FSR 2.2 is doing the smoothing." if s.upscaler == "fsr2" and s.render_scale < 1.0 else "")
	_choice("Shadows", "shadows", [["low", "Low"], ["medium", "Medium"], ["high", "High"], ["ultra", "Ultra"]])
	_choice("View distance", "draw", [["low", "Short"], ["medium", "Medium"], ["high", "Far"]])
	_choice("Model detail", "detail", [["low", "Low"], ["medium", "Medium"], ["high", "High"]])
	_choice("Texture filtering", "aniso", [[0, "Off"], [2, "2x"], [4, "4x"], [8, "8x"], [16, "16x"]])
	_section("Effects")
	_toggle("Bloom on bright sky and paint", "bloom")
	_toggle("Haze in the air", "haze")
	_toggle("Bounce light (colored light off the truck and hangar)", "bounce")
	_toggle("Ambient occlusion (soft contact shadows)", "ao")
	_toggle("Dust in the sunbeams", "dust")
	_note("The game has no motion blur, depth of field, chromatic aberration or ray tracing to turn off.")


func _tab_audio() -> void:
	_slider("Master volume", "master", 0.0, 1.0, 0.01, "%d%%", 100.0)
	_slider("Music (the shop radio)", "music", 0.0, 1.0, 0.01, "%d%%", 100.0)
	_slider("Sound effects (tools, engine)", "sfx", 0.0, 1.0, 0.01, "%d%%", 100.0)
	_slider("Ambience (hangar room tone)", "ambience", 0.0, 1.0, 0.01, "%d%%", 100.0)
	_section("Output")
	_toggle("Night mode: evens out loud and quiet sounds", "night")
	_toggle("Mono audio (one ear or one speaker)", "mono")
	_note("There's no spoken dialogue, so there's no voice slider. Speaker setup follows your system.")


func _tab_controls() -> void:
	_slider("Mouse sensitivity", "sens", 0.3, 2.5, 0.05, "%.2fx", 1.0)
	_toggle("Invert look up and down", "invert")
	_toggle("Quick hold (tap instead of press-and-hold in repairs)", "quick_hold")
	_note("Click a key, then press the new one. Esc cancels. Mouse look uses raw input, with no acceleration.")
	for g in BINDS:
		_section(g[0])
		for a in g[1]:
			_bind(a[0], a[1], g[1])
	var reset := Button.new()
	reset.text = "Reset all keys"
	Style.button(reset, "quiet")
	reset.custom_minimum_size.y = 44
	reset.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	reset.pressed.connect(func():
		main.set_setting({}, "keys")
		_build())
	rows.add_child(reset)


func _tab_game() -> void:
	_choice("Difficulty", "difficulty", main.DIFFICULTIES.keys().map(func(d): return [d, d.capitalize()]), main.current_career_locked(),
		main.DIFFICULTIES[main.difficulty])
	_slider("Field of view", "fov", 60.0, 100.0, 1.0, "%d deg", 1.0)
	_toggle("Crosshair", "crosshair")
	_toggle("Frame rate counter", "fps_counter")
	_toggle("Screen shake (off also calms other motion)", "shake")


func _tab_access() -> void:
	_choice("Message text size", "text_size", [["small", "Small"], ["medium", "Medium"], ["large", "Large"], ["xl", "Extra large"]])
	_slider("Message background", "text_bg", 0.4, 1.0, 0.05, "%d%%", 100.0)
	_choice("Color vision", "colorblind", [["off", "Standard"], ["protan", "Protanopia (red-weak)"],
		["deutan", "Deuteranopia (green-weak)"], ["tritan", "Tritanopia (blue-weak)"]], false,
		"Shifts colors so reds, greens and blues stay apart. Status is always in words too.")
	_note("Messages are the game's captions: everything you see and hear at the plane is written out.")


# ---------- rows ----------

func _row(text: String, note := "") -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", Style.SPACE_4)
	var lab := VBoxContainer.new()
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lab.add_theme_constant_override("separation", 0)
	lab.add_child(Style.label(text, "body", Style.SIZE_MD, 700))
	if note != "":
		var n := Style.label(note, "muted", Style.SIZE_SM)
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lab.add_child(n)
	hb.add_child(lab)
	rows.add_child(hb)
	return hb


func _section(text: String) -> void:
	var l := Style.label(text.to_upper(), "accent", Style.SIZE_LG, 900)
	rows.add_child(l)


func _note(text: String) -> void:
	var l := Style.label(text, "muted", Style.SIZE_SM)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(l)


func _choice(text: String, key: String, options: Array, locked := false, note := "") -> void:
	var hb := _row(text, note)
	var ob := OptionButton.new()
	ob.custom_minimum_size = Vector2(300, 40)
	Style.button(ob, "quiet")
	ob.add_theme_font_size_override("font_size", Style.SIZE_MD)
	var cur = main.get_setting(key)
	for i in options.size():
		ob.add_item(options[i][1], i)
		if options[i][0] == cur:
			ob.select(i)
	ob.disabled = locked
	ob.item_selected.connect(func(i):
		main.set_setting(options[i][0], key)
		_build.call_deferred())  # other rows can depend on it (presets, upscaling)
	hb.add_child(ob)


func _toggle(text: String, key: String) -> void:
	var hb := _row(text)
	var b := Button.new()
	b.toggle_mode = true
	b.button_pressed = main.get_setting(key)
	b.text = "ON" if b.button_pressed else "OFF"
	b.custom_minimum_size = Vector2(110, 40)
	Style.button(b, "primary" if b.button_pressed else "quiet")
	b.toggled.connect(func(on):
		main.set_setting(on, key)
		_build.call_deferred())
	hb.add_child(b)


func _slider(text: String, key: String, lo: float, hi: float, step: float, fmt: String, mult: float) -> void:
	var hb := _row(text)
	var sl := HSlider.new()
	sl.custom_minimum_size = Vector2(240, 40)
	sl.min_value = lo
	sl.max_value = hi
	sl.step = step
	sl.value = main.get_setting(key)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(Style.COLOR_TEXT_PAPER, 0.25)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	sl.add_theme_stylebox_override("slider", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Style.COLOR_ACTION_PRIMARY
	fill.content_margin_top = 3
	fill.content_margin_bottom = 3
	sl.add_theme_stylebox_override("grabber_area", fill)
	sl.add_theme_stylebox_override("grabber_area_highlight", fill)
	hb.add_child(sl)
	var val := Style.label(fmt % (sl.value * mult), "body", Style.SIZE_MD, 700)
	val.custom_minimum_size.x = 72
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hb.add_child(val)
	sl.value_changed.connect(func(v):
		val.text = fmt % (v * mult)
		main.set_setting(v, key, false))  # no rebuild mid-drag
	sl.drag_ended.connect(func(_c):
		main.slider_released(key)
		if key == "render_scale":
			_build.call_deferred())


func _bind(action: String, text: String, group: Array) -> void:
	var clash: Array = group.filter(func(a): return a[0] != action and main.key_name(a[0]) == main.key_name(action))
	var hb := _row(text, ("Same key as %s" % clash[0][1].to_lower()) if clash.size() > 0 else "")
	var b := Button.new()
	b.text = main.key_name(action)
	b.custom_minimum_size = Vector2(160, 40)
	Style.button(b, "quiet")
	b.pressed.connect(func():
		_waiting = action
		_wait_button = b
		b.text = "Press a key..."
		Style.button(b, "primary"))
	hb.add_child(b)


func _input(ev: InputEvent) -> void:
	if _waiting == "" or not ev is InputEventKey or not ev.pressed or ev.echo:
		return
	get_viewport().set_input_as_handled()
	if ev.physical_keycode != KEY_ESCAPE:
		main.rebind(_waiting, ev.physical_keycode)
	_waiting = ""
	_build.call_deferred()
