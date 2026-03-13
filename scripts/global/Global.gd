extends Node

## Dear - 전역 데이터 허브
## 로어북 규칙 준수: 데이터 영속성 관리 및 user:// 경로 활용

var pet_data: PetData
var media_registry: Array[String] = []

func _ready() -> void:
	_initialize_data()

func _initialize_data() -> void:
	# 기존 데이터 로드 시도 또는 새 데이터 생성
	pet_data = PetData.new()
	pet_data.created_at = int(Time.get_unix_time_from_system())
	print("[Global] Data initialized.")

## 미디어 경로 등록 (Lorebook: Privacy 보장)
func register_media(path: String) -> void:
	if not media_registry.has(path):
		media_registry.append(path)
		print("[Global] Media registered: ", path)

## 세이브 데이터 저장 (Lorebook: user:// 경로 활용)
func save_game() -> void:
	var save_path = "user://memorial_save.tres"
	var error = ResourceSaver.save(pet_data, save_path)
	if error == OK:
		print("[Global] Game saved to: ", save_path)
	else:
		push_error("[Global] Save failed: ", error)
