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
	
	# 카메라 자동 검색 (사용자가 이름을 바꿔도 Exterior/Interior 포함된 노드를 찾음)
	exterior_cam = find_child("*ExteriorCam*", true, false)
	interior_cam = find_child("*InteriorCam*", true, false)
	
	# 안전장치: 카메라를 못 찾았을 경우 새로 생성하거나 기본값 할당
	if not interior_cam and has_node("MainRoom/Geometry"):
		interior_cam = Camera3D.new()
		interior_cam.name = "InteriorCam_Fallback"
		$MainRoom/Geometry.add_child(interior_cam)
		interior_cam.transform = Transform3D(Basis(), Vector3(0, 3, 7))
	
	print("[Title] Cameras assigned. Exterior: ", exterior_cam != null, " Interior: ", interior_cam != null)
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
		# 방 안에서 창문을 바라보는 시점
		interior_cam.current = true
		exterior_cam.current = false
		# 창문 중앙 위치를 향하도록 정밀하게 조정
		interior_cam.look_at(Vector3(0, 3.5, -12), Vector3.UP)
		print("[Title] Cleared state: Interior view (Facing Window)")
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
