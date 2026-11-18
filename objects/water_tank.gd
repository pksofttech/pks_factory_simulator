extends StaticBody3D

signal valve_toggled_3d(open: bool)

@export var plc_mode: bool = false
@export var active: bool = false:
	set(value):
		active = value
		_update_indicator()

@export var level: float = 0.25
@export var low_threshold: float = 0.20
@export var mid_threshold: float = 0.50
@export var high_threshold: float = 0.85

@export var low_level: bool = true
@export var mid_level: bool = false
@export var high_level: bool = false
@export var level_percent: int = 25

@export var valve_open: bool = false:
	set(value):
		if valve_open == value:
			return
		valve_open = value
		_update_valve_visuals()

@export_range(0.0, 1.0, 0.01) var valve_opening: float = 1.0:
	set(value):
		valve_opening = clampf(value, 0.0, 1.0)
		_update_valve_visuals()

var _indicator_mat: StandardMaterial3D
var _low_led_mat: StandardMaterial3D
var _mid_led_mat: StandardMaterial3D
var _high_led_mat: StandardMaterial3D
var _valve_led_mat: StandardMaterial3D
var _last_blink: bool = false
var _valve_angle: float = PI * 0.5
var _loop_audio: AudioStreamPlayer3D

@onready var water_mesh: MeshInstance3D = get_node_or_null("WaterColumn")
@onready var indicator: MeshInstance3D = get_node_or_null("Indicator")
@onready var level_label: Label3D = get_node_or_null("LevelLabel")
@onready var low_led: MeshInstance3D = get_node_or_null("SensorsGroup/SensorLow/LowLED")
@onready var mid_led: MeshInstance3D = get_node_or_null("SensorsGroup/SensorMid/MidLED")
@onready var high_led: MeshInstance3D = get_node_or_null("SensorsGroup/SensorHigh/HighLED")
@onready var valve_handle: Node3D = get_node_or_null("OutletValveGroup/ValveHandlePivot")
@onready var valve_led: MeshInstance3D = get_node_or_null("OutletValveGroup/ValveLED")
@onready var valve_area: Area3D = get_node_or_null("OutletValveGroup/ValveArea")
@onready var drain_stream: MeshInstance3D = get_node_or_null("OutletValveGroup/DrainStream")
@onready var drain_splash: GPUParticles3D = get_node_or_null("OutletValveGroup/DrainSplash")
@onready var overflow_curtain: MeshInstance3D = get_node_or_null("OverflowCurtain")
@onready var overflow_splash: GPUParticles3D = get_node_or_null("OverflowSplash")
@onready var overflow_puddle: MeshInstance3D = get_node_or_null("OverflowPuddle")
var _built_stream_opening: float = -1.0
var _last_stream_opening: float = -1.0
var _last_visual_level: float = -1.0
var _last_label_text: String = ""
var _last_label_color: Color = Color.TRANSPARENT
var _overflow_amount: float = 0.0
var _puddle_amount: float = 0.0
var _overflowing: bool = false


func _ready() -> void:
	if indicator != null:
		_indicator_mat = indicator.material_override as StandardMaterial3D
	if low_led != null:
		_low_led_mat = low_led.material_override as StandardMaterial3D
	if mid_led != null:
		_mid_led_mat = mid_led.material_override as StandardMaterial3D
	if high_led != null:
		_high_led_mat = high_led.material_override as StandardMaterial3D
	if valve_led != null:
		_valve_led_mat = valve_led.material_override as StandardMaterial3D
	if valve_area != null:
		valve_area.input_event.connect(_on_valve_area_input)
	var fa := get_node_or_null("/root/FactoryAudio")
	if fa != null:
		_loop_audio = fa.call("attach_loop", self, "tank_loop", -14.0, 15.0) as AudioStreamPlayer3D
	_sync_level_sensors()
	_update_visuals()
	_update_indicator()
	_update_valve_visuals()


func _is_running() -> bool:
	var scene := get_parent()
	if scene != null:
		if scene.get("edit_mode") != null and bool(scene.get("edit_mode")):
			return false
		if scene.get("running") != null and not bool(scene.get("running")):
			return false
	return true


func _on_valve_area_input(_cam: Node, event: InputEvent, _pos: Vector3, _norm: Vector3, _idx: int) -> void:
	var scene := get_parent()
	if scene != null and scene.get("edit_mode") != null and bool(scene.get("edit_mode")):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		valve_open = not valve_open
		var fa := get_node_or_null("/root/FactoryAudio")
		if fa != null:
			fa.call("play_one_shot", self, "pneumatic", -9.0, 14.0)
		valve_toggled_3d.emit(valve_open)


