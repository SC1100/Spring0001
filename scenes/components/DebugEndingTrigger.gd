extends Node
class_name DebugEndingTrigger

## 임시 엔딩 트리거 컴포넌트
## 로어북 규칙 준수: 독립된 컴포넌트, 디버그 기능의 모듈화

func _ready() -> void:
	if not find_child("HighlightComponent", true, false):
		var hc_script = load("res://scenes/components/HighlightComponent.gd")
		var hc = hc_script.new()
		hc.name = "HighlightComponent"
		add_child(hc)

func trigger_ending(_interactor: Node3D = null, _is_long: bool = false) -> void:
	var player_data = Global.get("player_data")
	if player_data:
		player_data.is_game_cleared = true
		Global.save_game()
		print("[Debug] Ending triggered. is_game_cleared saved as TRUE.")
