// Frosted glass for the end-of-mission card (D3): the scene behind, blurred, under the panel's own
// tint. Set as the PanelContainer's material, so it shades only the panel's stylebox; the text and
// figures on it draw normally. A fixed ring of taps rather than mipmaps, which the Compatibility
// renderer doesn't build for the screen texture.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float radius_px = 9.0;

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE * radius_px;
	vec3 sum = texture(screen_tex, SCREEN_UV).rgb;
	float n = 1.0;
	for (int ring = 1; ring <= 2; ring++) {
		for (int k = 0; k < 8; k++) {
			float a = float(k) * 0.785398 + float(ring) * 0.39;
			sum += texture(screen_tex, SCREEN_UV + vec2(cos(a), sin(a)) * px * float(ring)).rgb;
			n += 1.0;
		}
	}
	vec3 behind = sum / n;
	COLOR = vec4(mix(behind, COLOR.rgb, COLOR.a), 1.0);
}
