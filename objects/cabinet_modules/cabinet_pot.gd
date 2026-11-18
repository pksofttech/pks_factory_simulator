extends Node3D

signal value_changed(val: float, io_id: String)

@export var label_text: String = "VR":
	set(value):
		label_text = value
		if is_node_ready():
			_apply_visuals()

@export var knob_color: Color = Color(0.12, 0.14, 0.17, 1):
	set(value):
		knob_color = value
		if is_node_ready():
			_apply_visuals()

@export_range(0.0, 1.0) var value: float = 0.0:
	set(val):
		var clamped := clampf(val, 0.0, 1.0)
		if is_equal_approx(value, clamped):
			return
		value = clamped
		if is_node_ready():
			_update_knob()

@export var io_id: String = ""

var _dragging := false
var _hovered := false
var _drag_start_pos := Vector2.ZERO
var _drag_start_val := 0.0

@onready var knob_node: Node3D = $Knob
@onready var knob_body_mesh: MeshInstance3D = $Knob/KnobBody
@onready var tag_label: Label3D = $Tag
@onready var value_label: Label3D = $ValueTag
@onready var area: Area3D = $Area

func _ready() -> void:
	if area != null:
		area.input_event.connect(_on_area_input)
		area.mouse_entered.connect(func(): _hovered = true)
		area.mouse_exited.connect(func(): _hovered = false)
	_apply_visuals()
	_update_knob()

func _can_click() -> bool:
	var cabinet := get_parent()
	while cabinet != null and not cabinet.has_method("_can_click_buttons"):
		cabinet = cabinet.get_parent()
	if cabinet != null:
		return bool(cabinet.call("_can_click_buttons"))
	return true

func _input(event: InputEvent) -> void:
	if _dragging and event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var delta_px := (_drag_start_pos.y - mm.position.y) + (mm.position.x - _drag_start_pos.x)
		var next_val := clampf(_drag_start_val + delta_px * 0.005, 0.0, 1.0)
		if not is_equal_approx(next_val, value):
			value = next_val
			value_changed.emit(value, io_id)
		get_viewport().set_input_as_handled()
	elif _dragging and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_dragging = false
		get_viewport().set_input_as_handled()
	elif _hovered and event is InputEventMouseButton and event.pressed and _can_click():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			value = clampf(value + 0.05, 0.0, 1.0)
			value_changed.emit(value, io_id)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			value = clampf(value - 0.05, 0.0, 1.0)
			value_changed.emit(value, io_id)
			get_viewport().set_input_as_handled()

func _on_area_input(_cam: Node, event: InputEvent, _pos: Vector3, _norm: Vector3, _idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _can_click():
		var mb := event as InputEventMouseButton
		_dragging = true
		_drag_start_pos = mb.position
		_drag_start_val = value
		var fa := get_node_or_null("/root/FactoryAudio")
		if fa != null:
			fa.call("play_one_shot", self, "npc_check", -8.0, 24.0, 1.1)

func _update_knob() -> void:
	if knob_node != null:
		# 270 degree sweep: +135 (0%) to -135 (100%)
		knob_node.rotation_degrees.z = lerpf(135.0, -135.0, value)
	if value_label != null:
		value_label.text = "%d%%" % roundi(value * 100.0)

func _apply_visuals() -> void:
	if tag_label != null:
		tag_label.text = label_text
	if knob_body_mesh != null:
		var mat := knob_body_mesh.material_override as StandardMaterial3D
		if mat == null:
			mat = StandardMaterial3D.new()
			mat.resource_local_to_scene = true
			mat.metallic = 0.25
			mat.roughness = 0.35
			knob_body_mesh.material_override = mat
		mat.albedo_color = knob_color
