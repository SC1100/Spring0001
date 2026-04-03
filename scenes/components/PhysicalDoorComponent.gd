extends Node3D

## [PhysicalDoorComponent]
## 기능: 문 Hinge를 회전시키고, DoorCollision도 동일하게 Hinge 축 기준으로 회전시킵니다.
## StaticBody3D의 콜리전은 런타임 transform 변경 시 물리 갱신이 필요하므로,
## disabled 토글 + physics_frame 대기로 강제 갱신합니다.

enum State { CLOSED, OPENING, OPEN, CLOSING }

@export_group("Target Nodes")
@export var target_node: Node3D ## Hinge 노드
@export var collision_node: CollisionShape3D ## 문판 충돌 영역
@export var interactable: Node

@export_group("Animation Settings")
@export var open_rotation: Vector3 = Vector3(0, -110, 0)
@export var close_rotation: Vector3 = Vector3.ZERO
@export var duration: float = 1.2
@export var trans_type: Tween.TransitionType = Tween.TRANS_CUBIC
@export var ease_type: Tween.EaseType = Tween.EASE_OUT

var current_state: State = State.CLOSED
var current_tween: Tween
var _collision_closed_transform: Transform3D

func _ready() -> void:
	if not target_node:
		push_warning("[PhysicalDoorComponent] target_node이 설정되지 않았습니다.")
	
	if not interactable:
		interactable = get_parent().find_child("Interactable", true)
	
	if interactable and interactable.has_signal("interacted"):
		interactable.interacted.connect(_on_interacted)
	else:
		push_error("[PhysicalDoorComponent] Interactable을 찾을 수 없습니다.")

	if target_node:
		target_node.rotation_degrees = close_rotation
	
	if collision_node:
		_collision_closed_transform = collision_node.transform

func _on_interacted(_interactor: Node3D, _is_long_press: bool) -> void:
	match current_state:
		State.CLOSED:
			open_door()
		State.OPEN:
			close_door()
		State.OPENING:
			close_door()
		State.CLOSING:
			open_door()

func open_door() -> void:
	if not target_node: return
	_kill_current_tween()
	current_state = State.OPENING
	
	if collision_node:
		collision_node.disabled = true
	
	current_tween = create_tween().set_trans(trans_type).set_ease(ease_type)
	current_tween.tween_property(target_node, "rotation_degrees", open_rotation, duration)
	current_tween.finished.connect(_on_open_finished, CONNECT_ONE_SHOT)

func _on_open_finished() -> void:
	current_state = State.OPEN
	if collision_node and target_node:
		_move_collision_around_hinge(open_rotation.y)

func close_door() -> void:
	if not target_node: return
	_kill_current_tween()
	current_state = State.CLOSING
	
	if collision_node:
		collision_node.disabled = true
	
	current_tween = create_tween().set_trans(trans_type).set_ease(ease_type)
	current_tween.tween_property(target_node, "rotation_degrees", close_rotation, duration)
	current_tween.finished.connect(_on_close_finished, CONNECT_ONE_SHOT)

func _on_close_finished() -> void:
	current_state = State.CLOSED
	if collision_node:
		collision_node.transform = _collision_closed_transform
		_force_physics_update()

func _move_collision_around_hinge(angle_deg: float) -> void:
	var pivot := target_node.position
	var angle_rad := deg_to_rad(angle_deg)
	var rot_basis := Basis(Vector3.UP, angle_rad)
	
	# 닫힌 상태 기준으로 피벗 중심 회전 계산
	var closed_pos := _collision_closed_transform.origin
	var rel_pos := closed_pos - pivot
	var new_pos := pivot + rot_basis * rel_pos
	var new_basis := rot_basis * _collision_closed_transform.basis
	
	collision_node.transform = Transform3D(new_basis, new_pos)
	_force_physics_update()

## StaticBody3D 물리 서버에 충돌 영역 변경을 강제 알림
func _force_physics_update() -> void:
	collision_node.disabled = false
	# StaticBody3D 부모의 transform을 다시 알려줘서 물리 서버 갱신
	var body := collision_node.get_parent()
	if body is StaticBody3D:
		PhysicsServer3D.body_set_state(
			body.get_rid(),
			PhysicsServer3D.BODY_STATE_TRANSFORM,
			body.global_transform
		)

func _kill_current_tween() -> void:
	if current_tween and current_tween.is_running():
		current_tween.kill()
