extends Node
class_name DoorComponent

## Entrance Door Logic
## 로어북 규칙 준수: 장면 전환 시퀀스 및 화이트 페이드 활용
var interactable: Node

func _ready() -> void:
	interactable = find_child("Interactable", true, false)
	if not interactable:
		# 이름만으로 못 찾을 경우 타입으로 재검색
		for child in get_children():
			if child.has_method("interact"):
				interactable = child
				break
				
	if not interactable:
		push_error("[DoorComponent] Interactable child not found.")
		return
		
	if not interactable.interacted.is_connected(_on_door_interacted):
		interactable.interacted.connect(_on_door_interacted)
	print("[DoorComponent] Ready and connected to: ", interactable.name)

func _on_door_interacted(_interactor: Node3D) -> void:
	# 문 밖에서 상호작용하면 무조건 입장 시퀀스 시작 (테스트 편의성 및 자유도)
	_start_entrance_sequence()

func _start_entrance_sequence() -> void:
	# 씬 트리에 존재하는 SceneTransition 찾기 (Title에서 넘어올 때는 이미 처리됨)
	# 인게임에서 문을 나갔다 들어오는 로직은 나중에 추가
	print("[Door] Entrance sequence started.")
	
	# 전역 전환 효과 시도
	var transition = get_node_or_null("/root/SceneTransition")
	if transition:
		await transition.fade_out(1.5)
	
	# 방 안의 시작 위치로 플레이어 이동 (또는 씬 재시작)
	var player = get_tree().root.find_child("Player", true, false)
	if player:
		player.global_position = Vector3(-6, 2.5, 12.6) # 방 내부 시작점 (지형 고도 2m 반영)
		
	if transition:
		await transition.fade_in(1.0)

func _show_door_hint() -> void:
	print("[Door] The door is already unlocked or game cleared.")
