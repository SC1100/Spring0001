shader_type sky;

// 다중 파노라마 스카이 블렌딩 셰이더 (개별 회전 지원)

uniform sampler2D source_sky : filter_linear, source_color, hint_default_black;
uniform sampler2D target_sky : filter_linear, source_color, hint_default_black;
uniform float mix_amount : hint_range(0.0, 1.0) = 0.0;

uniform vec3 source_rotation = vec3(0.0);
uniform vec3 target_rotation = vec3(0.0);

vec3 rotate(vec3 rd, vec3 rot) {
    // Y축 회전
    float sy = sin(rot.y);
    float cy = cos(rot.y);
    float rx = rd.x * cy - rd.z * sy;
    float rz = rd.x * sy + rd.z * cy;
    rd.x = rx;
    rd.z = rz;
    
    // X축 회전
    float sx = sin(rot.x);
    float cx = cos(rot.x);
    float ry = rd.y * cx - rd.z * sx;
    float rzz = rd.y * sx + rd.z * cx;
    rd.y = ry;
    rd.z = rzz;
    
    return rd;
}

vec2 get_uv(vec3 rd) {
    float phi = atan(rd.x, rd.z);
    float theta = acos(clamp(rd.y, -1.0, 1.0));
    return vec2(phi / (2.0 * PI) + 0.5, theta / PI);
}

void sky() {
    // 각각의 텍스처에 독립적인 회전 적용
    vec3 rd1 = rotate(EYEDIR, source_rotation);
    vec3 rd2 = rotate(EYEDIR, target_rotation);
    
    vec4 col1 = texture(source_sky, get_uv(rd1));
    vec4 col2 = texture(target_sky, get_uv(rd2));
    
    COLOR = mix(col1.rgb, col2.rgb, mix_amount);
}
