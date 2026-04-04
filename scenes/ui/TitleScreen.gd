extends Control

## Title Screen Controller
## 로어북 규칙 준수: 상태 기반 연출, 데이터 연동

var exterior_cam: Camera3D
var interior_cam: Camera3D
@onready var menu_container: Control = $MenuContainer

# 전역 오토로드 인식 이슈 대응을 위한 동적 참조 함수
func get_transition():
	return get_node_or_null("/root/SceneTransition")

func _ready() -> void:
	# 마우스 커서 보이게 설정
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# 카메라 자동 검색 및 생성 (TitleScreen.tscn을 가볍게 유지하기 위함)
	exterior_cam = find_child("*ExteriorCam*", true, false)
	interior_cam = find_child("*InteriorCam*", true, false)
	
	# 외벽 시점용 카메라가 없다면 동적 생성 (설계도 중복 방지)
	if not exterior_cam:
		exterior_cam = Camera3D.new()
		exterior_cam.name = "ExteriorCam_Title"
		add_child(exterior_cam)
		# 플레이어가 문을 열기 전 바라보는 지점 (수치 최적화)
		exterior_cam.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(135)), Vector3(-13, 2, 17))
	
	if not interior_cam:
		# MainRoom 내부 카메라가 있다면 그것을 활용
		interior_cam = get_tree().get_nodes_in_group("MainRoomCamera").front() if get_tree().get_nodes_in_group("MainRoomCamera") else null
		if not interior_cam:
			interior_cam = Camera3D.new()
			interior_cam.name = "InteriorCam_Fallback"
			add_child(interior_cam)
			interior_cam.transform = Transform3D(Basis(), Vector3(0, 3, 7))
	
	print("[Title] View System Ready. Saved state will be applied via MainRoom.")
	_setup_view()
	
	var transition = get_transition()
	if transition:
		transition.fade_in(2.0)

func _setup_view() -> void:
	var player_data = Global.get("player_data")
	var cleared = player_data.is_game_cleared if player_data else false
	
	# 타이틀 배경의 플레이어 숨기기 (시점 방해 방지)
	var player = find_child("Player", true, false)
	if player:
		player.hide()
	
	if cleared:
		interior_cam.current = true
		exterior_cam.current = false
		print("[Title] Interior View Active. Global Pos: ", interior_cam.global_position)
	else:
		# 문 밖 시점
		exterior_cam.current = true
		interior_cam.current = false
		print("[Title] New game state: Exterior view")

func _on_enter_pressed() -> void:
	menu_container.hide()
	var transition = get_transition()
	if transition:
		await transition.fade_out(1.5)
	get_tree().change_scene_to_file("res://scenes/environment/World.tscn")

func _on_options_pressed() -> void:
	print("[Title] Options clicked.")

func _on_leave_pressed() -> void:
	get_tree().quit()
