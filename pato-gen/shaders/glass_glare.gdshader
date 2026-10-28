shader_type canvas_item;
render_mode unshaded, blend_add;
uniform vec2 frame_size = vec2(96.0,128.0);
uniform vec4 glass_rect = vec4(8.0,12.0,80.0,80.0);
uniform vec4 glare_color : source_color = vec4(0.6,0.85,1.0,0.34);
uniform float effect_time = 0.0;
uniform float sweep_speed = 0.055;
uniform float stripe_width = 0.09;
uniform float phase = 0.3;
varying vec2 pixel;
void vertex() { pixel = VERTEX; }
void fragment() {
	vec2 p = (pixel-glass_rect.xy)/glass_rect.zw;
	float inside = step(0.0,p.x)*step(0.0,p.y)*step(p.x,1.0)*step(p.y,1.0);
	float centre = mod(effect_time*sweep_speed+phase,2.0)-0.4;
	float line = 1.0-smoothstep(stripe_width*0.4,stripe_width,abs(p.x+p.y*0.35-centre));
	float thin = 1.0-smoothstep(0.006,0.014,abs(p.x+p.y*0.35-centre-0.11));
	float edge = smoothstep(0.0,0.06,p.x)*smoothstep(0.0,0.06,p.y)*smoothstep(0.0,0.06,1.0-p.x)*smoothstep(0.0,0.06,1.0-p.y);
	COLOR = vec4(glare_color.rgb, texture(TEXTURE,UV).a*inside*edge*max(line,thin*0.65)*glare_color.a);
}
