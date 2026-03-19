extends Node
class_name RealTimeSkyComponent

## 사실적 천체 궤적 계산 컴포넌트 (비주얼/환경 설정 제외)
## 로어북 규칙 준수: 기능 최소화, 사용자 환경 설정(WorldEnvironment) 보호

@export_group("Target Nodes")
@export var sun_light: DirectionalLight3D
@export var moon_light: DirectionalLight3D

@export_group("Lighting Settings")
@export var day_intensity: float = 1.2
@export var night_intensity: float = 0.2
@export var sun_color: Color = Color(1.0, 0.95, 0.8)
@export var sunset_color: Color = Color(1.0, 0.4, 0.2)
@export var moon_color: Color = Color(0.6, 0.7, 1.0)

@export_group("Sky Parameters")
@export var latitude: float = 50.0
@export var lunar_day: float = 14.0

@export_group("Debug Settings")
@export var debug_time_offset: float = 0.0

var current_time_seconds: float = 0.0

func _ready() -> void:
	add_to_group("RealTimeSky")
	if not sun_light:
		sun_light = get_parent().find_child("DirectionalLight3D", true, false)
	if not moon_light:
		moon_light = get_parent().find_child("MoonLight", true, false)
	
	update_sky(true)

func _process(_delta: float) -> void:
	update_sky()

func add_hour_offset(hours: float = 1.0) -> void:
	debug_time_offset += hours * 3600.0
	update_sky(true)

func update_sky(force: bool = false) -> void:
	var time = Time.get_time_dict_from_system()
	var new_seconds = fmod(time.hour * 3600 + time.minute * 60 + time.second + debug_time_offset, 86400.0)
	if new_seconds < 0: new_seconds += 86400.0
	
	if not force and int(new_seconds) == int(current_time_seconds):
		return
		
	current_time_seconds = new_seconds
	var day_ratio = current_time_seconds / 86400.0
	
	# 궤적 계산 (심플 버전: SE -> South -> SW 고정)
	var lat_rad = deg_to_rad(latitude)
	var hour_angle = (day_ratio - 0.5) * PI * 2.0
	
	# 태양 위치 (사용자 요청: 창문 방향인 남쪽(-Z)을 중심으로 남동에서 남서로 이동)
	var sun_pos = Vector3()
	sun_pos.x = - sin(hour_angle) # 동(+X)에서 서(-X)로 이동
	sun_pos.y = cos(hour_angle) * cos(lat_rad) # 고도
	sun_pos.z = - sin(lat_rad) # 남쪽(-Z) 오프셋으로 SE-SW 궤적 형성
	sun_pos = sun_pos.normalized()
	
	# 달 위치 (태양과 연동하되 월령 오프셋 적용)
	var lunar_offset = deg_to_rad(lunar_day * 12.2) 
	var moon_hour_angle = hour_angle - lunar_offset + PI
	
	var moon_pos = Vector3()
	moon_pos.x = - sin(moon_hour_angle)
	moon_pos.y = cos(moon_hour_angle) * cos(lat_rad)
	moon_pos.z = - sin(lat_rad) # 동일한 남측 궤적
	moon_pos = moon_pos.normalized()
	
	if sun_light:
		sun_light.look_at(sun_light.global_position - sun_pos, Vector3.UP)
		_adjust_light_parameters(sun_light, sun_pos.y, day_intensity, sun_color, true)
		
	if moon_light:
		moon_light.look_at(moon_light.global_position - moon_pos, Vector3.UP)
		var moon_altitude = -sun_pos.y # 보수적 계산
		_adjust_light_parameters(moon_light, moon_altitude, night_intensity, moon_color, false)

func _adjust_light_parameters(light: DirectionalLight3D, altitude: float, max_intensity: float, base_color: Color, is_sun: bool) -> void:
	if altitude > -0.05:
		var factor = clamp(altitude / 0.5, 0.0, 1.0)
		light.light_energy = lerp(0.0, max_intensity, factor)
		
		if is_sun and altitude < 0.3:
			light.light_color = lerp(sunset_color, base_color, altitude / 0.3)
		else:
			light.light_color = base_color
		
		light.visible = true
		light.shadow_enabled = altitude > 0.0
	else:
		light.visible = false
		light.shadow_enabled = false
