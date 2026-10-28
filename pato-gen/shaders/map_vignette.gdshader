shader_type canvas_item;
render_mode unshaded;
varying vec2 world;
void vertex() { world=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy; }
void fragment() {
	vec2 p=abs((world-vec2(1072.0,560.0))/vec2(1072.0,480.0));
	COLOR=vec4(0.02,0.04,0.06,smoothstep(0.8,1.0,max(p.x,p.y))*0.075);
}
