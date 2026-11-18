extends Area3D

const COLOR_NAMES := ["NONE", "ORANGE", "GREEN", "BLUE", "YELLOW", "RED", "PURPLE"]
const COLOR_VALUES := [
	Color("64f0c8"),
	Color("ee994e"),
	Color("79bd81"),
	Color("76afd9"),
	Color("e2c65c"),
	Color("d78983"),
	Color("c49bd4"),
]

@export_enum("All", "Orange", "Green", "Blue", "Yellow", "Red", "Purple") var detect_color: int = 0:
	set(value):
		detect_color = clampi(value, 0, 6)
		_recheck_overlaps()
		_update_mode_label()

@export var active: bool = false
@export var detected_color_id: int = 0

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

func _get_body_color_id(body: Node3D) -> int:
	if not is_instance_valid(body):
		return 0
	if body.has_meta("color_index"):
		return clampi(int(body.get_meta("color_index", 0)) + 1, 1, 6)
	return 1

func _matches_mode(body: Node3D) -> bool:
	if not is_instance_valid(body) or not body.is_in_group("product_boxes"):
		return false
	if detect_color == 0:
		return true
	return _get_body_color_id(body) == detect_color

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

func _compute_detected_color_id() -> int:
	for body in _detected_bodies:
		if is_instance_valid(body):
			return _get_body_color_id(body)
	return 0

func set_detected(is_active: bool) -> void:
	var new_id := _compute_detected_color_id() if is_active else 0
	var changed := active != is_active or detected_color_id != new_id
	active = is_active
	detected_color_id = new_id
	var glow_col: Color = COLOR_VALUES[new_id] if active and new_id >= 1 and new_id < COLOR_VALUES.size() else COLOR_VALUES[0]
	if indicator != null:
		var mat := indicator.material_override as StandardMaterial3D
		if mat != null:
			mat.albedo_color = glow_col
			mat.emission_enabled = true
			mat.emission = glow_col
			mat.emission_energy_multiplier = 2.6 if active else 0.9
	if ring_light_led != null:
		var rmat := ring_light_led.material_override as StandardMaterial3D
		if rmat != null:
			var rcol := glow_col if active else Color("d8fff4")
			rmat.albedo_color = rcol
			rmat.emission = rcol
			rmat.emission_energy_multiplier = 2.8 if active else 1.1
	if scan_beam != null:
		var bmat := scan_beam.material_override as StandardMaterial3D
		if bmat != null:
			var alpha := 0.38 if active else 0.16
			bmat.albedo_color = Color(glow_col.r, glow_col.g, glow_col.b, alpha)
			bmat.emission = glow_col
			bmat.emission_energy_multiplier = 1.6 if active else 0.5
	if changed:
		state_changed.emit(active)

func _update_mode_label() -> void:
	if mode_label == null:
		return
	if detect_color == 0:
		mode_label.text = "RGB: ALL"
	elif detect_color >= 1 and detect_color < COLOR_NAMES.size():
		mode_label.text = "RGB: " + COLOR_NAMES[detect_color]
