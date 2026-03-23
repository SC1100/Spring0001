extends Node
class_name RealTimeSkyComponent

## 사실적 천체 궤적 및 다중 파노라마 블렌딩 마스터 컴포넌트
## 로어북 규칙 준수: 기능 최소화, 사용자 환경 설정(WorldEnvironment) 보호

@export_group("Target Nodes")
@export var sun_light: DirectionalLight3D
@export var moon_light: DirectionalLight3D
@export var target_env: WorldEnvironment ## [수동] 인스펙터에서 WorldEnvironment를 여기에 드래그하거나 'world_env' 그룹을 설정하세요.

@export_group("Lighting Settings")
@export var day_intensity: float = 1.2
@export var night_intensity: float = 0.05
@export var sun_color: Color = Color(1.0, 0.95, 0.8)
@export var sunset_color: Color = Color(1.0, 0.4, 0.2)
@export var moon_color: Color = Color(0.6, 0.7, 1.0)

@export_group("Panorama Textures")
@export var night_texture: Texture2D
@export var dawn_texture: Texture2D
@export var day_texture: Texture2D
@export var sunset_texture: Texture2D

@export_group("Time Point Settings", "tp_")
@export_range(0, 24) var tp_night: float = 0.0
@export_range(0, 24) var tp_dawn: float = 6.0
@export_range(0, 24) var tp_day: float = 12.0
@export_range(0, 24) var tp_sunset: float = 18.0
@export_range(0, 10) var tp_blend_duration: float = 4.0 ## 전환(블렌딩)이 일어나는 총 시간 (예: 2.0 = 해당 시각 전후 1시간)

@export_group("Dynamic Rotation", "rot_")
@export var rot_sync_with_sun: bool = true ## 태양/달의 위치에 맞춰 하늘을 회전시킵니다.
@export var rot_dawn: Vector3 = Vector3(0, 3.232, 0)
@export var rot_day: Vector3 = Vector3(0, 3.232, 0)
@export var rot_sunset: Vector3 = Vector3(0, 3.232, 0)
@export var rot_night: Vector3 = Vector3(0, 3.232, 0)
@export var rot_sun_offset: float = 0.0 ## 텍스처 내 태양 위치 보정 (라디안)

@export_group("Environment Settings")
@export var day_exposure: float = 1.0
@export var night_exposure: float = 0.3
@export var day_bg_energy: float = 1.0
@export var night_bg_energy: float = 0.4

@export_group("Sky Parameters")
@export var latitude: float = 50.0

@export_group("Debug Settings")
@export var debug_time_offset: float = 0.0

var current_time_seconds: float = 0.0

func _ready() -> void:
	add_to_group("RealTimeSky")
	
	if not target_env:
		var envs = get_tree().get_nodes_in_group("world_env")
		if envs.size() > 0:
			target_env = envs[0]
	
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
	var hour_float = current_time_seconds / 3600.0
	
	# 궤적 계산
	var lat_rad = deg_to_rad(latitude)
	var hour_angle = (day_ratio - 0.5) * PI * 2.0
	
	# 태양 위치
	var sun_pos = Vector3()
	sun_pos.x = sin(hour_angle)
	sun_pos.y = cos(hour_angle) * cos(lat_rad)
	sun_pos.z = - sin(lat_rad)
	sun_pos = sun_pos.normalized()
	
	_update_lighting(sun_pos)
	_update_environment(sun_pos, hour_float)

func _update_lighting(sun_pos: Vector3) -> void:
	if sun_light:
		sun_light.look_at(sun_light.global_position - sun_pos, Vector3.UP)
		_adjust_light_parameters(sun_light, sun_pos.y, day_intensity, sun_color, true)
		
	if moon_light:
		var day_ratio = current_time_seconds / 86400.0
		var lat_rad = deg_to_rad(latitude)
		var moon_hour_angle = (day_ratio - 0.5) * PI * 2.0 + PI
		
		var moon_pos = Vector3()
		moon_pos.x = sin(moon_hour_angle)
		moon_pos.y = cos(moon_hour_angle) * cos(lat_rad)
		moon_pos.z = - sin(lat_rad)
		moon_pos = moon_pos.normalized()
		
		moon_light.look_at(moon_light.global_position - moon_pos, Vector3.UP)
		_adjust_light_parameters(moon_light, moon_pos.y, night_intensity, moon_color, false)