func _physics_process(delta: float) -> void:
	if _is_running():
		var inflow := 0.16 if active else 0.0
		var outflow := (0.16 * valve_opening) if valve_open else 0.0
		level = clampf(level + (inflow - outflow) * delta, 0.0, 1.0)
		_sync_level_sensors()
	_overflowing = _is_running() and active and level >= 0.995
	_overflow_amount = move_toward(_overflow_amount, 1.0 if _overflowing else 0.0, delta * (2.4 if _overflowing else 1.4))
	_puddle_amount = move_toward(_puddle_amount, 1.0 if _overflowing else 0.0, delta * (0.45 if _overflowing else 0.25))
	if overflow_curtain != null:
		overflow_curtain.visible = _overflow_amount > 0.01
		if overflow_curtain.visible:
			overflow_curtain.scale.y = _overflow_amount
			overflow_curtain.position.y = lerpf(1.53, 0.94, _overflow_amount)
	if overflow_splash != null:
		overflow_splash.emitting = _overflowing
	if overflow_puddle != null:
		overflow_puddle.visible = _puddle_amount > 0.01
		if overflow_puddle.visible:
			var p_scale := lerpf(0.55, 1.18, _puddle_amount)
			overflow_puddle.scale = Vector3(p_scale, 1.0, p_scale)
	if _is_running() or _overflow_amount > 0.01:
		_update_visuals()
	var working := _is_running() and active
	var blink_on := (Time.get_ticks_msec() / 350) % 2 == 0
	if working != bool(get_meta("_last_working", false)) or (working and blink_on != _last_blink):
		_update_indicator()
	var target_ang := (PI * 0.5 * (1.0 - valve_opening)) if valve_open else (PI * 0.5)
	_valve_angle = move_toward(_valve_angle, target_ang, delta * 8.0)
	if valve_handle != null and not is_equal_approx(valve_handle.rotation.y, _valve_angle):
		valve_handle.rotation.y = _valve_angle
	var draining := _is_running() and valve_open and valve_opening > 0.01 and level > 0.005
	if drain_stream != null:
		drain_stream.visible = draining
		if draining:
			if not is_equal_approx(_built_stream_opening, valve_opening):
				_rebuild_drain_stream(valve_opening)
			if not is_equal_approx(_last_stream_opening, valve_opening):
				_last_stream_opening = valve_opening
				var stream_mat := drain_stream.material_override as ShaderMaterial
				if stream_mat != null:
					stream_mat.set_shader_parameter("flow_speed", lerpf(2.2, 5.2, valve_opening))
	if drain_splash != null:
		drain_splash.emitting = draining


func _sync_level_sensors() -> void:
	low_level = level >= low_threshold
	mid_level = level >= mid_threshold
	high_level = level >= high_threshold
	level_percent = roundi(level * 100.0)


func _update_visuals() -> void:
	if water_mesh != null and not is_equal_approx(_last_visual_level, level):
		_last_visual_level = level
		var fill := maxf(0.02, level)
		water_mesh.scale.y = fill
		water_mesh.position.y = 0.34 + 0.55 * fill
	if level_label != null:
		var v_txt := " | V:%d%%" % roundi(valve_opening * 100.0) if valve_open else ""
		var ovf_txt := " [OVERFLOW!]" if _overflowing else ""
		var next_txt := "TANK: %d%% [L:%d M:%d H:%d]%s%s" % [
			level_percent,
			1 if low_level else 0,
			1 if mid_level else 0,
			1 if high_level else 0,
			v_txt,
			ovf_txt,
		]
		if next_txt != _last_label_text:
			_last_label_text = next_txt
			level_label.text = next_txt
		var ovf_blink := (Time.get_ticks_msec() / 180) % 2 == 0
		var next_col := (Color("ff3b3b") if ovf_blink else Color("ffe066")) if _overflowing else (Color("ff6b6b") if high_level else Color("7de8ff"))
		if next_col != _last_label_color:
			_last_label_color = next_col
			level_label.modulate = next_col
	_set_led_state(_low_led_mat, low_level, Color("33d980"))
	_set_led_state(_mid_led_mat, mid_level, Color("f5bf2e"))
	var high_lit := high_level and (not _overflowing or ((Time.get_ticks_msec() / 180) % 2 == 0))
	_set_led_state(_high_led_mat, high_lit, Color("f23838"))


