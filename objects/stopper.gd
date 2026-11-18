extends StaticBody3D

enum GateState { BLOCKING, OPEN }

const SWING_CLOSED_DEG := 0.0
const SWING_OPEN_DEG := 90.0

@export var active: bool = false
@export var plc_mode: bool = false
@export var swing_speed_deg: float = 360.0

var gate_state: GateState = GateState.BLOCKING
var swing_deg: float = SWING_CLOSED_DEG
var part_at_gate := false
var is_open := false
var swing_arm: Node3D
var indicator_mat: StandardMaterial3D

@onready var gate_body: AnimatableBody3D = $GateBody
@onready var queue_sensor: Area3D = $QueueSensor
@onready var indicator: MeshInstance3D = $Indicator

func _ready() -> void:
	swing_arm = find_child("SwingArm", true, false) as Node3D
	if indicator != null:
		indicator_mat = indicator.material_override as StandardMaterial3D
	_apply_swing(swing_deg)
	_update_indicator()

func _physics_process(delta: float) -> void:
	var scene := get_parent()
	var is_running: bool = scene != null and bool(scene.get("running"))
	part_at_gate = _has_box(queue_sensor)

	var next_state := GateState.OPEN if (is_running and active) else GateState.BLOCKING
	if next_state != gate_state:
		gate_state = next_state
		if gate_state == GateState.OPEN:
			_wake_queued_boxes()
		var fa := get_node_or_null("/root/FactoryAudio")
		if fa != null:
			fa.call("play_one_shot", self, "pneumatic", -11.0, 14.0)
		_update_indicator()

	is_open = gate_state == GateState.OPEN
	var target_deg := SWING_CLOSED_DEG if gate_state == GateState.BLOCKING else SWING_OPEN_DEG
	if not is_equal_approx(swing_deg, target_deg):
		swing_deg = move_toward(swing_deg, target_deg, swing_speed_deg * delta)
		_apply_swing(swing_deg)

func _apply_swing(angle_deg: float) -> void:
	var rad := deg_to_rad(angle_deg)
	if swing_arm != null:
		swing_arm.rotation.y = rad
	if gate_body != null:
		gate_body.rotation.y = rad

func _wake_queued_boxes() -> void:
	if queue_sensor == null:
		return
	for body in queue_sensor.get_overlapping_bodies():
		if body is RigidBody3D and body.is_in_group("product_boxes"):
			body.sleeping = false

func _has_box(area: Area3D) -> bool:
	if area == null:
		return false
	for body in area.get_overlapping_bodies():
		if body is RigidBody3D and body.is_in_group("product_boxes") and not body.freeze:
			return true
	return false

func _update_indicator() -> void:
	if indicator_mat == null:
		return
	var blocking := gate_state == GateState.BLOCKING
	indicator_mat.albedo_color = Color("f06d2f") if blocking else Color("30df44")
	indicator_mat.emission = indicator_mat.albedo_color
	indicator_mat.emission_energy_multiplier = 1.6
