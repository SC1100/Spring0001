extends Node
class_name PickupComponent

## Pickup Capability Component
## 로어북 규칙 준수: 물리 상태와 시각적 상태의 분리 제어

signal picked_up(grabber: Node3D)
signal dropped

@export var hold_offset: Vector3 = Vector3(0, 0, -2.0)
@export var lerp_speed: float = 10.0

@export var freeze_delay: float = 2.0

var is_picked_up: bool = false
var current_grabber: Node3D = null
var is_waiting_for_impact: bool = false

func _ready() -> void:
	# 부모가 RigidBody3D인 경우 시그널 연결 준비
	var parent = get_parent()
	if parent is RigidBody3D:
		parent.body_entered.connect(_on_parent_body_entered)

func pick_up(grabber: Node3D) -> void:
	is_picked_up = true
	current_grabber = grabber
	is_waiting_for_impact = false
	
	var parent = get_parent()
	if parent is RigidBody3D:
		parent.freeze = true
		
	picked_up.emit(grabber)
	print("[PickupComponent] Picked up by: ", grabber.name)

func drop() -> void:
	var parent = get_parent()
	if parent is RigidBody3D:
		parent.freeze = false
		parent.contact_monitor = true
		parent.max_contacts_reported = 5
		
		# 드롭 직후 아주 짧게(0.1초) 충돌 감지 유예 (드롭 순간의 자기 충돌 방지)
		await get_tree().create_timer(0.1).timeout
		is_waiting_for_impact = true
		
	is_picked_up = false
	current_grabber = null
	dropped.emit()
	print("[PickupComponent] Dropped. Waiting for environment impact...")

func _on_parent_body_entered(body: Node) -> void:
	if not is_waiting_for_impact or is_picked_up:
		return
		
	# 플레이어와 닿은 것은 무시 (바닥이나 지형지물에 닿았을 때만 카운트)
	if body is CharacterBody3D or body.name.to_lower().contains("player"):
		return
		
	is_waiting_for_impact = false
	print("[PickupComponent] Environment impact detected (", body.name, "). Freezing in ", freeze_delay, "s...")
	
	# 지정된 시간 대기 후 고정
	await get_tree().create_timer(freeze_delay).timeout
	
	# 대기 시간 동안 플레이어가 다시 잡지 않았는지 최종 확인
	if not is_picked_up and not is_waiting_for_impact:
		var parent = get_parent()
		if parent is RigidBody3D:
			# 거의 멈췄을 때만 고정 (성능을 위해 2초면 충분히 멈춤)
			parent.freeze = true
			print("[PickupComponent] Delayed freeze applied.")
