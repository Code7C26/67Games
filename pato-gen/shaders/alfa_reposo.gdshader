shader_type canvas_item;
render_mode unshaded;

// A match-owned clock freezes the pose with the tutorial and global pause.
uniform float tiempo_reposo = 0.0;
uniform float intensidad_reposo : hint_range(0.0, 1.0) = 1.0;
uniform float fotograma = 0.0;
uniform vec4 color_latido : source_color = vec4(0.490196, 1.0, 0.270588, 1.0);
varying vec4 modulacion;

void vertex() { modulacion = COLOR; }

void fragment() {
	vec2 pixel = vec2((UV.x * 8.0 - fotograma) * 64.0, UV.y * 64.0);
	// The original roots and their ground pixels (rows 49-63) remain exact.
	float torso = 1.0 - smoothstep(38.0, 49.0, pixel.y);
	float respiracion = sin(tiempo_reposo * 2.6);
	float balanceo = sin(tiempo_reposo * 1.35);
	float costado = (pixel.x - 32.0) / 32.0;
	vec2 desplazamiento = vec2(
		balanceo * 1.5 + respiracion * costado * 1.2
			+ sin(tiempo_reposo * 3.0 + pixel.y * 0.16) * abs(costado) * 0.55,
		respiracion * 2.0
	) * torso * intensidad_reposo;
	vec2 muestra = pixel + desplazamiento;
	vec4 tinta = vec4(0.0);
	if (muestra.x >= 0.0 && muestra.x < 64.0 && muestra.y >= 0.0 && muestra.y < 64.0) {
		vec2 coordenada = vec2((fotograma + muestra.x / 64.0) / 8.0, muestra.y / 64.0);
		tinta = texture(TEXTURE, coordenada);
	}
	// A quiet green pulse makes the living veins readable without flashing.
	if (tinta.g > tinta.r * 1.1 && tinta.g > tinta.b * 1.1) {
		float latido = (0.5 + 0.5 * sin(tiempo_reposo * 2.6 - 0.6)) * 0.16;
		tinta.rgb = mix(tinta.rgb, color_latido.rgb, latido * torso * intensidad_reposo);
	}
	COLOR = tinta * modulacion;
}
