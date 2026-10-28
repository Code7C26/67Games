shader_type canvas_item;
render_mode unshaded;
uniform vec2 basin_size = vec2(474.0,212.0);
uniform float effect_time = 0.0;
uniform float caustic_intensity : hint_range(0.0,0.5) = 0.16;
uniform float depth_intensity : hint_range(0.0,0.7) = 0.24;
uniform float foam_intensity : hint_range(0.0,1.0) = 0.5;
uniform float wave_speed = 0.45;
uniform vec3 shallow_color : source_color = vec3(0.35,0.88,0.92);
uniform vec3 deep_color : source_color = vec3(0.025,0.23,0.4);
void fragment() {
	vec2 px = floor(UV*basin_size);
	float edge = min(min(px.x,basin_size.x-px.x),min(px.y,basin_size.y-px.y));
	float depth = smoothstep(0.0,basin_size.y*0.35,edge);
	float a = sin(px.x*0.09+sin(px.y*0.12+effect_time*wave_speed)*1.7+effect_time*wave_speed);
	float b = sin(px.y*0.10+sin(px.x*0.08-effect_time*wave_speed)*1.6);
	float caustic = pow(max(0.0,1.0-abs(a+b)*0.8),9.0)*caustic_intensity;
	float foam = (1.0-step(3.0,edge))*step(0.0,sin((px.x+px.y)*0.35+effect_time*wave_speed))*foam_intensity;
	vec3 color = mix(shallow_color,deep_color,depth)+vec3(caustic)+vec3(foam*0.6);
	COLOR = vec4(color,depth_intensity+caustic+foam*0.35);
}
