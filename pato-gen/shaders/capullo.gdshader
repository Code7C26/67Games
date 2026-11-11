shader_type canvas_item;
render_mode unshaded;
uniform vec4 vena : source_color = vec4(0.141176, 0.278431, 0.290196, 1.0);
uniform vec4 pulso : source_color = vec4(0.219608, 0.388235, 0.407843, 1.0);
uniform vec4 brillo : source_color = vec4(0.388235, 0.521569, 0.541176, 1.0);
uniform vec4 color_contorno : source_color = vec4(0.321569, 0.552941, 1.0, 1.0);
varying vec4 modulacion;
vec3 lineal(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}
bool coincide(vec3 c, vec3 origen) {
	return distance(c, origen) < 0.003 || distance(c, lineal(origen)) < 0.003;
}
void vertex() { modulacion = COLOR; }
void fragment() {
	vec4 tinta = texture(TEXTURE, UV);
	if (coincide(tinta.rgb, vec3(36.0, 71.0, 74.0) / 255.0)) tinta.rgb = vena.rgb;
	else if (coincide(tinta.rgb, vec3(56.0, 99.0, 104.0) / 255.0)) tinta.rgb = pulso.rgb;
	else if (coincide(tinta.rgb, vec3(99.0, 133.0, 138.0) / 255.0)) tinta.rgb = brillo.rgb;
	// Frames have transparent padding, so sampling never reaches another pose.
	vec2 paso = TEXTURE_PIXEL_SIZE;
	float vecino = 0.0;
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			if (x*x + y*y <= 4) vecino = max(vecino, texture(TEXTURE, UV + vec2(float(x), float(y)) * paso).a);
		}
	}
	float borde = vecino * (1.0 - tinta.a);
	float alfa = tinta.a + borde;
	COLOR = vec4((tinta.rgb * tinta.a + color_contorno.rgb * borde) / max(alfa, 0.0001), alfa) * modulacion;
}
