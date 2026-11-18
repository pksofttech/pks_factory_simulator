extends StaticBody3D

@export var plc_mode: bool = false
@export var active: bool = false:
	set(value):
		active = value
		_update_indicator()

@export var level: float = 0.25
@export var high_level: bool = false
@export var level_percent: int = 25

var _indicator_mat: StandardMaterial3D
var _last_blink: bool = false
var _loop_audio: AudioStreamPlayer3D

@onready var water_mesh: MeshInstance3D = get_node_or_null("WaterColumn")
@onready var indicator: MeshInstance3D = get_node_or_null("Indicator")
@onready var level_label: Label3D = get_node_or_null("LevelLabel")


func _ready() -> void:
	if indicator != null:
		_indicator_mat = indicator.material_override as StandardMaterial3D
	var fa := get_node_or_null("/root/FactoryAudio")
	if fa != null:
		_loop_audio = fa.call("attach_loop", self, "tank_loop", -14.0, 15.0) as AudioStreamPlayer3D
	_update_visuals()
	_update_indicator()


func _is_running() -> bool:
	var scene := get_parent()
	if scene != null:
		if scene.get("edit_mode") != null and bool(scene.get("edit_mode")):
			return false
		if scene.get("running") != null and not bool(scene.get("running")):
			return false
	return true


func _physics_process(delta: float) -> void:
	if _is_running():
		if active:
			level = clampf(level + delta * 0.16, 0.0, 1.0)
		else:
			level = clampf(level - delta * 0.05, 0.0, 1.0)
		high_level = level >= 0.85
		level_percent = roundi(level * 100.0)
		_update_visuals()
	var working := _is_running() and active
	var blink_on := (Time.get_ticks_msec() / 350) % 2 == 0
	if working != bool(get_meta("_last_working", false)) or (working and blink_on != _last_blink):
		_update_indicator()


func _update_visuals() -> void:
	if water_mesh != null:
		var fill := maxf(0.02, level)
		water_mesh.scale.y = fill
		water_mesh.position.y = 0.34 + 0.55 * fill
	if level_label != null:
		level_label.text = "TANK: %d%%" % level_percent
		level_label.modulate = Color("ff6b6b") if high_level else Color("7de8ff")


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
