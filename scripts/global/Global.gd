extends Node

## Dear - 전역 데이터 허브
## 로어북 규칙 준수: 데이터 영속성 관리 및 user:// 경로 활용

var pet_data: PetData
var player_data: Resource # PlayerData (캐시 이슈 방지를 위해 Resource로 선언)
var media_registry: Array[String] = []
var force_title_screen: bool = false # 일시정지 메뉴에서 타이틀로 강제 회귀할 때 사용

const PET_SAVE_PATH = "user://pet_save.tres"
const PLAYER_SAVE_PATH = "user://player_save.tres"

func _ready() -> void:
	_initialize_data()
	
	# PauseMenu 자동 생성 및 부착 (모든 씬에서 작동하게 만듦)
	var pause_menu_scene = load("res://scenes/ui/PauseMenu.tscn")
	if pause_menu_scene:
		var pm_instance = pause_menu_scene.instantiate()
		add_child(pm_instance)
		print("[Global] PauseMenu instantiated automatically.")

func _initialize_data() -> void:
	# 플레이어 데이터 로드 또는 생성
	if ResourceLoader.exists(PLAYER_SAVE_PATH):
		player_data = ResourceLoader.load(PLAYER_SAVE_PATH)
		print("[Global] PlayerData loaded.")
	else:
		player_data = load("res://resources/data/PlayerData.gd").new()
		print("[Global] New PlayerData created.")

	# 펫 데이터 로드 또는 생성
	if ResourceLoader.exists(PET_SAVE_PATH):
		pet_data = ResourceLoader.load(PET_SAVE_PATH)
		print("[Global] PetData loaded.")
	else:
		pet_data = PetData.new()
		pet_data.created_at = int(Time.get_unix_time_from_system())
		print("[Global] New PetData created.")

## 미디어 경로 등록
func register_media(path: String) -> void:
	if not media_registry.has(path):
		media_registry.append(path)
		print("[Global] Media registered: ", path)

## 세이브 데이터 저장 (오토세이브 유도)
func save_game(should_gather: bool = true) -> void:
	# 1. 필요한 경우 현재 씬 상태 수집
	if should_gather:
		gather_scene_data()
	
	# 2. 파일 저장
	var err_pet = ResourceSaver.save(pet_data, PET_SAVE_PATH)
	var err_player = ResourceSaver.save(player_data, PLAYER_SAVE_PATH)
	
	if err_pet == OK and err_player == OK:
		print("[Global] Auto-save success.")
	else:
		push_error("[Global] Save failed. Pet: %s, Player: %s" % [err_pet, err_player])

## 현재 씬의 'Persistent' 그룹 오브젝트 상태 수집
func gather_scene_data() -> void:
	if not player_data: return
	
	player_data.placed_objects.clear()
	var persistent_nodes = get_tree().get_nodes_in_group("Persistent")
	
	for node in persistent_nodes:
		if node is Node3D:
			var data = load("res://resources/data/PlacedObjectData.gd").new()
			data.node_name = node.name
			data.position = node.global_position
			data.rotation = node.global_rotation
			
			# MediaFrameComponent가 있다면 미디어 경로 저장 (이름 뒤에 숫자가 붙었을 경우 대비)
			var media_comp = node.find_child("*MediaFrameComponent*", true, false)
			if media_comp and "registered_media_path" in media_comp:
				data.media_path = media_comp.registered_media_path
				
			player_data.placed_objects.append(data)
	
	print("[Global] Gathered ", player_data.placed_objects.size(), " persistent objects.")

## 저장된 데이터를 씬의 오브젝트들에 적용
func apply_scene_data(root_node: Node) -> void:
	if not player_data or player_data.placed_objects.is_empty():
		return
	
	print("[Global] Applying saved data to: ", root_node.name)
	for data in player_data.placed_objects:
		# 이름 기반으로 노드 검색 (고유 아이디나 절대 경로가 안전하나, 현재 구조에선 이름/그룹 활용)
		var target = root_node.find_child(data.node_name, true, false)
		if target and target is Node3D:
			target.global_position = data.position
			target.global_rotation = data.rotation
			
			# 미디어 복구
			var media_comp = target.find_child("*MediaFrameComponent*", true, false)
			if media_comp and not data.media_path.is_empty():
				if media_comp.has_method("load_media_from_path"):
					media_comp.load_media_from_path(data.media_path)
			
			# RigidBody3D인 경우 물리 엔진 안정화를 위해 상태 갱신 필요할 수 있음
			if target is RigidBody3D:
				target.freeze = true # 로드 직후엔 고정 상태로 시작 권장

## 모든 진행 데이터 초기화 (완전 리셋)
func reset_all_data() -> void:
	# 1. 새 데이터 객체 생성 (기존 파일 덮어쓰기 준비)
	player_data = load("res://resources/data/PlayerData.gd").new()
	
	# 펫 데이터 초기화
	pet_data = PetData.new()
	pet_data.created_at = int(Time.get_unix_time_from_system())
	
	# 2. 강제 저장 (현재 씬의 '더러운' 데이터를 수집하지 않고 빈 상태로 저장)
	save_game(false)
	print("[Global] All progress and object data has been HARD RESET.")
