extends StaticBody3D

@export var active: bool = false:
	set(value):
		var rising := (not active) and value
		active = value
		if rising:
			_cooldown = 0.0
		_update_indicator()

@export var plc_mode: bool = false
@export var spawn_interval: float = 2.5
@export_enum("Alternate", "Cardboard", "Plastic", "SmallBox", "MetalCrate", "Pallet", "Workpiece") var box_mode: int = 0
@export_range(0, 100, 1) var defect_rate: int = 0

var _cooldown := 0.0
var _next_plastic := false
var indicator_mat: StandardMaterial3D

@onready var clear_zone: Area3D = $ClearZone
@onready var indicator: MeshInstance3D = $Indicator
@onready var beacon_light: OmniLight3D = $BeaconLight

func _ready() -> void:
	if indicator != null:
		indicator_mat = indicator.material_override as StandardMaterial3D
	_update_indicator()

func _physics_process(delta: float) -> void:
	if active:
		var blink_on := (Time.get_ticks_msec() / 350) % 2 == 0
		if blink_on != bool(get_meta("_last_blink", false)):
			_update_indicator()
	if _cooldown > 0.0:
		_cooldown = maxf(0.0, _cooldown - delta)
	var scene := get_parent()
	var is_running: bool = scene != null and bool(scene.get("running"))
	if not is_running or not active or _cooldown > 0.0 or _has_blocking_box():
		return
	_emit_box(scene)
	_cooldown = spawn_interval

func _has_blocking_box() -> bool:
	if clear_zone == null:
		return false
	for body in clear_zone.get_overlapping_bodies():
		if body is RigidBody3D and body.is_in_group("product_boxes"):
			if box_mode != 5 and str(body.get_meta("kind", "")) == "pallet":
				continue
			return true
	return false

func _emit_box(scene: Node) -> void:
	if scene == null:
		return
	var kind := "box"
	match box_mode:
		0:
			kind = "box_plastic" if _next_plastic else "box"
			_next_plastic = not _next_plastic
		1:
			kind = "box"
		2:
			kind = "box_plastic"
		3:
			kind = "box_small"
		4:
			kind = "box_metal"
		5:
			kind = "pallet"
		6:
			kind = "workpiece"
	if scene.has_method("spawn_emitted_box"):
		var is_defective := defect_rate > 0 and (randi() % 100) < defect_rate
		scene.call("spawn_emitted_box", global_position, kind, is_defective)
		var fa := get_node_or_null("/root/FactoryAudio")
		if fa != null:
			fa.call("play_one_shot", self, "emit", -10.0, 14.0)

func _update_indicator() -> void:
	var blink_on := (Time.get_ticks_msec() / 350) % 2 == 0
	set_meta("_last_blink", blink_on)
	if beacon_light != null:
		beacon_light.visible = active and blink_on
	if indicator_mat == null:
		return
	indicator_mat.albedo_color = Color("f22929") if active else Color("4a5a66")
	indicator_mat.emission = Color("f22929")
	indicator_mat.emission_energy_multiplier = (3.2 if blink_on else 0.15) if active else 0.0