func _set_led_state(mat: StandardMaterial3D, on: bool, on_color: Color) -> void:
	if mat == null:
		return
	if mat.has_meta("_last_on") and bool(mat.get_meta("_last_on")) == on:
		return
	mat.set_meta("_last_on", on)
	var col := on_color if on else Color("4a5a66")
	mat.albedo_color = col
	mat.emission_enabled = on
	mat.emission = on_color
	mat.emission_energy_multiplier = 2.4 if on else 0.0


func _update_valve_visuals() -> void:
	_set_led_state(_valve_led_mat, valve_open and valve_opening > 0.01, Color("33d9f2"))
	_update_visuals()


func _rebuild_drain_stream(opening: float) -> void:
	if drain_stream == null:
		return
	_built_stream_opening = opening
	var arc_reach := lerpf(0.08, 0.28, opening)
	var r_top := lerpf(0.014, 0.048, opening)
	var r_bot := r_top * 0.62
	const SEGS := 12
	const RINGS := 12

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var ring_verts: Array = []
	for i in range(SEGS + 1):
		var t := float(i) / float(SEGS)
		var center := Vector3(0.08 + arc_reach * t, -0.45 * t * t, 0.0)
		var tangent := Vector3(arc_reach, -0.90 * t, 0.0).normalized()
		var side := Vector3(0.0, 0.0, 1.0)
		var normal_up := side.cross(tangent).normalized()
		var radius := lerpf(r_top, r_bot, t)
		var ring: Array[Vector3] = []
		for j in range(RINGS + 1):
			var ang := (float(j) / float(RINGS)) * TAU
			var offset := (normal_up * cos(ang) + side * sin(ang)) * radius
			ring.append(center + offset)
		ring_verts.append(ring)

	for i in range(SEGS):
		var t0 := float(i) / float(SEGS)
		var t1 := float(i + 1) / float(SEGS)
		var r0: Array = ring_verts[i]
		var r1: Array = ring_verts[i + 1]
		for j in range(RINGS):
			var u0 := float(j) / float(RINGS)
			var u1 := float(j + 1) / float(RINGS)
			var v00: Vector3 = r0[j]
			var v01: Vector3 = r0[j + 1]
			var v10: Vector3 = r1[j]
			var v11: Vector3 = r1[j + 1]
			st.set_uv(Vector2(u0, t0))
			st.add_vertex(v00)
			st.set_uv(Vector2(u0, t1))
			st.add_vertex(v10)
			st.set_uv(Vector2(u1, t1))
			st.add_vertex(v11)

			st.set_uv(Vector2(u0, t0))
			st.add_vertex(v00)
			st.set_uv(Vector2(u1, t1))
			st.add_vertex(v11)
			st.set_uv(Vector2(u1, t0))
			st.add_vertex(v01)

	st.generate_normals()
	drain_stream.mesh = st.commit()
	if drain_splash != null:
		drain_splash.position = Vector3(0.08 + arc_reach, -0.44, 0.0)


func _update_indicator() -> void:
	if _indicator_mat == null:
		return
	var working := _is_running() and active
	var blink_on := (Time.get_ticks_msec() / 350) % 2 == 0
	set_meta("_last_working", working)
	_last_blink = blink_on
	var col := Color("f22929") if working else Color("4a5a66")
	_indicator_mat.albedo_color = col
	_indicator_mat.emission_enabled = working
	_indicator_mat.emission = col
	_indicator_mat.emission_energy_multiplier = (3.2 if blink_on else 0.15) if working else 0.0
	var fa := get_node_or_null("/root/FactoryAudio")
	if fa != null and _loop_audio != null:
		fa.call("set_loop_active", _loop_audio, working)


func get_tank_config() -> Dictionary:
	return {
		"valve_open": valve_open,
		"valve_opening": valve_opening,
		"low_threshold": low_threshold,
		"mid_threshold": mid_threshold,
		"high_threshold": high_threshold,
	}


func apply_tank_config(cfg: Dictionary) -> void:
	if cfg.has("low_threshold"):
		low_threshold = clampf(float(cfg["low_threshold"]), 0.0, 1.0)
	if cfg.has("mid_threshold"):
		mid_threshold = clampf(float(cfg["mid_threshold"]), 0.0, 1.0)
	if cfg.has("high_threshold"):
		high_threshold = clampf(float(cfg["high_threshold"]), 0.0, 1.0)
	if cfg.has("valve_opening"):
		valve_opening = clampf(float(cfg["valve_opening"]), 0.0, 1.0)
	if cfg.has("valve_open"):
		valve_open = bool(cfg["valve_open"])
	_sync_level_sensors()
	_update_visuals()
	_update_valve_visuals()
