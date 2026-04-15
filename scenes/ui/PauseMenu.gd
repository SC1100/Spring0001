extends CanvasLayer

@onready var color_rect = $ColorRect
@onready var resume_btn = $CenterContainer/VBoxContainer/ResumeButton
@onready var option_btn = $CenterContainer/VBoxContainer/OptionButton
@onready var leave_btn = $CenterContainer/VBoxContainer/LeaveButton

func _ready() -> void:
	visible = false
	resume_btn.pressed.connect(_on_resume_pressed)
	option_btn.pressed.connect(_on_option_pressed)
	leave_btn.pressed.connect(_on_leave_pressed)
	
	# 버튼 포커스 해제 (이동 키 등으로 실수로 눌러지는 것 방지)
	resume_btn.focus_mode = Control.FOCUS_NONE
	option_btn.focus_mode = Control.FOCUS_NONE
	leave_btn.focus_mode = Control.FOCUS_NONE

func _unhandled_input(event: InputEvent) -> void:
	# "ui_cancel"은 기본적으로 ESC 키와 매핑됩니다.
	if event.is_action_pressed("ui_cancel"):
		
		# 현재 씬이 TitleScreen이면 일시정지 작동 안함
		var current_scene = get_tree().current_scene
		if current_scene and current_scene.name == "TitleScreen":
			return
			
		# SceneTransition 진행 중이면 씹기
		var transition = get_node_or_null("/root/SceneTransition")
		if transition and transition.color_rect.color.a > 0.01:
			return 
			
		toggle_pause()

func toggle_pause() -> void:
	var new_state = not get_tree().paused
	get_tree().paused = new_state
	visible = new_state
	
	if new_state:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_resume_pressed() -> void:
	toggle_pause()

func _on_option_pressed() -> void:
	print("[PauseMenu] Option pressed (Not implemented yet)")

func _on_leave_pressed() -> void:
	# 1. 시뮬레이션 일시정지 해제 (트윈과 트랜지션 작동 허용)
	get_tree().paused = false
	visible = false
	
	# 2. 페이드 아웃 연출 시작
	var transition = get_node_or_null("/root/SceneTransition")
	if transition:
		await transition.fade_out(1.5)
	
	# 3. 타이틀 씬(World.tscn 안에 포함된 기존 타이틀 제어기) 부르기
	var global = get_node_or_null("/root/Global")
	if global:
		global.set("force_title_screen", true) # 확실하게 타이틀 화면이 뜨도록 강제
	get_tree().change_scene_to_file("res://scenes/environment/World.tscn")
	
	# 마우스 복원 및 페이드 인은 이후 로드되는 World.gd와 TitleController가 스스로 처리합니다.
