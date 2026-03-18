shader_type sky;

uniform vec3 sun_direction = vec3(0.0, 1.0, 0.0);
uniform vec3 moon_direction = vec3(0.0, -1.0, 0.0);

uniform vec3 day_top_color : source_color = vec3(0.1, 0.5, 0.9);
uniform vec3 day_bottom_color : source_color = vec3(0.4, 0.7, 1.0);
uniform vec3 sunset_color : source_color = vec3(1.0, 0.4, 0.1);
uniform vec3 night_top_color : source_color = vec3(0.02, 0.05, 0.1);
uniform vec3 night_bottom_color : source_color = vec3(0.1, 0.1, 0.2);

uniform float cloud_density : hint_range(0.0, 1.0) = 0.4;
uniform float cloud_speed : hint_range(0.0, 0.1) = 0.01;
uniform float horizon_blend : hint_range(0.0, 1.0) = 0.2;

uniform float star_density : hint_range(0.0, 1.0) = 0.5;

// 심플 노이즈 함수 (구름용)
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    mat2 rot = mat2(vec2(1.6, 1.2), vec2(-1.2, 1.6));
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p = rot * p * 2.0;
        a *= 0.5;
    }
    return v;
}

void sky() {
    vec3 dir = EYEDIR;
    float sun_amount = max(dot(dir, sun_direction), 0.0);
    float moon_amount = max(dot(dir, moon_direction), 0.0);
    float horizon_amount = 1.0 - abs(dir.y);
    
    // 1. 배경 그래디언트 (낮/밤/노을)
    float sun_up = max(sun_direction.y, 0.0);
    float sunset_amount = clamp(1.0 - abs(sun_direction.y) * 4.0, 0.0, 1.0);
    
    vec3 day_sky = mix(day_bottom_color, day_top_color, max(dir.y, 0.0));
    vec3 night_sky = mix(night_bottom_color, night_top_color, max(dir.y, 0.0));
    
    vec3 final_sky = mix(night_sky, day_sky, sun_up);
    final_sky = mix(final_sky, sunset_color, sunset_amount * max(dir.y + 0.2, 0.0));
    
    // 2. 태양 연출 (기능별 조절 가이드)
    // [크기 조절]: 0.9985가 1.0에 가까울수록(예: 0.9995) 태양이 작아지고 예리해짐
    float sun_disk = smoothstep(0.99999, 1.0, sun_amount); 
    
    // [후광 조절]: 1500.0(지수)이 클수록 후광이 좁게 응축되고, 1.5(배율)가 클수록 밝아짐
    float sun_halo = pow(sun_amount, 1500.0) * 1.8;      
    
    // [대기 확산]: 50.0이 작을수록 하늘 전체로 빛무리가 넓게 퍼짐
    float sun_glow = pow(sun_amount, 40.0) * 0.3;       
    
    vec3 sun_color_final = mix(vec3(1.0, 1.0, 1.0), vec3(1.0, 0.8, 0.5), 0.5); 
    sun_color_final = mix(sun_color_final, sunset_color, sunset_amount); 
    
    // 최종 노출값 (10.0, 3.0 등)을 조절하여 전체적인 눈부심 정도를 결정
    final_sky += sun_disk * sun_color_final * 10.0;     // 태양 본체 밝기
    final_sky += sun_halo * sun_color_final * 3.0;      // 후광 밝기
    final_sky += sun_glow * sun_color_final * 1.0;      // 빛무리 밝기

    // 3. 달 연출 (기능별 조절 가이드)
    // [크기 조절]: 0.999가 1.0에 가까울수록 달이 작아짐
    float moon_disk = smoothstep(0.999, 1.0, moon_amount);
    
    // [후광 조절]: 800.0이 클수록 후광이 좁아짐
    float moon_halo = pow(moon_amount, 800.0) * 0.8;
    
    vec3 moon_color_final = vec3(0.8, 0.9, 1.0);
    final_sky += moon_disk * moon_color_final * 2.0;     // 달 본체 밝기
    final_sky += moon_halo * moon_color_final * 1.0;     // 달 후광 밝기

    // 4. 구름 (임시 제거: 깨짐 현상 해결 전까지 맑은 하늘 유지)
    /*
    float phi = atan(dir.z, dir.x);
    float theta = acos(dir.y);
    vec2 cloud_uv = vec2(phi / (2.0 * PI), theta / PI);
    float safe_time = mod(TIME, 1000.0) * cloud_speed;
    cloud_uv += safe_time;
    float cloud = fbm(cloud_uv * 0.8);
    cloud = smoothstep(1.0 - cloud_density, 1.0, cloud);
    cloud *= smoothstep(0.0, 0.2, dir.y);
    vec3 cloud_color = mix(vec3(1.0), sunset_color * 1.5, sunset_amount);
    cloud_color = mix(cloud_color, vec3(0.05, 0.05, 0.1), 1.0 - sun_up);
    final_sky = mix(final_sky, cloud_color, cloud);
    */
    
    // 
    
    COLOR = final_sky;
}
