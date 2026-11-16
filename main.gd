extends Node3D

const BELT_SPEED := 1.8
const CAMERA_TARGET := Vector3(0, 0.6, 0)
const BOX_COLORS := [Color("ee994e"), Color("79bd81"), Color("76afd9"), Color("e2c65c"), Color("d78983"), Color("c49bd4")]
const PRODUCT_KINDS := ["box", "box_plastic"]
const EQUIPMENT_BASE_HEIGHT := {"conveyor": 0.0, "turn": -0.03, "sensor": 1.0025, "pusher": 0.0, "stopper": 0.0}
var conveyor: StaticBody3D
var camera: Camera3D
var camera_yaw := 0.6435
var camera_pitch := 0.447
var camera_distance := 19.4
var camera_target := CAMERA_TARGET
var random := RandomNumberGenerator.new()
var edit_mode := false
var placement := "select"
var placement_angle := 0.0
var placement_reversed := false
var placement_preview: Node3D
var preview_material: StandardMaterial3D
var edit_grid: Node3D
var floor_body: StaticBody3D
var workspace_width := 40
var workspace_depth := 40
var width_input: SpinBox
var depth_input: SpinBox
var dragging_object := false
var rotating_object := false
var rotation_drag_pixels := 0.0
var drag_grid_offset := Vector3.ZERO
var sandbox_label: Label
const SANDBOX_PATH := "user://sandbox-layout.json"
var sensor: Area3D
var sensor_indicator: MeshInstance3D
var sensor_indicator_material: StandardMaterial3D
var sensor_bodies: Array[Node3D] = []
var selected_object: Node3D
var selection_label: Label
var selection_material: StandardMaterial3D
var transform_panel: PanelContainer
var transform_title: Label
var transform_value: Label
var conveyor_speed_row: HBoxContainer
var conveyor_speed_input: SpinBox
var modbus_coil_row: HBoxContainer
var modbus_coil_input: LineEdit
var modbus_input_row: HBoxContainer
var modbus_input_field: LineEdit
var force_panel: PanelContainer
var force_title: Label
var force_status_label: Label
var force_on_button: Button
var force_off_button: Button
var force_clear_button: Button
var io_status_panel: PanelContainer
var io_status_list: VBoxContainer
var io_status_buttons: Dictionary = {}
var object_dialog: PanelContainer
var object_dialog_backdrop: ColorRect
var modbus_dialog: PanelContainer
var modbus_dialog_backdrop: ColorRect
var modbus_ip_input: LineEdit
var modbus_port_input: SpinBox
var modbus_srv_status: Label
var modbus_io_grid: GridContainer
var modbus_config_button: Button
var axis_gizmo: Control
var status_label: Label
var counter_label: Label
var modbus_label: Label
var start_button: Button
var plc_button: Button
var running := true
var plc_mode := false
var detected_count := 0
var test_mode := false
var test_box: RigidBody3D
var elapsed := 0.0
var spawn_clock := 0.0
var spawn_plastic_next := false
var test_stopped := false
var test_resumed := false
var test_controls_ok := true
var cardboard_material: StandardMaterial3D
var plastic_material: StandardMaterial3D

