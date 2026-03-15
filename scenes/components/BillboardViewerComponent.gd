extends Node3D
class_name BillboardViewerComponent

## 3D 월드에서 플레이어를 항상 바라보는 미디어 뷰어 컴포넌트
## 로어북 규칙 준수: 시각 연출의 컴포넌트화, Tween 활용

@export var fade_duration: float = 0.3
@export var keep_upright: bool = true # 부모가 회전해도 항상 똑바로 서 있음
@export var vertical_offset: float = 0.8 # 부모 위치로부터의 높이 간격

@onready var mesh_instance: MeshInstance3D = $MeshInstance

var is_active: bool = false

func _ready() -> void:
	if keep_upright:
		top_level = true # 부모의 회전 상속을 차단하고 전역 좌표계에서 독립적으로 작동
	
	# 초기화: 투명하게 시작
	modulate_alpha(0.0)
	hide()

func _process(_delta: float) -> void:
	if is_active:
		if keep_upright and is_instance_valid(get_parent()):
			# 부모의 위치를 따라가되 회전은 독립적으로 유지
			global_position = get_parent().global_position + Vector3(0, vertical_offset, 0)
			
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
