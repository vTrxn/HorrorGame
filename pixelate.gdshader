shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform int pixel_size : hint_range(1, 16) = 4;

void fragment() {
	vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 uv = FRAGCOORD.xy / res;
	vec2 pixelated_uv = floor(uv * (res / float(pixel_size))) / (res / float(pixel_size));
	COLOR = texture(screen_texture, pixelated_uv);
}