func _ready() -> void:
	random.randomize()
	test_mode = "--smoke-test" in OS.get_cmdline_user_args()
	_build_world()
	_build_edit_grid()
	_build_ui()
	test_box = _spawn_box()
	if test_mode:
		_set_running(true)
	else:
		_apply_plc_mode(true)
		_set_running(false)
		sandbox_label.text = "Mode: STOP"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and rotating_object and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_update_rotation_drag(event.relative.x)
	elif event is InputEventMouseMotion and dragging_object and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_drag_selected_to(event.position)
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
		camera_yaw -= event.relative.x * 0.006
		camera_pitch = clampf(camera_pitch + event.relative.y * 0.006, 0.12, 1.35)
		_update_camera()
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
		var scale_factor := camera_distance * 0.0015
		camera_target += (-camera.global_basis.x * event.relative.x + camera.global_basis.y * event.relative.y) * scale_factor
		_update_camera()
	elif event is InputEventMouseMotion and edit_mode and placement != "select":
		_update_placement_preview(event.position)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if edit_mode and placement != "select":
				_place_at(event.position)
			else:
				_select_at(event.position)
				if edit_mode:
					if event.shift_pressed:
						_start_rotation_drag()
					else:
						_start_object_drag(event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = maxf(4.5, camera_distance - 1.0)
			_update_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = minf(35.0, camera_distance + 1.0)
			_update_camera()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		dragging_object = false
		rotating_object = false
		rotation_drag_pixels = 0.0
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_reset_camera()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_DELETE and edit_mode:
		_delete_selected()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and edit_mode:
		_set_placement("select")
	elif event is InputEventKey and event.pressed and not event.echo and edit_mode:
		match event.keycode:
			KEY_ESCAPE:
				if is_instance_valid(modbus_dialog) and modbus_dialog.visible:
					_set_modbus_dialog_visible(false)
				if is_instance_valid(object_dialog) and object_dialog.visible:
					_set_object_dialog_visible(false)
			KEY_LEFT: _move_selected(Vector3(-1, 0, 0))
			KEY_RIGHT: _move_selected(Vector3(1, 0, 0))
			KEY_UP: _move_selected(Vector3(0, 0, -1))
			KEY_DOWN: _move_selected(Vector3(0, 0, 1))
			KEY_PAGEUP: _move_selected_height(1)
			KEY_PAGEDOWN: _move_selected_height(-1)
			KEY_Q: _rotate_selected(-1)
			KEY_E: _rotate_selected(1)
			KEY_F: _toggle_turn_direction()

func _reset_camera() -> void:
	camera_yaw = 0.6435
	camera_pitch = 0.447
	camera_distance = 19.4
	camera_target = CAMERA_TARGET
	_update_camera()

func _select_at(screen_position: Vector2) -> void:
	var origin := camera.project_ray_origin(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + camera.project_ray_normal(screen_position) * 1000.0, 3)
	query.collide_with_areas = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var collider := hit.get("collider") as Node3D
	var cursor: Node = collider
	while cursor != null:
		if cursor is Node3D and cursor.is_in_group("sandbox_objects"):
			collider = cursor as Node3D
			break
		cursor = cursor.get_parent()
	_set_selection(collider)

func _set_selection(object: Node3D) -> void:
	if is_instance_valid(selected_object):
		_set_selection_overlay(selected_object, null)
	selected_object = object
	if not is_instance_valid(object):
		selection_label.text = "Selected: none"
		_refresh_transform_controls()
		return
	if selection_material == null:
		selection_material = StandardMaterial3D.new()
		selection_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		selection_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		selection_material.albedo_color = Color(1.0, 0.85, 0.2, 0.3)
	_set_selection_overlay(object, selection_material)
	if object == conveyor:
		selection_label.text = "Selected: Conveyor"
	elif object == sensor:
		selection_label.text = "Selected: Sensor A"
	elif object.is_in_group("sandbox_objects"):
		selection_label.text = "Selected: " + str(object.get_meta("kind")).replace("_", " ")
	elif object.is_in_group("product_boxes"):
		selection_label.text = "Selected: Box"
	else:
		selection_label.text = "Selected: Floor"
	_refresh_transform_controls()

func _set_selection_overlay(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		node.material_overlay = material
	for child in node.get_children():
		_set_selection_overlay(child, material)

func _update_camera() -> void:
	var horizontal := camera_distance * cos(camera_pitch)
	camera.position = camera_target + Vector3(horizontal * sin(camera_yaw), camera_distance * sin(camera_pitch), horizontal * cos(camera_yaw))
	camera.look_at(camera_target, Vector3.UP)
	if is_instance_valid(axis_gizmo):
		axis_gizmo.queue_redraw()

func _physics_process(delta: float) -> void:
	elapsed += delta
	if not test_mode:
		for box in get_tree().get_nodes_in_group("product_boxes"):
			if box.global_position.y < -4.0:
				if box == selected_object:
					_set_selection(null)
				if box.is_in_group("sandbox_objects"):
					box.freeze = true
					box.visible = false
				else:
					box.queue_free()
	if running:
		spawn_clock += delta
		if not test_mode and spawn_clock >= 3.5 and not _has_placed_products():
			spawn_clock = 0.0
			_spawn_box()
	if is_instance_valid(modbus_label):
		modbus_label.text = "Modbus :%d (%d)" % [ModbusTCP.port, ModbusTCP.client_count()]
	if plc_mode:
		_sync_modbus_io()
	if is_instance_valid(force_panel) and force_panel.visible:
		_refresh_force_panel()
	_refresh_io_status_list()
	if test_mode and elapsed >= 3.0 and not test_stopped:
		_toggle_conveyor()
		test_controls_ok = test_controls_ok and not running and conveyor.constant_linear_velocity == Vector3.ZERO
		test_stopped = true
	if test_mode and elapsed >= 4.0 and not test_resumed:
		_toggle_conveyor()
		test_controls_ok = test_controls_ok and running and is_equal_approx(conveyor.constant_linear_velocity.x, BELT_SPEED)
		test_resumed = true
	if test_mode and elapsed >= 7.0:
		var advanced := is_instance_valid(test_box) and test_box.global_position.x > -1.0
		if detected_count > 0 and advanced and test_controls_ok and test_resumed:
			print("SMOKE_TEST_PASS sensor_detected=", detected_count, " box_x=", test_box.global_position.x, " controls=ok")
			get_tree().quit(0)
		else:
			push_error("SMOKE_TEST_FAIL sensor_detected=%d box_x=%s" % [detected_count, str(test_box.global_position.x)])
			get_tree().quit(1)

func _material(color: Color, roughness: float = 0.8) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	return mat

func _cardboard_material() -> StandardMaterial3D:
	if cardboard_material != null:
		return cardboard_material
	var noise := FastNoiseLite.new()
	noise.seed = 42
	noise.frequency = 0.16
	var gradient := Gradient.new()
	gradient.set_color(0, Color("976437"))
	gradient.set_color(1, Color("d6a36b"))
	var texture := NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.noise = noise
	texture.color_ramp = gradient
	texture.seamless = true
	cardboard_material = StandardMaterial3D.new()
	cardboard_material.albedo_texture = texture
	cardboard_material.roughness = 1.0
	return cardboard_material

func _plastic_material() -> StandardMaterial3D:
	if plastic_material == null:
		plastic_material = StandardMaterial3D.new()
		plastic_material.roughness = 0.55
	return plastic_material

func _box_mesh(parent: Node, dimensions: Vector3, location: Vector3, color: Color) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	visual.mesh = mesh
	visual.material_override = _material(color)
	visual.position = location
	parent.add_child(visual)
	return visual

func _collision(parent: Node, dimensions: Vector3, location: Vector3 = Vector3.ZERO) -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	collision.position = location
	parent.add_child(collision)

func _static_box(parent: Node, dimensions: Vector3, location: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = location
	parent.add_child(body)
	_box_mesh(body, dimensions, Vector3.ZERO, color)
	_collision(body, dimensions)
	return body

func _build_world() -> void:
	var environment := WorldEnvironment.new()
	environment.name = "FactoryEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("182536")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("cbdfff")
	env.ambient_light_energy = 0.65
	environment.environment = env
	add_child(environment)

	var light := DirectionalLight3D.new()
	light.name = "FactorySunLight"
	light.rotation_degrees = Vector3(-55, -35, 0)
	light.light_energy = 1.3
	light.shadow_enabled = true
	add_child(light)

	camera = Camera3D.new()
	camera.name = "FactoryCamera"
	add_child(camera)
	_update_camera()
	camera.current = true
	camera.fov = 45.0

	floor_body = _static_box(self, Vector3(workspace_width, 0.25, workspace_depth), Vector3(0, -0.18, 0), Color("293b4a"))
	floor_body.name = "FactoryFloor"
	(floor_body.get_child(1) as CollisionShape3D).position.y = 0.01

	# Primary line: MainConveyor -> EntrySensor -> QueueStopper -> CornerTurn -> BranchConveyor -> DivertPusher -> ReturnConveyor
	conveyor = _create_sandbox_object("conveyor", Vector3.ZERO, true) as StaticBody3D
	conveyor.name = "MainConveyor"
	conveyor.set_meta("base_id", "base_conveyor")

	sensor = _create_sandbox_object("sensor", Vector3.ZERO, true) as Area3D
	sensor.name = "EntrySensor"
	sensor.set_meta("base_id", "base_sensor")
	sensor_indicator = sensor.get_node("Indicator") as MeshInstance3D
	sensor_indicator_material = sensor_indicator.material_override as StandardMaterial3D

	if not test_mode:
		var queue_stopper := _create_sandbox_object("stopper", Vector3(3.2, 0, 0))
		if queue_stopper != null:
			queue_stopper.name = "QueueStopper"

		var corner_turn := _create_sandbox_object("turn", Vector3(5.25, 0, 0))
		if corner_turn != null:
			corner_turn.name = "CornerTurn"

		var branch_conveyor := _create_sandbox_object("conveyor", Vector3(5.25, 0, 5.25))
		if branch_conveyor != null:
			branch_conveyor.name = "BranchConveyor"
			branch_conveyor.rotation_degrees.y = -90.0

		var divert_pusher := _create_sandbox_object("pusher", Vector3(6.45, 0, 4.5))
		if divert_pusher != null:
			divert_pusher.name = "DivertPusher"
			divert_pusher.rotation_degrees.y = -90.0

		var return_conveyor := _create_sandbox_object("conveyor", Vector3(0.0, 0, 4.5))
		if return_conveyor != null:
			return_conveyor.name = "ReturnConveyor"
			return_conveyor.rotation_degrees.y = 180.0

		for obj in [conveyor, sensor, queue_stopper, corner_turn, branch_conveyor, divert_pusher, return_conveyor]:
			if is_instance_valid(obj):
				_set_object_active_state(obj, false)

func _set_object_active_state(obj: Node3D, is_active: bool) -> void:
	var kind := str(obj.get_meta("kind", ""))
	if kind == "turn":
		var area := obj.get_node_or_null("TransferArea")
		if area != null:
			area.set("active", is_active)
	elif kind == "sensor":
		obj.call("set_detected", is_active)
	elif "active" in obj:
		obj.set("active", is_active)

func _ui_stylebox(bg: Color, border: Color = Color(0, 0, 0, 0), radius: int = 8, border_w: int = 1, pad_h: int = 10, pad_v: int = 6) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(border_w if border.a > 0.0 else 0)
	box.set_corner_radius_all(radius)
	box.content_margin_left = pad_h
	box.content_margin_right = pad_h
	box.content_margin_top = pad_v
	box.content_margin_bottom = pad_v
	return box

func _build_ui_theme() -> Theme:
	var ui_theme := Theme.new()
	ui_theme.set_stylebox("normal", "Button", _ui_stylebox(Color("1c2a36"), Color("2f4556"), 7, 1, 12, 6))
	ui_theme.set_stylebox("hover", "Button", _ui_stylebox(Color("263949"), Color("4a6b82"), 7, 1, 12, 6))
	ui_theme.set_stylebox("pressed", "Button", _ui_stylebox(Color("142029"), Color("5c85a1"), 7, 1, 12, 6))
	ui_theme.set_stylebox("focus", "Button", _ui_stylebox(Color("1c2a36"), Color("58b4d1"), 7, 1, 12, 6))
	ui_theme.set_color("font_color", "Button", Color("e4edf2"))
	ui_theme.set_color("font_hover_color", "Button", Color("ffffff"))
	ui_theme.set_color("font_pressed_color", "Button", Color("cfe8f5"))
	ui_theme.set_font_size("font_size", "Button", 13)

	ui_theme.set_color("font_color", "Label", Color("c9d7e0"))
	ui_theme.set_font_size("font_size", "Label", 13)

	ui_theme.set_stylebox("normal", "LineEdit", _ui_stylebox(Color("111a22"), Color("2f4556"), 6, 1, 8, 4))
	ui_theme.set_stylebox("focus", "LineEdit", _ui_stylebox(Color("111a22"), Color("58b4d1"), 6, 1, 8, 4))
	ui_theme.set_color("font_color", "LineEdit", Color("edf5f8"))
	ui_theme.set_font_size("font_size", "LineEdit", 13)
	return ui_theme

func _style_accent_button(button: Button, normal_hex: String, hover_hex: String, border_hex: String) -> void:
	button.add_theme_stylebox_override("normal", _ui_stylebox(Color(normal_hex), Color(border_hex), 7, 1, 12, 6))
	button.add_theme_stylebox_override("hover", _ui_stylebox(Color(hover_hex), Color(border_hex), 7, 1, 12, 6))
	button.add_theme_stylebox_override("pressed", _ui_stylebox(Color(normal_hex).darkened(0.2), Color(border_hex), 7, 1, 12, 6))
	button.add_theme_color_override("font_color", Color("ffffff"))

func _make_ui_divider() -> VSeparator:
	var sep := VSeparator.new()
	sep.custom_minimum_size = Vector2(2, 24)
	sep.add_theme_stylebox_override("separator", _ui_stylebox(Color("2a3f50"), Color(0, 0, 0, 0), 1, 0, 0, 0))
	return sep

func _make_status_pill(parent: Control, initial_text: String, text_color: Color = Color("c9d7e0")) -> Label:
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", _ui_stylebox(Color("121d26"), Color("283c4c"), 12, 1, 10, 4))
	parent.add_child(pill)
	var label := Label.new()
	label.text = initial_text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", text_color)
	pill.add_child(label)
	return label

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var ui_root := Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.theme = _build_ui_theme()
	canvas.add_child(ui_root)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left = 12
	panel.offset_top = 10
	panel.offset_right = -12
	var background := _ui_stylebox(Color(0.063, 0.098, 0.137, 0.92), Color("294052"), 12, 1, 16, 10)
	background.shadow_color = Color(0, 0, 0, 0.35)
	background.shadow_size = 8
	panel.add_theme_stylebox_override("panel", background)
	ui_root.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)

	# Row 1: Brand + Primary Sim Controls + Live Status Pills
	var toolbar := HFlowContainer.new()
	toolbar.add_theme_constant_override("h_separation", 8)
	toolbar.add_theme_constant_override("v_separation", 6)
	column.add_child(toolbar)

	var title := Label.new()
	title.text = "FACTORY 3D"
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color("eef7fa"))
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toolbar.add_child(title)

	sandbox_label = _make_status_pill(toolbar, "Mode: RUN", Color("66e0a3"))
	toolbar.add_child(_make_ui_divider())

	var edit_button := Button.new()
	edit_button.text = "Edit"
	edit_button.custom_minimum_size = Vector2(68, 32)
	_style_accent_button(edit_button, "1b4f6e", "23668f", "3b8cb8")
	edit_button.pressed.connect(_enter_edit_mode)
	toolbar.add_child(edit_button)

	start_button = Button.new()
	start_button.text = "Run"
	start_button.custom_minimum_size = Vector2(78, 32)
	_style_accent_button(start_button, "1e6b45", "278758", "3eb87a")
	start_button.pressed.connect(func():
		if running:
			_set_running(false)
			if not edit_mode:
				sandbox_label.text = "Mode: STOP"
		else:
			_clear_preview()
			edit_grid.visible = false
			edit_mode = false
			placement = "select"
			_set_running(true)
			sandbox_label.text = "Mode: RUN"
	)
	toolbar.add_child(start_button)

	var reset_button := Button.new()
	reset_button.text = "Reset"
	reset_button.custom_minimum_size = Vector2(68, 32)
	reset_button.pressed.connect(_reset_simulation)
	toolbar.add_child(reset_button)

	var reset_view := Button.new()
	reset_view.text = "Reset View"
	reset_view.custom_minimum_size = Vector2(92, 32)
	reset_view.pressed.connect(_reset_camera)
	toolbar.add_child(reset_view)

	plc_button = Button.new()
	plc_button.text = "Control: AUTO"
	plc_button.custom_minimum_size = Vector2(114, 32)
	plc_button.tooltip_text = "Toggle between AUTO demo and PLC Modbus TCP (:1502)"
	plc_button.pressed.connect(_toggle_plc_mode)
	toolbar.add_child(plc_button)

	modbus_config_button = Button.new()
	modbus_config_button.text = "Modbus Setup"
	modbus_config_button.custom_minimum_size = Vector2(108, 32)
	modbus_config_button.tooltip_text = "Configure Modbus TCP server & I/O mapping"
	modbus_config_button.pressed.connect(func(): _set_modbus_dialog_visible(not modbus_dialog.visible if is_instance_valid(modbus_dialog) else true))
	toolbar.add_child(modbus_config_button)

	toolbar.add_child(_make_ui_divider())
	status_label = _make_status_pill(toolbar, "Conveyor: RUNNING", Color("8bd3ff"))
	counter_label = _make_status_pill(toolbar, "Sensor A: 0 boxes detected", Color("f7d070"))
	modbus_label = _make_status_pill(toolbar, "Modbus :1502 (0)", Color("8de0c8"))
	selection_label = _make_status_pill(toolbar, "Selected: none", Color("b5c7d4"))

	# Row 2: Placement, Transform, Layout & Workspace Tools
	var edit_tools := HFlowContainer.new()
	edit_tools.add_theme_constant_override("h_separation", 6)
	edit_tools.add_theme_constant_override("v_separation", 6)
	column.add_child(edit_tools)

	var select_button := Button.new()
	select_button.text = "Select"
	select_button.pressed.connect(func(): _enter_edit_mode(); _set_placement("select"))
	edit_tools.add_child(select_button)

	var add_object_button := Button.new()
	add_object_button.text = "+ Add Object..."
	_style_accent_button(add_object_button, "1b4f6e", "23668f", "3b8cb8")
	add_object_button.pressed.connect(func(): _set_object_dialog_visible(not object_dialog.visible if is_instance_valid(object_dialog) else true))
	edit_tools.add_child(add_object_button)

	edit_tools.add_child(_make_ui_divider())

	var rotate_left := Button.new()
	rotate_left.text = "Rotate -90° (Q)"
	rotate_left.pressed.connect(func(): _rotate_selected(-1))
	edit_tools.add_child(rotate_left)

	var rotate_right := Button.new()
	rotate_right.text = "Rotate +90° (E)"
	rotate_right.pressed.connect(func(): _rotate_selected(1))
	edit_tools.add_child(rotate_right)

	var reverse_turn := Button.new()
	reverse_turn.text = "Reverse Turn (F)"
	reverse_turn.pressed.connect(_toggle_turn_direction)
	edit_tools.add_child(reverse_turn)

	var delete_button := Button.new()
	delete_button.text = "Delete"
	_style_accent_button(delete_button, "592428", "783036", "a34850")
	delete_button.pressed.connect(_delete_selected)
	edit_tools.add_child(delete_button)

	edit_tools.add_child(_make_ui_divider())

	for item in [["Save", _save_layout], ["Load", _load_layout]]:
		var button := Button.new()
		button.text = item[0]
		button.pressed.connect(item[1])
		edit_tools.add_child(button)

	edit_tools.add_child(_make_ui_divider())

	var size_title := Label.new()
	size_title.text = "Floor:"
	size_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	edit_tools.add_child(size_title)

	width_input = SpinBox.new()
	width_input.min_value = 10
	width_input.max_value = 100
	width_input.step = 1
	width_input.value = workspace_width
	width_input.custom_minimum_size.x = 76
	edit_tools.add_child(width_input)

	var x_label := Label.new()
	x_label.text = "×"
	x_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	edit_tools.add_child(x_label)

	depth_input = SpinBox.new()
	depth_input.min_value = 10
	depth_input.max_value = 100
	depth_input.step = 1
	depth_input.value = workspace_depth
	depth_input.custom_minimum_size.x = 76
	edit_tools.add_child(depth_input)

	var apply_size := Button.new()
	apply_size.text = "Apply"
	apply_size.pressed.connect(_apply_workspace_input)
	edit_tools.add_child(apply_size)

	# Bottom-left keyboard shortcut hint pill
	var info_pill := PanelContainer.new()
	info_pill.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	info_pill.offset_left = 14
	info_pill.offset_top = -42
	info_pill.offset_bottom = -12
	info_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_pill.add_theme_stylebox_override("panel", _ui_stylebox(Color(0.063, 0.098, 0.137, 0.82), Color("233747"), 8, 1, 12, 4))
	ui_root.add_child(info_pill)

	var info := Label.new()
	info.text = "X/Y: floor  |  Z: PgUp/PgDn  |  Drag: move  |  Shift+Drag: rotate Z  |  Q/E: rotate  |  Esc: cancel"
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_theme_font_size_override("font_size", 12)
	info.add_theme_color_override("font_color", Color("9cb3c4"))
	info_pill.add_child(info)

	axis_gizmo = Control.new()
	axis_gizmo.name = "WorldAxisGizmo"
	axis_gizmo.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	axis_gizmo.offset_left = 18
	axis_gizmo.offset_top = -182
	axis_gizmo.offset_right = 170
	axis_gizmo.offset_bottom = -46
	axis_gizmo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	axis_gizmo.draw.connect(_draw_axis_gizmo)
	axis_gizmo.visible = false
	ui_root.add_child(axis_gizmo)
	_build_transform_controls(ui_root)
	_build_force_panel(ui_root)
	_build_io_status_panel(ui_root)
	_build_object_dialog(ui_root)
	_build_modbus_dialog(ui_root)

func _build_io_status_panel(ui_root: Control) -> void:
	io_status_panel = PanelContainer.new()
	io_status_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	io_status_panel.offset_left = 14
	io_status_panel.offset_top = 114
	io_status_panel.offset_right = 236
	var style := _ui_stylebox(Color(0.063, 0.098, 0.137, 0.86), Color("294052"), 10, 1, 10, 10)
	io_status_panel.add_theme_stylebox_override("panel", style)
	ui_root.add_child(io_status_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	io_status_panel.add_child(vbox)

	var header := Label.new()
	header.text = "OBJECT STATUS"
	header.add_theme_font_size_override("font_size", 11)
	header.add_theme_color_override("font_color", Color("7ea7c2"))
	vbox.add_child(header)

	io_status_list = VBoxContainer.new()
	io_status_list.add_theme_constant_override("separation", 3)
	vbox.add_child(io_status_list)
	_refresh_io_status_list()

func _refresh_io_status_list() -> void:
	if not is_instance_valid(io_status_list):
		return
	var equipment: Array[Node3D] = []
	for obj in get_tree().get_nodes_in_group("sandbox_objects"):
		if str(obj.get_meta("kind", "")) not in PRODUCT_KINDS:
			equipment.append(obj as Node3D)
	if io_status_buttons.size() != equipment.size():
		for child in io_status_list.get_children():
			child.queue_free()
		io_status_buttons.clear()
		for obj in equipment:
			var btn := Button.new()
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.custom_minimum_size = Vector2(198, 24)
			btn.add_theme_font_size_override("font_size", 12)
			var target := obj
			btn.pressed.connect(func(): _set_selection(target))
			io_status_list.add_child(btn)
			io_status_buttons[obj.get_instance_id()] = btn
	for obj in equipment:
		var btn: Button = io_status_buttons.get(obj.get_instance_id())
		if btn == null:
			continue
		var is_active := _is_object_active(obj)
		var tag := "FORCED" if obj.has_meta("forced_active") else ("ACTIVE" if is_active else "DEACTIVE")
		btn.text = "%s  [%s]" % [obj.name, tag]
		var col := Color("f7d070") if obj.has_meta("forced_active") else (Color("66e0a3") if is_active else Color("8aa0b0"))
		btn.add_theme_color_override("font_color", col)

func _build_force_panel(ui_root: Control) -> void:
	force_panel = PanelContainer.new()
	force_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	force_panel.offset_left = -280
	force_panel.offset_top = -155
	force_panel.offset_right = -16
	force_panel.offset_bottom = -46
	var style := _ui_stylebox(Color(0.063, 0.098, 0.137, 0.92), Color("294052"), 12, 1, 12, 12)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 8
	force_panel.add_theme_stylebox_override("panel", style)
	force_panel.visible = false
	ui_root.add_child(force_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	force_panel.add_child(vbox)

	force_title = Label.new()
	force_title.text = "FORCE I/O"
	force_title.add_theme_font_size_override("font_size", 14)
	force_title.add_theme_color_override("font_color", Color("eef7fa"))
	vbox.add_child(force_title)

	force_status_label = Label.new()
	force_status_label.text = "Status: DEACTIVE"
	vbox.add_child(force_status_label)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 6)
	vbox.add_child(btn_row)

	force_on_button = Button.new()
	force_on_button.text = "Force ON"
	force_on_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_accent_button(force_on_button, "1e6b45", "278758", "3eb87a")
	force_on_button.pressed.connect(func(): _set_object_force(selected_object, true))
	btn_row.add_child(force_on_button)

	force_off_button = Button.new()
	force_off_button.text = "Force OFF"
	force_off_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_accent_button(force_off_button, "7a2e33", "993b41", "cc5a61")
	force_off_button.pressed.connect(func(): _set_object_force(selected_object, false))
	btn_row.add_child(force_off_button)

	force_clear_button = Button.new()
	force_clear_button.text = "Release"
	force_clear_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	force_clear_button.pressed.connect(func(): _clear_object_force(selected_object))
	btn_row.add_child(force_clear_button)

func _is_object_active(obj: Node3D) -> bool:
	var kind := str(obj.get_meta("kind", ""))
	if kind == "turn":
		var area := obj.get_node_or_null("TransferArea")
		return bool(area.get("active")) if area != null else false
	return bool(obj.get("active"))

func _set_object_force(obj: Node3D, value: bool) -> void:
	if not is_instance_valid(obj) or str(obj.get_meta("kind", "")) in PRODUCT_KINDS:
		return
	obj.set_meta("forced_active", value)
	_apply_object_force(obj, value)
	_refresh_boxes_freeze()
	_refresh_force_panel()

func _clear_object_force(obj: Node3D) -> void:
	if not is_instance_valid(obj):
		return
	if obj.has_meta("forced_active"):
		obj.remove_meta("forced_active")
	var kind := str(obj.get_meta("kind", ""))
	if kind in ["pusher", "stopper"]:
		obj.set("plc_mode", plc_mode)
		if not plc_mode:
			obj.set("active", false)
	elif kind == "turn":
		var area := obj.get_node_or_null("TransferArea")
		if area != null:
			area.set("plc_mode", plc_mode)
			if not plc_mode:
				area.set("active", running)
	elif kind == "conveyor" and obj is StaticBody3D:
		_apply_conveyor_speed(obj as StaticBody3D)
	_refresh_boxes_freeze()
	_refresh_force_panel()

func _has_any_forced_active() -> bool:
	for obj in get_tree().get_nodes_in_group("sandbox_objects"):
		if obj.has_meta("forced_active") and bool(obj.get_meta("forced_active")):
			return true
	return false

func _refresh_boxes_freeze() -> void:
	var should_freeze := (not running) and (not _has_any_forced_active())
	for box in get_tree().get_nodes_in_group("product_boxes"):
		box.freeze = should_freeze

func _apply_object_force(obj: Node3D, value: bool) -> void:
	var kind := str(obj.get_meta("kind", ""))
	match kind:
		"conveyor":
			obj.set("active", value)
		"turn":
			var area := obj.get_node_or_null("TransferArea")
			if area != null:
				area.set("plc_mode", true)
				area.set("active", value)
		"pusher", "stopper":
			obj.set("plc_mode", true)
			obj.set("active", value)
		"sensor":
			obj.call("set_detected", value)

func _refresh_force_panel() -> void:
	if not is_instance_valid(force_panel):
		return
	var show_force := (not edit_mode) and is_instance_valid(selected_object) and selected_object.is_in_group("sandbox_objects") and (str(selected_object.get_meta("kind", "")) not in PRODUCT_KINDS)
	force_panel.visible = show_force
	if not show_force:
		return
	force_title.text = "FORCE: " + selected_object.name
	var is_active := _is_object_active(selected_object)
	if selected_object.has_meta("forced_active"):
		var f_val := bool(selected_object.get_meta("forced_active"))
		force_status_label.text = "Status: FORCED ON" if f_val else "Status: FORCED OFF"
		force_status_label.add_theme_color_override("font_color", Color("f7d070"))
	else:
		force_status_label.text = "Status: ACTIVE" if is_active else "Status: DEACTIVE"
		force_status_label.add_theme_color_override("font_color", Color("66e0a3") if is_active else Color("9cb3c4"))
	force_clear_button.disabled = not selected_object.has_meta("forced_active")

func _set_object_dialog_visible(visible_state: bool) -> void:
	if is_instance_valid(object_dialog_backdrop):
		object_dialog_backdrop.visible = visible_state
	if is_instance_valid(object_dialog):
		object_dialog.visible = visible_state

func _build_object_dialog(ui_root: Control) -> void:
	object_dialog_backdrop = ColorRect.new()
	object_dialog_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	object_dialog_backdrop.color = Color(0.02, 0.04, 0.06, 0.45)
	object_dialog_backdrop.visible = false
	object_dialog_backdrop.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_set_object_dialog_visible(false)
	)
	ui_root.add_child(object_dialog_backdrop)

	object_dialog = PanelContainer.new()
	object_dialog.set_anchors_preset(Control.PRESET_CENTER)
	object_dialog.custom_minimum_size = Vector2(440, 0)
	object_dialog.offset_left = -220
	object_dialog.offset_right = 220
	object_dialog.offset_top = -175
	object_dialog.offset_bottom = 175
	var dialog_style := _ui_stylebox(Color(0.068, 0.106, 0.149, 0.97), Color("36566e"), 14, 1, 18, 16)
	dialog_style.shadow_color = Color(0, 0, 0, 0.55)
	dialog_style.shadow_size = 16
	object_dialog.add_theme_stylebox_override("panel", dialog_style)
	object_dialog.visible = false
	ui_root.add_child(object_dialog)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	object_dialog.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)
	var heading := Label.new()
	heading.text = "ADD FACTORY OBJECT"
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_font_size_override("font_size", 15)
	heading.add_theme_color_override("font_color", Color("eef7fa"))
	header.add_child(heading)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(30, 28)
	close_btn.pressed.connect(func(): _set_object_dialog_visible(false))
	header.add_child(close_btn)

	var categories := [
		["EQUIPMENT", [
			["Conveyor Belt", "9.0m straight belt", "conveyor"],
			["Turn Table", "90° pop-up transfer", "turn"],
			["Photo Sensor", "Optical beam detector", "sensor"],
			["Pusher", "Pneumatic diverter", "pusher"],
			["Pneumatic Stopper", "Queue gate before turn", "stopper"],
		]],
		["PRODUCTS", [
			["Cardboard Box", "Standard carton", "box"],
			["Plastic Crate", "Euro stackable crate", "box_plastic"],
		]],
	]
	for cat in categories:
		var cat_label := Label.new()
		cat_label.text = cat[0]
		cat_label.add_theme_font_size_override("font_size", 11)
		cat_label.add_theme_color_override("font_color", Color("7ea7c2"))
		vbox.add_child(cat_label)

		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		vbox.add_child(grid)

		for item in cat[1]:
			var btn := Button.new()
			btn.text = "%s\n%s" % [item[0], item[1]]
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.custom_minimum_size = Vector2(194, 52)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var kind: String = item[2]
			btn.pressed.connect(func():
				_set_object_dialog_visible(false)
				_enter_edit_mode()
				_set_placement(kind)
			)
			grid.add_child(btn)

