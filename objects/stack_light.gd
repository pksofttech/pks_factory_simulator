extends StaticBody3D

@export var plc_mode: bool = false
@export var active: bool = false

@export var lamp_green_on: bool = false:
	set(value):
		lamp_green_on = value
		_update_lamps()

@export var lamp_yellow_on: bool = false:
	set(value):
		lamp_yellow_on = value
		_update_lamps()

@export var lamp_red_on: bool = false:
	set(value):
		lamp_red_on = value
		_update_lamps()

@onready var green_mesh: MeshInstance3D = get_node_or_null("LampGreen")
@onready var yellow_mesh: MeshInstance3D = get_node_or_null("LampYellow")
@onready var red_mesh: MeshInstance3D = get_node_or_null("LampRed")

func _ready() -> void:
	_update_lamps()

func _update_lamps() -> void:
	active = lamp_green_on or lamp_yellow_on or lamp_red_on
	_set_lamp_visual(green_mesh, lamp_green_on, Color("29d66f"), Color("18422b"))
	_set_lamp_visual(yellow_mesh, lamp_yellow_on, Color("f5c542"), Color("4a3d14"))
	_set_lamp_visual(red_mesh, lamp_red_on, Color("f23838"), Color("4a1818"))

func _set_lamp_visual(mesh: MeshInstance3D, is_on: bool, on_col: Color, off_col: Color) -> void:
	if mesh == null:
		return
	var mat := mesh.material_override as StandardMaterial3D
	if mat == null:
		return
	mat.albedo_color = on_col if is_on else off_col
	mat.emission_enabled = is_on
	mat.emission = on_col
	mat.emission_energy_multiplier = 2.8 if is_on else 0.0
