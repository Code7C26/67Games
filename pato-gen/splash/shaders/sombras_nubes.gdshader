shader_type canvas_item;
render_mode unshaded;

uniform vec2 area_size = vec2(1856.0, 860.0);
uniform float ambient_time = 0.0;
uniform float speed = 18.0;
uniform float intensity : hint_range(0.0, 0.35) = 0.24;
uniform vec4 shadow_colour : source_color = vec4(0.157, 0.204, 0.235, 1.0);

float puff(vec2 p, vec2 centre, vec2 radius) {
	return 1.0 - smoothstep(0.72, 1.08, length((p - centre) / radius));
}

void fragment() {
	// Horizontal wrap keeps clouds present throughout long matches; vertical sway stays bounded.
	vec2 point = UV * area_size + vec2(ambient_time * speed, sin(ambient_time * 0.025) * 30.0);
	point.x = mod(point.x, 2500.0);
	float cloud_a = max(puff(point, vec2(310.0, 395.0), vec2(190.0, 105.0)), puff(point, vec2(510.0, 355.0), vec2(250.0, 150.0)));
	cloud_a = max(cloud_a, puff(point, vec2(725.0, 405.0), vec2(180.0, 115.0)));
	float cloud_b = max(puff(point, vec2(1490.0, 805.0), vec2(220.0, 125.0)), puff(point, vec2(1700.0, 755.0), vec2(200.0, 150.0)));
	cloud_b = max(cloud_b, puff(point, vec2(1880.0, 820.0), vec2(160.0, 105.0)));
	COLOR = vec4(shadow_colour.rgb, max(cloud_a, cloud_b) * intensity);
}
