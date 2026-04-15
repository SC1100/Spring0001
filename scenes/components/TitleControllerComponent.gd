extends CanvasLayer

## Title Controller Component
## 로어북 규칙 준수: 장면 통합 제어, 상태 기반 연동

signal game_started

@onready var title_ui: Control = %TitleUI
var interior_cam: Camera3D
var player: Node3D

func _ready() -> void:
	title_ui.hide()
	# 기본 마우스 모드는 캡처 (인게임용)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func setup_and_check(p_room: Node3D, p_player: Node3D) -> void:
	player = p_player
	interior_cam = p_room.find_child("InteriorCam", true, false)
	
	# 초기화: UI는 무조건 숨김
	title_ui.hide()
	
	# 클리어 데이터 확인 및 강제 타이틀 플래그 확인
	var player_data = Global.player_data
	var cleared = player_data.is_game_cleared if player_data else false
	var forced_title = Global.get("force_title_screen") if Global.get("force_title_screen") != null else false
	
	print("[TitleController] State Check - Cleared: ", cleared, " | Forced: ", forced_title)
	
	if cleared or forced_title:
		Global.set("force_title_screen", false) # 사용 후 초기화
		activate_title()
	else:
		# 1회차면 아무것도 안 함 (인게임 상태 유지)
		print("[TitleController] 1st Play: Staying in world.")

func activate_title() -> void:
	title_ui.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# 카메라 전환
	if interior_cam:
		interior_cam.current = true
	
	# 플레이어 일시 정지 및 숨기기
	if player:
		player.set_physics_process(false)
		player.set_process_input(false)
		player.hide()
	
	print("[TitleController] Activated Title View.")

func _on_enter_pressed() -> void:
	var transition = get_node_or_null("/root/SceneTransition")
	if transition:
		await transition.fade_out(1.5) # 0.5에서 1.5로 늦춤 (더 부드러운 전환)
	
	title_ui.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# 플레이어 복구
	if player:
		player.show()
		player.set_physics_process(true)
		player.set_process_input(true)
		var p_cam = player.find_child("Camera3D", true, false)
		if p_cam: p_cam.current = true
	
	if transition:
		await transition.fade_in(1.5) # 0.5에서 1.5로 늦춤
	
	game_started.emit()
	print("[TitleController] Game Started.")

func _on_options_pressed() -> void:
	print("[TitleController] Options clicked.")

func _on_leave_pressed() -> void:
	get_tree().quit()
