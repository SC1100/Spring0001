extends CanvasLayer

## Debug Time UI
## 로어북 규칙 준수: 독립 노드, 글로벌 영향 최소화

@onready var skip_button: Button = $Control/SkipButton

func _ready() -> void:
	if skip_button:
		skip_button.pressed.connect(_on_skip_button_pressed)
		skip_button.text = "Skip 1 Hour (L Key)"

func _unhandled_input(event: InputEvent) -> void:
	# 'L' 키(Lighting)를 누르면 시간 스킵 발동
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_L:
			_on_skip_button_pressed()

func _on_skip_button_pressed() -> void:
	# SceneTree에서 실시간 하늘 컴포넌트 강제 검색
	# AtmosphericLighting 내에 있을 것으로 예상됨
	var sky = get_tree().get_nodes_in_group("RealTimeSky")
	
	if sky.size() > 0:
		sky[0].add_hour_offset(1.0)
	else:
		# 그룹에 없으면 수동 검색 시도
		var nodes = get_tree().root.find_children("*", "RealTimeSkyComponent", true, false)
		if nodes.size() > 0:
			nodes[0].add_hour_offset(1.0)
		else:
			print("[DebugTimeUI] RealTimeSkyComponent not found in current scene.")
