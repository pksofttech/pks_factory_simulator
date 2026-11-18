extends Node3D

@export var label_text: String = "LAMP":
	set(value):
		label_text = value
		if is_node_ready():
			_apply_visuals()

@export var lamp_color: Color = Color("18d97c"):
	set(value):
		lamp_color = value
		if is_node_ready():
			_apply_visuals()

@export var lit: bool = false:
	set(value):
		lit = value
		if is_node_ready():
			_apply_visuals()

@export var io_id: String = ""

@onready var lens_mesh: MeshInstance3D = $Lens
@onready var tag_label: Label3D = $Tag

func _ready() -> void:
	_apply_visuals()

func _apply_visuals() -> void:
	if tag_label != null:
		tag_label.text = label_text
	if lens_mesh != null:
		var mat := lens_mesh.material_override as StandardMaterial3D
		if mat == null:
			mat = StandardMaterial3D.new()
			mat.resource_local_to_scene = true
			mat.roughness = 0.14
			mat.clearcoat_enabled = true
			mat.clearcoat = 0.8
			lens_mesh.material_override = mat
		mat.albedo_color = lamp_color if lit else lamp_color.darkened(0.65)
		mat.emission_enabled = true
		mat.emission = lamp_color
		mat.emission_energy_multiplier = 2.4 if lit else 0.0
