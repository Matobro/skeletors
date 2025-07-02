shader_type canvas_item;

uniform float outline_size = 1.0;
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Default red

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);

	// Check if the current pixel is transparent
	if (tex_color.a < 0.1) {
		// Look around to see if there's an opaque neighbor
		bool has_opaque_neighbor = false;

		for (float x = -outline_size; x <= outline_size; x++) {
			for (float y = -outline_size; y <= outline_size; y++) {
				vec2 offset = vec2(x, y) * TEXTURE_PIXEL_SIZE;
				vec4 neighbor = texture(TEXTURE, UV + offset);
				if (neighbor.a > 0.1) {
					has_opaque_neighbor = true;
				}
			}
		}

		// If a neighbor is opaque, draw the outline
		if (has_opaque_neighbor) {
			COLOR = outline_color;
		} else {
			// Otherwise keep it transparent
			COLOR = vec4(0.0);
		}
	} else {
		// If the pixel is part of the main sprite, just show it
		COLOR = tex_color;
	}
}