func _set_modbus_dialog_visible(visible_state: bool) -> void:
	if visible_state:
		_refresh_modbus_dialog()
	if is_instance_valid(modbus_dialog_backdrop):
		modbus_dialog_backdrop.visible = visible_state
	if is_instance_valid(modbus_dialog):
		modbus_dialog.visible = visible_state

func _build_modbus_dialog(ui_root: Control) -> void:
	modbus_dialog_backdrop = ColorRect.new()
	modbus_dialog_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	modbus_dialog_backdrop.color = Color(0.02, 0.04, 0.06, 0.45)
	modbus_dialog_backdrop.visible = false
	modbus_dialog_backdrop.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_set_modbus_dialog_visible(false)
	)
	ui_root.add_child(modbus_dialog_backdrop)

	modbus_dialog = PanelContainer.new()
	modbus_dialog.set_anchors_preset(Control.PRESET_CENTER)
	modbus_dialog.custom_minimum_size = Vector2(560, 0)
	modbus_dialog.offset_left = -280
	modbus_dialog.offset_right = 280
	modbus_dialog.offset_top = -230
	modbus_dialog.offset_bottom = 230
	var style := _ui_stylebox(Color(0.068, 0.106, 0.149, 0.97), Color("36566e"), 14, 1, 18, 16)
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 16
	modbus_dialog.add_theme_stylebox_override("panel", style)
	modbus_dialog.visible = false
	ui_root.add_child(modbus_dialog)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	modbus_dialog.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)
	var heading := Label.new()
	heading.text = "MODBUS TCP & I/O MAPPING"
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_font_size_override("font_size", 15)
	heading.add_theme_color_override("font_color", Color("eef7fa"))
	header.add_child(heading)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(30, 28)
	close_btn.pressed.connect(func(): _set_modbus_dialog_visible(false))
	header.add_child(close_btn)

	# Server settings row
	var srv_row := HBoxContainer.new()
	srv_row.add_theme_constant_override("separation", 8)
	vbox.add_child(srv_row)

	var ip_lbl := Label.new()
	ip_lbl.text = "Bind IP:"
	srv_row.add_child(ip_lbl)

	modbus_ip_input = LineEdit.new()
	modbus_ip_input.text = ModbusTCP.bind_address
	modbus_ip_input.custom_minimum_size.x = 120
	srv_row.add_child(modbus_ip_input)

	var port_lbl := Label.new()
	port_lbl.text = "Port:"
	srv_row.add_child(port_lbl)

	modbus_port_input = SpinBox.new()
	modbus_port_input.min_value = 1
	modbus_port_input.max_value = 65535
	modbus_port_input.step = 1
	modbus_port_input.value = ModbusTCP.port
	modbus_port_input.custom_minimum_size.x = 90
	srv_row.add_child(modbus_port_input)

	var restart_btn := Button.new()
	restart_btn.text = "Apply & Restart"
	_style_accent_button(restart_btn, "1b4f6e", "23668f", "3b8cb8")
	restart_btn.pressed.connect(_apply_modbus_server_settings)
	srv_row.add_child(restart_btn)

	modbus_srv_status = Label.new()
	modbus_srv_status.add_theme_font_size_override("font_size", 12)
	vbox.add_child(modbus_srv_status)

	var table_title := Label.new()
	table_title.text = "OBJECT I/O ADDRESSES (IEC 61131-3: %QX / %IX or 0..255; empty = unused)"
	table_title.add_theme_font_size_override("font_size", 11)
	table_title.add_theme_color_override("font_color", Color("7ea7c2"))
	vbox.add_child(table_title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 230)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	modbus_io_grid = GridContainer.new()
	modbus_io_grid.columns = 4
	modbus_io_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modbus_io_grid.add_theme_constant_override("h_separation", 8)
	modbus_io_grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(modbus_io_grid)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	vbox.add_child(footer)

	var auto_btn := Button.new()
	auto_btn.text = "Auto-Map IEC"
	_style_accent_button(auto_btn, "1e6b45", "278758", "3eb87a")
	auto_btn.pressed.connect(_auto_map_modbus_iec)
	footer.add_child(auto_btn)

	var clear_btn := Button.new()
	clear_btn.text = "Clear All"
	_style_accent_button(clear_btn, "592428", "783036", "a34850")
	clear_btn.pressed.connect(_clear_all_modbus_tags)
	footer.add_child(clear_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)

	var done_btn := Button.new()
	done_btn.text = "Done"
	done_btn.custom_minimum_size = Vector2(84, 30)
	done_btn.pressed.connect(func(): _set_modbus_dialog_visible(false))
	footer.add_child(done_btn)

