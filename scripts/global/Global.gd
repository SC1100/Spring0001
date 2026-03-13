extends Node

## Dear - 전역 데이터 허브
## 로어북 규칙 준수: 데이터 영속성 관리 및 user:// 경로 활용

var pet_data: PetData
var player_data: Resource # PlayerData (캐시 이슈 방지를 위해 Resource로 선언)
var media_registry: Array[String] = []

const PET_SAVE_PATH = "user://pet_save.tres"
const PLAYER_SAVE_PATH = "user://player_save.tres"

func _ready() -> void:
	_initialize_data()

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

## 세이브 데이터 저장
func save_game() -> void:
	var err_pet = ResourceSaver.save(pet_data, PET_SAVE_PATH)
	var err_player = ResourceSaver.save(player_data, PLAYER_SAVE_PATH)
	
	if err_pet == OK and err_player == OK:
		print("[Global] All game data saved.")
	else:
		push_error("[Global] Save failed. Pet: %s, Player: %s" % [err_pet, err_player])
