extends Node

## Dear - 게임 상태 관리자 (FSM)
## 로어북 규칙 준수: 중앙 집중식 흐름 제어

enum GameState {
	START,      # 초기 문/타이틀 (다이제틱)
	CUSTOMIZE,  # 애완동물 커스터마이징
	TRANSITION, # 하얀 방 (전이 단계)
	MEMORIAL    # 메인 기억 공간
}

signal state_changed(new_state: GameState)

var current_state: GameState = GameState.START

func _ready() -> void:
	print("[GameStateManager] Initialized at START state.")

func change_state(new_state: GameState) -> void:
	if current_state == new_state:
		return
		
	current_state = new_state
	state_changed.emit(new_state)
	print("[GameStateManager] State changed to: ", GameState.keys()[new_state])
	
	# 실제 씬 이동 로직은 나중에 씬 매니저나 여기서 직접 구현 가능
	_handle_scene_transition(new_state)

func _handle_scene_transition(state: GameState) -> void:
	match state:
		GameState.START:
			# get_tree().change_scene_to_file("res://scenes/environment/StartDoor.tscn")
			pass
		GameState.CUSTOMIZE:
			# get_tree().change_scene_to_file("res://scenes/ui/Customize.tscn")
			pass
		GameState.TRANSITION:
			# get_tree().change_scene_to_file("res://scenes/environment/WhiteRoom.tscn")
			pass
		GameState.MEMORIAL:
			get_tree().change_scene_to_file("res://scenes/environment/World.tscn")
