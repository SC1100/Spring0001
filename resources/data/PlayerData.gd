extends Resource
class_name PlayerData

## 플레이어의 전역 진행도 및 설정을 담는 리소스
## 로어북 규칙 준수: 데이터 주도 설계, 기능별 리소스 분리

@export_group("Progress")
@export var is_game_cleared: bool = false
@export var play_count: int = 0

@export_group("Settings")
@export var master_volume: float = 1.0
