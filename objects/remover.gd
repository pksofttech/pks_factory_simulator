extends Area3D

@export var active: bool = false:
	set(value):
		active = value
		_update_indicator()

@export var plc_mode: bool = false
@export var removed_count: int = 0

var indicator_mat: StandardMaterial3D

@onready var indicator: MeshInstance3D = get_node_or_null("Indicator")
@onready var count_label: Label3D = get_node_or_null("CountLabel")

func _ready() -> void:
	if indicator != null:
		indicator_mat = indicator.material_override as StandardMaterial3D
	body_entered.connect(_on_body_entered)
	_update_indicator()
	_update_label()

func _is_working() -> bool:
	if plc_mode:
		return active
	var scene := get_parent()
	var is_running: bool = scene == null or scene.get("running") == null or bool(scene.get("running"))
	return active and is_running

func _physics_process(_delta: float) -> void:
	if active:
		var blink_on := (Time.get_ticks_msec() / 350) % 2 == 0
		if blink_on != bool(get_meta("_last_blink", false)):
			_update_indicator()
	if not _is_working():
		return
	for body in get_overlapping_bodies():
		_consume_body(body)

func _on_body_entered(body: Node3D) -> void:
	if _is_working():
		_consume_body(body)

func _consume_body(body: Node3D) -> void:
	if not is_instance_valid(body) or not (body is RigidBody3D) or not body.is_in_group("product_boxes"):
		return
	body.remove_from_group("product_boxes")
	body.queue_free()
	removed_count += 1
	_update_label()
	var fa := get_node_or_null("/root/FactoryAudio")
	if fa != null:
		fa.call("play_one_shot", self, "remove", -10.0, 14.0)

func _update_indicator() -> void:
	if indicator_mat == null:
		return
	var blink_on := (Time.get_ticks_msec() / 350) % 2 == 0
	set_meta("_last_blink", blink_on)
	var col := Color("ff7a2e") if active else Color("4a5a66")
	indicator_mat.albedo_color = col
	indicator_mat.emission = col
	indicator_mat.emission_energy_multiplier = (3.2 if blink_on else 0.15) if active else 0.0

func _update_label() -> void:
	if count_label != null:
		count_label.text = "REMOVER: %d" % removed_count
