extends Node
class_name PlacementComponent

## 미디어 프레임 설치 시스템 컴포넌트
## 로어북 규칙 준수: 레이캐스트 활용, 프리뷰 연출, 독립적 기능 분리

@export_group("References")
@export var ray_cast: RayCast3D
@export var placement_ui: CanvasLayer
@export var placeable_scenes: Array[PackedScene] = []

@export_group("Settings")
@export var toggle_action: String = "key_b"

var is_ui_open: bool = false
var thumbnail_textures: Dictionary = {} # {index: Texture2D}

func _ready() -> void:
	_ensure_input_actions()
	
	if placement_ui:
		placement_ui.hide()
		# 버튼 시그널 연결
		var cube_btn = placement_ui.find_child("CubeBtn", true, false)
		var cyl_btn = placement_ui.find_child("CylinderBtn", true, false)
		var cancel_btn = placement_ui.find_child("CancelBtn", true, false)
		
		if cube_btn: cube_btn.pressed.connect(_on_spawn_selected.bind(0))
		if cyl_btn: cyl_btn.pressed.connect(_on_spawn_selected.bind(1))
		if cancel_btn: cancel_btn.pressed.connect(toggle_menu.bind(0))

	# 아이템 리스트 초기화 및 썸네일 생성 대기
	_init_item_list()
	call_deferred("_generate_thumbnails") # 씬이 준비된 후 비동기로 생성

func _init_item_list() -> void:
	if placeable_scenes.is_empty():
		placeable_scenes.append(load("res://scenes/environment/PlaceableCube.tscn"))
		placeable_scenes.append(load("res://scenes/environment/PlaceableCylinder.tscn"))

func _ensure_input_actions() -> void:
	if not InputMap.has_action(toggle_action):
		InputMap.add_action(toggle_action)
		var event = InputEventKey.new()
		event.physical_keycode = KEY_B
		InputMap.action_add_event(toggle_action, event)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(toggle_action):
		toggle_menu()

func toggle_menu(force_state: int = -1) -> void:
	if force_state == 1:
		is_ui_open = true
	elif force_state == 0:
		is_ui_open = false
	else:
		is_ui_open = !is_ui_open
		
	if is_ui_open:
		placement_ui.show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		placement_ui.hide()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_spawn_selected(index: int) -> void:
	_spawn_object(index)
	toggle_menu(0)

func _spawn_object(index: int) -> void:
	if index >= placeable_scenes.size(): return
	
	var scene = placeable_scenes[index]
	var new_obj = scene.instantiate()
	get_tree().current_scene.add_child(new_obj)
	
	var camera = get_viewport().get_camera_3d()
	if camera:
		var spawn_pos = camera.global_position + camera.global_transform.basis.z * -2.0
		new_obj.global_position = spawn_pos
		new_obj.global_rotation.y = camera.global_rotation.y
	
	print("[Placement] Object spawned: ", new_obj.name)

## [핵심] 고도 엔진 내부에서 실시간으로 스냅샷을 찍어 아이콘을 생성하는 로직
func _generate_thumbnails() -> void:
	print("[Placement] Generating thumbnails internally (Fresh Viewport per Item)...")
	
	for i in range(placeable_scenes.size()):
		# 1. 매 아이템마다 완전히 새로운 가상 스튜디오 생성 (잔상 원천 차단)
		var studio = SubViewport.new()
		studio.size = Vector2i(256, 256)
		studio.transparent_bg = true
		studio.own_world_3d = true
		studio.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(studio)
		
		# 2. 카메라 및 환경 설정 (고도 기본 월드와 흡사한 세팅)
		var cam = Camera3D.new()
		cam.transform = Transform3D(Basis.from_euler(Vector3(deg_to_rad(-30), deg_to_rad(45), 0)), Vector3(2.5, 2.0, 2.5))
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = 2.5
		
		var env = Environment.new()
		env.background_mode = Environment.BG_CANVAS
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		var sky = Sky.new()
		sky.sky_material = ProceduralSkyMaterial.new()
		env.sky = sky
		env.ambient_light_energy = 1.0
		cam.environment = env
		studio.add_child(cam)
		
		# 3. 부드러운 태양광 추가
		var sun = DirectionalLight3D.new()
		sun.quaternion = Quaternion(Vector3(1, -1, -0.5).normalized(), 0.0)
		sun.light_energy = 1.0
		sun.shadow_enabled = false
		studio.add_child(sun)
		
		# 4. 대상 물체 소환
		var instance = placeable_scenes[i].instantiate() as Node3D
		studio.add_child(instance)
		instance.global_position = Vector3.ZERO
		
		# 5. 렌더링 완료 대기 (2프레임 + Post Draw)
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		
		# 6. 촬영 및 저장
		var img = studio.get_texture().get_image()
		if img and not img.is_empty():
			var tex = ImageTexture.create_from_image(img)
			thumbnail_textures[i] = tex
			_apply_icon_to_button(i, tex)
			print("[Placement] Thumbnail %d generated with fresh viewport." % i)
		else:
			print("[Placement] Error: Failed to capture thumbnail for %d" % i)
		
		# 7. 스튜디오 완전 파괴 (다음 아이템을 위해 도화지를 완전히 새로 갈아 끼움)
		studio.queue_free()
		await get_tree().process_frame # 파괴 처리 대기
	
	print("[Placement] All thumbnails generated successfully.")

func _apply_icon_to_button(index: int, tex: Texture2D) -> void:
	if not placement_ui: return
	
	var button_name = "CubeBtn" if index == 0 else "CylinderBtn"
	var btn = placement_ui.find_child(button_name, true, false) as Button
	if btn:
		btn.icon = tex
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		# 텍스트와 아이콘 공존을 위해 조절
		btn.custom_minimum_size = Vector2(160, 180)
