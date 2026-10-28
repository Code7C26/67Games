shader_type canvas_item;
render_mode unshaded, blend_add;
#include "res://shaders/sunlight_mask.gdshaderinc"
uniform vec2 area_size = vec2(2144.0,1024.0);
uniform float effect_time = 0.0;
uniform float beam_speed = 7.0;
uniform float beam_spacing = 640.0;
uniform float beam_width = 85.0;
uniform vec4 beam_color : source_color = vec4(0.60,0.77,0.91,0.12);
varying vec2 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX,0.0,1.0)).xy; }
void fragment() {
	vec2 p = floor(UV*area_size);
	float stripe = abs(mod(p.x+p.y*0.68-effect_time*beam_speed,beam_spacing)-beam_spacing*0.5);
	float beam = 1.0-smoothstep(beam_width*0.2,beam_width,stripe);
	float edge = smoothstep(0.0,0.12,UV.y)*smoothstep(0.0,0.12,1.0-UV.y);
	COLOR = vec4(beam_color.rgb,beam*edge*beam_color.a*sunlight_at(world));
}
