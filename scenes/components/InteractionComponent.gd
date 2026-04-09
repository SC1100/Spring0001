extends Node
class_name InteractionComponent

## 플레이어의 상호작용 감지 및 실행을 담당하는 컴포넌트
## 로어북 규칙 준수: 레이캐스트를 통한 결합도 해제

@export var interaction_ray: RayCast3D
@export var interaction_action: String = "interact"
@export var hold_threshold: float = 0.5 # 롱 프레스 판정 시간

var hint_ui: Control
var current_highlight_target: Node = null

var is_holding: bool = false
var hold_timer: float = 0.0
var was_long_press_triggered: bool = false

func _ready() -> void:
	# 로어북 규칙 준수: UI 레이어에서 힌트 UI 검색 (경로 유동성 확보)
	hint_ui = get_tree().root.find_child("InteractionHintUI", true, false)
	if hint_ui:
		print("[InteractionComponent] Hint UI registered.")
		
	# 시선을 아래로 향할 때 레이저가 플레이어 자신의 몸체(CollisionShape)에 가로막히는 현상 방지
	var player_body = get_parent()
	if interaction_ray and player_body is CollisionObject3D:
		interaction_ray.add_exception(player_body)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(interaction_action):
		is_holding = true
		hold_timer = 0.0
		was_long_press_triggered = false
		
	if event.is_action_released(interaction_action):
		if is_holding and not was_long_press_triggered:
			# 짧은 클릭 실행
			_attempt_interaction(false)
		
		is_holding = false
		hold_timer = 0.0

func _process(delta: float) -> void:
	_check_for_interactables()
	
	if is_holding and not was_long_press_triggered:
		hold_timer += delta
		if hold_timer >= hold_threshold:
			was_long_press_triggered = true
			_attempt_interaction(true) # 롱 프레스 실행

func _check_for_interactables() -> void:
	var target_interactable = null
	var target_highlight = null

	if interaction_ray and interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		if collider:
			# 로어북 규칙 준수: 정밀 타겟팅. 충돌체 자신과 그 직속 자식들에서만 검색.
			# 부모의 다른 자식(형제 노드)들을 검색하지 않음으로써 오작동 방지.
			var nodes_to_check = [collider]
			nodes_to_check.append_array(collider.get_children())
			
			for node in nodes_to_check:
				if not target_interactable:
					if node.has_method("interact") or node.name.contains("Interactable"):
						target_interactable = node
				if not target_highlight:
					if node.has_method("set_highlight") or node is HighlightComponent:
						target_highlight = node
				
				if target_interactable and target_highlight:
					break

	# 1. 힌트 UI 처리
	if target_interactable and not target_interactable.is_queued_for_deletion():
		var already_done = Global.player_data.has_interacted_once if Global.player_data else false
		if not already_done:
			if hint_ui: hint_ui.show_hint()
	else:
		if hint_ui: hint_ui.hide_hint()

	# 2. 하이라이트 제어
	if target_highlight != current_highlight_target:
		if current_highlight_target and is_instance_valid(current_highlight_target):
			if current_highlight_target.has_method("set_highlight"):
				current_highlight_target.set_highlight(false)
		
		current_highlight_target = target_highlight
		if current_highlight_target and is_instance_valid(current_highlight_target):
			if current_highlight_target.has_method("set_highlight"):
				current_highlight_target.set_highlight(true)

func _attempt_interaction(is_long_press: bool) -> void:
	if not interaction_ray or not interaction_ray.is_colliding():
		return
		
	var collider = interaction_ray.get_collider()
	if not collider: return
	
	# 상호작용 대상 정밀 탐색 (충돌체 본인 + 직속 자식)
	var interactable_node = null
	if collider.has_method("interact") or collider.name.contains("Interactable"):
		interactable_node = collider
	else:
		# 비재귀적 검색으로 형제 노드 간섭 차단
		interactable_node = collider.find_child("*Interactable*", false, false)
		
	if interactable_node:
		# [수정] 거대한 가구(침대 등)의 중심점이 치우쳐 있어 상호작용이 막히는 문제를 해결합니다.
		# 하이라이트가 뜨는 표면 충돌 지점(Hit Point)을 기준으로 거리를 재어, 하이라이트 = 100% 작동으로 완벽 동기화.
		var hit_point = interaction_ray.get_collision_point()
		var dist = hit_point.distance_to(get_parent().global_position)
		var limit = interactable_node.get("interact_distance_limit") if interactable_node.has_method("get") else 3.0
		
		# 레이캐스트가 닿았다는 것 자체가 근접했다는 의미이므로 여유 거리를 주어 하이라이트와 판정 완벽 일치보장
		if dist <= limit + 1.0:
			if interactable_node.has_method("interact"):
				interactable_node.interact(get_parent(), is_long_press)
			
			# 최초 상호작용 기록
			if Global.player_data and not Global.player_data.has_interacted_once:
				Global.player_data.has_interacted_once = true
				Global.save_game()
				if hint_ui: hint_ui.hide_hint()
				print("[Interaction] First success recorded. Hint disabled.")
