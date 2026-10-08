shader_type canvas_item;
// Contorno de 1 pixel para destacar personagens sobre o cenário escuro.

uniform vec4 outline_color : source_color = vec4(1.0, 0.95, 0.85, 1.0);

varying vec4 modulate_color;

void vertex() {
	modulate_color = COLOR;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.a < 0.1) {
		vec2 px = TEXTURE_PIXEL_SIZE;
		float a = texture(TEXTURE, UV + vec2(px.x, 0.0)).a
			+ texture(TEXTURE, UV - vec2(px.x, 0.0)).a
			+ texture(TEXTURE, UV + vec2(0.0, px.y)).a
			+ texture(TEXTURE, UV - vec2(0.0, px.y)).a;
		if (a > 0.1) {
			c = outline_color;
		}
	}
	COLOR = c * modulate_color;
}
