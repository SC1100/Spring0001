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
		# [수정] 부모 위치에 고정하지 않고, 호출자(MediaFrame)가 정해준 위치를 유지합니다.
		# 만약 부모를 계속 따라다녀야 한다면 호출자측에서 업데이트하도록 변경.
		
		var camera = get_viewport().get_camera_3d()
		if camera:
			# [수정] 카메라의 전역 회전값을 그대로 복사하여 화면에 완벽하게 정면으로 평행하게 유지합니다.
			global_rotation = camera.global_rotation

func show_media(texture: Texture2D, interactor: Node3D = null) -> void:
	# [추가] 인터랙터(플레이어)가 제공되면 프레임과 플레이어 사이의 위치를 계산하여 배치합니다.
	if interactor and is_instance_valid(get_parent()):
		var parent_node = get_parent() as Node3D
		if parent_node:
			# 중심점 보정 (눈높이 약 1.5m)
			var frame_pos = parent_node.global_position + Vector3(0, vertical_offset, 0)
			var player_pos = interactor.global_position + Vector3(0, 1.5, 0)
			global_position = frame_pos.lerp(player_pos, 0.4) # 40% 지점 배치
			
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
