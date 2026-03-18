extends Node
class_name RealTimeSkyComponent

## 실시간 시간 동기화 컴포넌트
## 로어북 규칙 준수: 기능 분리, 데이터 기반(Gradient/Curve) 보간 지향

@export_group("Target Nodes")
@export var sun_light: DirectionalLight3D
@export var moon_light: DirectionalLight3D # 달빛 연출용 (선택)
@export var world_env: WorldEnvironment

@export_group("Lighting Settings")
@export var day_intensity: float = 1.2
@export var night_intensity: float = 0.2
@export var sun_color: Color = Color(1.0, 0.95, 0.8) # 낮 태양색
@export var sunset_color: Color = Color(1.0, 0.4, 0.2) # 노을색
@export var moon_color: Color = Color(0.6, 0.7, 1.0) # 달빛 색

@export_group("Sky & Environment")
@export var latitude: float = 55.0 # 높은 위도 기준 (기존 37.5에서 상향)
@export var sky_top_day: Color = Color(0.3, 0.5, 0.9)
@export var sky_top_night: Color = Color(0.05, 0.05, 0.1)
@export var cloud_density_base: float = 0.5

@export_group("Debug Settings")
@export var debug_time_offset: float = 0.0 # 초 단위 오프셋

var current_time_seconds: float = 0.0

func _ready() -> void:
	add_to_group("RealTimeSky")
	# 초기화 시 타겟 자동 검색
	if not sun_light:
		sun_light = get_parent().find_child("DirectionalLight3D", true, false)
	if not moon_light:
		moon_light = get_parent().find_child("MoonLight", true, false)
	if not world_env:
		world_env = get_parent().find_child("WorldEnvironment", true, false)
	
	update_sky(true) # 즉시 적용

func _process(_delta: float) -> void:
	update_sky()

## 외부에서 시간을 1시간씩 넘길 때 사용할 디버그 함수
func add_hour_offset(hours: float = 1.0) -> void:
	debug_time_offset += hours * 3600.0
	print("[RealTimeSky] Debug Time Skip: +", hours, " hour(s). Total Offset: ", debug_time_offset / 3600.0, "h")
	update_sky(true)

func update_sky(force: bool = false) -> void:
	var time = Time.get_time_dict_from_system()
	var new_seconds = time.hour * 3600 + time.minute * 60 + time.second
	
	# 디버그 오프셋 적용 및 24시간 루프 처리
	new_seconds = fmod(new_seconds + debug_time_offset, 86400.0)
	if new_seconds < 0: new_seconds += 86400.0
	
	# 초 단위 변화가 있을 때만 업데이트 (성능 최적화)
	if not force and int(new_seconds) == int(current_time_seconds):
		return
		
	current_time_seconds = new_seconds
	
	# 0.0 ~ 1.0 비율 (00:00 ~ 24:00)
	var day_ratio = current_time_seconds / 86400.0
	
	# --- 태양 궤적 계산 (북반구/한국 위도 반영) ---
	# 시간각 (H): 정오(12시)에 0, 06시에 -PI/2, 18시에 +PI/2
	var hour_angle = (day_ratio - 0.5) * PI * 2.0
	var lat_rad = deg_to_rad(latitude)
	
	# 태양의 위치 벡터 (현재 메인룸 창문 방향인 -Z를 남쪽으로 설정)
	# 북반구에서는 태양이 남쪽(-Z) 하늘을 따라 이동함
	var sun_pos = Vector3()
	sun_pos.x = sin(hour_angle) # 동쪽(-X)에서 떠서 서쪽(+X)으로 이동
	sun_pos.y = cos(hour_angle) * cos(lat_rad) # 고도
	sun_pos.z = - cos(hour_angle) * sin(lat_rad)
	
	var moon_pos = - sun_pos # 달은 태양의 정반대
	
	if sun_light:
		# 빛의 방향은 태양 위치에서 원점을 바라보는 방향
		sun_light.look_at(sun_light.global_position - sun_pos, Vector3.UP)
		
	if moon_light:
		moon_light.look_at(moon_light.global_position - moon_pos, Vector3.UP)
		
	# 쉐이더 컴포넌트 업데이트
	var sky_shader = get_parent().find_child("DynamicSky", true, false)
	if sky_shader and sky_shader.has_method("update_sun_direction"):
		sky_shader.update_sun_direction(sun_pos.normalized())
	
	# 광량 및 색상 보간
	_adjust_light_parameters(day_ratio, sun_pos.y)

	# 2. 하늘 색상 보간
	_adjust_sky_parameters(day_ratio)

func _adjust_light_parameters(_ratio: float, sun_altitude: float) -> void:
	if not sun_light or not moon_light: return
	
	# --- 태양광 제어 ---
	if sun_altitude > -0.05:
		var sun_factor = clamp(sun_altitude / 0.5, 0.0, 1.0)
		sun_light.light_energy = lerp(0.0, day_intensity, sun_factor)
		
		if sun_altitude < 0.3:
			sun_light.light_color = lerp(sunset_color, sun_color, sun_altitude / 0.3)
		else:
			sun_light.light_color = sun_color
		
		sun_light.visible = true
		sun_light.shadow_enabled = sun_altitude > 0.0
	else:
		sun_light.visible = false
		sun_light.shadow_enabled = false
		
	# --- 달빛 제어 ---
	var moon_altitude = - sun_altitude
	if moon_altitude > -0.05:
		var moon_factor = clamp(moon_altitude / 0.5, 0.0, 1.0)
		moon_light.light_energy = lerp(0.0, night_intensity, moon_factor)
		moon_light.light_color = moon_color
		moon_light.visible = true
		moon_light.shadow_enabled = moon_altitude > 0.0
	else:
		moon_light.visible = false
		moon_light.shadow_enabled = false

func _adjust_sky_parameters(ratio: float) -> void:
	if not world_env or not world_env.environment: return
	
	var env = world_env.environment
	# 하늘 색상 및 조명 동기화를 위한 고도 계수
	var hour_angle = (ratio - 0.5) * PI * 2.0
	var altitude_factor = clamp(cos(hour_angle), -1.0, 1.0)
	var day_vibrancy = clamp(altitude_factor, 0, 1)
	
	# 3. 환경 및 색상 동기화 (안개 로직 완전 제거)
	env.volumetric_fog_enabled = false
	env.fog_enabled = false
	
	# 시간에 따른 앰비언트 광량 조절 (밤낮 느낌 복구)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = lerp(0.05, 0.4, day_vibrancy)
	env.ambient_light_color = Color(0.1, 0.1, 0.1)
	
	# 4. 하늘 색상 동기화 (DynamicSky 쉐이더 연동)
	var sky_node = get_parent().find_child("DynamicSky", true, false)
	if sky_node:
		var shader_mat = sky_node.get("shader_material") as ShaderMaterial
		if shader_mat:
			# 직접적인 색상 주입으로 회색화 방지 (상단/하단 모두 동기화)
			shader_mat.set_shader_parameter("day_top_color", sky_top_day)
			shader_mat.set_shader_parameter("day_bottom_color", Color(0.7, 0.85, 1.0)) # 지평선을 더 연하고 부드럽게
			shader_mat.set_shader_parameter("night_top_color", sky_top_night)
			shader_mat.set_shader_parameter("sunset_color", sunset_color)
