extends Node
class_name CameraControllerComponent

## 마우스 기반 카메라 제어를 담당하는 컴포넌트
## 로어북 규칙 준수: 모듈화, 입력 처리 분리

@export_group("Settings")
@export var sensitivity: float = 0.2
@export var min_pitch: float = -80.0
@export var max_pitch: float = 80.0

@export_group("Nodes")
@export var character_body: CharacterBody3D
@export var camera_pivot: Node3D

var _pitch: float = 0.0

func _ready() -> void:
	if not character_body or not camera_pivot:
		push_warning("CameraControllerComponent: character_body와 camera_pivot 노드가 설정되지 않았습니다.")
	
	# 마우스 커서 가두기
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_handle_mouse_look(event.relative)

func _handle_mouse_look(relative: Vector2) -> void:
	if not character_body or not camera_pivot:
		return
		
	# 좌우 회전 (플레이어 바디)
	character_body.rotate_y(deg_to_rad(-relative.x * sensitivity))
	
	# 상하 회전 (카메라 피벗)
	_pitch -= relative.y * sensitivity
	_pitch = clamp(_pitch, min_pitch, max_pitch)
	
	camera_pivot.rotation.x = deg_to_rad(_pitch)
