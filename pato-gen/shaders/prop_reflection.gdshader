shader_type canvas_item;
render_mode unshaded;
uniform vec2 frame_size = vec2(96.0,128.0);
uniform vec4 atlas_bounds = vec4(0.0,0.0,1.0,1.0);
uniform vec4 reflection_tint : source_color = vec4(0.55,0.78,0.88,0.25);
uniform float fade_power : hint_range(0.5,4.0) = 1.7;
uniform float ripple_pixels : hint_range(0.0,5.0) = 0.6;
uniform float ripple_speed = 0.75;
uniform float effect_time = 0.0;
uniform bool water_clip = false;
uniform vec4 clip_rect = vec4(0.0);
varying vec2 local_uv;
varying vec2 world;
void vertex() {
	local_uv = VERTEX / frame_size;
	world = (MODEL_MATRIX * vec4(VERTEX,0.0,1.0)).xy;
}
void fragment() {
	float wave = floor(sin(local_uv.y*35.0+effect_time*ripple_speed)*ripple_pixels+0.5);
	vec2 sample_uv = UV + vec2(wave*TEXTURE_PIXEL_SIZE.x,0.0);
	sample_uv = clamp(sample_uv,atlas_bounds.xy+TEXTURE_PIXEL_SIZE*0.5,atlas_bounds.zw-TEXTURE_PIXEL_SIZE*0.5);
	vec4 source = texture(TEXTURE,sample_uv);
	float mask = 1.0;
	if (water_clip) mask = step(clip_rect.x,world.x)*step(clip_rect.y,world.y)*step(world.x,clip_rect.x+clip_rect.z)*step(world.y,clip_rect.y+clip_rect.w);
	COLOR = vec4(source.rgb*reflection_tint.rgb, source.a*reflection_tint.a*pow(clamp(local_uv.y,0.0,1.0),fade_power)*mask);
}
