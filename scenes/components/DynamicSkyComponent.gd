extends Node
class_name DynamicSkyComponent

## 다이내믹 스카이 쉐이더 제어 컴포넌트
## 로어북 규칙 준수: 기능 분리, 쉐이더 파라미터 관리 일원화

@export var world_env: WorldEnvironment
@export var shader_material: ShaderMaterial

func _ready() -> void:
	_setup_sky_material()

func _setup_sky_material() -> void:
	if not world_env:
		world_env = get_parent().find_child("WorldEnvironment", true, false)
	
	if not world_env or not world_env.environment:
		push_error("[DynamicSky] WorldEnvironment or Environment missing!")
		return
		
	# 쉐이더가 할당되지 않았다면 로드
	if not shader_material:
		shader_material = ShaderMaterial.new()
		shader_material.shader = load("res://scenes/shaders/DynamicSky.gdshader")
	
	# Sky 노드 생성 및 재질 적용
	var sky = Sky.new()
	sky.sky_material = shader_material
	world_env.environment.sky = sky
	world_env.environment.background_mode = Environment.BG_SKY
	
	print("[DynamicSky] Shader Component initialized and applied to Environment.")

## 외부(RealTimeSkyComponent 등)에서 태양 방향을 업데이트할 수 있는 인터페이스
func update_sun_direction(direction: Vector3) -> void:
	if shader_material:
		shader_material.set_shader_parameter("sun_direction", direction)
		# 달 방향은 반대 평면으로 설정
		shader_material.set_shader_parameter("moon_direction", -direction)
