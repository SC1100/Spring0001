extends Node
class_name PetStatusComponent

## 애완동물의 실시간 상태 수치 및 변화를 관리하는 컴포넌트
## 로어북 규칙 준수: 데이터 주도 설계, 상태 관리 로직 분리

signal hunger_reached_threshold(value: float)
signal thirst_reached_threshold(value: float)
signal health_critical(value: float)

@export var data: PetData
@export var update_interval: float = 1.0 # 업데이트 주기 (성능 최적화)

var _timer: float = 0.0

func _ready() -> void:
	if not data:
		# 전역 데이터에서 가져오기 시도
		var global = get_node_or_null("/root/Global")
		if global and "pet_data" in global:
			data = global.pet_data
	
	if not data:
		push_warning("[PetStatus] PetData not assigned!")

func _process(delta: float) -> void:
	if not data: return
	
	_timer += delta
	if _timer >= update_interval:
		_update_stats(_timer)
		_timer = 0.0

func _update_stats(delta_time: float) -> void:
	# 1. 수치 자연 변화 (증가/감소)
	data.hunger = clamp(data.hunger + (data.hunger_rate * delta_time), 0, 100)
	data.thirst = clamp(data.thirst + (data.thirst_rate * delta_time), 0, 100)
	data.affection = clamp(data.affection - (data.affection_decay_rate * delta_time), 0, 100)
	
	# 2. 페널티 처리 (방치 시 체력 감소)
	if data.hunger >= 100.0 or data.thirst >= 100.0:
		data.health = clamp(data.health - (data.health_decay_rate * delta_time), 0, 100)
		if data.health < 20.0:
			health_critical.emit(data.health)
	
	# 3. 임계치 체크 및 시그널
	if data.hunger >= 70.0:
		hunger_reached_threshold.emit(data.hunger)
	if data.thirst >= 70.0:
		thirst_reached_threshold.emit(data.thirst)

## 외부 상호작용을 통한 수치 조정 (함수 호출 방식)
func add_hunger(amount: float) -> void:
	if data: data.hunger = clamp(data.hunger + amount, 0, 100)

func add_thirst(amount: float) -> void:
	if data: data.thirst = clamp(data.thirst + amount, 0, 100)

func add_affection(amount: float) -> void:
	if data: data.affection = clamp(data.affection + amount, 0, 100)
