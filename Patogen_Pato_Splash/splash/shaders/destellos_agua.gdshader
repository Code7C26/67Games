shader_type canvas_item;
render_mode unshaded;

uniform sampler2D glints : filter_nearest, repeat_disable;
uniform vec2 basin_size = vec2(128.0);
uniform float ambient_time = 0.0;
uniform float speed = 1.0;
uniform float intensity : hint_range(0.0, 1.0) = 0.45;
uniform float phase = 0.0;

void fragment() {
	vec2 pixel = floor(UV * basin_size);
	vec2 tile = floor(pixel / 32.0);
	float frame = mod(floor(ambient_time * speed * 2.0 + phase + tile.x + tile.y * 3.0), 4.0);
	vec2 texel = mod(pixel, 32.0) + vec2(0.5);
	vec2 atlas_uv = vec2((texel.x + frame * 32.0) / 128.0, texel.y / 32.0);
	vec4 light = texture(glints, atlas_uv);
	COLOR = vec4(light.rgb, light.a * intensity);
}
