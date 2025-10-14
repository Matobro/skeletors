shader_type canvas_item;

uniform bool render_top = false;
uniform bool render_bottom = false;

void fragment() {
	if (render_top && UV.y > 0.5) discard;
	if (render_bottom && UV.y < 0.5) discard;
	COLOR = texture(TEXTURE, UV);
}