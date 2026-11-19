extends Node3D

signal toggled(active: bool, io_id: String)
signal position_changed(pos: int, io_id: String)

@export var label_text: String = "SW":
	set(value):
		label_text = value
		if is_node_ready():
			_apply_visuals()

@export var switch_color: Color = Color(0.09, 0.1, 0.12, 1):
	set(value):
		switch_color = value
		if is_node_ready():
			_apply_visuals()

@export_range(2, 3) var positions: int = 2:
	set(value):
		positions = clampi(value, 2, 3)
		if positions == 3 and switch_pos > 2:
			switch_pos = 1
		elif positions == 2 and switch_pos > 1:
			switch_pos = 1
		if is_node_ready():
			_update_knob()

var _syncing_props := false
var _ping_dir := 1

@export var switch_pos: int = 0:
	set(value):
		var max_p := 2 if positions == 3 else 1
		switch_pos = clampi(value, 0, max_p)
		if not _syncing_props:
			_syncing_props = true
			active = (switch_pos != 0) if positions == 2 else (switch_pos != 1)
			_syncing_props = false
		if is_node_ready():
			_update_knob()

@export var active: bool = false:
	set(value):
		active = value
		if not _syncing_props and positions == 2:
			_syncing_props = true
			switch_pos = 1 if value else 0
			_syncing_props = false
		if is_node_ready():
			_update_knob()

@export var io_id: String = ""

@onready var knob_node: Node3D = $Knob
@onready var knob_base_mesh: MeshInstance3D = $Knob/KnobBase
@onready var lever_mesh: MeshInstance3D = $Knob/Lever
@onready var tag_label: Label3D = $Tag
@onready var area: Area3D = $Area

func _ready() -> void:
	if area != null:
		area.input_event.connect(_on_area_input)
	_apply_visuals()
	_update_knob()

func _can_click() -> bool:
	var cabinet := get_parent()
	while cabinet != null and not cabinet.has_method("_can_click_buttons"):
		cabinet = cabinet.get_parent()
	if cabinet != null:
		return bool(cabinet.call("_can_click_buttons"))
	return true

func _on_area_input(_cam: Node, event: InputEvent, _pos: Vector3, _norm: Vector3, _idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and _can_click():
		if positions == 3:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if switch_pos <= 0:
					_ping_dir = 1
				elif switch_pos >= 2:
					_ping_dir = -1
				switch_pos += _ping_dir
			else:
				return
			_play_click()
			position_changed.emit(switch_pos, io_id)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			active = not active
			_play_click()
			toggled.emit(active, io_id)

func _play_click() -> void:
	var fa := get_node_or_null("/root/FactoryAudio")
	if fa != null:
		fa.call("play_one_shot", self, "npc_check", -6.0, 24.0, 0.95)

func _update_knob() -> void:
	if knob_node == null:
		return
	if positions == 3:
		var angles := [40.0, 0.0, -40.0]
		knob_node.rotation_degrees.z = angles[clampi(switch_pos, 0, 2)]
	else:
		knob_node.rotation_degrees.z = -35.0 if active else 35.0

func _apply_visuals() -> void:
	if tag_label != null:
		tag_label.text = label_text
	for mesh in [knob_base_mesh, lever_mesh]:
		if mesh == null:
			continue
		var mat := mesh.material_override as StandardMaterial3D
		if mat == null:
			mat = StandardMaterial3D.new()
			mat.resource_local_to_scene = true
			mat.metallic = 0.05
			mat.roughness = 0.42
			mesh.material_override = mat
		mat.albedo_color = switch_color
