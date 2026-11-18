extends StaticBody3D

enum State { IDLE, EXTENDING, RETRACTING }

@export var active: bool = false
@export var plc_mode: bool = false
@export var push_speed: float = 4.2
@export var stroke_length: float = 0.72
@export var retract_speed: float = 3.0

var state: State = State.IDLE
var extension := 0.0
var is_extended := false
var is_retracted := true
var paddle: Node3D
var paddle_base_z := 0.0
var paddle_col_base_z := 0.0

@onready var trigger_zone: Area3D = $TriggerZone
@onready var paddle_col: CollisionShape3D = get_node_or_null("PaddleCollision")

func _ready() -> void:
	paddle = find_child("PusherPaddle", true, false) as Node3D
	if paddle != null:
		paddle_base_z = paddle.position.z
	if paddle_col != null:
		paddle_col_base_z = paddle_col.position.z

func _physics_process(delta: float) -> void:
	var scene := get_parent()
	var is_running: bool = scene != null and scene.get("running") != null and bool(scene.get("running"))

	if is_running and active:
		if state != State.EXTENDING:
			var fa := get_node_or_null("/root/FactoryAudio")
			if fa != null:
				fa.call("play_one_shot", self, "pneumatic", -9.0, 14.0)
		state = State.EXTENDING
		if extension < stroke_length:
			extension = minf(extension + push_speed * delta, stroke_length)
			_push_overlapping_boxes()
	else:
		state = State.RETRACTING if extension > 0.0 else State.IDLE
		extension = maxf(extension - retract_speed * delta, 0.0)

	is_extended = extension >= stroke_length - 0.01
	is_retracted = extension <= 0.01
	if paddle != null:
		paddle.position.z = paddle_base_z + extension
	if paddle_col != null:
		paddle_col.position.z = paddle_col_base_z + extension

func _push_overlapping_boxes() -> void:
	var push_dir := global_basis.z.normalized()
	for body in trigger_zone.get_overlapping_bodies():
		if body is RigidBody3D and body.is_in_group("product_boxes") and not body.freeze:
			var vel := push_dir * push_speed
			body.linear_velocity = Vector3(vel.x, body.linear_velocity.y, vel.z)
