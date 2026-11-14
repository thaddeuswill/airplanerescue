extends RefCounted
## The radio's navigation chart: a sectional-style overlay on textures/us_map.png
## (graticule, airport symbols, compass rose on your field, magenta course lines with true
## course and nautical miles). `game` is main.gd (for CITIES, location, miles()).

var game


func _init(g) -> void:
	game = g


const MAGENTA := Color(0.62, 0.12, 0.45)
const BLUE := Color(0.16, 0.3, 0.55)
const K := 576.0 / 2048.0
# Quadratic fit lon/lat -> us_map.png pixels (same fit the CITIES pixels came from), for gridlines.
const MAP_X := [5046.137508, 44.595404, -25.016715, 0.038367, 0.056775, -0.215379]
const MAP_Y := [917.976027, -28.316197, -46.63631, -0.143734, 0.114237, 0.012057]


func px(city: String) -> Vector2:
	var c: Array = game.CITIES[city]
	return Vector2(c[3], c[4]) * K


func lonlat_px(lon: float, lat: float) -> Vector2:
	var v := [1.0, lon, lat, lon * lon, lat * lat, lon * lat]
	var p := Vector2.ZERO
	for i in 6:
		p += Vector2(MAP_X[i], MAP_Y[i]) * v[i]
	return p * K


## Initial great-circle true course from a to b, degrees 0..360.
func course(a: String, b: String) -> float:
	var r := PI / 180.0
	var p: Array = game.CITIES[a]
	var q: Array = game.CITIES[b]
	var dl: float = (q[0] - p[0]) * r
	var y := sin(dl) * cos(q[1] * r)
	var x: float = cos(p[1] * r) * sin(q[1] * r) - sin(p[1] * r) * cos(q[1] * r) * cos(dl)
	return fposmod(rad_to_deg(atan2(y, x)), 360.0)


