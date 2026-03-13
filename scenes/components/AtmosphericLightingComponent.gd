extends Node3D

## Atmospheric Lighting Component
## 로어북 규칙 준수: 환경 설정의 컴포넌트화, 분위기 제어 기능 분리

@export_group(" celestial Light")
@export var light_color: Color = Color(1.0, 0.95, 0.8)
@export var light_intensity: float = 2.0

@export_group("Environment")
@export var fog_enabled: bool = true
@export var fog_density: float = 0.01

@onready var directional_light: DirectionalLight3D = $DirectionalLight3D
@onready var world_environment: WorldEnvironment = $WorldEnvironment

func _ready() -> void:
	apply_settings()

func apply_settings() -> void:
	if directional_light:
		directional_light.light_color = light_color
		directional_light.light_energy = light_intensity
	
	if world_environment:
		var env = world_environment.environment
		env.volumetric_fog_enabled = fog_enabled
		env.volumetric_fog_density = fog_density

## 특정 기조(Mood)로 조명을 부드럽게 전환하는 함수 (추후 확장용)
func transition_to_mood(new_color: Color, new_intensity: float, duration: float = 2.0) -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(directional_light, "light_color", new_color, duration)
	tween.tween_property(directional_light, "light_energy", new_intensity, duration)
