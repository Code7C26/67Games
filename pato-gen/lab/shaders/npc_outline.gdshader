shader_type canvas_item;
render_mode unshaded;
uniform vec4 outline_color : source_color = vec4(0.04, 0.06, 0.1, 1.0);
uniform bool infected = false;
uniform float pulse_phase = 0.0;
void fragment() {
	vec2 pixel = TEXTURE_PIXEL_SIZE;
	// Every atlas frame has a transparent border; clamp to its 34px cell.
	vec2 cell = floor((UV / pixel) / 34.0) * 34.0;
	vec2 low = (cell + 0.5) * pixel;
	vec2 high = (cell + 33.5) * pixel;
	vec4 c = texture(TEXTURE, UV);
	float n = texture(TEXTURE, clamp(UV + vec2(pixel.x, 0.0),low,high)).a;
	n = max(n,texture(TEXTURE, clamp(UV - vec2(pixel.x, 0.0),low,high)).a);
	n = max(n,texture(TEXTURE, clamp(UV + vec2(0.0,pixel.y),low,high)).a);
	n = max(n,texture(TEXTURE, clamp(UV - vec2(0.0,pixel.y),low,high)).a);
	float pulse = infected ? 0.90 + 0.10*sin(TIME*2.4+pulse_phase) : 1.0;
	float edge = n * (1.0-c.a) * outline_color.a;
	float alpha = c.a + edge;
	vec3 rgb = (c.rgb*c.a + outline_color.rgb*pulse*edge)/max(alpha,0.0001);
	COLOR = vec4(rgb,alpha);
}
