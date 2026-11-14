class_name Style
extends RefCounted
## Airplane Rescue design tokens. One place for every color, size and font.
## Three tiers (after Owl-Listener/designer-skills, MIT):
##   1. GLOBAL  - raw values. Never used directly by a screen.
##   2. ALIAS   - what a value MEANS (text on paper, danger, action).
##   3. COMPONENT - one widget's choices, built from aliases.
## Screens read ALIAS or COMPONENT names only. To re-theme, change the alias map.
## Names follow {category}_{property}_{variant}_{state}.

# ---------- 1. GLOBAL (raw palette) ----------
const RED_600 := Color("A8261F")     # catalog cover red
const RED_800 := Color("7E1C16")
const RED_900 := Color("8B2020")     # main.gd C_RED; kept for the HUD until merged
const CREAM_100 := Color("F5F0E6")   # main.gd C_PAPER
const CREAM_200 := Color("EEE6CF")   # catalog paper
const INK_900 := Color("1E1B17")
const EARTH_950 := Color("1C1810")   # main.gd C_EARTH (HUD bars)
const MUSTARD_500 := Color("D9A62E")
const BRASS_300 := Color("C8B99A")   # main.gd C_BRASS
const GREEN_700 := Color("2E5339")
const GREEN_800 := Color("285A32")   # main.gd C_OK
const UMBER_600 := Color("6B5E4B")   # "faded"
const AMBER_700 := Color("8B6914")
const ORANGE_300 := Color(0.95, 0.65, 0.4)  # blocked-step text on the dark HUD

# Type scale, 1.25 ratio from a 16 px base (rounded to whole px).
const SIZE_XS := 13
const SIZE_SM := 15
const SIZE_MD := 18
const SIZE_LG := 22
const SIZE_XL := 28
const SIZE_2XL := 36
const SIZE_3XL := 44

# Spacing scale (4 px grid).
const SPACE_1 := 4
const SPACE_2 := 8
const SPACE_3 := 12
const SPACE_4 := 16
const SPACE_6 := 24
const SPACE_8 := 32

const RADIUS_SM := 2
const RADIUS_MD := 6

const MOTION_FAST := 0.12   # hover, press
const MOTION_BASE := 0.25   # page turn, toast in
const MOTION_SLOW := 0.45   # stamp thump, part flying to tray
const TOAST_SECONDS := 4.0  # 3-5 s; errors stay until fixed

# ---------- 2. ALIAS (meaning) ----------
# Paper screens: catalog, manual, logbook. Contrast checked against CREAM_200.
const COLOR_SURFACE_PAPER := CREAM_200
const COLOR_TEXT_PAPER := INK_900               # 13.8:1
const COLOR_TEXT_PAPER_MUTED := UMBER_600       # 5.1:1, ok for body
const COLOR_TEXT_PAPER_ACCENT := RED_600        # 5.7:1, part numbers, section heads
const COLOR_STATUS_OK := GREEN_700              # 7.0:1, "in stock", "fitted"
const COLOR_STATUS_WARN := RED_800              # 8.2:1, "mail order", "short $"
const COLOR_ACTION_PRIMARY := RED_600           # BUY, the one filled button per row
const COLOR_ACTION_PRIMARY_TEXT := CREAM_200    # 5.7:1
const COLOR_ACTION_QUIET := Color(INK_900, 0.12) # PREV / NEXT / CONTENTS
const COLOR_ACTION_EXIT := INK_900              # CLOSE (ESC)
const COLOR_PRICE := MUSTARD_500                # price tags; ink on mustard 7.7:1. Never red text on it (3.2:1).
# Dark HUD: work scenes, flight, title.
const COLOR_SURFACE_HUD := EARTH_950
const COLOR_TEXT_HUD := CREAM_100               # 15.6:1
const COLOR_TEXT_HUD_MUTED := BRASS_300         # 9.2:1
const COLOR_TEXT_HUD_BLOCKED := ORANGE_300      # 8.8:1, always paired with a reason in words
const COLOR_FOCUS := MUSTARD_500                # hover ring, hold-progress arc

# ---------- 3. COMPONENT ----------
const BUTTON_PRIMARY_SIZE := Vector2(118, 46)   # over the 44 px target minimum
const BUTTON_PRIMARY_FONT_SIZE := SIZE_LG
const BUTTON_QUIET_FONT_SIZE := SIZE_MD
const BUTTON_DISABLED_ALPHA := 0.35             # disabled must also show a reason label
const TOOLTIP_TITLE_SIZE := SIZE_SM
const TOOLTIP_BODY_SIZE := SIZE_XS + 1          # 14; 13 was too small at 1080p
const TOOLTIP_BAR_WIDTH := 3
const HUD_HINT_SIZE := SIZE_XS
const BOOK_BODY_SIZE := SIZE_MD  # Big Shoulders labels in the books
const BOOK_HEAD_SIZE := SIZE_2XL
const BOOK_MEASURE_CHARS := 75                  # wrap body before this many characters

