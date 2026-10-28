shader_type canvas_item;
render_mode unshaded;
uniform vec4 shadow_color : source_color = vec4(0.025,0.045,0.065,0.28);
uniform float falloff : hint_range(0.5,4.0) = 1.8;
void fragment() {
	float sides = smoothstep(0.0,0.08,UV.x)*smoothstep(0.0,0.08,1.0-UV.x);
	COLOR = vec4(shadow_color.rgb,shadow_color.a*pow(1.0-UV.y,falloff)*sides);
}