func _apply_modbus_server_settings() -> void:
	ModbusTCP.stop_server()
	ModbusTCP.bind_address = modbus_ip_input.text.strip_edges() if not modbus_ip_input.text.strip_edges().is_empty() else "0.0.0.0"
	ModbusTCP.port = int(modbus_port_input.value)
	ModbusTCP.start_server()
	_refresh_modbus_dialog()

func _auto_map_modbus_iec() -> void:
	var next_coil := 0
	var next_input := 0
	for obj in get_tree().get_nodes_in_group("sandbox_objects"):
		var kind := str(obj.get_meta("kind", ""))
		if kind in PRODUCT_KINDS:
			continue
		if kind in ["conveyor", "turn", "pusher", "stopper"]:
			obj.set_meta("modbus_coil", next_coil)
			next_coil += 1
		if kind in ["sensor", "stopper"]:
			obj.set_meta("modbus_input", next_input)
			next_input += 1
	_refresh_modbus_dialog()
	_refresh_transform_controls()

func _clear_all_modbus_tags() -> void:
	for obj in get_tree().get_nodes_in_group("sandbox_objects"):
		if str(obj.get_meta("kind", "")) not in PRODUCT_KINDS:
			obj.set_meta("modbus_coil", -1)
			obj.set_meta("modbus_input", -1)
	_refresh_modbus_dialog()
	_refresh_transform_controls()

func _refresh_modbus_dialog() -> void:
	if not is_instance_valid(modbus_io_grid):
		return
	if is_instance_valid(modbus_ip_input):
		modbus_ip_input.text = ModbusTCP.bind_address
	if is_instance_valid(modbus_port_input):
		modbus_port_input.value = ModbusTCP.port
	if is_instance_valid(modbus_srv_status):
		if ModbusTCP.is_listening():
			modbus_srv_status.text = "Server: LISTENING on %s:%d (%d clients)" % [ModbusTCP.bind_address, ModbusTCP.port, ModbusTCP.client_count()]
			modbus_srv_status.add_theme_color_override("font_color", Color("66e0a3"))
		else:
			modbus_srv_status.text = "Server: STOPPED (port %d unavailable)" % ModbusTCP.port
			modbus_srv_status.add_theme_color_override("font_color", Color("f06d6d"))

	for child in modbus_io_grid.get_children():
		child.queue_free()
	for h in ["Object", "Type", "Coil (Active)", "Input (DI)"]:
		var lbl := Label.new()
		lbl.text = h
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color("9cb3c4"))
		modbus_io_grid.add_child(lbl)

	for obj in get_tree().get_nodes_in_group("sandbox_objects"):
		var kind := str(obj.get_meta("kind", ""))
		if kind in PRODUCT_KINDS:
			continue
		var name_lbl := Label.new()
		name_lbl.text = obj.name
		name_lbl.custom_minimum_size.x = 135
		modbus_io_grid.add_child(name_lbl)

		var type_lbl := Label.new()
		type_lbl.text = kind
		type_lbl.custom_minimum_size.x = 75
		type_lbl.add_theme_color_override("font_color", Color("8aa0b0"))
		modbus_io_grid.add_child(type_lbl)

		var coil_edit := LineEdit.new()
		coil_edit.custom_minimum_size.x = 130
		coil_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var has_coil := kind in ["conveyor", "turn", "pusher", "stopper"]
		coil_edit.editable = has_coil
		coil_edit.placeholder_text = "%QX0.0" if has_coil else "-"
		coil_edit.text = _format_iec_address(int(obj.get_meta("modbus_coil", -1)), "QX") if has_coil else ""
		if has_coil:
			var target_obj := obj
			coil_edit.text_changed.connect(func(txt: String):
				var p := _parse_iec_or_int_address(txt)
				if p >= -1:
					target_obj.set_meta("modbus_coil", p)
			)
			coil_edit.focus_exited.connect(func():
				coil_edit.text = _format_iec_address(int(target_obj.get_meta("modbus_coil", -1)), "QX")
			)
		modbus_io_grid.add_child(coil_edit)

		var input_edit := LineEdit.new()
		input_edit.custom_minimum_size.x = 130
		input_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var has_input := kind in ["sensor", "stopper"]
		input_edit.editable = has_input
		input_edit.placeholder_text = "%IX0.0" if has_input else "-"
		input_edit.text = _format_iec_address(int(obj.get_meta("modbus_input", -1)), "IX") if has_input else ""
		if has_input:
			var target_obj := obj
			input_edit.text_changed.connect(func(txt: String):
				var p := _parse_iec_or_int_address(txt)
				if p >= -1:
					target_obj.set_meta("modbus_input", p)
			)
			input_edit.focus_exited.connect(func():
				input_edit.text = _format_iec_address(int(target_obj.get_meta("modbus_input", -1)), "IX")
			)
		modbus_io_grid.add_child(input_edit)

