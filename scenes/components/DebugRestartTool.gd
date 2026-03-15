extends Node
class_name DebugRestartTool

## 전용 리스타트 컴포넌트 (2회차 테스트용)
## 로어북 규칙 준수: 독립된 기능, 장면 전환 일원화

func _ready() -> void:
	if not find_child("HighlightComponent", true, false):
		var hc_script = load("res://scenes/components/HighlightComponent.gd")
		var hc = hc_script.new()
		hc.name = "HighlightComponent"
		add_child(hc)

func restart_to_title(_interactor: Node3D = null, _is_long: bool = false) -> void:
	# 전역 전환 컴포넌트 활용
	var transition = get_node_or_null("/root/SceneTransition")
	if transition:
		await transition.fade_out(1.0)
	
	# 월드 재시작 (통합 타이틀 컴포넌트가 로직 처리)
	get_tree().change_scene_to_file("res://scenes/environment/World.tscn")
	print("[Debug] Restarting to title...")