# ---------- fonts ----------
const FONT_DISPLAY_PATH := "res://fonts/BigShouldersDisplay.ttf"
const FONT_SCRIPT_PATH := "res://fonts/Yellowtail-Regular.ttf"  # logo and signatures only
const FONT_TEXT_PATH := "res://fonts/DejaVuSerifCondensed.ttf"  # long reading: manual summaries and steps
## Figures and typed records: money, gauges, counters, logbook lines. Courier Prime (OFL): a 1940s
## typewriter face whose digits are all one width, so changing numbers don't jitter. Big Shoulders
## has proportional digits and no tabular-figures feature.
const FONT_FIGURES_PATH := "res://fonts/CourierPrime-Regular.ttf"
const FONT_FIGURES_BOLD_PATH := "res://fonts/CourierPrime-Bold.ttf"
const CAPS_TRACKING := 0.06  # all-caps labels are tracked out: +0.06 em (typography: +0.04 to +0.12)
const TEXT_SIZE := 16  # the serif reads larger than Big Shoulders at the same px

static var _cache := {}


## Big Shoulders at a weight: 900 titles, 800 labels, 600 body.
static func display(weight := 800) -> Font:
	var key := "display_%d" % weight
	if _cache.has(key):
		return _cache[key]
	var base: Font
	if ResourceLoader.exists(FONT_DISPLAY_PATH):
		base = load(FONT_DISPLAY_PATH)
	else:
		var sf := SystemFont.new()
		sf.font_names = PackedStringArray(["Bahnschrift", "Arial Narrow", "sans-serif"])
		base = sf
	var f := FontVariation.new()
	f.base_font = base
	f.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	_cache[key] = f
	return f


## Big Shoulders tracked for ALL-CAPS labels (menu items, section heads, buttons). Capitals set
## tight read as a block; a little air between them reads as a label. `size_px` sets the spacing.
static func caps(weight := 800, size_px := SIZE_MD) -> Font:
	var key := "caps_%d_%d" % [weight, size_px]
	if not _cache.has(key):
		# Built straight on the font file: a FontVariation wrapped around another FontVariation
		# loses the inner weight and falls back to the file's default instance, Thin.
		var f: FontVariation = display(weight).duplicate()
		f.spacing_glyph = maxi(1, roundi(size_px * CAPS_TRACKING))
		_cache[key] = f
	return _cache[key]


## The figures face: anything that counts, ticks or changes while you watch.
static func figures(bold := false) -> Font:
	var key := "figures_%s" % bold
	if not _cache.has(key):
		var p := FONT_FIGURES_BOLD_PATH if bold else FONT_FIGURES_PATH
		_cache[key] = load(p) if ResourceLoader.exists(p) else display(700)
	return _cache[key]


## The reading face for paragraphs and procedure steps; falls back to Big Shoulders 600.
static func text_font() -> Font:
	if not _cache.has("text"):
		_cache["text"] = load(FONT_TEXT_PATH) if ResourceLoader.exists(FONT_TEXT_PATH) else display(600)
	return _cache["text"]


static func script_font() -> Font:
	return load(FONT_SCRIPT_PATH) if ResourceLoader.exists(FONT_SCRIPT_PATH) else display(900)


## A label on paper or HUD. role: "body", "muted", "accent", "ok", "warn", "hud", "hud_muted".
static func label(text: String, role := "body", size_px := BOOK_BODY_SIZE, weight := 600) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", display(weight))
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", role_color(role))
	return l


static func role_color(role: String) -> Color:
	match role:
		"muted": return COLOR_TEXT_PAPER_MUTED
		"accent": return COLOR_TEXT_PAPER_ACCENT
		"ok": return COLOR_STATUS_OK
		"warn": return COLOR_STATUS_WARN
		"hud": return COLOR_TEXT_HUD
		"hud_muted": return COLOR_TEXT_HUD_MUTED
		"blocked": return COLOR_TEXT_HUD_BLOCKED
	return COLOR_TEXT_PAPER


## kind: "primary" (filled red), "quiet" (ink tint), "exit" (solid ink).
static func button(b: Button, kind := "primary") -> void:
	var bg: Color = {"primary": COLOR_ACTION_PRIMARY, "quiet": COLOR_ACTION_QUIET, "exit": COLOR_ACTION_EXIT}.get(kind, COLOR_ACTION_QUIET)
	var fg: Color = COLOR_TEXT_PAPER if kind == "quiet" else COLOR_ACTION_PRIMARY_TEXT
	b.add_theme_font_override("font", display(800))
	b.add_theme_font_size_override("font_size", BUTTON_PRIMARY_FONT_SIZE if kind == "primary" else BUTTON_QUIET_FONT_SIZE)
	var states := {"normal": bg, "hover": bg.lightened(0.15) if bg.a > 0.5 else Color(INK_900, 0.25),
		"pressed": bg.darkened(0.2), "disabled": Color(bg, bg.a * BUTTON_DISABLED_ALPHA)}
	for s in states:
		var sb := StyleBoxFlat.new()
		sb.bg_color = states[s]
		sb.set_corner_radius_all(RADIUS_SM)
		sb.content_margin_left = SPACE_3
		sb.content_margin_right = SPACE_3
		b.add_theme_stylebox_override(s, sb)
	var focus := StyleBoxFlat.new()  # keyboard focus is visible, not just hover
	focus.draw_center = false
	focus.set_border_width_all(2)
	focus.border_color = COLOR_FOCUS
	focus.set_corner_radius_all(RADIUS_SM)
	b.add_theme_stylebox_override("focus", focus)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, fg)
	b.add_theme_color_override("font_disabled_color", Color(fg if bg.a > 0.5 else INK_900, 0.45))
