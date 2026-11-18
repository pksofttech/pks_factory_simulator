extends Area3D

@export_enum("All", "Cardboard", "Plastic") var detect_mode: int = 0:
	set(value):
		detect_mode = clampi(value, 0, 2)
		_recheck_overlaps()
		_update_mode_label()

@export var active: bool = false
@export var detected_id: int = 0

signal state_changed(active: bool)

var _detected_bodies: Array[Node3D] = []

@onready var indicator: MeshInstance3D = $Indicator
@onready var scan_beam: MeshInstance3D = $ScanBeam
@onready var mode_label: Label3D = $ModeLabel

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	set_detected(false)
	_update_mode_label()

func _get_body_kind(body: Node3D) -> String:
	var kind := str(body.get_meta("kind", ""))
	if kind.is_empty():
		return "box_plastic" if body.name.begins_with("PlasticBox") else "box"
	return kind

func _matches_mode(body: Node3D) -> bool:
	if not is_instance_valid(body) or not body.is_in_group("product_boxes"):
		return false
	var kind := _get_body_kind(body)
	match detect_mode:
		1:
			return kind == "box"
		2:
			return kind == "box_plastic"
		_:
			return true

func _recheck_overlaps() -> void:
	_detected_bodies.clear()
	if is_inside_tree():
		for body in get_overlapping_bodies():
			if _matches_mode(body) and body not in _detected_bodies:
				_detected_bodies.append(body)
	set_detected(not _detected_bodies.is_empty())

func _on_body_entered(body: Node3D) -> void:
	if _matches_mode(body) and body not in _detected_bodies:
		_detected_bodies.append(body)
		set_detected(true)

func _on_body_exited(body: Node3D) -> void:
	_detected_bodies.erase(body)
	for i in range(_detected_bodies.size() - 1, -1, -1):
		if not is_instance_valid(_detected_bodies[i]) or not _matches_mode(_detected_bodies[i]):
			_detected_bodies.remove_at(i)
	set_detected(not _detected_bodies.is_empty())

func _compute_detected_id() -> int:
	for body in _detected_bodies:
		if is_instance_valid(body):
			var kind := _get_body_kind(body)
			return 2 if kind == "box_plastic" else 1
	return 0

func set_detected(is_active: bool) -> void:
	var new_id := _compute_detected_id() if is_active else 0
	var changed := active != is_active or detected_id != new_id
	active = is_active
	detected_id = new_id
	if indicator != null:
		var mat := indicator.material_override as StandardMaterial3D
		if mat != null:
			var col := Color("ff3b9a") if active else Color("28c8ff")
			mat.albedo_color = col
			mat.emission_enabled = true
			mat.emission = col
			mat.emission_energy_multiplier = 2.6 if active else 0.9
	if scan_beam != null:
		var bmat := scan_beam.material_override as StandardMaterial3D
		if bmat != null:
			var bcol := Color(1.0, 0.25, 0.65, 0.36) if active else Color(0.15, 0.78, 1.0, 0.16)
			bmat.albedo_color = bcol
			bmat.emission = Color(bcol.r, bcol.g, bcol.b, 1.0)
			bmat.emission_energy_multiplier = 1.6 if active else 0.5
	if changed:
		state_changed.emit(active)

func _update_mode_label() -> void:
	if mode_label == null:
		return
	match detect_mode:
		1:
			mode_label.text = "VISION: BOX"
		2:
			mode_label.text = "VISION: CRATE"
		_:
			mode_label.text = "VISION: ALL"
