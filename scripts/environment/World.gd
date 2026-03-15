extends Node3D

## World Scene Controller
## 로어북 규칙 준수: 장면 진입 시 전역 페이드 인 처리

@onready var main_room: Node3D = $MainRoom

func _ready() -> void:
	# 1. 정보 획득
	var player = find_child("Player", true, false)
	var player_data = Global.player_data
	var cleared = player_data.is_game_cleared if player_data else false
	
	print("[World] Entry Check - Cleared Status: ", cleared)
	
	# 2. 타이틀 컨트롤러 및 힌트 UI 추가
	var title_scene = load("res://scenes/components/TitleControllerComponent.tscn")
	var title_controller = title_scene.instantiate()
	add_child(title_controller)
	
	var hint_scene = load("res://scenes/ui/InteractionHintUI.tscn")
	var hint_ui = hint_scene.instantiate()
	add_child(hint_ui)
	
	# 3. 타이틀 체크 및 설정 실행
	# TitleControllerComponent 내부에서 cleared 값에 따라 타이틀 노출 여부를 결정합니다.
	title_controller.setup_and_check(main_room, player)
	
	# 4. 전역 페이드 인
	var global_transition = get_node_or_null("/root/SceneTransition")
	if global_transition:
		global_transition.fade_in(1.5)
	
	print("[World] Entry sequence complete.")
