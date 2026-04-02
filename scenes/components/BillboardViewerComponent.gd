extends CanvasLayer
class_name BillboardViewerComponent

## 플레이어 화면에 이미지를 직접 표시하는 2D UI 오버레이 컴포넌트
## 로어북 규칙 준수: 시각 연출의 컴포넌트화, Tween 활용

@export var fade_duration: float = 0.3
@export var billboard_fixed_width: float = 600.0 # 화면에 표시되는 고정 가로 너비(픽셀)

@onready var texture_rect: TextureRect = $TextureRect

var is_active: bool = false

func _ready() -> void:
	# 초기화: 숨김 상태로 시작
	layer = 10 # UI 최상위
	hide()

func show_media(texture: Texture2D, _interactor: Node3D = null) -> void:
	# 텍스처 적용
	texture_rect.texture = texture
	
	# 가로 폭 고정, 세로는 비율에 맞춰 자동 계산
	var aspect = float(texture.get_width()) / float(texture.get_height())
	var target_height = billboard_fixed_width / aspect
	texture_rect.custom_minimum_size = Vector2(billboard_fixed_width, target_height)
	texture_rect.size = Vector2(billboard_fixed_width, target_height)
	
	# 화면 중앙 배치
	var viewport_size = get_viewport().get_visible_rect().size
	texture_rect.position = (viewport_size - texture_rect.size) / 2.0
	
	show()
	is_active = true
	
	# 페이드 인
	texture_rect.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(texture_rect, "modulate:a", 1.0, fade_duration)

func hide_media() -> void:
	if not is_active: return
	
	is_active = false
	# 페이드 아웃
	var tween = create_tween()
	tween.tween_property(texture_rect, "modulate:a", 0.0, fade_duration)
	tween.tween_callback(hide)
