shader_type spatial;

uniform sampler2D belt_albedo : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D belt_normal : hint_normal, repeat_enable, filter_linear_mipmap_anisotropic;
uniform float belt_roughness : hint_range(0.0, 1.0) = 0.88;
uniform float normal_strength : hint_range(0.0, 1.0) = 0.25;
uniform bool has_normal = false;
uniform float scroll_offset = 0.0;

void fragment() {
	vec2 belt_uv = UV - vec2(scroll_offset, 0.0);
	ALBEDO = texture(belt_albedo, belt_uv).rgb;
	ROUGHNESS = belt_roughness;
	METALLIC = 0.0;
	if (has_normal) {
		NORMAL_MAP = texture(belt_normal, belt_uv).rgb;
		NORMAL_MAP_DEPTH = normal_strength;
	}
}
