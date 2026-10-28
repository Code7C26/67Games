shader_type canvas_item;
render_mode unshaded;
varying vec2 world;
void vertex() { world=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy; }
void fragment() {
	vec2 d=abs((world-vec2(16.0,80.0))/vec2(1888.0,800.0)-0.5)*2.0;
	float edge=smoothstep(0.78,1.0,max(d.x,d.y));
	COLOR=vec4(0.015,0.035,0.05,edge*0.075);
}
