shader_type canvas_item;
#include "res://shaders/sunlight_mask.gdshaderinc"
uniform float ambient : hint_range(0.0, 1.0) = 0.66;
uniform vec3 shadow_tint = vec3(-0.03, 0.025, 0.045);
uniform vec3 highlight_tint = vec3(0.035, 0.025, -0.015);
uniform float effect_time = 0.0;
uniform float sheen_intensity : hint_range(0.0,0.5) = 0.0;
uniform float sheen_speed = 10.0;
uniform float sheen_width = 65.0;
uniform float sheen_spacing = 900.0;
uniform vec3 sheen_color : source_color = vec3(0.55,0.78,0.88);
varying vec2 world;
varying vec4 tint;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX,0.0,1.0)).xy; tint = COLOR; }
void fragment() {
	vec4 c = texture(TEXTURE, UV) * tint;
	float value = dot(c.rgb, vec3(0.2126,0.7152,0.0722));
	// Preserve the eight floor hues while softening the contrast of grout and flecks.
	vec3 muted = mix(vec3(value), c.rgb, 0.65);
	muted = mix(muted,vec3(0.53,0.58,0.59),0.16);
	float tile_noise = fract(sin(dot(floor((world-vec2(16.0,80.0))/32.0),vec2(12.9898,78.233)))*43758.5453);
	muted += (tile_noise-0.5)*0.012;
	muted += shadow_tint*(1.0-smoothstep(0.08,0.45,value)) + highlight_tint*smoothstep(0.5,0.95,value);
	float stripe = abs(mod(world.x+world.y*0.55-effect_time*sheen_speed,sheen_spacing)-sheen_spacing*0.5);
	float sheen = (1.0-smoothstep(sheen_width*0.35,sheen_width,stripe))*smoothstep(0.28,0.7,value)*sheen_intensity*sunlight_at(world);
	COLOR=vec4(max(muted,vec3(0.0))*ambient+sheen_color*sheen,c.a);
}
