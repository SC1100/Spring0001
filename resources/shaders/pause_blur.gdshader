shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 5.0) = 2.5;
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 0.4);

void fragment() {
    // màn 화면 캡처 텍스처를 흐리게(블러) 만듭니다.
    vec4 color = textureLod(screen_texture, SCREEN_UV, blur_amount);
    
    // 추가적인 색상 틴트(하얀색)를 섞습니다.
    COLOR = mix(color, tint_color, tint_color.a);
    COLOR.a = 1.0;
}
