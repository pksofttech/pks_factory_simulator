extends Node3D

signal pressed(io_id: String)
signal released(io_id: String)

const CAP_Z_RELEASED := 0.004
const CAP_Z_PRESSED := -0.003
const CAP_TRAVEL_SPEED := 0.14

@export var label_text: String = "BTN":
	set(value):
		label_text = value
		if is_node_ready():
			_apply_visuals()

@export var button_color: Color = Color(0.14, 0.62, 0.28, 1):
	set(value):
		button_color = value
		if is_node_ready():
			_apply_visuals()

@export var is_lit: bool = false:
	set(value):
		is_lit = value
		if is_node_ready():
			_apply_visuals()

@export var io_id: String = ""

var held := false
var pulse := 0.0
var is_pressed := false

@onready var cap_mesh: MeshInstance3D = $Cap
@onready var tag_label: Label3D = $Tag
@onready var area: Area3D = $Area

func _ready() -> void:
	if area != null:
		area.input_event.connect(_on_area_input)
	_apply_visuals()

func _input(event: InputEvent) -> void:
	if held and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		held = false
		released.emit(io_id)

func _process(delta: float) -> void:
	if pulse > 0.0:
		pulse = maxf(0.0, pulse - delta)
	is_pressed = held or pulse > 0.0
	if cap_mesh != null:
		var target_z := CAP_Z_PRESSED if is_pressed else CAP_Z_RELEASED
		if not is_equal_approx(cap_mesh.position.z, target_z):
			cap_mesh.position.z = move_toward(cap_mesh.position.z, target_z, delta * CAP_TRAVEL_SPEED)

func _can_click() -> bool:
	var cabinet := get_parent()
	while cabinet != null and not cabinet.has_method("_can_click_buttons"):
		cabinet = cabinet.get_parent()
	if cabinet != null:
		return bool(cabinet.call("_can_click_buttons"))
	return true

func _on_area_input(_cam: Node, event: InputEvent, _pos: Vector3, _norm: Vector3, _idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _can_click():
			held = true
			pulse = 0.15
			_play_click()
			pressed.emit(io_id)
		elif not event.pressed and held:
			held = false
			released.emit(io_id)

func _play_click() -> void:
	var fa := get_node_or_null("/root/FactoryAudio")
	if fa != null:
		fa.call("play_one_shot", self, "npc_check", -5.0, 24.0, 1.0)

func _apply_visuals() -> void:
	if tag_label != null:
		tag_label.text = label_text
	if cap_mesh != null:
		var mat := cap_mesh.material_override as StandardMaterial3D
		if mat == null:
			mat = StandardMaterial3D.new()
			mat.resource_local_to_scene = true
			mat.roughness = 0.22
			mat.clearcoat_enabled = true
			mat.clearcoat = 0.45
			cap_mesh.material_override = mat
		mat.albedo_color = button_color
		mat.emission_enabled = is_lit
		mat.emission = button_color
		mat.emission_energy_multiplier = 0.8 if is_lit else 0.0
