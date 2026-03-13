extends Node
class_name DebugRestartTool

## 전용 리스타트 컴포넌트 (2회차 테스트용)
## 로어북 규칙 준수: 독립된 기능, 장면 전환 일원화

func restart_to_title(_interactor: Node3D = null) -> void:
	# 전역 전환 컴포넌트 활용
	var transition = get_node_or_null("/root/SceneTransition")
	if transition:
		await transition.fade_out(1.0)
	
	# 타이틀로 이동
	get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
	print("[Debug] Restarting to title...")