func draw(map: Control, calls: Array) -> void:
	var font := Style.display(700)
	var grid := Color(BLUE, 0.35)
	# The base map's own decorative compass (bottom right, 1715..1965 x 905..1185 px) would fight the
	# real compass rose: paper over it with a chart legend box.
	var legend := Rect2(Vector2(1712, 900) * K, Vector2(256, 288) * K)
	map.draw_rect(legend, Color(0.83, 0.86, 0.8))
	map.draw_rect(legend, BLUE, false, 1.0)
	var ly := legend.position.y + 14
	for line in [["LEGEND", BLUE], ["- - course", MAGENTA], ["o  airport", MAGENTA], ["NM / true", BLUE]]:
		map.draw_string(font, Vector2(legend.position.x + 6, ly), line[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, line[1])
		ly += 16
	for lon in range(-125, -64, 5):  # meridians
		var pts := PackedVector2Array()
		for lat in range(24, 51):
			pts.append(lonlat_px(lon, lat))
		map.draw_polyline(pts, grid, 1.0)
		map.draw_string(font, lonlat_px(lon, 24.5) + Vector2(2, -2), "%d°W" % -lon, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, grid)
	for lat in range(25, 51, 5):  # parallels
		var pts := PackedVector2Array()
		for lon in range(-126, -65):
			pts.append(lonlat_px(lon, lat))
		map.draw_polyline(pts, grid, 1.0)
		map.draw_string(font, lonlat_px(-125.5, lat) + Vector2(2, -2), "%d°N" % lat, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, grid)
	# every known field as a small non-towered airport symbol
	for city in game.CITIES:
		var p := px(city)
		map.draw_arc(p, 3.5, 0, TAU, 12, Color(MAGENTA, 0.55), 1.2)
	var home := px(game.location)
	# compass rose around your field, 10° ticks, longer every 30°, N up (true)
	var rose := 34.0
	map.draw_arc(home, rose, 0, TAU, 48, BLUE, 1.2)
	for d in range(0, 360, 10):
		var a := deg_to_rad(d - 90.0)
		var tick := 7.0 if d % 30 == 0 else 3.5
		map.draw_line(home + Vector2(cos(a), sin(a)) * (rose - tick), home + Vector2(cos(a), sin(a)) * rose, BLUE, 1.0)
	map.draw_string(font, home + Vector2(-4, -rose - 3), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, BLUE)
	# course lines with true course / distance boxed at the midpoint
	for job in calls:
		var to := px(job.city)
		map.draw_dashed_line(home, to, MAGENTA, 2.0, 8.0)
		var tag := "%03d°  %d NM" % [roundi(course(game.location, job.city)), roundi(game.miles(game.location, job.city) * 0.869)]
		var mid := home.lerp(to, clampf((rose + 45.0) / maxf(home.distance_to(to), 1.0), 0.5, 0.8))  # clear of the rose
		var sz := font.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
		map.draw_rect(Rect2(mid - Vector2(sz.x / 2 + 3, 10), sz + Vector2(6, 4)), Color(1, 1, 0.94, 0.9))
		map.draw_rect(Rect2(mid - Vector2(sz.x / 2 + 3, 10), sz + Vector2(6, 4)), MAGENTA, false, 1.0)
		map.draw_string(font, mid - Vector2(sz.x / 2, -1), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, MAGENTA)
		_airport(map, to, MAGENTA)
	_airport(map, home, Color(0.1, 0.45, 0.2))
	var hw := font.get_string_size(game.location.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	map.draw_string(font, home + Vector2(-hw / 2, rose + 13), game.location.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.1, 0.45, 0.2))


## The trip under way: flown leg solid, the rest dashed, the plane at fraction t of the way.
## The map keeps its aspect, so chart pixels are scaled and centered to whatever size it has now.
func draw_trip(map: Control, from: String, to: String, t: float) -> void:
	var s := minf(map.size.x / 576.0, map.size.y / 360.0)
	var off := (map.size - Vector2(576, 360) * s) / 2.0
	var a := off + px(from) * s
	var b := off + px(to) * s
	var at := a.lerp(b, t)
	map.draw_line(a, at, MAGENTA, 4.0)
	map.draw_dashed_line(at, b, MAGENTA, 3.0, 10.0)
	_airport(map, a, Color(0.1, 0.45, 0.2))
	_airport(map, b, MAGENTA)
	for field in [[from, a], [to, b]]:
		var spot: Vector2 = field[1] + Vector2(12, -10)
		map.draw_string_outline(game.UI_FONT, spot, field[0].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, 5, Color(1, 1, 0.94))
		map.draw_string(game.UI_FONT, spot, field[0].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, BLUE)
	map.draw_set_transform(at, a.angle_to_point(b) + PI / 2.0, Vector2.ONE * 1.1)
	var ink := Color(0.11, 0.09, 0.06)
	map.draw_colored_polygon(PackedVector2Array([Vector2(0, -13), Vector2(2.5, -8), Vector2(1.5, 11), Vector2(-1.5, 11), Vector2(-2.5, -8)]), ink)
	map.draw_rect(Rect2(-14, -6, 28, 5), ink)
	map.draw_rect(Rect2(-6, 8, 12, 3), ink)
	map.draw_set_transform(Vector2.ZERO)


## Sectional airport symbol: ring with four ticks and a runway bar.
func _airport(map: Control, p: Vector2, c: Color) -> void:
	map.draw_circle(p, 5.5, Color(1, 1, 0.94))
	map.draw_arc(p, 5.5, 0, TAU, 16, c, 2.0)
	for a in [0.0, PI / 2, PI, PI * 1.5]:
		map.draw_line(p + Vector2(cos(a), sin(a)) * 5.5, p + Vector2(cos(a), sin(a)) * 8.5, c, 2.0)
	map.draw_line(p + Vector2(-3, 2), p + Vector2(3, -2), c, 2.0)
