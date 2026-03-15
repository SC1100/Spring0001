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

@export_group("Stats (0-100)")
@export var hunger: float = 0.0
@export var thirst: float = 0.0
@export var health: float = 100.0
@export var affection: float = 50.0

@export_group("Rates (Per Second)")
@export var hunger_rate: float = 0.01 # 초당 증가량
@export var thirst_rate: float = 0.015 # 초당 증가량
@export var health_decay_rate: float = 0.05 # 아사/갈증 시 체력 감소량
@export var affection_decay_rate: float = 0.005 # 방치 시 유대감 감소량

@export_group("Meta")
@export var created_at: int = 0
@export var last_visited: int = 0
