extends Node3D
class_name BillboardViewerComponent

## 3D 월드에서 플레이어를 항상 바라보는 미디어 뷰어 컴포넌트
## 로어북 규칙 준수: 시각 연출의 컴포넌트화, Tween 활용

@export var fade_duration: float = 0.3

@onready var mesh_instance: MeshInstance3D = $MeshInstance

var is_active: bool = false

func _ready() -> void:
	# 초기화: 투명하게 시작
	modulate_alpha(0.0)
	hide()

func _process(_delta: float) -> void:
	if is_active:
		var camera = get_viewport().get_camera_3d()
		if camera:
			look_at(camera.global_position, Vector3.UP)
			rotate_y(PI) # 메시 방향 보정

func show_media(texture: Texture2D) -> void:
	# 텍스처 적용 및 비율 조정
	var material = mesh_instance.get_active_material(0).duplicate() as StandardMaterial3D
	material.albedo_texture = texture
	mesh_instance.set_surface_override_material(0, material)
	
	# 메시 크기를 이미지 해상도 비율에 맞게 조정 (기본 크기 1.0 기준)
	var aspect = float(texture.get_width()) / float(texture.get_height())
	mesh_instance.scale = Vector3(aspect, 1.0, 1.0)
	
	show()
	is_active = true
	
	# 페이드 인 (Tween 활용)
	var tween = create_tween()
	tween.tween_method(modulate_alpha, 0.0, 1.0, fade_duration)

func hide_media() -> void:
	if not is_active: return
	
	is_active = false
	# 페이드 아웃
	var tween = create_tween()
	tween.tween_method(modulate_alpha, 1.0, 0.0, fade_duration)
	tween.tween_callback(hide)

func modulate_alpha(alpha: float) -> void:
	var mat = mesh_instance.get_surface_override_material(0) as StandardMaterial3D
	if mat:
		mat.albedo_color.a = alpha
	else:
		# 기본 머티리얼이 없을 경우를 대비해 인스턴스 색상 조정 (StandardMaterial3D의 Transparency가 켜져 있어야 함)
		var base_mat = mesh_instance.get_active_material(0) as StandardMaterial3D
		if base_mat:
			base_mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
			base_mat.albedo_color.a = alpha
