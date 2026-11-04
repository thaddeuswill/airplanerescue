extends RefCounted
## Height-field terrain for one airfield. Dead flat around the strip and buildings, then rolling
## land that grows into hills or mountains toward the horizon. One height() drives the mesh, the
## collision and where every prop sits, so nothing floats or sinks.

const SIZE := 1000.0
const CELL := 5.0
const FLAT := Vector2(130, 32)  # half-extents (x, z) of the flat airfield pad, centered on the origin
# near/far: hill height next to the field and at the horizon. ridged: sharp crests. mesa: terraced buttes.
# top: texture for high ground, above top_h meters.
const SHAPES := {
	"plains": {"near": 7.0, "far": 40.0, "ridged": false, "mesa": false, "top": "ground_wheat", "top_h": 9.0, "pond": true},
	"forest": {"near": 9.0, "far": 80.0, "ridged": false, "mesa": false, "top": "ground_grass", "top_h": 30.0, "pond": true},
	"desert": {"near": 10.0, "far": 75.0, "ridged": false, "mesa": true, "top": "ground_sand", "top_h": 1000.0, "pond": false},
	"snow": {"near": 8.0, "far": 150.0, "ridged": true, "mesa": false, "top": "ground_snow", "top_h": 18.0, "pond": false},
}
const WATER_Y := -0.6

var shape: Dictionary
var noise := FastNoiseLite.new()
var detail := FastNoiseLite.new()
var groves := FastNoiseLite.new()
var pond := Vector3.INF  # x, z, radius of a small pond, or INF for none


func _init(region: String, seed_value: int) -> void:
	shape = SHAPES[region]
	noise.seed = seed_value
	noise.frequency = 0.0045
	noise.fractal_octaves = 5
	detail.seed = seed_value + 1
	detail.frequency = 0.04
	groves.seed = seed_value + 2
	groves.frequency = 0.012
	if shape.pond:
		var r := RandomNumberGenerator.new()
		r.seed = seed_value
		pond = Vector3(r.randf_range(-70, 50), r.randf_range(85, 110) * (1.0 if r.randf() < 0.5 else -1.0), r.randf_range(18, 26))


## 0 on the airfield pad, easing to 1 about 50 m out.
func _away(x: float, z: float) -> float:
	var d := Vector2(maxf(absf(x) - FLAT.x, 0.0), maxf(absf(z) - FLAT.y, 0.0)).length()
	return smoothstep(0.0, 50.0, d)


func height(x: float, z: float) -> float:
	var m := _away(x, z)
	var h := 0.0
	if m > 0.0:
		var amp := lerpf(shape.near, shape.far, smoothstep(140.0, 480.0, Vector2(x, z).length()))
		var n := noise.get_noise_2d(x, z)
		var t: float
		if shape.ridged:
			t = pow(1.0 - absf(n), 2.0)
		else:
			t = n * 0.5 + 0.5
		if shape.mesa:  # flat-topped steps with steep risers
			var s := t * 4.0
			t = (floorf(s) + smoothstep(0.75, 1.0, s - floorf(s))) / 4.0
		h = (t * amp + detail.get_noise_2d(x, z) * 1.2) * m
	if pond != Vector3.INF:
		var d := Vector2(x - pond.x, z - pond.y).length()
		h = lerpf(h, -2.5, 1.0 - smoothstep(pond.z * 0.55, pond.z, d))
	return h


## 0..1 tree density: groves and open clearings rather than an even sprinkle.
func grove(x: float, z: float) -> float:
	return smoothstep(-0.1, 0.45, groves.get_noise_2d(x, z))


## How steep the ground is: 0 flat, 1 vertical.
func slope(x: float, z: float) -> float:
	var n := Vector3(height(x - 1, z) - height(x + 1, z), 2.0, height(x, z - 1) - height(x, z + 1)).normalized()
	return 1.0 - n.y


func in_water(x: float, z: float) -> bool:
	return pond != Vector3.INF and height(x, z) < WATER_Y + 0.25


