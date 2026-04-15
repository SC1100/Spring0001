extends Node
class_name MediaFrameComponent

## Media Frame Logic Component
## 로어북 규칙 준수: 순수 로직 분리, 컴포넌트 지향

@export var billboard_viewer: BillboardViewerComponent
@export var interactable: Interactable

@onready var file_dialog: FileDialog = $FileDialog

var is_viewer_open: bool = false
var last_interactor: Node3D
@export var default_texture: Texture2D # 추가: 에디터에서 등록 가능한 기본 번들 미디어
var registered_texture: Texture2D # 등록된 미디어 저장
var registered_media_path: String # 세이브용 경로 저장

func _ready() -> void:
	# 자동 할당 시도 (할당 안 된 경우 자식/형제 검색)
	if not billboard_viewer:
		billboard_viewer = get_parent().find_child("*BillboardViewer*", true, false)
	
	if not interactable:
		interactable = get_parent().find_child("*Interactable*", true, false)
		
	if interactable:
		interactable.interacted.connect(_on_interacted)
	
	# [중요] D3D12 환경에서의 충돌 방지를 위해 내장 탐색기 강제 사용
	if file_dialog:
		file_dialog.use_native_dialog = false
		file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		file_dialog.filters = PackedStringArray(["*.png, *.jpg, *.jpeg, *.hdr ; Images"])
		
		# 탐색기 중에도 일시정지에 구애받지 않도록 설정 및 취소 시그널 연결 (조작 잠금용)
		file_dialog.process_mode = Node.PROCESS_MODE_ALWAYS
		if not file_dialog.canceled.is_connected(_on_file_dialog_canceled):
			file_dialog.canceled.connect(_on_file_dialog_canceled)
		
	# 저장된 경로가 있다면 자동 로드, 없다면 기본 텍스처 사용
	if not registered_media_path.is_empty():
		load_media_from_path(registered_media_path)
	elif default_texture:
		registered_texture = default_texture
		
	print("[MediaFrameComponent] Ready. Viewer: ", (str(billboard_viewer.name) if billboard_viewer else "Missing"))

func load_media_from_path(path: String) -> void:
	if FileAccess.file_exists(path):
		var image = Image.load_from_file(path)
		if image:
			registered_texture = ImageTexture.create_from_image(image)
			registered_media_path = path # 경로 동기화
			print("[MediaFrameComponent] Media restored from: ", path)

var interaction_start_pos: Vector3 = Vector3.ZERO

func _process(_delta: float) -> void:
	if is_viewer_open and last_interactor and interactable:
		# [수정] 거대한 물체의 중심점 대신, 플레이어가 상호작용을 시작한 위치를 기준으로 도망가는지 판정
		var dist = interaction_start_pos.distance_to(last_interactor.global_position)
		if dist > interactable.interact_distance_limit + 1.0: # 플레이어가 해당 자리에서 1m 이상 벗어나면 끄기
			_close_viewer()

var _ignore_next_interact: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if is_viewer_open and event.is_action_pressed("interact"):
		_close_viewer()
		_ignore_next_interact = true
		get_viewport().set_input_as_handled()

func _on_interacted(interactor: Node3D, is_long_press: bool) -> void:
	if _ignore_next_interact and not is_long_press:
		_ignore_next_interact = false
		return
		
	last_interactor = interactor
	if is_instance_valid(interactor):
		interaction_start_pos = interactor.global_position
	
	if is_long_press:
		# 롱 프레스: 무조건 파일 탐색기 (교체)
		_open_file_dialog()
	else:
		# 짧은 클릭: 등록 여부에 따라 분기
		if registered_texture:
			if is_viewer_open:
				_close_viewer()
			else:
				_open_viewer(registered_texture)
		else:
			# 미등록 상태면 탐색기 오픈
			_open_file_dialog()

func _open_file_dialog() -> void:
	if file_dialog:
		# 엔진 시뮬레이션을 멈춰 키보드 입력(WASD 이동, 시야 이동 등) 방지
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		file_dialog.popup_centered()

func _on_file_dialog_canceled() -> void:
	# X 누르거나 취소 시 조작 복구
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
signal media_changed(new_path: String)

func _on_file_selected(path: String) -> void:
	# 정상 선택 시 조작 복구
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	var image = Image.load_from_file(path)
	if image:
		registered_texture = ImageTexture.create_from_image(image)
		registered_media_path = path # 경로 저장 (세이브 시 활용)
		_open_viewer(registered_texture)
		
		media_changed.emit(path)
		
		var global = get_node_or_null("/root/Global")
		if global:
			if global.has_method("register_media"):
				global.register_media(path)
			if global.has_method("save_game"):
				global.save_game(true) # 사진이 등록되면 즉시 세이브를 발동하여 영속성화

func _open_viewer(texture: Texture2D) -> void:
	if billboard_viewer and last_interactor:
		is_viewer_open = true
		# [수정] 배치는 이제 BillboardViewerComponent 내부에서 공통으로 처리합니다.
		billboard_viewer.show_media(texture, last_interactor)

func _close_viewer() -> void:
	if not is_viewer_open: return
	is_viewer_open = false
	if billboard_viewer:
		billboard_viewer.hide_media()
