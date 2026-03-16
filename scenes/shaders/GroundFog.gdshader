shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec3 fog_color : source_color = vec3(0.8, 0.9, 1.0);
uniform float fog_density : hint_range(0.0, 1.0) = 0.5;
uniform float center_mask_radius = 10.0;
uniform float center_mask_softness = 5.0;
uniform vec3 center_position = vec3(0.0, 0.0, 0.0);

uniform float scroll_speed = 0.05;
uniform float noise_scale = 0.1;

// 간단한 3D 노이즈를 위한 해시
float hash(vec3 p) {
    p = fract(p * vec3(123.34, 456.21, 789.12));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y * p.z);
}

// 3D smooth 노이즈 함수
float noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    return mix(
        mix(mix(hash(i + vec3(0, 0, 0)), hash(i + vec3(1, 0, 0)), f.x),
            mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
        mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
            mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z
    );
}

void fragment() {
    // 1. 월드 좌표 기준 노이즈 (흐르는 안개 효과)
    vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float time = TIME * scroll_speed;
    
    // 공간 + 시간 보간된 노이즈 사용
    float n = noise(world_pos * noise_scale + time);
    n = mix(n, noise(world_pos * noise_scale - time * 0.5), 0.5); // 두 레이어 믹스로 더 자연스럽게
    
    // 2. 실내 제외 마스크 (중침점에서 멀어질수록 안개가 진해짐)
    float dist_to_center = distance(world_pos, center_position);
    float mask = smoothstep(center_mask_radius, center_mask_radius + center_mask_softness, dist_to_center);
    
    // 3. 카메라 거리 페이드 (가까이 있으면 투명하게)
    float dist_to_cam = length(VERTEX);
    float cam_fade = smoothstep(0.0, 2.0, dist_to_cam);
    
    // 4. 최종 알파 계산
    float alpha = n * fog_density * mask * cam_fade;
    
    ALBEDO = fog_color;
    ALPHA = clamp(alpha, 0.0, 1.0);
}
