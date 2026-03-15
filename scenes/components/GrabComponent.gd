extends Node
class_name GrabComponent

## Player-side Grab Logic
## 로어북 규칙 준수: 레이캐스트 활용, 부드러운 물리 연출(Lerp)

@export var interaction_ray: RayCast3D
@export var hold_point: Marker3D
@export var grab_action: String = "mouse_left" # 마우스 왼쪽 버튼 (InputMap 설정 필요)
@export var grab_distance_limit: float = 3.0 # 집기 가능한 최대 거리

var current_held_object: Node3D = null
var current_pickup_component: PickupComponent = null

func _ready() -> void:
	# InputMap에 마우스 왼쪽 버튼이 없다면 기본값 확인
	if not InputMap.has_action(grab_action):
		# 런타임에 액션 추가 (사용자가 에디터에서 안 했을 경우 대비)
		InputMap.add_action(grab_action)
		var event = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event(grab_action, event)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(grab_action):
		if current_held_object:
			_drop_object()
		else:
			_attempt_grab()

func _process(delta: float) -> void:
	if current_held_object and hold_point:
		# 물체를 HoldPoint 위치로 부드럽게 이동
		var target_pos = hold_point.global_position
		var target_rot = hold_point.global_rotation
		
		# lerp를 사용한 부드러운 추적
		current_held_object.global_position = current_held_object.global_position.lerp(target_pos, delta * 15.0)
		current_held_object.global_rotation = target_rot # 회전은 즉시 맞춤 (또는 slerp)

func _attempt_grab() -> void:
	if not interaction_ray or not interaction_ray.is_colliding():
		return
		
	var collider = interaction_ray.get_collider()
	if not collider: return
	
	# 상호작용 거리 체크
	var player_pos = get_parent().global_position
	var hit_pos = interaction_ray.get_collision_point()
	if player_pos.distance_to(hit_pos) > grab_distance_limit:
		return
	
	# PickupComponent 찾기 (노드 자신 또는 부모들 중에서만)
	# 로어북 규칙 준수: 결합도 최소화 및 정밀한 타겟팅
	var pc = null
	var current_node = collider
	
	# 부모 계층을 올라가며 PickupComponent가 있는지 확인
	# 재귀적 find_child를 쓰지 않는 이유는 공통 부모(MainRoom 등)에서 다른 물체의 컴포넌트를 찾는 것을 방지하기 위함
	while current_node and current_node != get_tree().root:
		pc = current_node.get_node_or_null("PickupComponent")
		if pc and pc is PickupComponent:
			break
		
		# 자식 중에서도 검색하되 '재귀 제외' (내 직속 부품만)
		pc = current_node.find_child("PickupComponent", false, false)
		if pc and pc is PickupComponent:
			break
			
		current_node = current_node.get_parent()
	
	if pc and pc is PickupComponent:
		# 실제 이동시킬 루트 노드 결정 (컴포넌트의 부모)
		current_held_object = pc.get_parent()
		current_pickup_component = pc
		current_pickup_component.pick_up(get_parent())
		
		# 물리 엔진 간섭 방지 (간략화)
		if current_held_object is StaticBody3D:
			# 이동을 위해 일시적으로 처리가 필요할 수 있음
			pass

func _drop_object() -> void:
	if current_pickup_component:
		current_pickup_component.drop()
	
	current_held_object = null
	current_pickup_component = null
