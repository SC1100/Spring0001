extends Node3D

## World Scene Controller
## 로어북 규칙 준수: 장면 진입 시 전역 페이드 인 처리

func _ready() -> void:
	# 전역 전환 효과 시도
	var transition = get_node_or_null("/root/SceneTransition")
	if transition:
		transition.fade_in(1.5)
	
	print("[World] Entry sequence: Fade-in triggered.")
