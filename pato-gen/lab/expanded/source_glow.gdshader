shader_type canvas_item;
render_mode unshaded;
uniform vec2 frame_size=vec2(96.0,112.0);
uniform vec4 emission_rect=vec4(0.0);
uniform vec4 secondary_rect=vec4(0.0);
uniform float secondary_strength : hint_range(0.0,1.0)=0.0;
uniform float emission_energy : hint_range(1.0,4.0)=2.15;
uniform float emission_opacity : hint_range(0.0,1.0)=0.58;
uniform bool use_emission_tint=false;
uniform bool include_neutral_pixels=false;
uniform vec3 emission_tint : source_color=vec3(1.0);
float inside_rect(vec2 p,vec4 rect) {
	return float(all(greaterThanEqual(p,rect.xy)) && all(lessThan(p,rect.xy+rect.zw)));
}
void fragment() {
	vec4 c=texture(TEXTURE,UV);
	vec2 p=mod(UV/TEXTURE_PIXEL_SIZE,frame_size);
	float colored=step(c.r*1.12,c.g)*step(0.12,c.g);
	float brightness=max(max(c.r,c.g),c.b);
	if (include_neutral_pixels) colored=max(colored,step(0.45,brightness));
	float region=max(inside_rect(p,emission_rect),inside_rect(p,secondary_rect)*secondary_strength);
	float mask=region*colored*c.a*emission_opacity;
	vec3 source=use_emission_tint ? emission_tint*brightness : c.rgb;
	COLOR=vec4(source*emission_energy,mask);
}
