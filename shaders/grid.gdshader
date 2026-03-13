shader_type spatial;

render_mode unshaded;

uniform vec3 base_color : source_color = vec3(0.05, 0.05, 0.05);
uniform vec3 grid_color : source_color = vec3(0.3, 0.3, 0.3);
uniform float grid_size = 1.0;
uniform float line_thickness = 0.02;

void fragment() {
	// 월드 좌표 기반 그리드 계산
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 grid_coord = world_pos.xz / grid_size;
	
	// 각 그리드 칸의 중심에서의 거리 계산
	vec2 grid = abs(fract(grid_coord - 0.5) - 0.5) / (fwidth(grid_coord) + 0.001);
	float line = min(grid.x, grid.y);
	
	// 선 두께 적용
	float mask = 1.0 - smoothstep(0.0, line_thickness * 10.0, line);
	
	ALBEDO = mix(base_color, grid_color, mask);
}
