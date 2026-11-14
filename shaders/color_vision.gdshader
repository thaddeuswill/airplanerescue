shader_type canvas_item;
// Color-vision filter for the whole screen (Settings > Accessibility). Daltonizes: simulates
// what a red-, green- or blue-weak eye loses, then pushes that lost difference into the
// channels it can still tell apart (Fidaner et al.). mode: 1 protan, 2 deutan, 3 tritan.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform int mode = 0;

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	// RGB to LMS cone response.
	float L = 17.8824 * c.r + 43.5161 * c.g + 4.11935 * c.b;
	float M = 3.45565 * c.r + 27.1554 * c.g + 3.86714 * c.b;
	float S = 0.0299566 * c.r + 0.184309 * c.g + 1.46709 * c.b;
	// What the weak cone can't see.
	if (mode == 1) { L = 2.02344 * M - 2.52581 * S; }
	else if (mode == 2) { M = 0.494207 * L + 1.24827 * S; }
	else if (mode == 3) { S = -0.395913 * L + 0.801109 * M; }
	// Back to RGB.
	vec3 sim = vec3(
		0.0809444479 * L - 0.130504409 * M + 0.116721066 * S,
		-0.0102485335 * L + 0.0540193266 * M - 0.113614708 * S,
		-0.000365296938 * L - 0.00412161469 * M + 0.693511405 * S);
	vec3 err = c - sim;
	// Shift the lost difference into the channels that are still seen.
	vec3 fix = vec3(0.0, 0.7 * err.r + err.g, 0.7 * err.r + err.b);
	COLOR = vec4(clamp(c + (mode == 0 ? vec3(0.0) : fix), 0.0, 1.0), 1.0);
}
