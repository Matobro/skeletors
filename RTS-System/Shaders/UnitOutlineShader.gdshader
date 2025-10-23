shader_type canvas_item;

uniform float outline_size = 1.0;
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	bool is_main = tex_color.a > 0.35;
	bool has_opaque_neighbor = false;

	// Only check neighbors if this pixel is transparent
	if (!is_main) {
		for (float x = -outline_size; x <= outline_size; x++) {
			for (float y = -outline_size; y <= outline_size; y++) {
				// Circular area (prevents diagonals extending too far)
				if (x * x + y * y > outline_size * outline_size) {
					continue;
				}
				vec2 offset = vec2(x, y) * TEXTURE_PIXEL_SIZE;
				vec4 neighbor = texture(TEXTURE, UV + offset);
				if (neighbor.a > 0.5) { // higher threshold avoids haloing
					has_opaque_neighbor = true;
					break;
				}
			}
			if (has_opaque_neighbor) {
				break;
			}
		}
	}

	// Choose final color
	if (is_main) {
		COLOR = tex_color;
	} else if (has_opaque_neighbor) {
		COLOR = outline_color;
	} else {
		COLOR = vec4(0.0);
	}
}