func _draw_axis_gizmo() -> void:
	axis_gizmo.draw_rect(Rect2(Vector2.ZERO, axis_gizmo.size), Color(0.08, 0.13, 0.18, 0.88), true)
	axis_gizmo.draw_rect(Rect2(Vector2.ZERO, axis_gizmo.size), Color("4b6575"), false, 1.0)
	var font := ThemeDB.fallback_font
	axis_gizmo.draw_string(font, Vector2(12, 21), "WORLD AXES (Z UP)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("e5f2f3"))
	var origin := Vector2(69, 84)
	# Right-handed editor coordinates: X = Godot X, Y = -Godot Z, Z = Godot Y.
	for item in [["+X", Vector3.RIGHT, Color("f06d6d")], ["+Y", Vector3.FORWARD, Color("78d989")], ["+Z", Vector3.UP, Color("78afff")]]:
		var axis: Vector3 = item[1]
		var color: Color = item[2]
		var projected := Vector2(axis.dot(camera.global_basis.x), -axis.dot(camera.global_basis.y))
		if projected.length() < 0.15:
			projected = Vector2(0.15, 0)
		var direction := projected.normalized()
		var tip := origin + projected * 40.0
		axis_gizmo.draw_line(origin, origin - projected * 17.0, Color(color, 0.35), 1.0, true)
		axis_gizmo.draw_line(origin, tip, color, 3.0, true)
		var wing := Vector2(-direction.y, direction.x)
		axis_gizmo.draw_line(tip, tip - direction * 8.0 + wing * 4.0, color, 2.0, true)
		axis_gizmo.draw_line(tip, tip - direction * 8.0 - wing * 4.0, color, 2.0, true)
		axis_gizmo.draw_string(font, tip + Vector2(4, 5), item[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color)
	axis_gizmo.draw_circle(origin, 3.0, Color.WHITE)

func _build_transform_controls(ui_root: Control) -> void:
	transform_panel = PanelContainer.new()
	transform_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	transform_panel.offset_left = -280
	transform_panel.offset_top = -340
	transform_panel.offset_right = -16
	transform_panel.offset_bottom = -46
	var panel_style := _ui_stylebox(Color(0.063, 0.098, 0.137, 0.92), Color("294052"), 12, 1, 12, 12)
	panel_style.shadow_color = Color(0, 0, 0, 0.35)
	panel_style.shadow_size = 8
	transform_panel.add_theme_stylebox_override("panel", panel_style)
	ui_root.add_child(transform_panel)
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 12)
	transform_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)
	transform_title = Label.new()
	transform_title.text = "OBJECT CONTROLS"
	column.add_child(transform_title)
	transform_value = Label.new()
	column.add_child(transform_value)
	var move_row := HBoxContainer.new()
	column.add_child(move_row)
	for item in [["X -", Vector3(-1, 0, 0)], ["X +", Vector3(1, 0, 0)], ["Y -", Vector3(0, 0, 1)], ["Y +", Vector3(0, 0, -1)]]:
		var button := Button.new()
		button.text = item[0]
		button.tooltip_text = "Move one grid unit"
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var delta: Vector3 = item[1]
		button.pressed.connect(func(): _move_selected(delta))
		move_row.add_child(button)
	var height_row := HBoxContainer.new()
	column.add_child(height_row)
	for item in [["Z -  Down", -1], ["Z +  Up", 1]]:
		var button := Button.new()
		button.text = item[0]
		button.tooltip_text = "Move 0.25 unit vertically"
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var direction: int = item[1]
		button.pressed.connect(func(): _move_selected_height(direction))
		height_row.add_child(button)
	var rotate_row := HBoxContainer.new()
	column.add_child(rotate_row)
	for item in [["Rotate Z -90°", -1], ["Rotate Z +90°", 1]]:
		var button := Button.new()
		button.text = item[0]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var direction: int = item[1]
		button.pressed.connect(func(): _rotate_selected(direction))
		rotate_row.add_child(button)
	conveyor_speed_row = HBoxContainer.new()
	conveyor_speed_row.visible = false
	column.add_child(conveyor_speed_row)
	var speed_label := Label.new()
	speed_label.text = "Speed:"
	conveyor_speed_row.add_child(speed_label)
	conveyor_speed_input = SpinBox.new()
	conveyor_speed_input.min_value = -10.0
	conveyor_speed_input.max_value = 10.0
	conveyor_speed_input.step = 0.1
	conveyor_speed_input.suffix = " m/s"
	conveyor_speed_input.tooltip_text = "Conveyor belt speed (negative = reverse)"
	conveyor_speed_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	conveyor_speed_input.value_changed.connect(_on_conveyor_speed_changed)
	conveyor_speed_row.add_child(conveyor_speed_input)
	modbus_coil_row = HBoxContainer.new()
	modbus_coil_row.visible = false
	column.add_child(modbus_coil_row)
	var coil_label := Label.new()
	coil_label.text = "Coil (Active):"
	coil_label.custom_minimum_size.x = 92
	modbus_coil_row.add_child(coil_label)
	modbus_coil_input = LineEdit.new()
	modbus_coil_input.placeholder_text = "%QX0.0 or 0..255"
	modbus_coil_input.tooltip_text = "Modbus Coil (%QX0.0..%QX31.7 or 0..255); leave empty if unused"
	modbus_coil_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modbus_coil_input.text_changed.connect(func(txt: String): _on_modbus_tag_changed("modbus_coil", txt))
	modbus_coil_input.text_submitted.connect(func(_t: String): _commit_modbus_field("modbus_coil", modbus_coil_input, "QX"))
	modbus_coil_input.focus_exited.connect(func(): _commit_modbus_field("modbus_coil", modbus_coil_input, "QX"))
	modbus_coil_row.add_child(modbus_coil_input)

	modbus_input_row = HBoxContainer.new()
	modbus_input_row.visible = false
	column.add_child(modbus_input_row)
	var input_label := Label.new()
	input_label.text = "Input (DI):"
	input_label.custom_minimum_size.x = 92
	modbus_input_row.add_child(input_label)
	modbus_input_field = LineEdit.new()
	modbus_input_field.placeholder_text = "%IX0.0 or 0..255"
	modbus_input_field.tooltip_text = "Modbus Discrete Input (%IX0.0..%IX31.7 or 0..255); leave empty if unused"
	modbus_input_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modbus_input_field.text_changed.connect(func(txt: String): _on_modbus_tag_changed("modbus_input", txt))
	modbus_input_field.text_submitted.connect(func(_t: String): _commit_modbus_field("modbus_input", modbus_input_field, "IX"))
	modbus_input_field.focus_exited.connect(func(): _commit_modbus_field("modbus_input", modbus_input_field, "IX"))
	modbus_input_row.add_child(modbus_input_field)
	transform_panel.visible = false

func _refresh_transform_controls() -> void:
	if not is_instance_valid(transform_panel):
		return
	var active := edit_mode and is_instance_valid(selected_object) and selected_object.is_in_group("sandbox_objects")
	transform_panel.visible = active
	_refresh_force_panel()
	if active:
		var pos: Vector3 = selected_object.get_meta("grid_position")
		var display_y := 0.0 if is_zero_approx(pos.z) else -pos.z
		var display_z := selected_object.global_position.y - (floor_body.position.y + 0.125)
		var direction := " (REVERSE)" if selected_object.get_meta("kind") == "turn" and selected_object.get_meta("reversed", false) else ""
		transform_title.text = "OBJECT: " + str(selected_object.get_meta("kind")).replace("_", " ").to_upper() + direction
		transform_value.text = "X: %.1f   Y: %.1f   Z: %.2f\nRotate Z: %.0f°" % [pos.x, display_y, display_z, selected_object.rotation_degrees.y]
		var is_conveyor: bool = str(selected_object.get_meta("kind")) == "conveyor"
		conveyor_speed_row.visible = is_conveyor
		if is_conveyor and is_instance_valid(conveyor_speed_input):
			var fallback_speed := float(selected_object.get("speed")) if "speed" in selected_object else BELT_SPEED
			conveyor_speed_input.set_value_no_signal(float(selected_object.get_meta("configured_speed", fallback_speed)))
		var kind_str: String = str(selected_object.get_meta("kind"))
		var has_coil: bool = kind_str in ["conveyor", "turn", "pusher", "stopper"]
		modbus_coil_row.visible = has_coil
		if has_coil and is_instance_valid(modbus_coil_input):
			var c_addr := int(selected_object.get_meta("modbus_coil", -1))
			modbus_coil_input.text = _format_iec_address(c_addr, "QX")
		var has_input: bool = kind_str in ["sensor", "stopper"]
		modbus_input_row.visible = has_input
		if has_input and is_instance_valid(modbus_input_field):
			var i_addr := int(selected_object.get_meta("modbus_input", -1))
			modbus_input_field.text = _format_iec_address(i_addr, "IX")

func _parse_iec_or_int_address(raw_text: String) -> int:
	var s := raw_text.strip_edges().to_upper()
	if s.is_empty():
		return -1
	if s.is_valid_int():
		return clampi(s.to_int(), 0, 255)
	if s.begins_with("%"):
		s = s.substr(1)
	if s.begins_with("QX") or s.begins_with("IX"):
		s = s.substr(2)
	elif s.begins_with("Q") or s.begins_with("I"):
		s = s.substr(1)
	else:
		return -2
	var parts := s.split(".")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return -2
	var byte_idx := parts[0].to_int()
	var bit_idx := parts[1].to_int()
	if byte_idx < 0 or bit_idx < 0 or bit_idx > 7:
		return -2
	return clampi(byte_idx * 8 + bit_idx, 0, 255)

func _format_iec_address(addr: int, prefix: String) -> String:
	if addr < 0:
		return ""
	return "%%%s%d.%d" % [prefix, addr / 8, addr % 8]

func _on_modbus_tag_changed(meta_key: String, raw_text: String) -> void:
	if not edit_mode or not is_instance_valid(selected_object):
		return
	var parsed := _parse_iec_or_int_address(raw_text)
	if parsed >= -1:
		selected_object.set_meta(meta_key, parsed)

func _commit_modbus_field(meta_key: String, field: LineEdit, prefix: String) -> void:
	if not is_instance_valid(selected_object) or not is_instance_valid(field):
		return
	var parsed := _parse_iec_or_int_address(field.text)
	if parsed >= -1:
		selected_object.set_meta(meta_key, parsed)
		field.text = _format_iec_address(parsed, prefix)
	else:
		field.text = _format_iec_address(int(selected_object.get_meta(meta_key, -1)), prefix)

func _on_conveyor_speed_changed(value: float) -> void:
	if not edit_mode or not is_instance_valid(selected_object):
		return
	if selected_object.get_meta("kind") != "conveyor":
		return
	selected_object.set_meta("configured_speed", value)
	if selected_object is StaticBody3D:
		_apply_conveyor_speed(selected_object as StaticBody3D)

func _spawn_box() -> RigidBody3D:
	if spawn_plastic_next:
		spawn_plastic_next = false
		return _spawn_plastic_box()
	spawn_plastic_next = true
	var box := (load("res://objects/box.tscn") as PackedScene).instantiate() as RigidBody3D
	box.name = "ProductBox"
	box.position = _product_world_position("box", Vector3(-4.0, 0, 0))
	box.freeze = not running
	add_child(box)
	box.add_to_group("product_boxes")
	var cardboard := box.find_child("CardboardBody", true, false) as MeshInstance3D
	var box_material := _cardboard_material().duplicate() as StandardMaterial3D
	box_material.albedo_color = BOX_COLORS[random.randi_range(0, BOX_COLORS.size() - 1)]
	cardboard.material_override = box_material
	return box

func _spawn_plastic_box() -> RigidBody3D:
	var box := (load("res://objects/box_plastic.tscn") as PackedScene).instantiate() as RigidBody3D
	box.name = "PlasticBox"
	box.position = _product_world_position("box_plastic", Vector3(-4.0, 0, 0)) + Vector3(0, 1.0, 0)
	box.freeze = not running
	add_child(box)
	box.add_to_group("product_boxes")
	var plastic := box.find_child("Box", true, false) as MeshInstance3D
	var box_material := _plastic_material().duplicate() as StandardMaterial3D
	box_material.albedo_color = BOX_COLORS[random.randi_range(0, BOX_COLORS.size() - 1)]
	plastic.material_override = box_material
	return box

func _has_placed_products() -> bool:
	for object in get_tree().get_nodes_in_group("sandbox_objects"):
		if object.get_meta("kind", "") in PRODUCT_KINDS:
			return true
	return false

func _support_surface_y(pos: Vector3) -> float:
	var top := floor_body.position.y + 0.125
	for object in get_tree().get_nodes_in_group("sandbox_objects"):
		var kind: String = object.get_meta("kind", "")
		if kind not in ["conveyor", "turn"]:
			continue
		var center: Vector3 = object.get_meta("grid_position")
		var size := _object_footprint(object)
		if absf(pos.x - center.x) <= size.x * 0.5 and absf(pos.z - center.z) <= size.y * 0.5:
			var collision_name := "BeltCollision" if kind == "conveyor" else "TurnCollision"
			var collision := object.get_node(collision_name) as CollisionShape3D
			var shape := collision.shape as BoxShape3D
			top = maxf(top, object.position.y + collision.position.y + shape.size.y * 0.5)
	return top

