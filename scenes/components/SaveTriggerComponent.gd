extends Node
class_name SaveTriggerComponent

## Auto-Save Trigger Component
## 로어북 규칙 준수: 이벤트 기반 세이브, 모듈화

@export var target_nodes: Array[Node] = []
@export var signals_to_watch: Array[String] = ["dropped", "file_selected"]

func _ready() -> void:
	# 만약 런타임에 target_nodes가 비어있다면 부모를 기본 대상으로 설정
	if target_nodes.is_empty():
		target_nodes.append(get_parent())
		
	for node in target_nodes:
		if not node: continue
		for signal_name in signals_to_watch:
			if node.has_signal(signal_name):
				node.connect(signal_name, _on_save_triggered)

func _on_save_triggered(_arg1 = null, _arg2 = null) -> void:
	# 인자는 시그널마다 다를 수 있으므로 가변 인자 대응
	print("[SaveTrigger] Auto-save triggered by: ", get_parent().name)
	
	var global = get_node_or_null("/root/Global")
	if global and global.has_method("save_game"):
		global.save_game()
