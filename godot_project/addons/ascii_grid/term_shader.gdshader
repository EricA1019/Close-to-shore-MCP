shader_type canvas_item;

uniform sampler2D glyphs : filter_nearest, repeat_disable;
uniform sampler2D character_grid : filter_nearest, repeat_disable;
uniform sampler2D fg_color : filter_nearest, repeat_disable;
uniform sampler2D bg_color : filter_nearest, repeat_disable;

// Debug: when true, shader outputs solid white to help detect occlusion issues
uniform bool debug_force_white = false;
	
const vec2 tile_size = vec2(1.0 / 8.0, 1.0 / 16.0);
uniform vec2 grid_size;
uniform int chars_per_line = 16;

void fragment() {
	vec3 out_rgb;
	if (debug_force_white) {
		// Debug path: force output to white to identify occlusion
		out_rgb = vec3(1.0);
	} else {
		// Determine current cell and UV within the cell
		vec2 cell_coord = floor(UV * grid_size) + vec2(0.5);
		vec2 cell_uv = fract(UV * grid_size);

		// Look up the character id from the grid texture (encoded in the red channel)
		int char_code = int((texture(character_grid, cell_coord / grid_size).r) * 256.0);

		// Compute glyph UV within the atlas
		vec2 glyph_pixel_pos = (vec2(
			float(char_code % chars_per_line),
			float(char_code / chars_per_line)
		) + cell_uv) / vec2(float(chars_per_line), float(256 / chars_per_line));

		// Sample colors for this cell
		vec3 fg_color_pixel = texture(fg_color, cell_coord / grid_size).rgb;
		vec3 bg_color_pixel = texture(bg_color, cell_coord / grid_size).rgb;

		// Sample glyph mask from the atlas. Prefer alpha channel, fall back to luminance of rgb.
		vec4 glyph_sample = texture(glyphs, glyph_pixel_pos, 0.0);
		float mask = glyph_sample.a;
		// Some atlases do not use alpha; derive mask from color intensity if alpha is zero or near-zero
		if (mask <= 0.001) {
			mask = max(glyph_sample.r, max(glyph_sample.g, glyph_sample.b));
		}

		// Compose final color
		out_rgb = mix(bg_color_pixel, fg_color_pixel, mask);
	}
	// Ensure fully opaque output.
	COLOR = vec4(out_rgb, 1.0);
}