func _product_world_position(kind: String, pos: Vector3) -> Vector3:
	var support_y := _support_surface_y(pos)
	var floor_y := floor_body.position.y + 0.125
	var bottom := support_y + (0.005 if is_equal_approx(support_y, floor_y) else 0.02)
	return Vector3(pos.x, bottom, pos.z)

func _set_product_color(object: RigidBody3D, kind: String, color_index: int) -> void:
	var visual_name := "CardboardBody" if kind == "box" else "Box"
	var visual := object.find_child(visual_name, true, false) as MeshInstance3D
	var material := (_cardboard_material() if kind == "box" else _plastic_material()).duplicate() as StandardMaterial3D
	material.albedo_color = BOX_COLORS[color_index]
	visual.material_override = material
	object.set_meta("color_index", color_index)

func _restore_placed_products() -> void:
	for box in get_tree().get_nodes_in_group("product_boxes"):
		if box.is_in_group("sandbox_objects"):
			box.freeze = true
			box.visible = true
			box.linear_velocity = Vector3.ZERO
			box.angular_velocity = Vector3.ZERO
			box.position = _product_world_position(box.get_meta("kind"), box.get_meta("grid_position")) + Vector3(0, float(box.get_meta("height_offset", 0.0)), 0)
			box.rotation_degrees = Vector3(0, float(box.get_meta("placed_rotation", 0.0)), 0)
		else:
			if box == selected_object:
				_set_selection(null)
			box.remove_from_group("product_boxes")
			box.queue_free()

func _on_sensor_body_entered(body: Node3D) -> void:
	if body is RigidBody3D and body.is_in_group("product_boxes"):
		if not sensor_bodies.has(body):
			sensor_bodies.append(body)
		_update_sensor_indicator()
		detected_count += 1
		counter_label.text = "Sensor A: %d boxes detected" % detected_count
		print("SENSOR_A_DETECTED count=", detected_count)

func _on_sensor_body_exited(body: Node3D) -> void:
	sensor_bodies.erase(body)
	_update_sensor_indicator()

func _update_sensor_indicator() -> void:
	var active := not sensor_bodies.is_empty()
	sensor.set_detected(active)

func _toggle_conveyor() -> void:
	_set_running(not running)

func _set_running(value: bool) -> void:
	running = value
	if running:
		dragging_object = false
		rotating_object = false
		if is_instance_valid(axis_gizmo):
			axis_gizmo.visible = false
	_refresh_transform_controls()
	_apply_conveyor_speed(conveyor)
	for object in get_tree().get_nodes_in_group("sandbox_conveyors"):
		if object is StaticBody3D:
			_apply_conveyor_speed(object as StaticBody3D)
	for obj in get_tree().get_nodes_in_group("sandbox_objects"):
		if str(obj.get_meta("kind", "")) == "turn":
			var area := obj.get_node_or_null("TransferArea")
			if area != null and not obj.has_meta("forced_active") and not plc_mode:
				area.set("active", running)
	status_label.text = "Conveyor: RUNNING" if running else "Conveyor: STOPPED"
	if is_instance_valid(start_button):
		start_button.text = "Stop" if running else "Run"
		if running:
			_style_accent_button(start_button, "7a2e33", "993b41", "cc5a61")
		else:
			_style_accent_button(start_button, "1e6b45", "278758", "3eb87a")
	_refresh_boxes_freeze()

func _apply_conveyor_speed(belt: StaticBody3D) -> void:
	if not belt.has_meta("configured_speed"):
		var initial_speed = belt.get("speed")
		belt.set_meta("configured_speed", float(initial_speed) if initial_speed != null else BELT_SPEED)
	var target_speed := float(belt.get_meta("configured_speed"))
	if "speed" in belt:
		belt.set("speed", target_speed)
	if "active" in belt:
		if belt.has_meta("forced_active"):
			belt.set("active", bool(belt.get_meta("forced_active")))
		elif not plc_mode:
			belt.set("active", running)
	else:
		belt.constant_linear_velocity = belt.global_basis.x.normalized() * (target_speed if running else 0.0)

func _toggle_plc_mode() -> void:
	_apply_plc_mode(not plc_mode)

func _apply_plc_mode(enabled: bool) -> void:
	plc_mode = enabled
	if is_instance_valid(plc_button):
		plc_button.text = "Control: PLC" if plc_mode else "Control: AUTO"
		if plc_mode:
			_style_accent_button(plc_button, "1b4f6e", "23668f", "3b8cb8")
		else:
			plc_button.remove_theme_stylebox_override("normal")
			plc_button.remove_theme_stylebox_override("hover")
			plc_button.remove_theme_stylebox_override("pressed")
			plc_button.remove_theme_color_override("font_color")
	for obj in get_tree().get_nodes_in_group("sandbox_objects"):
		var kind := str(obj.get_meta("kind", ""))
		if kind in ["pusher", "stopper"]:
			obj.set("plc_mode", plc_mode)
		elif kind == "turn":
			var area := obj.get_node_or_null("TransferArea")
			if area != null:
				area.set("plc_mode", plc_mode)
	if plc_mode:
		_sync_modbus_io()
	else:
		_set_running(running)

func _sync_modbus_io() -> void:
	for obj in get_tree().get_nodes_in_group("sandbox_objects"):
		var kind := str(obj.get_meta("kind", ""))
		if kind in PRODUCT_KINDS:
			continue
		if obj.has_meta("forced_active"):
			_apply_object_force(obj, bool(obj.get_meta("forced_active")))
			var forced_input := int(obj.get_meta("modbus_input", -1))
			if forced_input >= 0 and kind == "sensor":
				ModbusTCP.set_discrete_input(forced_input, bool(obj.get("active")))
			continue
		var coil_addr := int(obj.get_meta("modbus_coil", -1))
		var input_addr := int(obj.get_meta("modbus_input", -1))
		match kind:
			"sensor":
				if input_addr >= 0:
					ModbusTCP.set_discrete_input(input_addr, bool(obj.get("active")))
			"conveyor":
				obj.set("active", running and coil_addr >= 0 and ModbusTCP.get_coil(coil_addr))
			"turn":
				var area := obj.get_node_or_null("TransferArea")
				if area != null:
					area.set("active", running and coil_addr >= 0 and ModbusTCP.get_coil(coil_addr))
			"pusher":
				obj.set("active", coil_addr >= 0 and ModbusTCP.get_coil(coil_addr))
			"stopper":
				obj.set("active", coil_addr >= 0 and ModbusTCP.get_coil(coil_addr))
				if input_addr >= 0:
					ModbusTCP.set_discrete_input(input_addr, bool(obj.get("part_at_gate")))

func _reset_simulation() -> void:
	_set_running(false)
	_set_selection(null)
	_restore_placed_products()
	sensor_bodies.clear()
	_update_sensor_indicator()
	detected_count = 0
	counter_label.text = "Sensor A: 0 boxes detected"
	spawn_clock = 0.0
	if not _has_placed_products():
		var box := _spawn_box()
		box.freeze = true

func _enter_edit_mode() -> void:
	_clear_preview()
	edit_mode = true
	edit_grid.visible = true
	dragging_object = false
	rotating_object = false
	placement = "select"
	_set_running(false)
	axis_gizmo.visible = true
	_restore_placed_products()
	sandbox_label.text = "Edit: select"
	_refresh_transform_controls()

func _build_edit_grid() -> void:
	edit_grid = Node3D.new()
	edit_grid.name = "EditGrid"
	add_child(edit_grid)
	_rebuild_grid()
	edit_grid.visible = false

func _rebuild_grid() -> void:
	for child in edit_grid.get_children():
		edit_grid.remove_child(child)
		child.queue_free()
	for x in range(-int(workspace_width / 2), int(workspace_width / 2) + 1):
		var z_axis := x == 0
		_box_mesh(edit_grid, Vector3(0.025 if z_axis else 0.012, 0.008, workspace_depth), Vector3(float(x), -0.056, 0), Color("78d989") if z_axis else Color("54717b"))
	for z in range(-int(workspace_depth / 2), int(workspace_depth / 2) + 1):
		var x_axis := z == 0
		_box_mesh(edit_grid, Vector3(workspace_width, 0.008, 0.025 if x_axis else 0.012), Vector3(0, -0.056, float(z)), Color("f06d6d") if x_axis else Color("54717b"))

func _fits_workspace(pos: Vector3, size: Vector2, width: int, depth: int) -> bool:
	return absf(pos.x) + size.x * 0.5 <= width * 0.5 and absf(pos.z) + size.y * 0.5 <= depth * 0.5

func _apply_workspace_input() -> void:
	if not edit_mode:
		sandbox_label.text = "Switch to Edit before resizing"
		return
	var width := int(width_input.value)
	var depth := int(depth_input.value)
	for object in get_tree().get_nodes_in_group("sandbox_objects"):
		if not _fits_workspace(object.get_meta("grid_position"), _object_footprint(object), width, depth):
			sandbox_label.text = "Resize blocked: equipment outside new area"
			return
	_set_workspace_size(width, depth)
	sandbox_label.text = "Workspace: %d x %d" % [width, depth]

func _set_workspace_size(width: int, depth: int) -> void:
	workspace_width = width
	workspace_depth = depth
	var dimensions := Vector3(width, 0.25, depth)
	(floor_body.get_child(0) as MeshInstance3D).mesh.size = dimensions
	(floor_body.get_child(1) as CollisionShape3D).shape.size = dimensions
	_rebuild_grid()
	if is_instance_valid(width_input):
		width_input.value = width
		depth_input.value = depth
	_update_preview_color()

func _place_at(screen_position: Vector2) -> void:
	var point = _ground_point(screen_position)
	if point == null:
		return
	var snapped := _snap_placement(placement, Vector3(round(point.x), 0, round(point.z)), placement_angle)
	if not _placement_valid(placement, snapped, placement_angle):
		sandbox_label.text = "Cannot place: overlaps same type or outside floor"
		return
	var object := _create_sandbox_object(placement, snapped)
	if object != null:
		object.rotation_degrees.y = placement_angle
		if placement == "turn":
			_set_turn_direction(object, placement_reversed)
		if placement in PRODUCT_KINDS:
			object.set_meta("placed_rotation", placement_angle)
			var placed_kind := placement
			_set_placement("select")
			_set_selection(object)
			sandbox_label.text = "Placed " + placed_kind + " | drag or use object controls"
		else:
			sandbox_label.text = "Placed " + placement + " | click to add more; Esc to finish"

func _clear_preview() -> void:
	if is_instance_valid(placement_preview):
		placement_preview.queue_free()
	placement_preview = null

