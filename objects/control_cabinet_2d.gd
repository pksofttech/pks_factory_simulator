extends CanvasLayer

signal start_triggered
signal stop_triggered
signal estop_toggled(active: bool)
signal mode_toggled
signal dynamic_button_changed(io_id: String, active: bool)
signal dynamic_switch_changed(io_id: String, active: bool)
signal dynamic_switch_3pos_changed(io_id: String, pos: int)
signal dynamic_pot_changed(io_id: String, val: float)

var start_pulse := 0.0
var stop_pulse := 0.0
var reverse_pulse := 0.0
var start_active := false
var stop_active := false
var reverse_active := false
var switch_auto_active := false
var estop_active := false
var lamp_green_on := false
var lamp_yellow_on := false
var lamp_red_on := false

@onready var panel: PanelContainer = $CabinetPanel
@onready var cabinet_3d: StaticBody3D = $CabinetPanel/Margin/VBox/ViewportContainer/CabinetViewport/Cabinet3D

func _ready() -> void:
	var cam := $CabinetPanel/Margin/VBox/ViewportContainer/CabinetViewport/CabinetCamera as Camera3D
	if cam != null:
		cam.look_at(Vector3(0.0, 1.33, 0.27), Vector3.UP)
	if cabinet_3d != null:
		cabinet_3d.connect("start_pressed_3d", func():
			start_pulse = 0.15
			start_triggered.emit()
		)
		cabinet_3d.connect("stop_pressed_3d", func():
			stop_pulse = 0.15
			stop_triggered.emit()
		)
		cabinet_3d.connect("reverse_pressed_3d", func():
			reverse_pulse = 0.15
		)
		cabinet_3d.connect("estop_toggled_3d", func(active: bool):
			estop_active = active
			estop_toggled.emit(active)
		)
		cabinet_3d.connect("selector_toggled_3d", func(active: bool):
			switch_auto_active = active
			mode_toggled.emit()
		)
		cabinet_3d.connect("dynamic_button_pressed", func(io_id: String):
			dynamic_button_changed.emit(io_id, true)
		)
		cabinet_3d.connect("dynamic_button_released", func(io_id: String):
			dynamic_button_changed.emit(io_id, false)
		)
		cabinet_3d.connect("dynamic_switch_toggled", func(active: bool, io_id: String):
			dynamic_switch_changed.emit(io_id, active)
		)
		cabinet_3d.connect("dynamic_switch_3pos_changed", func(pos: int, io_id: String):
			dynamic_switch_3pos_changed.emit(io_id, pos)
		)
		cabinet_3d.connect("dynamic_pot_changed", func(val: float, io_id: String):
			dynamic_pot_changed.emit(io_id, val)
		)

func _process(delta: float) -> void:
	if start_pulse > 0.0:
		start_pulse = maxf(0.0, start_pulse - delta)
	if stop_pulse > 0.0:
		stop_pulse = maxf(0.0, stop_pulse - delta)
	if reverse_pulse > 0.0:
		reverse_pulse = maxf(0.0, reverse_pulse - delta)
	if is_instance_valid(cabinet_3d):
		start_active = bool(cabinet_3d.get("start_pressed")) or start_pulse > 0.0
		stop_active = bool(cabinet_3d.get("stop_pressed")) or stop_pulse > 0.0
		reverse_active = bool(cabinet_3d.get("reverse_pressed")) or reverse_pulse > 0.0
	else:
		start_active = start_pulse > 0.0
		stop_active = stop_pulse > 0.0
		reverse_active = reverse_pulse > 0.0

func update_display(is_running: bool, is_plc_mode: bool, count: int, speed: float, hr0: int, _cab_alarm: bool = false) -> void:
	if not is_instance_valid(panel) or not panel.visible or cabinet_3d == null:
		return
	cabinet_3d.call("apply_hud_state", is_running, is_plc_mode, count, speed, hr0, lamp_green_on, lamp_yellow_on, lamp_red_on)
