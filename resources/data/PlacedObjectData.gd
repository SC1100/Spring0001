extends Resource
class_name PlacedObjectData

## 배치된 오브젝트의 영속적 데이터를 담는 리소스
## 로어북 규칙 준수: 데이터 주도 설계

@export var node_name: String
@export var scene_path: String # 인스턴스 생성이 필요할 경우 대비
@export var position: Vector3
@export var rotation: Vector3
@export var media_path: String
