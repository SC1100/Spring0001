extends Node
class_name HighlightComponent

## Highlight Component
## 로어북 규칙 준수: 독립 노드, Material Overlay 방식 활용, 광범위 검색

@export var enabled_by_default: bool = false
@export var outline_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var outline_width: float = 2.0

var mesh_instances: Array = [] # GeometryInstance3D들을 담음
var outline_material: ShaderMaterial

func _ready() -> void:
	# 1. 쉐이더 재질 로드/생성
	var shader_path = "res://resources/shaders/outline_shader.gdshader"
	if FileAccess.file_exists(shader_path):
		outline_material = ShaderMaterial.new()
		outline_material.shader = load(shader_path)
		outline_material.set_shader_parameter("outline_color", outline_color)
		outline_material.set_shader_parameter("outline_width", outline_width)
	
	# 2. 메쉬 검색 범위 확대 (부모 노드 전체 계층)
	_find_meshes_in_parent_tree()
	
	# 3. 초기 상태 설정
	set_highlight(enabled_by_default)

func _find_meshes_in_parent_tree() -> void:
	mesh_instances.clear()
	var search_root = get_parent()
	if not search_root: return
	
	_recursive_search(search_root)
	
	# 만약 부모 노드에서 메쉬를 못 찾았다면 (예: Interactable 부식에 붙었을 경우)
	# 조부모 노드(실제 물체 루트)까지 범위를 넓혀서 재탐색
	if mesh_instances.is_empty() and search_root.get_parent():
		search_root = search_root.get_parent()
		_recursive_search(search_root)
	
	print("[HighlightComponent] Detected ", mesh_instances.size(), " meshes for: ", search_root.name)

func _recursive_search(node: Node) -> void:
	# GeometryInstance3D (Mesh, CSG 등) 은 모두 material_overlay를 가짐
	# Parse 에러 방지를 위해 문자열 체크나 has_method 활용 고려 가능하나
	# Godot 4 표준에서는 GeometryInstance3D 기반 체크가 권장됨.
	if node.has_method("set_material_overlay") or node is MeshInstance3D:
		mesh_instances.append(node)
	
	for child in node.get_children():
		if child == self: continue
		_recursive_search(child)

func set_highlight(is_enabled: bool) -> void:
	for mesh in mesh_instances:
		if is_enabled:
			mesh.material_overlay = outline_material
		else:
			mesh.material_overlay = null

func update_parameters(color: Color, width: float) -> void:
	outline_color = color
	outline_width = width
	if outline_material:
		outline_material.set_shader_parameter("outline_color", outline_color)
		outline_material.set_shader_parameter("outline_width", outline_width)