func _set_placement(kind: String) -> void:
	_clear_preview()
	placement = kind
	dragging_object = false
	_set_selection(null)
	if kind == "select":
		sandbox_label.text = "Edit: select / drag"
		return
	placement_angle = 0.0
	placement_reversed = false
	placement_preview = Node3D.new()
	placement_preview.name = "PlacementPreview"
	add_child(placement_preview)
	var dimensions := Vector3(9.0, 0.25, 1.5)
	var height := 0.9
	match kind:
		"turn": dimensions = Vector3(1.5, 0.25, 1.5)
		"sensor":
			dimensions = Vector3(0.28, 1.0, 1.5)
			height = 1.55
		"pusher":
			dimensions = Vector3(0.7, 1.35, 0.7)
			height = 0.675
		"stopper":
			dimensions = Vector3(0.45, 1.35, 1.65)
			height = 0.675
		"box":
			dimensions = Vector3(0.65, 0.65, 0.65)
			height = _product_world_position(kind, Vector3.ZERO).y + 0.325
		"box_plastic":
			dimensions = Vector3(0.657, 0.314, 0.899)
			height = _product_world_position(kind, Vector3.ZERO).y + 0.157
	var preview_mesh := _box_mesh(placement_preview, dimensions, Vector3(0, height, 0), Color.WHITE)
	preview_material = StandardMaterial3D.new()
	preview_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	preview_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	preview_material.albedo_color = Color(0.2, 0.9, 0.85, 0.45)
	preview_mesh.material_override = preview_material
	placement_preview.visible = false
	sandbox_label.text = "Place " + kind + " | Q/E rotate | Esc cancel"

func _update_placement_preview(screen_position: Vector2) -> void:
	if not is_instance_valid(placement_preview):
		return
	var point = _ground_point(screen_position)
	placement_preview.visible = point != null
	if point != null:
		placement_preview.position = _snap_placement(placement, Vector3(round(point.x), 0, round(point.z)), placement_angle)
		placement_preview.rotation_degrees.y = placement_angle
		if placement in PRODUCT_KINDS:
			var visual_center := _product_world_position(placement, placement_preview.position).y
			visual_center += 0.325 if placement == "box" else 0.157
			(placement_preview.get_child(0) as MeshInstance3D).position.y = visual_center
		_update_preview_color()

func _update_preview_color() -> void:
	if not is_instance_valid(placement_preview) or preview_material == null:
		return
	var reason := _placement_conflict_reason(placement, placement_preview.position, placement_angle)
	var valid := reason.is_empty()
	preview_material.albedo_color = Color(0.2, 0.9, 0.85, 0.45) if valid else Color(1.0, 0.16, 0.14, 0.55)
	if not valid:
		sandbox_label.text = reason
	else:
		sandbox_label.text = "Place " + placement + " | Q/E rotate | Esc cancel"

func _footprint(kind: String, angle: float) -> Vector2:
	var size := Vector2(9.0, 1.5)
	match kind:
		"turn": size = Vector2(1.5, 1.5)
		"sensor": size = Vector2(0.28, 1.5)
		"pusher": size = Vector2(0.7, 0.7)
		"stopper": size = Vector2(0.45, 1.65)
		"box": size = Vector2(0.65, 0.65)
		"box_plastic": size = Vector2(0.657, 0.899)
	var turns := posmod(roundi(angle / 90.0), 2)
	return Vector2(size.y, size.x) if turns == 1 else size

func _snap_placement(kind: String, pos: Vector3, angle: float, ignored: Node3D = null) -> Vector3:
	if kind in ["sensor", "stopper"]:
		var best_span := pos
		var best_span_dist := 0.85
		var span_axis := posmod(roundi(angle / 90.0), 2)
		for other in get_tree().get_nodes_in_group("sandbox_conveyors"):
			if other == ignored or posmod(roundi(other.rotation_degrees.y / 90.0), 2) != span_axis:
				continue
			var center: Vector3 = other.get_meta("grid_position")
			var along := absf(pos.x - center.x) if span_axis == 0 else absf(pos.z - center.z)
			if along > 4.5:
				continue
			var candidate := pos
			if span_axis == 0:
				candidate.z = center.z
			else:
				candidate.x = center.x
			var dist := absf(candidate.z - pos.z) if span_axis == 0 else absf(candidate.x - pos.x)
			if dist < best_span_dist and _placement_valid(kind, candidate, angle, ignored):
				best_span = candidate
				best_span_dist = dist
		return best_span
	if kind == "pusher":
		var best_push := pos
		var best_push_dist := 0.85
		for other in get_tree().get_nodes_in_group("sandbox_conveyors"):
			if other == ignored:
				continue
			var belt_axis := posmod(roundi(other.rotation_degrees.y / 90.0), 2)
			var center: Vector3 = other.get_meta("grid_position")
			var along := absf(pos.x - center.x) if belt_axis == 0 else absf(pos.z - center.z)
			if along > 4.5:
				continue
			for side in [-1.0, 1.0]:
				var candidate := pos
				if belt_axis == 0:
					candidate.z = center.z + side * 1.2
				else:
					candidate.x = center.x + side * 1.2
				var dist := absf(candidate.z - pos.z) if belt_axis == 0 else absf(candidate.x - pos.x)
				if dist < best_push_dist and _placement_valid(kind, candidate, angle, ignored):
					best_push = candidate
					best_push_dist = dist
		return best_push
	if kind not in ["conveyor", "turn"]:
		return pos
	var axis := posmod(roundi(angle / 90.0), 2)
	var best := pos
	var best_distance := 0.76
	# Align a corner with either end of a belt, or a belt with a corner.
	for other in get_tree().get_nodes_in_group("sandbox_objects"):
		if other == ignored:
			continue
		var other_kind: String = other.get_meta("kind")
		if not ((kind == "turn" and other_kind == "conveyor") or (kind == "conveyor" and other_kind == "turn")):
			continue
		var center: Vector3 = other.get_meta("grid_position")
		var belt_axis := posmod(roundi(other.rotation_degrees.y / 90.0), 2) if kind == "turn" else axis
		for side in [-1.0, 1.0]:
			var offset := Vector3(5.25 * side, 0, 0) if belt_axis == 0 else Vector3(0, 0, 5.25 * side)
			var candidate := center + offset
			var distance := Vector2(pos.x - candidate.x, pos.z - candidate.z).length()
			if distance < best_distance and _placement_valid(kind, candidate, angle, ignored):
				best = candidate
				best_distance = distance
	if kind == "turn":
		return best
	for other in get_tree().get_nodes_in_group("sandbox_conveyors"):
		if other == ignored or posmod(roundi(other.rotation_degrees.y / 90.0), 2) != axis:
			continue
		var center: Vector3 = other.get_meta("grid_position")
		var along_distance := absf(pos.x - center.x) if axis == 0 else absf(pos.z - center.z)
		if along_distance >= 9.0:
			continue
		for side in [-1.0, 1.0]:
			var candidate := pos
			if axis == 0:
				candidate.z = center.z + side * 1.5
			else:
				candidate.x = center.x + side * 1.5
			var distance := absf(candidate.z - pos.z) if axis == 0 else absf(candidate.x - pos.x)
			if distance < best_distance and _placement_valid(kind, candidate, angle, ignored):
				best = candidate
				best_distance = distance
	return best

func _rectangles_overlap(a: Vector3, a_size: Vector2, b: Vector3, b_size: Vector2) -> bool:
	return absf(a.x - b.x) < (a_size.x + b_size.x) * 0.5 - 0.001 and absf(a.z - b.z) < (a_size.y + b_size.y) * 0.5 - 0.001

func _height_range(kind: String, height_offset: float) -> Vector2:
	var base := Vector2(0.0, 1.1)
	match kind:
		"conveyor": base = Vector2(0.0, 1.075)
		"turn": base = Vector2(0.0, 1.105)
		"sensor": base = Vector2(1.0, 1.65)
		"stopper": base = Vector2(0.0, 1.40)
		"pusher": base = Vector2(0.0, 1.38)
		"box": base = Vector2(1.075, 1.725)
		"box_plastic": base = Vector2(1.075, 1.39)
	return base + Vector2(height_offset, height_offset)

func _heights_overlap(a: Vector2, b: Vector2) -> bool:
	return a.x < b.y - 0.001 and b.x < a.y - 0.001

func _placement_conflict_reason(kind: String, pos: Vector3, angle: float, ignored: Node3D = null) -> String:
	if kind not in ["conveyor", "turn", "sensor", "pusher", "stopper", "box", "box_plastic"]:
		return "Unsupported object type"
	var size := _footprint(kind, angle)
	if is_instance_valid(ignored) and ignored.get_meta("base_id", "") == "base_conveyor":
		size = Vector2(1.5, 9.0) if posmod(roundi(angle / 90.0), 2) == 1 else Vector2(9.0, 1.5)
	if not _fits_workspace(pos, size, workspace_width, workspace_depth):
		return "Outside floor bounds"
	var height_offset := float(ignored.get_meta("height_offset", 0.0)) if is_instance_valid(ignored) else 0.0
	var height_span := _height_range(kind, height_offset)
	# Sensors and stoppers can span conveyors/turns, but cannot overlap each other or same-type objects.
	for object in get_tree().get_nodes_in_group("sandbox_objects"):
		var other_kind: String = object.get_meta("kind")
		if object == ignored:
			continue
		if kind in PRODUCT_KINDS or other_kind in PRODUCT_KINDS:
			if not (kind in PRODUCT_KINDS and other_kind in PRODUCT_KINDS):
				continue
		elif kind in ["sensor", "stopper"] or other_kind in ["sensor", "stopper"]:
			if other_kind in ["conveyor", "turn"] or kind in ["conveyor", "turn"]:
				continue
		var other_size := _object_footprint(object)
		var other_height := _height_range(other_kind, float(object.get_meta("height_offset", 0.0)))
		if _rectangles_overlap(pos, size, object.get_meta("grid_position"), other_size) and _heights_overlap(height_span, other_height):
			return "Overlaps: " + object.name
	return ""

func _placement_valid(kind: String, pos: Vector3, angle: float, ignored: Node3D = null) -> bool:
	return _placement_conflict_reason(kind, pos, angle, ignored).is_empty()

func _object_footprint(object: Node3D) -> Vector2:
	if object.get_meta("base_id", "") == "base_conveyor":
		return Vector2(1.5, 9.0) if posmod(roundi(object.rotation_degrees.y / 90.0), 2) == 1 else Vector2(9.0, 1.5)
	return _footprint(object.get_meta("kind"), object.rotation_degrees.y)

func _ground_point(screen_position: Vector2):
	return Plane(Vector3.UP, 0.0).intersects_ray(camera.project_ray_origin(screen_position), camera.project_ray_normal(screen_position))

func _start_object_drag(screen_position: Vector2) -> void:
	if not is_instance_valid(selected_object) or not selected_object.is_in_group("sandbox_objects"):
		return
	var point = _ground_point(screen_position)
	if point == null:
		return
	drag_grid_offset = selected_object.get_meta("grid_position") - point
	dragging_object = true

func _start_rotation_drag() -> void:
	if not edit_mode or not is_instance_valid(selected_object) or not selected_object.is_in_group("sandbox_objects"):
		return
	dragging_object = false
	rotating_object = true
	rotation_drag_pixels = 0.0

func _update_rotation_drag(relative_x: float) -> void:
	if not rotating_object or not edit_mode or not is_instance_valid(selected_object):
		rotating_object = false
		return
	rotation_drag_pixels += relative_x
	while absf(rotation_drag_pixels) >= 50.0:
		var direction := 1 if rotation_drag_pixels > 0.0 else -1
		_rotate_selected(direction)
		rotation_drag_pixels -= 50.0 * direction

func _drag_selected_to(screen_position: Vector2) -> void:
	if not edit_mode or not is_instance_valid(selected_object) or not selected_object.is_in_group("sandbox_objects"):
		dragging_object = false
		return
	var point = _ground_point(screen_position)
	if point == null:
		return
	var new_grid := Vector3(round(point.x + drag_grid_offset.x), 0, round(point.z + drag_grid_offset.z))
	new_grid = _snap_placement(selected_object.get_meta("kind"), new_grid, selected_object.rotation_degrees.y, selected_object)
	var previous: Vector3 = selected_object.get_meta("grid_position")
	if not _placement_valid(selected_object.get_meta("kind"), new_grid, selected_object.rotation_degrees.y, selected_object):
		sandbox_label.text = "Cannot move: overlaps same type or outside floor"
		return
	if selected_object.get_meta("kind") in PRODUCT_KINDS:
		selected_object.position = _product_world_position(selected_object.get_meta("kind"), new_grid) + Vector3(0, float(selected_object.get_meta("height_offset", 0.0)), 0)
	else:
		selected_object.position += new_grid - previous
	selected_object.set_meta("grid_position", new_grid)
	_refresh_transform_controls()
	sandbox_label.text = "Edit: moved " + str(selected_object.get_meta("kind"))

