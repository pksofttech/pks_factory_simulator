extends Area3D

@export_group("Indicator Colors")
@export var inactive_color: Color = Color(0.18942085, 0.8707594, 0.26382238, 1)
@export var active_color: Color = Color("ff492d")
@export_range(0.0, 8.0, 0.1) var active_brightness: float = 2.5

@export var active: bool = false

signal state_changed(active: bool)

var _detected_bodies: Array[Node3D] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	set_detected(false)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("product_boxes") and body not in _detected_bodies:
		_detected_bodies.append(body)
		set_detected(true)

func _on_body_exited(body: Node3D) -> void:
	_detected_bodies.erase(body)
	for i in range(_detected_bodies.size() - 1, -1, -1):
		if not is_instance_valid(_detected_bodies[i]):
			_detected_bodies.remove_at(i)
	set_detected(not _detected_bodies.is_empty())

func set_detected(is_active: bool) -> void:
	var changed := active != is_active
	active = is_active
	var material := ($Indicator as MeshInstance3D).material_override as StandardMaterial3D
	material.albedo_color = active_color if active else inactive_color
	material.emission_enabled = true
	material.emission = active_color
	material.emission_energy_multiplier = active_brightness if active else 0.0
	if changed:
		state_changed.emit(active)
