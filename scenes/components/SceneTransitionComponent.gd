extends CanvasLayer

## Global Scene Transition Component
## 로어북 규칙 준수: 범용 컴포넌트화, 싱글톤처럼 활용 가능

signal transition_finished

@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	color_rect.color = Color(1, 1, 1, 0) # 투명한 흰색으로 시작
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

## 흰색으로 페이드 아웃 (화면이 가려짐)
func fade_out(duration: float = 1.0) -> void:
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, duration)
	await tween.finished
	transition_finished.emit()

## 흰색에서 페이드 인 (화면이 보임)
func fade_in(duration: float = 1.2) -> void:
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, duration)
	await tween.finished
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_finished.emit()
