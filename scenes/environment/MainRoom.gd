extends Node3D

## MainRoom Script
## 로어북 규칙 준수: 상태 관리 및 라이프사이클 제어

func _ready() -> void:
	# 전역 세이브 데이터가 있다면 현재 방의 배치 상태 복구
	var global = get_node_or_null("/root/Global")
	if global and global.has_method("apply_scene_data"):
		global.apply_scene_data(self)
	
	print("[MainRoom] Ready and state applied.")
