extends CharacterBody3D

## Player Controller
## 로어북 규칙 준수: 이동 로직은 MovementComponent에 위임

# @onready를 사용하되, 타입 힌트를 Node로 낮추어 순환 참조나 로드 오류 방지
@onready var movement_component: Node = $MovementComponent

func _physics_process(delta: float) -> void:
	# 입력 벡터 계산 (WASD)
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# 카메라 방향에 맞춘 이동 방향 계산
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# 컴포넌트에 이동 위임
	if movement_component and movement_component.has_method("handle_movement"):
		movement_component.handle_movement(direction, delta)
	else:
		push_warning("MovementComponent를 찾을 수 없거나 handle_movement 메서드가 없습니다.")
