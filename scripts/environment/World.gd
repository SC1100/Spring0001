extends Node3D

## World Scene Controller
## 로어북 규칙 준수: 장면 진입 시 전역 페이드 인 처리

@onready var main_room: Node3D = $MainRoom

func _ready() -> void:
	# 1. 정보 획득
	var player = find_child("Player", true, false)
	
	# 2. 타이틀 컨트롤러 컴포넌트 생성 및 추가
	var title_scene = load("res://scenes/components/TitleControllerComponent.tscn")
	var title_controller = title_scene.instantiate()
	add_child(title_controller)
	
	# 3. 타이틀 체크 및 설정 실행
	title_controller.setup_and_check(main_room, player)
	
	# 4. 전역 페이드 인
	var global_transition = get_node_or_null("/root/SceneTransition")
	if global_transition:
		global_transition.fade_in(1.5)
	
	print("[World] Entry sequence: Integrated Title Component initiated.")
