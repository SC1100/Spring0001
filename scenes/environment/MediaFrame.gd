extends StaticBody3D

## Media Trigger Frame
## 로어북 규칙 준수: UI 분리 및 거리 기반 상태 제어

@onready var interactable: Interactable = $Interactable
@onready var file_dialog: FileDialog = $FileDialog
@onready var viewer_instance: BillboardViewerComponent = $BillboardViewer

var is_viewer_open: bool = false
var last_interactor: Node3D

func _ready() -> void:
	interactable.interacted.connect(_on_interacted)
	# 인스턴스 초기화 상태 확인 (이미 씬에 존재하므로 위치만 확인)
	if viewer_instance:
		print("[MediaFrame] Viewer component linked.")

func _process(_delta: float) -> void:
	if is_viewer_open and last_interactor:
		var dist = global_position.distance_to(last_interactor.global_position)
		if dist > interactable.interact_distance_limit:
			_close_viewer()

func _on_interacted(interactor: Node3D) -> void:
	last_interactor = interactor
	
	if is_viewer_open:
		_close_viewer()
	else:
		file_dialog.popup_centered()

func _on_file_selected(path: String) -> void:
	var image = Image.load_from_file(path)
	if image:
		var texture = ImageTexture.create_from_image(image)
		_open_viewer(texture)
		
		var global = get_node_or_null("/root/Global")
		if global and global.has_method("register_media"):
			global.register_media(path)

func _open_viewer(texture: Texture2D) -> void:
	is_viewer_open = true
	viewer_instance.show_media(texture)

func _close_viewer() -> void:
	if not is_viewer_open: return
	is_viewer_open = false
	viewer_instance.hide_media()
