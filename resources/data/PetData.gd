extends Resource
class_name PetData

## 애완동물 커스터마이징 데이터를 담는 리소스
## 로어북 규칙 준수: 데이터 주도 설계 및 객관적 명명

@export_group("Identity")
@export var pet_name: String = "Unnamed"

@export_group("Visuals")
@export var body_color: Color = Color.WHITE
@export var pattern_index: int = 0
@export var size_multiplier: float = 1.0

@export_group("Meta")
@export var created_at: int = 0
@export var last_visited: int = 0
