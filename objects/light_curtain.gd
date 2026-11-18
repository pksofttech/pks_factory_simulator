extends Area3D

@export var active: bool = false

var _indicator_mat: StandardMaterial3D
var _beam_mat: StandardMaterial3D
var _last_blink: bool = false

@onready var indicator: MeshInstance3D = get_node_or_null("Indicator")
@onready var beam_group: Node3D = get_node_or_null("Beams")
@onready var status_label: Label3D = get_node_or_null("StatusLabel")


func _ready() -> void:
	if indicator != null:
		_indicator_mat = indicator.material_override as StandardMaterial3D
	if beam_group != null and beam_group.get_child_count() > 0:
		var first_beam := beam_group.get_child(0) as MeshInstance3D
		if first_beam != null:
			_beam_mat = first_beam.material_override as StandardMaterial3D
	_update_visuals()


func _physics_process(_delta: float) -> void:
	var tripped := false
	for body in get_overlapping_bodies():
		if body is RigidBody3D and body.is_in_group("product_boxes"):
			tripped = true
			break
	if not tripped:
		var inv := global_transform.affine_inverse()
		for npc in get_tree().get_nodes_in_group("factory_npcs"):
			if not is_instance_valid(npc) or not (npc is Node3D):
				continue
			var local_pt := inv * (npc as Node3D).global_position
			if absf(local_pt.x) <= 0.42 and absf(local_pt.z) <= 0.82:
				tripped = true
				break
	var blink_on := (Time.get_ticks_msec() / 350) % 2 == 0
	if tripped != active or (tripped and blink_on != _last_blink):
		var was_active := active
		active = tripped
		_update_visuals()
		if tripped and not was_active:
			var fa := get_node_or_null("/root/FactoryAudio")
			if fa != null:
				fa.call("play_one_shot", self, "alarm", -8.0, 16.0)


func _update_visuals() -> void:
	var blink_on := (Time.get_ticks_msec() / 350) % 2 == 0
	_last_blink = blink_on
	if _beam_mat != null:
		var bcol := Color(1.0, 0.2, 0.2, 0.55) if active else Color(0.18, 0.92, 0.45, 0.28)
		_beam_mat.albedo_color = bcol
		_beam_mat.emission = Color(bcol.r, bcol.g, bcol.b, 1.0)
		_beam_mat.emission_energy_multiplier = 2.2 if active else 0.9
	if _indicator_mat != null:
		var col := Color("f22929") if active else Color("29d66f")
		_indicator_mat.albedo_color = col
		_indicator_mat.emission = col
		_indicator_mat.emission_energy_multiplier = (3.2 if blink_on else 0.2) if active else 0.9
	if status_label != null:
		status_label.text = "TRIPPED!" if active else "SAFE"
		status_label.modulate = Color("ff6b6b") if active else Color("66e0a3")
