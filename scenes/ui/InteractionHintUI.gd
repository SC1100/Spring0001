extends Control

## Interaction Hint UI
## 로어북 규칙 준수: 단순 UI 정적 제어

@onready var hint_label: Label = %HintLabel

func _ready() -> void:
	hide_hint()

func show_hint(text: String = "Press E to Interact") -> void:
	hint_label.text = text
	show()

func hide_hint() -> void:
	hide()
