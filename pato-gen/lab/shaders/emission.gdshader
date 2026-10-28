shader_type canvas_item;
render_mode unshaded;
uniform vec2 frame_size=vec2(96.0,112.0);
uniform vec4 emission_rect=vec4(0.0);
uniform float emission_energy=1.4;
void fragment() {
	vec4 c=texture(TEXTURE,UV);
	vec2 p=mod(UV/TEXTURE_PIXEL_SIZE,frame_size);
	bool inside=all(greaterThanEqual(p,emission_rect.xy)) && all(lessThan(p,emission_rect.xy+emission_rect.zw));
	// Only colored phosphor / status pixels within a designated equipment panel.
	float colored=step(c.r*1.16,c.g)*step(0.24,c.g);
	float brightness=max(max(c.r,c.g),c.b);
	float mask=(inside ? 1.0 : 0.0)*colored*c.a;
	COLOR=vec4(c.rgb/max(brightness,0.001)*emission_energy,mask);
}
