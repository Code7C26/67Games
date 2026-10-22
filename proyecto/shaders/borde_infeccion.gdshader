shader_type canvas_item;

// Borde INTERIOR: mantiene el color original y no necesita ampliar el sprite.
// Cada bot recibe su propio ShaderMaterial desde Bot.gd.
uniform bool borde_activo = false;
uniform vec4 color_borde : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform float grosor_borde : hint_range(1.0, 6.0, 1.0) = 2.0;

void fragment() {
    vec4 base = COLOR;

    if (!borde_activo || base.a <= 0.01) {
        COLOR = base;
    } else {
        vec2 desplazamiento = TEXTURE_PIXEL_SIZE * grosor_borde;

        float a1 = texture(TEXTURE, UV + vec2(desplazamiento.x, 0.0)).a;
        float a2 = texture(TEXTURE, UV - vec2(desplazamiento.x, 0.0)).a;
        float a3 = texture(TEXTURE, UV + vec2(0.0, desplazamiento.y)).a;
        float a4 = texture(TEXTURE, UV - vec2(0.0, desplazamiento.y)).a;
        float a5 = texture(TEXTURE, UV + desplazamiento).a;
        float a6 = texture(TEXTURE, UV - desplazamiento).a;
        float a7 = texture(TEXTURE, UV + vec2(desplazamiento.x, -desplazamiento.y)).a;
        float a8 = texture(TEXTURE, UV + vec2(-desplazamiento.x, desplazamiento.y)).a;

        float min_alpha = min(min(min(a1, a2), min(a3, a4)),
                              min(min(a5, a6), min(a7, a8)));
        float borde = 1.0 - step(0.1, min_alpha);
        COLOR = mix(base, vec4(color_borde.rgb, base.a), borde * 1.0);
    }
}
