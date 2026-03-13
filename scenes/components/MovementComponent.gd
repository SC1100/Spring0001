extends Node

## CharacterBody3D 이동을 담당하는 컴포넌트
## 로어북 규칙 준수: 결합도 최소화, 데이터 주도 설계

@export_group("Settings")
@export var speed: float = 5.0
@export var acceleration: float = 10.0
@export var friction: float = 10.0

@onready var body: CharacterBody3D = get_parent() as CharacterBody3D

func handle_movement(direction: Vector3, delta: float) -> void:
	if not body:
		return
	
	var target_velocity = direction * speed
	
	# 중력 적용 (기본적인 3D 이동을 위해)
	if not body.is_on_floor():
		body.velocity.y -= 9.8 * delta
	
	# 수평 이동 가속/감속
	if direction != Vector3.ZERO:
		var horizontal_vel = Vector2(body.velocity.x, body.velocity.z)
		var target_horizontal = Vector2(target_velocity.x, target_velocity.z)
		horizontal_vel = horizontal_vel.lerp(target_horizontal, acceleration * delta)
		body.velocity.x = horizontal_vel.x
		body.velocity.z = horizontal_vel.y
	else:
		var horizontal_vel = Vector2(body.velocity.x, body.velocity.z)
		horizontal_vel = horizontal_vel.lerp(Vector2.ZERO, friction * delta)
		body.velocity.x = horizontal_vel.x
		body.velocity.z = horizontal_vel.y
	
	body.move_and_slide()
