extends Node3D
class_name GroundFogComponent

## 근경 레이어 안개를 생성하는 컴포넌트
## 로어북 규칙 준수: 기능 분리, 실내 제외 로직 포함

@export var fog_radius: float = 100.0
@export var fog_height: float = 20.0
@export var center_exclusion_radius: float = 12.0
@export var fog_color: Color = Color(0.8, 0.9, 1.0)

var _mesh_instance: MeshInstance3D

func _ready() -> void:
	_create_fog_mesh()

func _create_fog_mesh() -> void:
	# 1. 메쉬 생성 (방 주위를 덮는 거대한 원통)
	_mesh_instance = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = fog_radius
	cylinder.bottom_radius = fog_radius
	cylinder.height = fog_height
	cylinder.flip_faces = true # 내부에서 보이도록 설정 (또는 cull_disabled)
	
	_mesh_instance.mesh = cylinder
	add_child(_mesh_instance)
	
	# 2. 쉐이더 재질 적용
	var mat = ShaderMaterial.new()
	mat.shader = load("res://scenes/shaders/GroundFog.gdshader")
	mat.set_shader_parameter("fog_color", fog_color)
	mat.set_shader_parameter("center_mask_radius", center_exclusion_radius)
	mat.set_shader_parameter("center_position", global_position)
	
	_mesh_instance.material_override = mat
	
	print("[GroundFog] Component initialized with exclusion radius: ", center_exclusion_radius)

## 실시간으로 안개 색상을 업데이트 (조명과 동기화용)
func update_fog_color(new_color: Color) -> void:
	if _mesh_instance and _mesh_instance.material_override:
		_mesh_instance.material_override.set_shader_parameter("fog_color", new_color)

## 실시간으로 안개 밀도를 업데이트
func update_fog_density(new_density: float) -> void:
	if _mesh_instance and _mesh_instance.material_override:
		_mesh_instance.material_override.set_shader_parameter("fog_density", new_density)
