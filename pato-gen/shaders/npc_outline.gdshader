shader_type canvas_item;
render_mode unshaded;
// Independent padded textures prevent atlas bleeding and cropped outlines.
uniform bool borde_activo = false;
uniform vec4 color_borde : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform float pulse_phase = 0.0;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 s = TEXTURE_PIXEL_SIZE;
	float n = texture(TEXTURE, UV + vec2(s.x,0.0)).a;
	n = max(n, texture(TEXTURE, UV - vec2(s.x,0.0)).a);
	n = max(n, texture(TEXTURE, UV + vec2(0.0,s.y)).a);
	n = max(n, texture(TEXTURE, UV - vec2(0.0,s.y)).a);
	float edge = n * (1.0-c.a);
	vec3 outline = borde_activo ? color_borde.rgb * (0.94 + 0.06*sin(TIME*2.4+pulse_phase)) : vec3(0.04,0.06,0.10);
	float alpha = c.a + edge;
	COLOR = vec4((c.rgb*c.a + outline*edge)/max(alpha,0.0001),alpha) * tint;
}
