extends Area3D

@export_enum("All", "Cardboard", "Plastic", "Defective (NG)", "Good (OK)") var detect_mode: int = 0:
	set(value):
		detect_mode = clampi(value, 0, 4)
		_recheck_overlaps()
		_update_mode_label()

@export var active: bool = false
@export var detected_id: int = 0

signal state_changed(active: bool)

var _detected_bodies: Array[Node3D] = []

@onready var indicator: MeshInstance3D = $Indicator
@onready var ring_light_led: MeshInstance3D = get_node_or_null("Lens/RingLightLED")
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
		3:
			return bool(body.get_meta("is_defective", false))
		4:
			return not bool(body.get_meta("is_defective", false))
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
			if bool(body.get_meta("is_defective", false)):
				return 3
			var kind := _get_body_kind(body)
			return 2 if kind == "box_plastic" else 1
	return 0

func set_detected(is_active: bool) -> void:
	var new_id := _compute_detected_id() if is_active else 0
	var changed := active != is_active or detected_id != new_id
	active = is_active
	detected_id = new_id
	var ind_col := Color("28c8ff")
	var ring_col := Color("b3f0ff")
	var beam_col := Color(0.15, 0.78, 1.0, 0.16)
	if active:
		if detected_id == 3:
			ind_col = Color("ff2e3b")
			ring_col = Color("ffd0d0")
			beam_col = Color(1.0, 0.18, 0.22, 0.42)
		elif detect_mode == 4:
			ind_col = Color("2ee878")
			ring_col = Color("d0ffe0")
			beam_col = Color(0.18, 0.92, 0.45, 0.36)
		else:
			ind_col = Color("ff3b9a")
			ring_col = Color("ffffff")
			beam_col = Color(1.0, 0.25, 0.65, 0.36)
	if indicator != null:
		var mat := indicator.material_override as StandardMaterial3D
		if mat != null:
			mat.albedo_color = ind_col
			mat.emission_enabled = true
			mat.emission = ind_col
			mat.emission_energy_multiplier = 2.6 if active else 0.9
	if ring_light_led != null:
		var rmat := ring_light_led.material_override as StandardMaterial3D
		if rmat != null:
			rmat.albedo_color = ring_col
			rmat.emission = ring_col
			rmat.emission_energy_multiplier = 3.0 if active else 1.1
	if scan_beam != null:
		var bmat := scan_beam.material_override as StandardMaterial3D
		if bmat != null:
			bmat.albedo_color = beam_col
			bmat.emission = Color(beam_col.r, beam_col.g, beam_col.b, 1.0)
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
		3:
			mode_label.text = "VISION: NG"
		4:
			mode_label.text = "VISION: OK"
		_:
			mode_label.text = "VISION: ALL"