func _update_environment(sun_pos: Vector3, hour: float) -> void:
	if not target_env or not target_env.environment: return
	
	var env = target_env.environment
	var env_factor = clamp((sun_pos.y + 0.1) / 0.4, 0.0, 1.0)
	
	env.tonemap_exposure = lerp(night_exposure, day_exposure, env_factor)
	env.background_energy_multiplier = lerp(night_bg_energy, day_bg_energy, env_factor)
	
	if env.sky and env.sky.sky_material is ShaderMaterial:
		var mat = env.sky.sky_material as ShaderMaterial
		
		# [개선] 지정한 시각 전후로 반짝 블렌딩하는 로직
		var half_d = tp_blend_duration / 2.0
		var tex1 = null
		var tex2 = null
		var rot1 = Vector3.ZERO
		var rot2 = Vector3.ZERO
		var blend = 0.0
		
		# 1. 밤 -> 새벽 (tp_dawn 전후)
		if hour >= tp_dawn - half_d and hour < tp_dawn:
			tex1 = night_texture; tex2 = dawn_texture
			rot1 = rot_night; rot2 = rot_dawn
			blend = (hour - (tp_dawn - half_d)) / half_d
		# 2. 새벽 -> 낮 (tp_dawn ~ tp_dawn + half_d)
		elif hour >= tp_dawn and hour < tp_dawn + half_d:
			tex1 = dawn_texture; tex2 = day_texture
			rot1 = rot_dawn; rot2 = rot_day
			blend = (hour - tp_dawn) / half_d
		# 3. 낮 유지 (tp_dawn + half_d ~ tp_sunset - half_d)
		elif hour >= tp_dawn + half_d and hour < tp_sunset - half_d:
			tex1 = day_texture; tex2 = day_texture
			rot1 = rot_day; rot2 = rot_day
			blend = 0.0
		# 4. 낮 -> 노을 (tp_sunset 전후)
		elif hour >= tp_sunset - half_d and hour < tp_sunset:
			tex1 = day_texture; tex2 = sunset_texture
			rot1 = rot_day; rot2 = rot_sunset
			blend = (hour - (tp_sunset - half_d)) / half_d
		# 5. 노을 -> 밤 (tp_sunset ~ tp_sunset + half_d)
		elif hour >= tp_sunset and hour < tp_sunset + half_d:
			tex1 = sunset_texture; tex2 = night_texture
			rot1 = rot_sunset; rot2 = rot_night
			blend = (hour - tp_sunset) / half_d
		# 6. 밤 유지 
		else:
			tex1 = night_texture; tex2 = night_texture
			rot1 = rot_night; rot2 = rot_night
			blend = 0.0
		
		# 텍스처 및 기본 회전 전달
		if tex1: mat.set_shader_parameter("source_sky", tex1)
		if tex2: mat.set_shader_parameter("target_sky", tex2)
		mat.set_shader_parameter("mix_amount", clamp(blend, 0.0, 1.0))
		
		# 태양 궤적 동기화 회전 계산 (Y축)
		if rot_sync_with_sun:
			var sun_yaw = atan2(sun_pos.x, sun_pos.z)
			
			# 밤하늘용 보정: 사용자 요청에 따라 밤 텍스처(Night)에 대해서는 수평 위치를 반전 연산(-sun_yaw)합니다.
			var yaw1 = -sun_yaw if tex1 == night_texture else sun_yaw
			var yaw2 = -sun_yaw if tex2 == night_texture else sun_yaw
			
			mat.set_shader_parameter("source_rotation", rot1 + Vector3(0, yaw1 + rot_sun_offset, 0))
			mat.set_shader_parameter("target_rotation", rot2 + Vector3(0, yaw2 + rot_sun_offset, 0))
		else:
			mat.set_shader_parameter("source_rotation", rot1)
			mat.set_shader_parameter("target_rotation", rot2)

func _adjust_light_parameters(light: DirectionalLight3D, altitude: float, max_intensity: float, base_color: Color, is_sun: bool) -> void:
	if altitude > -0.05:
		var factor = clamp(altitude / 0.5, 0.0, 1.0)
		light.light_energy = lerp(0.0, max_intensity, factor)
		if is_sun and altitude < 0.3:
			light.light_color = lerp(sunset_color, base_color, altitude / 0.3)
		else:
			light.light_color = base_color
		light.visible = true
	else:
		light.visible = false
