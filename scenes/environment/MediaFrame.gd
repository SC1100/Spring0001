extends StaticBody3D

## Media Trigger Frame (Shell)
## 로어북 규칙 준수: 컴포넌트에 기능 위임

@onready var interactable: Interactable = $Interactable

func _ready() -> void:
	# 상호작용 거리 늘리기 (높은 위치 고려)
	if interactable:
		interactable.interact_distance_limit = 4.0
		
	# 하이라이트 컴포넌트 자동 추가
	if not find_child("HighlightComponent", true, false):
		var hc_script = load("res://scenes/components/HighlightComponent.gd")
		var hc = hc_script.new()
		hc.name = "HighlightComponent"
		add_child(hc)

# 모든 실질적인 로직(파일 선택, 빌보드 제어)은 자식인 MediaFrameComponent가 담당합니다.