func _create_sandbox_object(kind: String, position: Vector3, is_base: bool = false) -> Node3D:
	var scene_path := "res://objects/" + kind + ".tscn"
	if kind not in ["conveyor", "turn", "sensor", "pusher", "stopper", "box", "box_plastic"]:
		return null
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("Could not load equipment scene: " + scene_path)
		return null
	var object := packed.instantiate() as Node3D
	object.position = _product_world_position(kind, position) if kind in PRODUCT_KINDS else position + Vector3(0, float(EQUIPMENT_BASE_HEIGHT[kind]), 0)
	add_child(object)
	object.add_to_group("sandbox_objects")
	object.set_meta("kind", kind)
	object.set_meta("grid_position", position)
	object.set_meta("height_offset", 0.0)
	if kind not in PRODUCT_KINDS:
		object.set_meta("modbus_coil", -1)
		object.set_meta("modbus_input", -1)
	if kind in PRODUCT_KINDS:
		var product := object as RigidBody3D
		product.freeze = true
		product.add_to_group("product_boxes")
		product.set_meta("placed_rotation", 0.0)
		_set_product_color(product, kind, random.randi_range(0, BOX_COLORS.size() - 1))
	elif kind == "conveyor":
		object.add_to_group("sandbox_conveyors")
		if object is StaticBody3D:
			_apply_conveyor_speed(object as StaticBody3D)
	elif kind == "turn":
		_set_turn_direction(object, false)
		var turn_area := object.get_node_or_null("TransferArea")
		if turn_area != null:
			turn_area.set("plc_mode", plc_mode)
	elif kind in ["pusher", "stopper"]:
		object.set("plc_mode", plc_mode)
	elif kind == "sensor":
		var area := object as Area3D
		if is_base:
			area.body_entered.connect(_on_sensor_body_entered)
			area.body_exited.connect(_on_sensor_body_exited)
		else:
			var detected: Array[Node3D] = []
			area.body_entered.connect(func(body):
				if body.is_in_group("product_boxes"):
					detected.append(body)
					area.set_detected(true)
			)
			area.body_exited.connect(func(body):
				detected.erase(body)
				if detected.is_empty():
					area.set_detected(false)
			)
	return object

func _set_turn_direction(object: Node3D, reversed: bool) -> void:
	object.set_meta("reversed", reversed)
	for child in object.get_children():
		if child.is_in_group("belt_direction_arrows"):
			child.rotation_degrees.y = float(child.get_meta("normal_yaw")) + (180.0 if reversed else 0.0)

func _toggle_turn_direction() -> void:
	if not edit_mode:
		return
	if placement == "turn":
		placement_reversed = not placement_reversed
		sandbox_label.text = "Place turn: " + ("reverse" if placement_reversed else "forward")
		return
	if placement != "select" or not is_instance_valid(selected_object) or selected_object.get_meta("kind", "") != "turn":
		sandbox_label.text = "Select a turn to reverse"
		return
	_set_turn_direction(selected_object, not selected_object.get_meta("reversed", false))
	_refresh_transform_controls()
	sandbox_label.text = "Turn: " + ("reverse" if selected_object.get_meta("reversed") else "forward")

func _delete_selected() -> void:
	if edit_mode and is_instance_valid(selected_object) and selected_object.is_in_group("sandbox_objects"):
		if selected_object.has_meta("base_id"):
			sandbox_label.text = "Base equipment can be moved and rotated"
			return
		var object := selected_object
		_set_selection(null)
		object.remove_from_group("sandbox_objects")
		object.queue_free()
		sandbox_label.text = "Edit: object deleted"

func _move_selected(delta: Vector3) -> void:
	if not edit_mode or not is_instance_valid(selected_object) or not selected_object.is_in_group("sandbox_objects"):
		return
	var target: Vector3 = selected_object.get_meta("grid_position") + delta
	if not _placement_valid(selected_object.get_meta("kind"), target, selected_object.rotation_degrees.y, selected_object):
		sandbox_label.text = "Cannot move: overlaps same type or outside floor"
		return
	if selected_object.get_meta("kind") in PRODUCT_KINDS:
		selected_object.position = _product_world_position(selected_object.get_meta("kind"), target) + Vector3(0, float(selected_object.get_meta("height_offset", 0.0)), 0)
	else:
		selected_object.position += delta
	selected_object.set_meta("grid_position", target)
	_refresh_transform_controls()
	sandbox_label.text = "Edit: moved " + str(selected_object.get_meta("kind"))

func _move_selected_height(direction: int) -> void:
	if not edit_mode or not is_instance_valid(selected_object) or not selected_object.is_in_group("sandbox_objects"):
		return
	var previous := float(selected_object.get_meta("height_offset", 0.0))
	var next := clampf(previous + 0.25 * direction, -5.0, 10.0)
	selected_object.position.y += next - previous
	selected_object.set_meta("height_offset", next)
	_refresh_transform_controls()
	sandbox_label.text = "Z height: %.2f" % (selected_object.global_position.y - (floor_body.position.y + 0.125))

func _rotate_selected(steps: int) -> void:
	if edit_mode and placement != "select":
		placement_angle = fposmod(placement_angle + 90.0 * steps, 360.0)
		if is_instance_valid(placement_preview):
			placement_preview.rotation_degrees.y = placement_angle
			_update_preview_color()
		sandbox_label.text = "Place " + placement + " | rotation: %d deg" % int(placement_angle)
		return
	if not edit_mode or not is_instance_valid(selected_object) or not selected_object.is_in_group("sandbox_objects"):
		return
	var new_angle := fposmod(selected_object.rotation_degrees.y + 90.0 * steps, 360.0)
	if not _placement_valid(selected_object.get_meta("kind"), selected_object.get_meta("grid_position"), new_angle, selected_object):
		sandbox_label.text = "Cannot rotate: overlaps same type or outside floor"
		return
	selected_object.rotation_degrees.y = new_angle
	if selected_object.get_meta("kind") in PRODUCT_KINDS:
		selected_object.set_meta("placed_rotation", new_angle)
	_refresh_transform_controls()
	sandbox_label.text = "Edit: rotated " + str(selected_object.get_meta("kind"))

func _save_layout() -> void:
	var objects: Array = []
	for object in get_tree().get_nodes_in_group("sandbox_objects"):
		var pos: Vector3 = object.get_meta("grid_position")
		var kind: String = object.get_meta("kind")
		var rotation: float = object.get_meta("placed_rotation", object.rotation_degrees.y) if kind in PRODUCT_KINDS else object.rotation_degrees.y
		var entry := {"kind": kind, "x": pos.x, "z": pos.z, "height_offset": object.get_meta("height_offset", 0.0), "rotation": rotation, "base_id": object.get_meta("base_id", ""), "reversed": object.get_meta("reversed", false)}
		if kind in PRODUCT_KINDS:
			entry["color_index"] = object.get_meta("color_index", 0)
		objects.append(entry)
	var file := FileAccess.open(SANDBOX_PATH, FileAccess.WRITE)
	if file == null:
		sandbox_label.text = "Save failed"
		return
	file.store_string(JSON.stringify({"version": 1, "workspace": {"width": workspace_width, "depth": workspace_depth}, "objects": objects}, "  "))
	sandbox_label.text = "Layout saved"

func _load_layout() -> void:
	if not FileAccess.file_exists(SANDBOX_PATH):
		sandbox_label.text = "No saved layout"
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SANDBOX_PATH))
	if not data is Dictionary or data.get("version") != 1 or not data.get("objects") is Array:
		sandbox_label.text = "Invalid layout"
		return
	var workspace = data.get("workspace", {"width": 22, "depth": 15})
	if not workspace is Dictionary or not (workspace.get("width") is float or workspace.get("width") is int) or not (workspace.get("depth") is float or workspace.get("depth") is int):
		sandbox_label.text = "Invalid workspace size"
		return
	var new_width := int(workspace.width)
	var new_depth := int(workspace.depth)
	if new_width < 10 or new_width > 100 or new_depth < 10 or new_depth > 100 or float(new_width) != float(workspace.width) or float(new_depth) != float(workspace.depth):
		sandbox_label.text = "Invalid workspace size"
		return
	for entry in data.objects:
		if not entry is Dictionary or entry.get("kind") not in ["sensor", "conveyor", "turn", "pusher", "stopper", "box", "box_plastic"] or not (entry.get("x") is float or entry.get("x") is int) or not (entry.get("z") is float or entry.get("z") is int) or not (entry.get("rotation", 0) is float or entry.get("rotation", 0) is int):
			sandbox_label.text = "Invalid layout"
			return
		if entry.get("base_id", "") not in ["", "base_conveyor", "base_sensor"] or (entry.get("base_id", "") == "base_conveyor" and entry.kind != "conveyor") or (entry.get("base_id", "") == "base_sensor" and entry.kind != "sensor"):
			sandbox_label.text = "Invalid layout"
			return
		if not entry.get("reversed", false) is bool:
			sandbox_label.text = "Invalid layout"
			return
		var height_offset = entry.get("height_offset", 0.0)
		if not (height_offset is float or height_offset is int) or float(height_offset) < -5.0 or float(height_offset) > 10.0:
			sandbox_label.text = "Invalid Z height"
			return
		if entry.kind in PRODUCT_KINDS and entry.has("color_index"):
			var color_index = entry.color_index
			if not (color_index is float or color_index is int) or float(color_index) != float(int(color_index)) or int(color_index) < 0 or int(color_index) >= BOX_COLORS.size():
				sandbox_label.text = "Invalid box color"
				return
	_enter_edit_mode()
	_set_selection(null)
	_set_workspace_size(new_width, new_depth)
	for object in get_tree().get_nodes_in_group("sandbox_objects"):
		if object.has_meta("base_id"):
			continue
		object.remove_from_group("sandbox_objects")
		object.queue_free()
	for entry in data.objects:
		var position := Vector3(float(entry.x), 0, float(entry.z))
		var object: Node3D
		if entry.get("base_id", "") == "base_conveyor":
			object = conveyor
			object.position = position + Vector3(0, EQUIPMENT_BASE_HEIGHT.conveyor, 0)
			object.set_meta("grid_position", position)
		elif entry.get("base_id", "") == "base_sensor":
			object = sensor
			object.position = position + Vector3(0, EQUIPMENT_BASE_HEIGHT.sensor, 0)
			object.set_meta("grid_position", position)
		else:
			object = _create_sandbox_object(entry.kind, position)
		var height_offset := float(entry.get("height_offset", 0.0))
		object.position.y += height_offset
		object.set_meta("height_offset", height_offset)
		object.rotation_degrees.y = float(entry.get("rotation", 0))
		if entry.kind in PRODUCT_KINDS:
			object.set_meta("placed_rotation", object.rotation_degrees.y)
			if entry.has("color_index"):
				_set_product_color(object as RigidBody3D, entry.kind, int(entry.color_index))
		if entry.kind == "turn":
			_set_turn_direction(object, entry.get("reversed", false))
	_restore_placed_products()
	sandbox_label.text = "Layout loaded"
