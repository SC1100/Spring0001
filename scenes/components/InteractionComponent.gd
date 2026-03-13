extends Node
class_name InteractionComponent

## 플레이어의 상호작용 감지 및 실행을 담당하는 컴포넌트
## 로어북 규칙 준수: 레이캐스트를 통한 결합도 해제

@export var interaction_ray: RayCast3D
@export var interaction_action: String = "interact"

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(interaction_action):
		_attempt_interaction()

func _attempt_interaction() -> void:
	if not interaction_ray or not interaction_ray.is_colliding():
		return
		
	var collider = interaction_ray.get_collider()
	if not collider:
		return
		
	print("[Interaction] Ray hit: ", collider.name)
		
	# 콜라이더의 자식 중 상호작용 가능한 컴포넌트 검색
	for child in collider.get_children():
		if child is Interactable or child.has_method("interact"):
			var dist = collider.global_position.distance_to(get_parent().global_position)
			var limit = child.get("interact_distance_limit") if child.has_method("get") else 2.0
			
			if dist <= limit:
				child.interact(get_parent())
				print("[Interaction] Success with: ", child.name)
				return
			else:
				print("[Interaction] Too far: ", dist, " > ", limit)
