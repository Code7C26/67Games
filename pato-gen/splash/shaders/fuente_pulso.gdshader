shader_type canvas_item;
render_mode unshaded;

uniform float flow : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	vec2 pixel = UV / TEXTURE_PIXEL_SIZE;
	pixel.x = mod(pixel.x, 128.0);
	// Only the hanging water changes opacity. Cap, column and basin remain fixed.
	bool outside_column = pixel.x < 55.0 || pixel.x >= 75.0;
	bool curtain = pixel.y >= 54.0 && pixel.y < 100.0 && pixel.x >= 13.0 && pixel.x <= 114.0 && outside_column;
	COLOR = vec4(texel.rgb, texel.a * (curtain ? flow : 1.0));
}
