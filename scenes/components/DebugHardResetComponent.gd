extends Node
class_name DebugHardResetComponent

## 개발/테스트용 하드 리셋 트리거 컴포넌트
## 로어북 규칙 준수: 기능 격리, 배포 시 삭제 용이성 확보
## 나중에 이 파일과 관련 노드만 삭제하면 됩니다.

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		var global = get_node_or_null("/root/Global")
		if global and global.has_method("reset_all_data"):
			print("[DebugHardReset] Triggering full data wipe...")
			global.reset_all_data()
			
			# 현재 씬 리로드하여 초기 상태 적용
			get_tree().reload_current_scene()
