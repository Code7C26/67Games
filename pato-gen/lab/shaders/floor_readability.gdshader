shader_type canvas_item;
varying vec2 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX,0.0,1.0)).xy; }
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float value = dot(c.rgb, vec3(0.2126,0.7152,0.0722));
	// Preserve the eight floor hues while softening the contrast of grout and flecks.
	vec3 muted = mix(vec3(value), c.rgb, 0.65);
	muted = mix(muted,vec3(0.53,0.58,0.59),0.16);
	float tile_noise = fract(sin(dot(floor((world-vec2(16.0,80.0))/32.0),vec2(12.9898,78.233)))*43758.5453);
	muted += (tile_noise-0.5)*0.012;
	COLOR=vec4(muted,c.a);
}