## The ground mesh (with trimesh collision) and, if there is one, the pond surface.
func build(parent: Node3D, ground_tex: String) -> void:
	var n := int(SIZE / CELL)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in n + 1:
		for i in n + 1:
			var x := -SIZE / 2 + i * CELL
			var z := -SIZE / 2 + j * CELL
			st.add_vertex(Vector3(x, height(x, z), z))
	for j in n:
		for i in n:
			var a := j * (n + 1) + i
			for k in [a, a + 1, a + n + 1, a + 1, a + n + 2, a + n + 1]:
				st.add_index(k)
	st.generate_normals()
	var mesh := st.commit()
	mesh.surface_set_material(0, _material(ground_tex))
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	parent.add_child(mi)
	mi.create_trimesh_collision()
	if pond != Vector3.INF:
		var w := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = pond.z
		disc.bottom_radius = pond.z
		disc.height = 0.02
		disc.radial_segments = 32
		var wm := StandardMaterial3D.new()
		wm.albedo_texture = load("res://textures/water.png")
		wm.albedo_color = Color(0.32, 0.45, 0.42, 0.92)  # dark pond green-blue, sky glints from the specular
		wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		wm.roughness = 0.08
		wm.metallic_specular = 0.6
		wm.uv1_triplanar = true
		wm.uv1_scale = Vector3.ONE * 0.08
		disc.material = wm
		w.mesh = disc
		w.position = Vector3(pond.x, WATER_Y, pond.y)
		parent.add_child(w)


func _material(ground_tex: String) -> ShaderMaterial:
	var sm := ShaderMaterial.new()
	sm.shader = SHADER
	sm.set_shader_parameter("ground", load("res://textures/%s.png" % ground_tex))
	sm.set_shader_parameter("rock", load("res://textures/rock.png"))
	sm.set_shader_parameter("top", load("res://textures/%s.png" % shape.top))
	sm.set_shader_parameter("top_height", shape.top_h)
	var vary := NoiseTexture2D.new()
	vary.seamless = true
	vary.noise = FastNoiseLite.new()
	vary.noise.frequency = 0.02
	sm.set_shader_parameter("vary", vary)
	return sm


# Ground blends by world height and slope: grass/dirt on the flats, rock on steep faces, the
# region's high-ground texture (wheat, snow...) on top. Two texture scales plus a big noise tint
# break up the tiling, which is what made the old flat ground look like wallpaper.
static var SHADER := _make_shader()


static func _make_shader() -> Shader:
	var s := Shader.new()
	s.code = """
shader_type spatial;
uniform sampler2D ground : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D top : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D vary : repeat_enable;
uniform float top_height = 1000.0;
varying vec3 wp;
varying vec3 wn;
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
vec3 tri(sampler2D t, float s) {
	vec3 b = pow(abs(wn), vec3(4.0));
	b /= b.x + b.y + b.z;
	return texture(t, wp.zy * s).rgb * b.x + texture(t, wp.xz * s).rgb * b.y + texture(t, wp.xy * s).rgb * b.z;
}
void fragment() {
	float v = texture(vary, wp.xz * 0.003).r;
	vec3 g = mix(texture(ground, wp.xz * 0.2).rgb, texture(ground, wp.xz * 0.031).rgb, 0.45);
	g *= mix(vec3(0.82, 0.86, 0.78), vec3(1.08, 1.04, 0.95), v);
	float slope = 1.0 - wn.y;
	vec3 c = mix(g, tri(rock, 0.06), smoothstep(0.22, 0.42, slope + (v - 0.5) * 0.12));
	float hi = smoothstep(top_height - 5.0, top_height + 5.0, wp.y + v * 12.0) * (1.0 - smoothstep(0.4, 0.65, slope));
	c = mix(c, mix(texture(top, wp.xz * 0.17).rgb, texture(top, wp.xz * 0.029).rgb, 0.4), hi);
	ALBEDO = c;
	ROUGHNESS = 0.95;
}
"""
	return s
