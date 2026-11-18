shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;

uniform float flow_speed = 3.8;
uniform vec4 water_color : source_color = vec4(0.14, 0.72, 0.96, 0.76);
uniform vec4 foam_color : source_color = vec4(0.84, 0.96, 1.0, 0.92);

void fragment() {
	float v_scroll = UV.y * 6.0 - TIME * flow_speed;
	float u_angle = UV.x * 6.2831853;
	float wave1 = sin(v_scroll * 3.2 + sin(u_angle * 2.0 + TIME * 4.0) * 1.1);
	float wave2 = sin(v_scroll * 6.5 - u_angle * 3.0);
	float streak = smoothstep(0.25, 0.95, 0.5 * wave1 + 0.5 * wave2);

	float fresnel = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.2);
	float bottom_fade = smoothstep(1.0, 0.86, UV.y);

	ALBEDO = mix(water_color.rgb, foam_color.rgb, streak * 0.5 + fresnel * 0.35);
	EMISSION = water_color.rgb * 0.18 + foam_color.rgb * (streak * 0.14);
	ROUGHNESS = 0.08;
	SPECULAR = 0.85;
	ALPHA = clamp(water_color.a + streak * 0.18 + fresnel * 0.15, 0.0, 0.94) * bottom_fade;
}
