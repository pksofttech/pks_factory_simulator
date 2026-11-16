extends Area3D

# Simplified transfer: move along local +X to the center, then local +Z.
# The parent rotation rotates both travel directions.
@export var active: bool = false
@export var plc_mode: bool = false
@export_range(0.0, 5.0, 0.1) var speed := 1.8

func _physics_process(_delta: float) -> void:
	var scene := get_parent().get_parent()
	var can_run := active if plc_mode else (active and scene != null and bool(scene.get("running")))
	if not can_run:
		return
	var turn := get_parent() as Node3D
	for body in get_overlapping_bodies():
		if not body is RigidBody3D or not body.is_in_group("product_boxes") or body.freeze:
			continue
		var local := turn.to_local(body.global_position)
		var direction: Vector3
		if turn.get_meta("reversed", false):
			direction = Vector3.FORWARD if local.z > 0.08 else Vector3.LEFT
		else:
			direction = Vector3.RIGHT if local.x < -0.08 else Vector3.BACK
		var velocity := turn.global_basis * direction * speed
		body.linear_velocity = Vector3(velocity.x, body.linear_velocity.y, velocity.z)
