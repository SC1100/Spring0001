extends Node3D

## Atmospheric Lighting Component (Simplified)
## 로어북 규칙 준수: 환경 설정 충돌 방지, 순수 조명 제어 집중

@onready var sun_light: DirectionalLight3D = find_child("DirectionalLight3D", true, false)
@onready var moon_light: DirectionalLight3D = find_child("MoonLight", true, false)

func _ready() -> void:
	# 더 이상 WorldEnvironment를 제어하지 않습니다.
	# 모든 환경 설정은 메인 씬의 WorldEnvironment를 따릅니다.
	print("[AtmosphericLighting] Initialized as pure light control component.")
