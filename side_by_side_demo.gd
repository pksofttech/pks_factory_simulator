extends "res://main.gd"

var side_spawn_clock := 0.0
const SIDE_LANE_Z := 1.5

func _ready() -> void:
	super._ready()
	var side_belt := _create_sandbox_object("conveyor", Vector3(0, 0, SIDE_LANE_Z))
	side_belt.name = "SideConveyor"
	sandbox_label.text = "Demo: two parallel conveyors"
	_spawn_side_box()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if running:
		side_spawn_clock += delta
		if side_spawn_clock >= 3.5:
			side_spawn_clock = 0.0
			_spawn_side_box()

func _spawn_side_box() -> void:
	var box := _spawn_box()
	box.position = _product_world_position("box", Vector3(-4.0, 0, SIDE_LANE_Z))
