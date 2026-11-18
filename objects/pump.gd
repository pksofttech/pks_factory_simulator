extends StaticBody3D

@export var plc_mode: bool = false
@export var active: bool = false:
	set(value):
		active = value
		_update_indicator()

var _spin_speed: float = 0.0
var _indicator_mat: StandardMaterial3D
var _last_blink: bool = false
var _loop_audio: AudioStreamPlayer3D

@onready var coupling: Node3D = get_node_or_null("Coupling")
@onready var indicator: MeshInstance3D = get_node_or_null("Indicator")


func _ready() -> void:
	if indicator != null:
		_indicator_mat = indicator.material_override as StandardMaterial3D
	var fa := get_node_or_null("/root/FactoryAudio")
	if fa != null:
		_loop_audio = fa.call("attach_loop", self, "pump_loop", -13.0, 16.0) as AudioStreamPlayer3D
	_update_indicator()


func _is_running() -> bool:
	var scene := get_parent()
	if scene != null:
		if scene.get("edit_mode") != null and bool(scene.get("edit_mode")):
			return false
		if scene.get("running") != null and not bool(scene.get("running")):
			return false
	return active


func _physics_process(delta: float) -> void:
	var working := _is_running()
	var blink_on := (Time.get_ticks_msec() / 350) % 2 == 0
	if working != bool(get_meta("_last_working", false)) or (working and blink_on != _last_blink):
		_update_indicator()
	var target_speed := 16.0 if working else 0.0
	_spin_speed = move_toward(_spin_speed, target_speed, delta * 22.0)
	if coupling != null and _spin_speed > 0.01:
		coupling.rotation.x += _spin_speed * delta


func _update_indicator() -> void:
	if _indicator_mat == null:
		return
	var working := _is_running()
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
