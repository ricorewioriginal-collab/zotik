shader_type sky;
// Night sky for Lunaris: gradient, stars, a big moon with a halo and a soft
// aurora band. Cheap (no textures) so it also runs in the compatibility
// renderer on the web and on Android.

uniform vec3 sky_top : source_color = vec3(0.02, 0.04, 0.16);
uniform vec3 sky_horizon : source_color = vec3(0.25, 0.22, 0.52);
uniform vec3 ground_color : source_color = vec3(0.04, 0.05, 0.12);
uniform vec3 moon_dir = vec3(-0.35, 0.42, -0.84);
uniform float moon_size = 0.045;
uniform vec3 moon_color : source_color = vec3(0.85, 0.92, 1.0);
uniform float star_amount = 0.6;
uniform vec3 aurora_color : source_color = vec3(0.2, 0.9, 0.8);
uniform float aurora_strength = 0.35;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float h = clamp(d.y, -1.0, 1.0);
	vec3 col = mix(sky_horizon, sky_top, pow(clamp(h, 0.0, 1.0), 0.55));
	col = mix(col, ground_color, smoothstep(0.0, -0.25, h));
	// stars
	if (h > 0.02) {
		vec3 g = floor(d * 160.0);
		float r = hash(g);
		float tw = 0.7 + 0.3 * sin(TIME * (1.0 + r * 3.0) + r * 40.0);
		float star = step(1.0 - 0.012 * star_amount, r) * tw;
		col += vec3(star) * smoothstep(0.02, 0.3, h);
	}
	// aurora: a wavy band high in the sky
	float band = smoothstep(0.55, 0.0, abs(h - 0.42 - 0.08 * sin(d.x * 6.0 + TIME * 0.15)));
	col += aurora_color * band * aurora_strength * (0.6 + 0.4 * sin(d.x * 9.0 + d.z * 5.0 + TIME * 0.3));
	// moon and halo
	vec3 m = normalize(moon_dir);
	float a = acos(clamp(dot(d, m), -1.0, 1.0));
	float disc = smoothstep(moon_size, moon_size * 0.92, a);
	float halo = exp(-a * 9.0) * 0.55 + exp(-a * 3.0) * 0.15;
	col += moon_color * halo;
	col = mix(col, moon_color * 1.25, disc);
	COLOR = col;
}
