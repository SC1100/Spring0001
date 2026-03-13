extends Node
class_name Interactable

## 상호작용 가능한 객체에 부착하는 컴포넌트
## 로어북 규칙 준수: 시그널 업 (Signal Up) 방식 활용

signal interacted(interactor: Node3D)

@export var interaction_text: String = "Interact"

func interact(interactor: Node3D) -> void:
	interacted.emit(interactor)
	print("[Interactable] Interacted by: ", interactor.name)
