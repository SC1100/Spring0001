extends Node
class_name MediaFrameComponent

## Media Frame Logic Component
## 로어북 규칙 준수: 순수 로직 분리, 컴포넌트 지향

@export var billboard_viewer: BillboardViewerComponent
@export var interactable: Interactable

@onready var file_dialog: FileDialog = $FileDialog

var is_viewer_open: bool = false
var last_interactor: Node3D
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
		
	# 저장된 경로가 있다면 자동 로드
	if not registered_media_path.is_empty():
		load_media_from_path(registered_media_path)
		
	print("[MediaFrameComponent] Ready. Viewer: ", (str(billboard_viewer.name) if billboard_viewer else "Missing"))

func load_media_from_path(path: String) -> void:
	if FileAccess.file_exists(path):
		var image = Image.load_from_file(path)
		if image:
			registered_texture = ImageTexture.create_from_image(image)
			registered_media_path = path # 경로 동기화
			print("[MediaFrameComponent] Media restored from: ", path)

func _process(_delta: float) -> void:
	if is_viewer_open and last_interactor and interactable:
		var dist = get_parent().global_position.distance_to(last_interactor.global_position)
		if dist > interactable.interact_distance_limit + 1.0: # 여유 거리 1m 추가
			_close_viewer()

func _on_interacted(interactor: Node3D, is_long_press: bool) -> void:
	last_interactor = interactor
	
	if is_long_press:
		# 롱 프레스: 무조건 파일 탐색기 (교체)
		if file_dialog:
			file_dialog.popup_centered()
	else:
		# 짧은 클릭: 등록 여부에 따라 분기
		if registered_texture:
			if is_viewer_open:
				_close_viewer()
			else:
				_open_viewer(registered_texture)
		else:
			# 미등록 상태면 탐색기 오픈
			if file_dialog:
				file_dialog.popup_centered()

signal media_changed(new_path: String)

func _on_file_selected(path: String) -> void:
	var image = Image.load_from_file(path)
	if image:
		registered_texture = ImageTexture.create_from_image(image)
		registered_media_path = path # 경로 저장 (세이브 시 활용)
		_open_viewer(registered_texture)
		
		media_changed.emit(path)
		
		var global = get_node_or_null("/root/Global")
		if global and global.has_method("register_media"):
			global.register_media(path)

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
