shader_type canvas_item;
uniform vec4 color_vena : source_color = vec4(0.258824, 0.780392, 0.784314, 1.0);
uniform vec4 color_brillo : source_color = vec4(0.635294, 0.937255, 0.878431, 1.0);
varying vec4 modulacion;

void vertex() {
	modulacion = COLOR;
}

void fragment() {
	vec4 tinta = texture(TEXTURE, UV);
	if (distance(tinta.rgb, vec3(66.0, 199.0, 200.0) / 255.0) < 0.005) {
		tinta.rgb = color_vena.rgb;
	} else if (distance(tinta.rgb, vec3(162.0, 239.0, 224.0) / 255.0) < 0.005) {
		tinta.rgb = color_brillo.rgb;
	}
	COLOR = tinta * modulacion;
}
