shader_type canvas_item;
void fragment() {
	vec4 c=texture(TEXTURE,UV);
	float v=dot(c.rgb,vec3(0.2126,0.7152,0.0722));
	c.rgb += vec3(-0.005,0.005,0.009)*(1.0-smoothstep(0.08,0.45,v));
	c.rgb += vec3(0.009,0.004,-0.004)*smoothstep(0.50,0.95,v);
	COLOR=c;
}
