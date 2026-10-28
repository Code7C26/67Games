shader_type canvas_item;
// Independent padded textures prevent atlas bleeding and cropped outlines.
// Defaults preserve other maps; Lab opts into illumination on the body only.
uniform float environment_ambient : hint_range(0.0,1.0) = 1.0;
uniform float local_light_response : hint_range(0.0,1.0) = 0.0;
uniform bool borde_activo = false;
uniform vec4 color_borde : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform float pulse_phase = 0.0;
varying vec4 tint;
varying vec4 body;
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
	body = vec4(c.rgb*c.a/max(alpha,0.0001),c.a)*tint;
	COLOR = vec4((c.rgb*c.a*environment_ambient + outline*edge)/max(alpha,0.0001),alpha) * tint;
}
void light() {
	float diffuse = max(dot(NORMAL,LIGHT_DIRECTION),0.0);
	// Transparent padding and team outlines receive no light. The shared body
	// material survives skin swaps, possession, infection and replication.
	LIGHT = vec4(body.rgb*LIGHT_COLOR.rgb*LIGHT_ENERGY*diffuse*local_light_response,LIGHT_COLOR.a);
}
