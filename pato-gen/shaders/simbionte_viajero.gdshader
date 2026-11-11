shader_type canvas_item;
render_mode unshaded;
// Used only before fusion; the host keeps its existing appearance material.
uniform vec4 color_vena : source_color = vec4(0.321569, 0.552941, 1.0, 1.0);
uniform vec4 color_brillo : source_color = vec4(0.776471, 0.854902, 1.0, 1.0);
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
	if (coincide(tinta.rgb, vec3(66.0, 199.0, 200.0) / 255.0)) tinta.rgb = color_vena.rgb;
	else if (coincide(tinta.rgb, vec3(162.0, 239.0, 224.0) / 255.0)) tinta.rgb = color_brillo.rgb;
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
