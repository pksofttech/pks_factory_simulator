extends Node3D

const BELT_SPEED := 1.8
const CAMERA_TARGET := Vector3(0, 0.6, 0)
const BOX_COLORS := [
	Color("ee994e"),
	Color("79bd81"),
	Color("76afd9"),
	Color("e2c65c"),
	Color("d78983"),
	Color("c49bd4"),
]
const PRODUCT_KINDS := ["box", "box_plastic", "box_small", "box_metal", "pallet", "workpiece"]
const PROP_KINDS := [
	"prop_rack",
	"prop_barrier",
	"prop_barrel",
	"prop_workbench",
	"prop_forklift",
	"prop_pallet_stack",
	"prop_pallet_jack",
	"prop_bollard",
	"prop_safety_sign",
	"prop_qc_desk",
	"prop_production_board",
	"prop_locker",
]
const EQUIPMENT_BASE_HEIGHT := {
	"conveyor": 0.0,
	"conveyor_short": 0.0,
	"turn": - 0.03,
	"sensor": 1.0025,
	"vision_sensor": 0.0,
	"rgb_sensor": 0.0,
	"pusher": 0.0,
	"stopper": 0.0,
	"emitter": 0.0,
	"remover": 0.0,
	"stack_light": 0.0,
	"motor_fan": 0.0,
	"pump": 0.0,
	"water_tank": 0.0,
	"solenoid_valve": 0.0,
	"light_curtain": 0.0,
	"reject_bin": 0.0,
	"cabinet": 0.0,
	"prop_rack": 0.0,
	"prop_barrier": 0.0,
	"prop_barrel": 0.0,
	"prop_workbench": 0.0,
	"prop_forklift": 0.0,
	"prop_pallet_stack": 0.0,
	"prop_pallet_jack": 0.0,
	"prop_bollard": 0.0,
	"prop_safety_sign": 0.0,
	"prop_qc_desk": 0.0,
	"prop_production_board": 0.0,
	"prop_locker": 0.0,
}
const GRID_STEP := 0.5
var grid_step: float = GRID_STEP
var show_edit_grid: bool = true
const SETTINGS_PATH := "user://settings.cfg"
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
var _right_click_tracking := false
var _right_click_press_pos := Vector2.ZERO
var _right_click_moved := false
var _touch_points: Dictionary = {}
var _touch_start_pos := Vector2.ZERO
var _touch_moved := false
var _touch_mode: String = "" # "", "orbit", "object_drag", "pinch_pan"
var _touch_prev_pinch_dist := 0.0
var _touch_prev_centroid := Vector2.ZERO
var _is_touch_device := false
var top_toolbar_panel: PanelContainer
var desktop_info_pill: PanelContainer
var io_status_scroll: ScrollContainer
var mobile_cam_bar: PanelContainer
var _mobile_cam_view_btn: Button
var _cam_top_view := false
var edit_grid: Node3D
var floor_body: StaticBody3D
var workspace_width := 40
var workspace_depth := 40
var width_input: SpinBox
var depth_input: SpinBox
var decor_option: OptionButton
var factory_decor: Node3D
var decor_style: String = "factory"
const DECOR_THEMES := {
	"factory": {
		"label": "Factory",
		"floor": "343f48",
		"bg": "1b2530",
		"fog": "1f2b38",
		"wall_upper": "465360",
		"wall_dado": "24313d",
		"steel": "293542",
		"line": "e8b923",
		"joint": "263038",
		"lamp": "dceeff",
		"border": "walls",
		"sign": "ZONE A  |  AUTOMATED CONVEYOR LINE",
	},
	"shop": {
		"label": "Shop",
		"floor": "50606b",
		"bg": "22313f",
		"fog": "263645",
		"wall_upper": "768694",
		"wall_dado": "33485a",
		"steel": "3d5163",
		"line": "3dd68c",
		"joint": "42505a",
		"lamp": "f4fbff",
		"border": "fence",
		"sign": "WORKSHOP  |  SMART ASSEMBLY CELL",
	},
	"warehouse": {
		"label": "Warehouse",
		"floor": "2a3138",
		"bg": "141c24",
		"fog": "18212b",
		"wall_upper": "3c4650",
		"wall_dado": "1e262e",
		"steel": "252d36",
		"line": "f28c28",
		"joint": "1d2329",
		"lamp": "ffe9c7",
		"border": "bollards",
		"sign": "BAY 04  |  LOGISTICS & DISPATCH",
	},
	"minimal": {
		"label": "Minimal",
		"floor": "293b4a",
		"bg": "182536",
		"fog": "182536",
		"wall_upper": "465360",
		"wall_dado": "24313d",
		"steel": "293542",
		"line": "4b6b82",
		"joint": "21303d",
		"lamp": "dceeff",
		"border": "none",
		"sign": "",
	},
}
var dragging_object := false
var rotating_object := false
var rotation_drag_pixels := 0.0
var drag_grid_offset := Vector3.ZERO
var sandbox_label: Label
const SANDBOX_PATH := "user://sandbox-layout.json"
const PROJECT_FILE_EXT := "pksfac"
var current_project_path: String = ""
var project_file_label: Label
var project_file_dialog: FileDialog
var project_file_dialog_mode: String = ""
var new_project_confirm_dialog: ConfirmationDialog
var sensor: Area3D
var sensor_indicator: MeshInstance3D
var sensor_indicator_material: StandardMaterial3D
var sensor_bodies: Array[Node3D] = []
var selected_object: Node3D
var selection_material: StandardMaterial3D
var transform_panel: PanelContainer
var transform_scroll: ScrollContainer
var transform_column: VBoxContainer
var transform_title: Label
var transform_value: Label
var object_name_input: LineEdit
var conveyor_speed_row: HBoxContainer
var conveyor_speed_input: SpinBox
var vision_mode_row: HBoxContainer
var vision_mode_option: OptionButton
var rgb_mode_row: HBoxContainer
var rgb_mode_option: OptionButton
var emitter_mode_row: HBoxContainer
var emitter_mode_option: OptionButton
var emitter_defect_row: HBoxContainer
var emitter_defect_input: SpinBox
var undo_button: Button
var redo_button: Button
const MAX_UNDO_STEPS := 30
var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []
var _drag_undo_snapshot: Dictionary = {}
var cabinet_title_row: HBoxContainer
var cabinet_title_input: LineEdit
var cabinet_parts_row: HBoxContainer
var cabinet_yellow_check: CheckBox
var cabinet_rev_check: CheckBox
var cabinet_slot_box: VBoxContainer
var cabinet_slot_grid: GridContainer
var cabinet_slot_buttons: Array[Button] = []
var cabinet_selected_col: int = 0
var cabinet_selected_row: int = 0
var cabinet_slot_io_label: Label
var cabinet_slot_kind: OptionButton
var cabinet_slot_color: ColorPickerButton
var cabinet_dpm_row: HBoxContainer
var cabinet_dpm_unit: LineEdit
var cabinet_dpm_decimals: OptionButton
var tank_force_box: VBoxContainer
var tank_force_sensors_label: Label
var tank_force_valve_btn: Button
var tank_force_valve_slider: HSlider
var tank_force_valve_pct_label: Label
var tank_edit_box: VBoxContainer
var tank_edit_sensors_label: Label
var tank_edit_valve_btn: Button
var tank_edit_valve_slider: HSlider
var tank_edit_valve_pct_label: Label
var cabinet_slot_label: LineEdit
var cabinet_slot_move_mode: bool = false
var cabinet_slot_move_btn: Button
var modbus_section_sep: HSeparator
var modbus_section_header: Label
var modbus_slot_io_label: Label
var modbus_conflict_label: Label
var modbus_coil_row: HBoxContainer
var modbus_coil_input: LineEdit
var modbus_input_row: HBoxContainer
var modbus_input_field: LineEdit
var vision_ir_row: HBoxContainer
var vision_ir_field: LineEdit
var vision_hr_row: HBoxContainer
var vision_hr_field: LineEdit
var force_panel: PanelContainer
var force_title: Label
var force_status_label: Label
var force_item_option: OptionButton
var _force_item_sig: String = ""
var force_on_button: Button
var force_off_button: Button
var force_clear_button: Button
var io_status_panel: PanelContainer
var io_status_list: GridContainer
var io_status_rows: Dictionary = {}
var io_status_signature: String = ""
var io_status_expanded_cabinets: Dictionary = {}
var object_dialog: PanelContainer
var object_dialog_backdrop: ColorRect
var floor_dialog_button: Button
var floor_dialog: PanelContainer
var floor_dialog_backdrop: ColorRect
var grid_step_option: OptionButton
var show_grid_check: CheckBox
var modbus_dialog: PanelContainer
var modbus_dialog_backdrop: ColorRect
var modbus_enabled_check: CheckBox
var modbus_mode_option: OptionButton
var modbus_ip_label: Label
var modbus_ip_input: LineEdit
var modbus_port_input: SpinBox
var modbus_poll_input: SpinBox
var modbus_restart_btn: Button
var modbus_srv_status: Label
var modbus_io_grid: GridContainer
var modbus_config_button: Button
var plc_notation: String = "iec"
var modbus_profile_option: OptionButton
var modbus_fx_row: HBoxContainer
var modbus_fx_coil_off_input: SpinBox
var modbus_fx_di_off_input: SpinBox
var modbus_fx_hr_off_input: SpinBox
var modbus_fx_ir_off_input: SpinBox
var modbus_unit_id_input: SpinBox
var modbus_pack_di_check: CheckBox
var modbus_table_title: Label
var modbus_auto_map_btn: Button
var ladder_notation_option: OptionButton
const SoftPLCScript := preload("res://soft_plc.gd")
var soft_plc = SoftPLCScript.new()
var ladder_dialog: PanelContainer
var ladder_dialog_backdrop: ColorRect
var ladder_enabled_check: CheckBox
var ladder_code_edit: CodeEdit
var ladder_status_label: Label
var ladder_watch_label: Label
var ladder_config_button: Button
var plc_controller_option: OptionButton
var edit_tools_row: HFlowContainer
var edit_mode_button: Button
var delete_tool_button: Button
var _svg_icon_cache: Dictionary = {}
var axis_gizmo: Control
var start_button: Button
var status_toggle_button: Button
var npc_toggle_button: Button
var help_button: Button
var help_dialog: PanelContainer
var help_dialog_backdrop: ColorRect
var _help_select_tab_cb: Callable
var _help_rebuild_cb: Callable
var _help_current_tab: int = 0
var guide_lang: String = "en"
var npcs_enabled: bool = true
var npc_operator_enabled: bool = true
var npc_tester_enabled: bool = true
var npc_safety_enabled: bool = true
var npc_maintenance_enabled: bool = true
var npc_qc_enabled: bool = true
var npc_walk_speed: float = 1.85
var npc_inspect_duration: float = 2.2
var npc_chat_enabled: bool = true
var npc_sound_enabled: bool = true
var npc_dialog: PanelContainer
var npc_dialog_backdrop: ColorRect
var npc_master_check: CheckBox
var npc_op_check: CheckBox
var npc_tester_check: CheckBox
var npc_safety_check: CheckBox
var npc_maint_check: CheckBox
var npc_qc_check: CheckBox
var npc_chat_check: CheckBox
var npc_sound_check: CheckBox
var npc_speed_spin: SpinBox
var npc_inspect_spin: SpinBox
var sound_toggle_button: Button
var sound_enabled: bool = true
var cabinet_layer: CanvasLayer
var cabinet_panel: PanelContainer
var cabinet_coil_addr := -1
var cabinet_input_addr := -1
const CABINET_IO_DEFS := [
	{"id": "BtnStart", "label": "Cabinet.BtnStart", "kind": "button", "dir": "input"},
	{"id": "BtnStop", "label": "Cabinet.BtnStop", "kind": "button", "dir": "input"},
	{"id": "Btn01", "label": "Cabinet.Btn01", "kind": "button", "dir": "input"},
	{"id": "SwitchAuto", "label": "Cabinet.SwitchAuto", "kind": "switch", "dir": "input"},
	{"id": "SwitchEStop", "label": "Cabinet.SwitchEStop", "kind": "switch", "dir": "input"},
	{"id": "LampGreen", "label": "Cabinet.LampGreen", "kind": "lamp", "dir": "coil"},
	{"id": "LampRed", "label": "Cabinet.LampRed", "kind": "lamp", "dir": "coil"},
]
var cabinet_io_addrs: Dictionary = {
	"BtnStart": - 1,
	"BtnStop": - 1,
	"Btn01": - 1,
	"SwitchAuto": - 1,
	"SwitchEStop": - 1,
	"LampGreen": - 1,
	"LampRed": - 1,
}
var running := true
var plc_mode := false
var detected_count := 0
var test_mode := false
var _is_loading_settings := false
var test_box: RigidBody3D
var elapsed := 0.0
var _io_status_refresh_timer := 0.0
var _status_style_cache: Dictionary = {}
var _force_panel_layout_sig: String = ""
var spawn_plastic_next := false
var test_stopped := false
var test_resumed := false
var test_controls_ok := true
var cardboard_material: StandardMaterial3D
var plastic_material: StandardMaterial3D
var _cardboard_color_materials: Dictionary = {}
var _plastic_color_materials: Dictionary = {}
var _edit_grid_material: StandardMaterial3D


func _ready() -> void:
	random.randomize()
	test_mode = "--smoke-test" in OS.get_cmdline_user_args()
	selection_material = StandardMaterial3D.new()
	selection_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	selection_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	selection_material.albedo_color = Color(1.0, 0.85, 0.2, 0.3)
	_build_world()
	_build_edit_grid()
	_build_ui()
	if get_viewport() != null:
		get_viewport().size_changed.connect(_on_viewport_resized)
	if is_instance_valid(top_toolbar_panel):
		top_toolbar_panel.resized.connect(_on_viewport_resized)
	ModbusTCP.coil_written.connect(_on_modbus_coil_written)
	test_box = _spawn_box()
	if test_mode:
		_set_running(true)
	else:
		_is_loading_settings = true
		if FileAccess.file_exists(SANDBOX_PATH):
			_load_layout(true)
		_apply_plc_mode(true)
		_set_running(false)
		sandbox_label.text = "Mode: STOP"
		_load_settings()
		if (
			(_is_mobile_web() or _is_compact_viewport())
			and is_instance_valid(io_status_panel) and io_status_panel.visible
		):
			_toggle_io_status_panel()
		_is_loading_settings = false
	_on_viewport_resized.call_deferred()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_layout(true)
		_save_settings()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		_set_help_dialog_visible(not help_dialog.visible if is_instance_valid(help_dialog) else true)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if is_instance_valid(help_dialog) and help_dialog.visible:
			_set_help_dialog_visible(false)
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		var mode := DisplayServer.window_get_mode()
		var is_full := (
			mode == DisplayServer.WINDOW_MODE_FULLSCREEN
			or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		)
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED if is_full else DisplayServer.WINDOW_MODE_FULLSCREEN
		)
		get_viewport().set_input_as_handled()
		return
	if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if event is InputEventScreenTouch:
		_is_touch_device = true
		if event.pressed:
			_touch_points[event.index] = event.position
			if _touch_points.size() == 1:
				_touch_start_pos = event.position
				_touch_moved = false
				_touch_mode = ""
			elif _touch_points.size() == 2:
				dragging_object = false
				rotating_object = false
				_drag_undo_snapshot = {}
				_touch_mode = "pinch_pan"
				_touch_moved = true
				var pts := _touch_points.values()
				var p0: Vector2 = pts[0]
				var p1: Vector2 = pts[1]
				_touch_prev_pinch_dist = p0.distance_to(p1)
				_touch_prev_centroid = (p0 + p1) * 0.5
		else:
			_touch_points.erase(event.index)
			if _touch_points.is_empty():
				if not _touch_moved:
					if edit_mode and placement != "select":
						_place_at(event.position)
					else:
						_select_at(event.position)
				elif _touch_mode == "object_drag" and dragging_object:
					dragging_object = false
					_commit_drag_edit()
				_touch_mode = ""
				_touch_moved = false
			elif _touch_points.size() == 1:
				_touch_mode = "orbit"
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenDrag:
		_is_touch_device = true
		_touch_points[event.index] = event.position
		if _touch_points.size() >= 2:
			var pts := _touch_points.values()
			var p0: Vector2 = pts[0]
			var p1: Vector2 = pts[1]
			var dist := p0.distance_to(p1)
			var centroid := (p0 + p1) * 0.5
			if _touch_prev_pinch_dist > 10.0 and dist > 10.0:
				camera_distance = clampf(camera_distance * (_touch_prev_pinch_dist / dist), 4.5, 35.0)
			var pan_delta := centroid - _touch_prev_centroid
			var scale_factor := camera_distance * 0.0018
			camera_target += (
				-camera.global_basis.x * pan_delta.x + camera.global_basis.y * pan_delta.y
			) * scale_factor
			_touch_prev_pinch_dist = dist
			_touch_prev_centroid = centroid
			_update_camera()
		elif _touch_points.size() == 1:
			if not _touch_moved and event.position.distance_to(_touch_start_pos) > 8.0:
				_touch_moved = true
				if (
					edit_mode and placement == "select"
					and is_instance_valid(selected_object)
					and _hit_sandbox_object_at(_touch_start_pos) == selected_object
				):
					_touch_mode = "object_drag"
					_start_object_drag(_touch_start_pos)
				else:
					_touch_mode = "orbit"
			if _touch_mode == "object_drag" and dragging_object:
				_drag_selected_to(event.position)
			elif _touch_mode == "orbit":
				camera_yaw -= event.relative.x * 0.006
				camera_pitch = clampf(camera_pitch + event.relative.y * 0.006, 0.12, 1.35)
				_update_camera()
		get_viewport().set_input_as_handled()
		return
	if (
		event is InputEventMouseMotion and rotating_object
		and event.button_mask & MOUSE_BUTTON_MASK_LEFT
	):
		_update_rotation_drag(event.relative.x)
	elif (
		event is InputEventMouseMotion and dragging_object
		and event.button_mask & MOUSE_BUTTON_MASK_LEFT
	):
		_drag_selected_to(event.position)
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
		if _right_click_tracking and event.position.distance_to(_right_click_press_pos) > 5.0:
			_right_click_moved = true
		camera_yaw -= event.relative.x * 0.006
		camera_pitch = clampf(camera_pitch + event.relative.y * 0.006, 0.12, 1.35)
		_update_camera()
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
		var scale_factor := camera_distance * 0.0015
		camera_target += (
			- camera.global_basis.x * event.relative.x + camera.global_basis.y * event.relative.y
		) * scale_factor
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
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if edit_mode and get_viewport().gui_get_hovered_control() == null:
				_right_click_tracking = true
				_right_click_press_pos = event.position
				_right_click_moved = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if get_viewport().gui_get_hovered_control() == null:
				camera_distance = maxf(4.5, camera_distance - 1.0)
				_update_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if get_viewport().gui_get_hovered_control() == null:
				camera_distance = minf(35.0, camera_distance + 1.0)
				_update_camera()
	elif (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed
	):
		var was_click := _right_click_tracking and not _right_click_moved
		_right_click_tracking = false
		_right_click_moved = false
		if was_click and edit_mode:
			if placement != "select":
				_set_placement("select")
			else:
				_set_object_dialog_visible(true)
	elif (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed
	):
		var was_editing := dragging_object or rotating_object
		dragging_object = false
		rotating_object = false
		rotation_drag_pixels = 0.0
		if was_editing:
			_commit_drag_edit()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_reset_camera()
	elif (
		event is InputEventKey and event.pressed and not event.echo
		and event.keycode == KEY_DELETE and edit_mode
	):
		_delete_selected()
	elif (
		event is InputEventKey and event.pressed and not event.echo
		and event.keycode == KEY_ESCAPE and edit_mode
	):
		_set_placement("select")
	elif event is InputEventKey and event.pressed and not event.echo and edit_mode:
		if event.ctrl_pressed and event.keycode == KEY_Z:
			if event.shift_pressed:
				_redo()
			else:
				_undo()
			return
		if event.ctrl_pressed and event.keycode == KEY_Y:
			_redo()
			return
		match event.keycode:
			KEY_ESCAPE:
				if is_instance_valid(modbus_dialog) and modbus_dialog.visible:
					_set_modbus_dialog_visible(false)
				if is_instance_valid(ladder_dialog) and ladder_dialog.visible:
					_set_ladder_dialog_visible(false)
				if is_instance_valid(object_dialog) and object_dialog.visible:
					_set_object_dialog_visible(false)
				if is_instance_valid(floor_dialog) and floor_dialog.visible:
					_set_floor_dialog_visible(false)
				if is_instance_valid(npc_dialog) and npc_dialog.visible:
					_set_npc_dialog_visible(false)
			KEY_LEFT:
				_move_selected(Vector3(-grid_step, 0, 0))
			KEY_RIGHT:
				_move_selected(Vector3(grid_step, 0, 0))
			KEY_UP:
				_move_selected(Vector3(0, 0, -grid_step))
			KEY_DOWN:
				_move_selected(Vector3(0, 0, grid_step))
			KEY_PAGEUP:
				_move_selected_height(1)
			KEY_PAGEDOWN:
				_move_selected_height(-1)
			KEY_Q:
				_rotate_selected(-1)
			KEY_E:
				_rotate_selected(1)
			KEY_F:
				_toggle_turn_direction()


func _commit_drag_edit() -> void:
	if not _drag_undo_snapshot.is_empty():
		var after_snap := _build_layout_data()
		if JSON.stringify(after_snap) != JSON.stringify(_drag_undo_snapshot):
			_record_undo_snapshot(_drag_undo_snapshot)
		_drag_undo_snapshot = {}
	_save_layout(true)


func _reset_camera() -> void:
	camera_yaw = 0.6435
	camera_pitch = 0.447
	camera_distance = 19.4
	camera_target = CAMERA_TARGET
	_cam_top_view = false
	if is_instance_valid(_mobile_cam_view_btn):
		_mobile_cam_view_btn.text = "Top"
	_update_camera()


func _hit_sandbox_object_at(screen_position: Vector2) -> Node3D:
	var origin := camera.project_ray_origin(screen_position)
	var query := PhysicsRayQueryParameters3D.create(
		origin,
		origin + camera.project_ray_normal(screen_position) * 1000.0,
		3,
	)
	query.collide_with_areas = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var cursor: Node = hit.get("collider") as Node
	while cursor != null:
		if cursor is Node3D and cursor.is_in_group("sandbox_objects"):
			return cursor as Node3D
		cursor = cursor.get_parent()
	return null


func _select_at(screen_position: Vector2) -> void:
	_set_selection(_hit_sandbox_object_at(screen_position))


func _set_selection(object: Node3D) -> void:
	if is_instance_valid(selected_object):
		_set_selection_overlay(selected_object, null)
	selected_object = object
	cabinet_slot_move_mode = false
	_update_cabinet_panel_visibility()
	if not is_instance_valid(object):
		_refresh_transform_controls()
		return
	if selection_material == null:
		selection_material = StandardMaterial3D.new()
		selection_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		selection_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		selection_material.albedo_color = Color(1.0, 0.85, 0.2, 0.3)
	_set_selection_overlay(object, selection_material)
	_refresh_transform_controls()
	_refresh_io_status_list()
	if is_instance_valid(io_status_list):
		var row = io_status_rows.get(object.get_instance_id())
		if row != null and is_instance_valid(row[0]):
			var scroll := io_status_list.get_parent() as ScrollContainer
			if scroll != null:
				scroll.ensure_control_visible(row[0] as Control)


func _set_selection_overlay(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		node.material_overlay = material
	for child in node.get_children():
		_set_selection_overlay(child, material)


func _update_camera() -> void:
	var horizontal := camera_distance * cos(camera_pitch)
	camera.position = camera_target + Vector3(
		horizontal * sin(camera_yaw),
		camera_distance * sin(camera_pitch),
		horizontal * cos(camera_yaw),
	)
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
	if plc_mode:
		_sync_modbus_io()
		if running and soft_plc.enabled and not ModbusTCP.enabled:
			soft_plc.step(delta, ModbusTCP)
			_sync_modbus_io()
	_io_status_refresh_timer += delta
	if _io_status_refresh_timer >= 0.15:
		_io_status_refresh_timer = 0.0
		_refresh_io_status_list()
		if is_instance_valid(force_panel) and force_panel.visible:
			_refresh_force_panel()
		if is_instance_valid(ladder_dialog) and ladder_dialog.visible:
			_refresh_ladder_watch()
		_refresh_cabinet_hud()
	if test_mode and elapsed >= 3.0 and not test_stopped:
		_toggle_conveyor()
		test_controls_ok = (
			test_controls_ok and not running and conveyor.constant_linear_velocity == Vector3.ZERO
		)
		test_stopped = true
	if test_mode and elapsed >= 4.0 and not test_resumed:
		_toggle_conveyor()
		test_controls_ok = (
			test_controls_ok and running
			and is_equal_approx(conveyor.constant_linear_velocity.x, BELT_SPEED)
		)
		test_resumed = true
	if test_mode and elapsed >= 7.0:
		var advanced := is_instance_valid(test_box) and test_box.global_position.x > -1.0
		if detected_count > 0 and advanced and test_controls_ok and test_resumed:
			print(
				"SMOKE_TEST_PASS sensor_detected=",
				detected_count,
				" box_x=",
				test_box.global_position.x,
				" controls=ok",
			)
			get_tree().quit(0)
		else:
			push_error(
				"SMOKE_TEST_FAIL sensor_detected=%d box_x=%s"
				% [detected_count, str(test_box.global_position.x)]
			)
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


func _box_mesh(
	parent: Node,
	dimensions: Vector3,
	location: Vector3,
	color: Color,
) -> MeshInstance3D:
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


func _static_box(
	parent: Node,
	dimensions: Vector3,
	location: Vector3,
	color: Color,
) -> StaticBody3D:
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
	env.background_color = Color("1b2530")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d4e2f0")
	env.ambient_light_energy = 0.62
	env.fog_enabled = true
	env.fog_light_color = Color("1f2b38")
	env.fog_density = 0.007
	environment.environment = env
	add_child(environment)

	var light := DirectionalLight3D.new()
	light.name = "FactorySunLight"
	light.rotation_degrees = Vector3(-55, -35, 0)
	light.light_color = Color("fff6e8")
	light.light_energy = 1.25
	light.shadow_enabled = true
	add_child(light)

	var fill_light := DirectionalLight3D.new()
	fill_light.name = "FactoryFillLight"
	fill_light.rotation_degrees = Vector3(-35, 135, 0)
	fill_light.light_color = Color("a8c8f0")
	fill_light.light_energy = 0.4
	add_child(fill_light)

	camera = Camera3D.new()
	camera.name = "FactoryCamera"
	add_child(camera)
	_update_camera()
	camera.current = true
	camera.fov = 45.0

	floor_body = _static_box(
		self,
		Vector3(workspace_width, 0.25, workspace_depth),
		Vector3(0, -0.18, 0),
		Color("343f48"),
	)
	floor_body.name = "FactoryFloor"
	(floor_body.get_child(1) as CollisionShape3D).position.y = 0.01
	_build_factory_decor()

	# Primary line: BoxEmitter -> MainConveyor -> EntrySensor -> QueueStopper -> CornerTurn -> BranchConveyor -> DivertPusher -> ReturnConveyor
	conveyor = _create_sandbox_object("conveyor", Vector3.ZERO, true) as StaticBody3D
	conveyor.name = "MainConveyor"
	conveyor.set_meta("base_id", "base_conveyor")

	sensor = _create_sandbox_object("sensor", Vector3.ZERO, true) as Area3D
	sensor.name = "EntrySensor"
	sensor.set_meta("base_id", "base_sensor")
	sensor_indicator = sensor.get_node("Indicator") as MeshInstance3D
	sensor_indicator_material = sensor_indicator.material_override as StandardMaterial3D

	if not test_mode:
		var box_emitter := _create_sandbox_object("emitter", Vector3(-3.5, 0, 0))
		if box_emitter != null:
			box_emitter.name = "BoxEmitter"

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

		var control_cabinet := _create_sandbox_object("cabinet", Vector3(-3.0, 0, 2.2))
		if control_cabinet != null:
			control_cabinet.name = "ControlCabinet"
			control_cabinet.set("cabinet_title", "LINE 1 CONTROL")

		for obj in [
			box_emitter,
			conveyor,
			sensor,
			queue_stopper,
			corner_turn,
			branch_conveyor,
			divert_pusher,
			return_conveyor,
			control_cabinet,
		]:
			if is_instance_valid(obj):
				_set_object_active_state(obj, false)

	var npc_scene := load("res://objects/operator_npc.tscn") as PackedScene
	if npc_scene != null:
		var operator_npc := npc_scene.instantiate() as Node3D
		operator_npc.name = "OperatorNPC"
		operator_npc.position = Vector3(-2.0, 0.0, 2.2)
		add_child(operator_npc)
	var tester_scene := load("res://objects/tester_npc.tscn") as PackedScene
	if tester_scene != null:
		var tester_npc := tester_scene.instantiate() as Node3D
		tester_npc.name = "TesterNPC"
		tester_npc.position = Vector3(6.5, 0.0, -2.5)
		add_child(tester_npc)
	var safety_scene := load("res://objects/safety_npc.tscn") as PackedScene
	if safety_scene != null:
		var safety_npc := safety_scene.instantiate() as Node3D
		safety_npc.name = "SafetyNPC"
		safety_npc.position = Vector3(-6.0, 0.0, -3.0)
		add_child(safety_npc)
	var maint_scene := load("res://objects/maintenance_npc.tscn") as PackedScene
	if maint_scene != null:
		var maint_npc := maint_scene.instantiate() as Node3D
		maint_npc.name = "MaintenanceNPC"
		maint_npc.position = Vector3(2.5, 0.0, 6.0)
		add_child(maint_npc)
	var qc_scene := load("res://objects/qc_npc.tscn") as PackedScene
	if qc_scene != null:
		var qc_npc := qc_scene.instantiate() as Node3D
		qc_npc.name = "QCNPC"
		qc_npc.position = Vector3(8.0, 0.0, 2.0)
		add_child(qc_npc)


func _apply_decor_style(style_id: String) -> void:
	if style_id not in DECOR_THEMES:
		style_id = "factory"
	decor_style = style_id
	if is_instance_valid(decor_option):
		var keys := DECOR_THEMES.keys()
		var idx := keys.find(decor_style)
		if idx >= 0:
			decor_option.select(idx)
	_build_factory_decor()
	_save_settings()


func _build_factory_decor() -> void:
	if is_instance_valid(factory_decor):
		if factory_decor.get_parent() == self:
			remove_child(factory_decor)
		factory_decor.queue_free()
		factory_decor = null
	var old := get_node_or_null("FactoryDecor")
	if old != null:
		remove_child(old)
		old.queue_free()
	var theme_cfg: Dictionary = DECOR_THEMES.get(decor_style, DECOR_THEMES["factory"])
	if is_instance_valid(floor_body):
		var floor_mesh := floor_body.get_child(0) as MeshInstance3D
		if floor_mesh != null and floor_mesh.material_override is StandardMaterial3D:
			(floor_mesh.material_override as StandardMaterial3D).albedo_color = Color(
				theme_cfg["floor"]
			)
	var border_mode := str(theme_cfg.get("border", "walls"))
	var world_env := get_node_or_null("FactoryEnvironment") as WorldEnvironment
	if world_env != null and world_env.environment != null:
		world_env.environment.background_color = Color(theme_cfg["bg"])
		world_env.environment.fog_light_color = Color(theme_cfg["fog"])
		world_env.environment.fog_enabled = border_mode == "walls"

	var decor := Node3D.new()
	decor.name = "FactoryDecor"
	factory_decor = decor
	add_child(decor)

	var hw := float(workspace_width) * 0.5
	var hd := float(workspace_depth) * 0.5

	var mat_wall_upper := StandardMaterial3D.new()
	mat_wall_upper.albedo_color = Color(theme_cfg["wall_upper"])
	mat_wall_upper.roughness = 0.85

	var mat_wall_dado := StandardMaterial3D.new()
	mat_wall_dado.albedo_color = Color(theme_cfg["wall_dado"])
	mat_wall_dado.roughness = 0.72

	var mat_steel := StandardMaterial3D.new()
	mat_steel.albedo_color = Color(theme_cfg["steel"])
	mat_steel.metallic = 0.45
	mat_steel.roughness = 0.45

	var mat_line := StandardMaterial3D.new()
	mat_line.albedo_color = Color(theme_cfg["line"])
	mat_line.roughness = 0.5

	var mat_joint := StandardMaterial3D.new()
	mat_joint.albedo_color = Color(theme_cfg["joint"])
	mat_joint.roughness = 0.9

	var mat_lamp := StandardMaterial3D.new()
	mat_lamp.albedo_color = Color(theme_cfg["lamp"])
	mat_lamp.emission_enabled = true
	mat_lamp.emission = Color(theme_cfg["lamp"])
	mat_lamp.emission_energy_multiplier = 2.0

	var add_box := func(parent: Node3D, sz: Vector3, pos: Vector3, mat: Material) -> void:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = sz
		mi.mesh = bm
		mi.material_override = mat
		mi.position = pos
		if sz.y <= 0.02:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)

	# Concrete floor expansion joints every 5m
	for gx in range(-int(floor(hw)) + 5, int(floor(hw)), 5):
		add_box.call(
			decor,
			Vector3(0.03, 0.004, float(workspace_depth)),
			Vector3(float(gx), -0.052, 0.0),
			mat_joint,
		)
	for gz in range(-int(floor(hd)) + 5, int(floor(hd)), 5):
		add_box.call(
			decor,
			Vector3(float(workspace_width), 0.004, 0.03),
			Vector3(0.0, -0.052, float(gz)),
			mat_joint,
		)

	match border_mode:
		"fence":
			var post_h := 0.95
			var fx := hw - 0.12
			var fz := hd - 0.12
			add_box.call(
				decor,
				Vector3(float(workspace_width) - 0.2, 0.06, 0.06),
				Vector3(0.0, 0.80, -fz),
				mat_line,
			)
			add_box.call(
				decor,
				Vector3(float(workspace_width) - 0.2, 0.05, 0.05),
				Vector3(0.0, 0.42, -fz),
				mat_steel,
			)
			add_box.call(
				decor,
				Vector3(float(workspace_width) - 0.2, 0.06, 0.06),
				Vector3(0.0, 0.80, fz),
				mat_line,
			)
			add_box.call(
				decor,
				Vector3(float(workspace_width) - 0.2, 0.05, 0.05),
				Vector3(0.0, 0.42, fz),
				mat_steel,
			)
			add_box.call(
				decor,
				Vector3(0.06, 0.06, float(workspace_depth) - 0.2),
				Vector3(-fx, 0.80, 0.0),
				mat_line,
			)
			add_box.call(
				decor,
				Vector3(0.05, 0.05, float(workspace_depth) - 0.2),
				Vector3(-fx, 0.42, 0.0),
				mat_steel,
			)
			add_box.call(
				decor,
				Vector3(0.06, 0.06, float(workspace_depth) - 0.2),
				Vector3(fx, 0.80, 0.0),
				mat_line,
			)
			add_box.call(
				decor,
				Vector3(0.05, 0.05, float(workspace_depth) - 0.2),
				Vector3(fx, 0.42, 0.0),
				mat_steel,
			)
			for px in range(-int(floor(fx)), int(floor(fx)) + 1, 4):
				for sz in [-fz, fz]:
					add_box.call(
						decor,
						Vector3(0.1, post_h, 0.1),
						Vector3(float(px), post_h * 0.5 - 0.05, sz),
						mat_steel,
					)
					add_box.call(
						decor,
						Vector3(0.12, 0.07, 0.12),
						Vector3(float(px), post_h - 0.05, sz),
						mat_line,
					)
			for pz in range(-int(floor(fz)) + 4, int(floor(fz)), 4):
				for sx in [-fx, fx]:
					add_box.call(
						decor,
						Vector3(0.1, post_h, 0.1),
						Vector3(sx, post_h * 0.5 - 0.05, float(pz)),
						mat_steel,
					)
					add_box.call(
						decor,
						Vector3(0.12, 0.07, 0.12),
						Vector3(sx, post_h - 0.05, float(pz)),
						mat_line,
					)
		"bollards":
			var bx := hw - 0.22
			var bz := hd - 0.22
			for px in range(-int(floor(bx)), int(floor(bx)) + 1, 3):
				for sz in [-bz, bz]:
					add_box.call(
						decor,
						Vector3(0.22, 0.06, 0.22),
						Vector3(float(px), -0.02, sz),
						mat_steel,
					)
					add_box.call(
						decor,
						Vector3(0.14, 0.82, 0.14),
						Vector3(float(px), 0.40, sz),
						mat_line,
					)
					add_box.call(
						decor,
						Vector3(0.15, 0.12, 0.15),
						Vector3(float(px), 0.72, sz),
						mat_steel,
					)
			for pz in range(-int(floor(bz)) + 3, int(floor(bz)), 3):
				for sx in [-bx, bx]:
					add_box.call(
						decor,
						Vector3(0.22, 0.06, 0.22),
						Vector3(sx, -0.02, float(pz)),
						mat_steel,
					)
					add_box.call(
						decor,
						Vector3(0.14, 0.82, 0.14),
						Vector3(sx, 0.40, float(pz)),
						mat_line,
					)
					add_box.call(
						decor,
						Vector3(0.15, 0.12, 0.15),
						Vector3(sx, 0.72, float(pz)),
						mat_steel,
					)
		"walls":
			var wall_h := 6.0
			var dado_h := 1.4
			add_box.call(
				decor,
				Vector3(float(workspace_width) + 0.6, wall_h, 0.3),
				Vector3(0.0, wall_h * 0.5 - 0.05, -hd - 0.15),
				mat_wall_upper,
			)
			add_box.call(
				decor,
				Vector3(float(workspace_width) + 0.6, dado_h, 0.34),
				Vector3(0.0, dado_h * 0.5 - 0.05, -hd - 0.13),
				mat_wall_dado,
			)
			add_box.call(
				decor,
				Vector3(float(workspace_width) + 0.4, 0.08, 0.36),
				Vector3(0.0, dado_h - 0.05, -hd - 0.12),
				mat_line,
			)

			add_box.call(
				decor,
				Vector3(0.3, wall_h, float(workspace_depth)),
				Vector3(-hw - 0.15, wall_h * 0.5 - 0.05, 0.0),
				mat_wall_upper,
			)
			add_box.call(
				decor,
				Vector3(0.34, dado_h, float(workspace_depth)),
				Vector3(-hw - 0.13, dado_h * 0.5 - 0.05, 0.0),
				mat_wall_dado,
			)
			add_box.call(
				decor,
				Vector3(0.36, 0.08, float(workspace_depth)),
				Vector3(-hw - 0.12, dado_h - 0.05, 0.0),
				mat_line,
			)

			add_box.call(
				decor,
				Vector3(0.3, wall_h, float(workspace_depth)),
				Vector3(hw + 0.15, wall_h * 0.5 - 0.05, 0.0),
				mat_wall_upper,
			)
			add_box.call(
				decor,
				Vector3(0.34, dado_h, float(workspace_depth)),
				Vector3(hw + 0.13, dado_h * 0.5 - 0.05, 0.0),
				mat_wall_dado,
			)
			add_box.call(
				decor,
				Vector3(0.36, 0.08, float(workspace_depth)),
				Vector3(hw + 0.12, dado_h - 0.05, 0.0),
				mat_line,
			)

			for cx in range(-int(floor(hw)) + 4, int(floor(hw)), 8):
				add_box.call(
					decor,
					Vector3(0.38, wall_h, 0.42),
					Vector3(float(cx), wall_h * 0.5 - 0.05, -hd + 0.05),
					mat_steel,
				)
				add_box.call(
					decor,
					Vector3(1.6, 0.08, 0.25),
					Vector3(float(cx), wall_h - 0.4, -hd + 0.45),
					mat_lamp,
				)
			for cz in range(-int(floor(hd)) + 4, int(floor(hd)), 8):
				add_box.call(
					decor,
					Vector3(0.42, wall_h, 0.38),
					Vector3(-hw + 0.05, wall_h * 0.5 - 0.05, float(cz)),
					mat_steel,
				)
				add_box.call(
					decor,
					Vector3(0.42, wall_h, 0.38),
					Vector3(hw - 0.05, wall_h * 0.5 - 0.05, float(cz)),
					mat_steel,
				)

	# Zone sign adapted to current style
	var sign_txt := str(theme_cfg["sign"])
	if not sign_txt.is_empty():
		var sign_y := 3.6 if border_mode == "walls" else 2.2
		if border_mode != "walls":
			add_box.call(decor, Vector3(0.12, 2.5, 0.12), Vector3(-4.6, 1.2, -hd + 0.12), mat_steel)
			add_box.call(decor, Vector3(0.12, 2.5, 0.12), Vector3(4.6, 1.2, -hd + 0.12), mat_steel)
			add_box.call(
				decor,
				Vector3(9.6, 0.9, 0.08),
				Vector3(0.0, sign_y, -hd + 0.12),
				mat_wall_dado,
			)
			add_box.call(
				decor,
				Vector3(9.64, 0.06, 0.1),
				Vector3(0.0, sign_y + 0.46, -hd + 0.12),
				mat_line,
			)
			add_box.call(
				decor,
				Vector3(9.64, 0.06, 0.1),
				Vector3(0.0, sign_y - 0.46, -hd + 0.12),
				mat_line,
			)
		var sign_lbl := Label3D.new()
		sign_lbl.text = sign_txt
		sign_lbl.position = Vector3(0.0, sign_y, -hd + (0.06 if border_mode == "walls" else 0.18))
		sign_lbl.pixel_size = 0.015
		sign_lbl.font_size = 42
		sign_lbl.modulate = Color(theme_cfg["line"])
		sign_lbl.outline_modulate = Color("101820")
		sign_lbl.outline_size = 8
		decor.add_child(sign_lbl)


func _set_object_active_state(obj: Node3D, is_active: bool) -> void:
	var kind := str(obj.get_meta("kind", ""))
	if kind == "turn":
		var area := obj.get_node_or_null("TransferArea")
		if area != null:
			area.set("active", is_active)
	elif kind in ["sensor", "vision_sensor", "rgb_sensor"]:
		obj.call("set_detected", is_active)
	elif "active" in obj:
		obj.set("active", is_active)


func _ui_stylebox(
	bg: Color,
	border: Color = Color(0, 0, 0, 0),
	radius: int = 8,
	border_w: int = 1,
	pad_h: int = 10,
	pad_v: int = 6,
) -> StyleBoxFlat:
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
	ui_theme.set_stylebox(
		"normal",
		"Button",
		_ui_stylebox(Color("1c2a36"), Color("2f4556"), 7, 1, 12, 6),
	)
	ui_theme.set_stylebox(
		"hover",
		"Button",
		_ui_stylebox(Color("263949"), Color("4a6b82"), 7, 1, 12, 6),
	)
	ui_theme.set_stylebox(
		"pressed",
		"Button",
		_ui_stylebox(Color("142029"), Color("5c85a1"), 7, 1, 12, 6),
	)
	ui_theme.set_stylebox(
		"focus",
		"Button",
		_ui_stylebox(Color("1c2a36"), Color("58b4d1"), 7, 1, 12, 6),
	)
	ui_theme.set_color("font_color", "Button", Color("e4edf2"))
	ui_theme.set_color("font_hover_color", "Button", Color("ffffff"))
	ui_theme.set_color("font_pressed_color", "Button", Color("cfe8f5"))
	ui_theme.set_font_size("font_size", "Button", 13)

	ui_theme.set_color("font_color", "Label", Color("c9d7e0"))
	ui_theme.set_font_size("font_size", "Label", 13)

	ui_theme.set_stylebox(
		"normal",
		"LineEdit",
		_ui_stylebox(Color("111a22"), Color("2f4556"), 6, 1, 8, 4),
	)
	ui_theme.set_stylebox(
		"focus",
		"LineEdit",
		_ui_stylebox(Color("111a22"), Color("58b4d1"), 6, 1, 8, 4),
	)
	ui_theme.set_color("font_color", "LineEdit", Color("edf5f8"))
	ui_theme.set_font_size("font_size", "LineEdit", 13)
	return ui_theme


func _style_accent_button(
	button: Button,
	normal_hex: String,
	hover_hex: String,
	border_hex: String,
) -> void:
	button.add_theme_stylebox_override(
		"normal",
		_ui_stylebox(Color(normal_hex), Color(border_hex), 7, 1, 12, 6),
	)
	button.add_theme_stylebox_override(
		"hover",
		_ui_stylebox(Color(hover_hex), Color(border_hex), 7, 1, 12, 6),
	)
	button.add_theme_stylebox_override(
		"pressed",
		_ui_stylebox(Color(normal_hex).darkened(0.2), Color(border_hex), 7, 1, 12, 6),
	)
	button.add_theme_color_override("font_color", Color("ffffff"))


func _make_ui_divider() -> VSeparator:
	var sep := VSeparator.new()
	sep.custom_minimum_size = Vector2(2, 24)
	sep.add_theme_stylebox_override(
		"separator",
		_ui_stylebox(Color("2a3f50"), Color(0, 0, 0, 0), 1, 0, 0, 0),
	)
	return sep


func _make_status_pill(
	parent: Control,
	initial_text: String,
	text_color: Color = Color("c9d7e0"),
) -> Label:
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override(
		"panel",
		_ui_stylebox(Color("121d26"), Color("283c4c"), 12, 1, 10, 4),
	)
	parent.add_child(pill)
	var label := Label.new()
	label.text = initial_text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", text_color)
	pill.add_child(label)
	return label


func _make_svg_icon(svg_paths: String, size: int = 15) -> ImageTexture:
	var key := "%d:%s" % [size, svg_paths]
	if _svg_icon_cache.has(key):
		return _svg_icon_cache[key]
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 24 24" fill="none" stroke="#e6f1f5" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">%s</svg>' % [size, size, svg_paths]
	var img := Image.new()
	if img.load_svg_from_string(svg) == OK:
		var tex := ImageTexture.create_from_image(img)
		_svg_icon_cache[key] = tex
		return tex
	return null


func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 2
	add_child(canvas)
	var ui_root := Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.theme = _build_ui_theme()
	canvas.add_child(ui_root)

	var panel := PanelContainer.new()
	top_toolbar_panel = panel
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left = 12
	panel.offset_top = 10
	panel.offset_right = -12
	var background := _ui_stylebox(Color(0.063, 0.098, 0.137, 0.92), Color("294052"), 10, 1, 12, 6)
	background.shadow_color = Color(0, 0, 0, 0.35)
	background.shadow_size = 8
	panel.add_theme_stylebox_override("panel", background)
	ui_root.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	panel.add_child(column)

	# Row 1: Brand + Primary Sim Controls + Live Status Pills
	var toolbar := HFlowContainer.new()
	toolbar.add_theme_constant_override("h_separation", 5)
	toolbar.add_theme_constant_override("v_separation", 4)
	column.add_child(toolbar)

	var title := Label.new()
	title.text = "FACTORY 3D"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color("eef7fa"))
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toolbar.add_child(title)

	sandbox_label = _make_status_pill(toolbar, "Mode: RUN", Color("66e0a3"))
	sandbox_label.add_theme_font_size_override("font_size", 11)
	toolbar.add_child(_make_ui_divider())

	edit_mode_button = Button.new()
	edit_mode_button.text = "Edit"
	edit_mode_button.icon = _make_svg_icon('<path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4Z"/>')
	edit_mode_button.custom_minimum_size = Vector2(64, 26)
	edit_mode_button.add_theme_font_size_override("font_size", 11)
	edit_mode_button.tooltip_text = "Enter Edit Mode"
	edit_mode_button.pressed.connect(_enter_edit_mode)
	toolbar.add_child(edit_mode_button)

	start_button = Button.new()
	start_button.text = ""
	start_button.icon = _make_svg_icon('<polygon points="6 3 20 12 6 21 6 3"/>')
	start_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start_button.custom_minimum_size = Vector2(34, 26)
	start_button.tooltip_text = "Run / Stop simulation"
	_style_accent_button(start_button, "1e6b45", "278758", "3eb87a")
	start_button.pressed.connect(
		func():
			if running:
				_set_running(false)
				if not edit_mode:
					sandbox_label.text = "Mode: STOP"
			else:
				_clear_preview()
				edit_grid.visible = false
				edit_mode = false
				placement = "select"
				if is_instance_valid(edit_tools_row):
					edit_tools_row.visible = false
				if is_instance_valid(edit_mode_button):
					edit_mode_button.remove_theme_stylebox_override("normal")
					edit_mode_button.remove_theme_stylebox_override("hover")
					edit_mode_button.remove_theme_stylebox_override("pressed")
					edit_mode_button.remove_theme_color_override("font_color")
				_set_running(true)
				_update_cabinet_panel_visibility()
				sandbox_label.text = "Mode: RUN",
	)
	toolbar.add_child(start_button)

	var reset_button := Button.new()
	reset_button.text = ""
	reset_button.icon = _make_svg_icon('<path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5"/>')
	reset_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reset_button.custom_minimum_size = Vector2(32, 26)
	reset_button.tooltip_text = "Reset simulation"
	reset_button.pressed.connect(_reset_simulation)
	toolbar.add_child(reset_button)

	toolbar.add_child(_make_ui_divider())

	var new_proj_btn := Button.new()
	new_proj_btn.text = "New"
	new_proj_btn.icon = _make_svg_icon('<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="12" y1="18" x2="12" y2="12"/><line x1="9" y1="15" x2="15" y2="15"/>')
	new_proj_btn.custom_minimum_size = Vector2(62, 26)
	new_proj_btn.add_theme_font_size_override("font_size", 11)
	new_proj_btn.tooltip_text = "Create a new blank factory project"
	new_proj_btn.pressed.connect(_on_new_project_pressed)
	toolbar.add_child(new_proj_btn)

	var open_proj_btn := Button.new()
	open_proj_btn.text = "Open"
	open_proj_btn.icon = _make_svg_icon('<path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/>')
	open_proj_btn.custom_minimum_size = Vector2(68, 26)
	open_proj_btn.add_theme_font_size_override("font_size", 11)
	open_proj_btn.tooltip_text = "Open a saved .pksfac factory project file"
	open_proj_btn.pressed.connect(_on_open_project_pressed)
	toolbar.add_child(open_proj_btn)

	var save_proj_btn := Button.new()
	save_proj_btn.text = "Save"
	save_proj_btn.icon = _make_svg_icon('<path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/>')
	save_proj_btn.custom_minimum_size = Vector2(64, 26)
	save_proj_btn.add_theme_font_size_override("font_size", 11)
	save_proj_btn.tooltip_text = "Save current factory project (.pksfac)"
	save_proj_btn.pressed.connect(_on_save_project_pressed)
	toolbar.add_child(save_proj_btn)

	var save_as_proj_btn := Button.new()
	save_as_proj_btn.text = "Save As"
	save_as_proj_btn.custom_minimum_size = Vector2(68, 26)
	save_as_proj_btn.add_theme_font_size_override("font_size", 11)
	save_as_proj_btn.tooltip_text = "Save factory project to a new .pksfac file"
	save_as_proj_btn.pressed.connect(_on_save_project_as_pressed)
	toolbar.add_child(save_as_proj_btn)

	project_file_label = _make_status_pill(toolbar, "Unsaved", Color("9cb6c9"))
	project_file_label.add_theme_font_size_override("font_size", 11)
	project_file_label.tooltip_text = "Current project file"

	project_file_dialog = FileDialog.new()
	project_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	project_file_dialog.use_native_dialog = true
	project_file_dialog.filters = PackedStringArray(["*.pksfac ; PKS Factory Project"])
	project_file_dialog.file_selected.connect(_on_project_file_selected)
	ui_root.add_child(project_file_dialog)

	new_project_confirm_dialog = ConfirmationDialog.new()
	new_project_confirm_dialog.title = "New Factory Project"
	new_project_confirm_dialog.dialog_text = "Create a new blank project? Unsaved changes to the current sandbox will be lost."
	new_project_confirm_dialog.ok_button_text = "New Project"
	new_project_confirm_dialog.confirmed.connect(_create_new_project)
	ui_root.add_child(new_project_confirm_dialog)

	toolbar.add_child(_make_ui_divider())

	modbus_config_button = Button.new()
	modbus_config_button.text = "Modbus"
	modbus_config_button.icon = _make_svg_icon('<path d="M13 2 3 14h9l-1 8 10-12h-9l1-8z"/>')
	modbus_config_button.custom_minimum_size = Vector2(78, 26)
	modbus_config_button.add_theme_font_size_override("font_size", 11)
	modbus_config_button.tooltip_text = "Configure Modbus TCP server & I/O mapping"
	modbus_config_button.pressed.connect(
		func():
			_set_modbus_dialog_visible(
				not modbus_dialog.visible if is_instance_valid(modbus_dialog) else true
			),
	)
	toolbar.add_child(modbus_config_button)

	ladder_config_button = Button.new()
	ladder_config_button.text = "Ladder"
	ladder_config_button.icon = _make_svg_icon('<path d="M8 3v18M16 3v18M8 8h8M8 13h8M8 18h8"/>')
	ladder_config_button.custom_minimum_size = Vector2(78, 26)
	ladder_config_button.add_theme_font_size_override("font_size", 11)
	ladder_config_button.tooltip_text = "Open IEC 61131-3 Ladder / IL Soft-PLC editor"
	ladder_config_button.pressed.connect(
		func():
			_set_ladder_dialog_visible(
				not ladder_dialog.visible if is_instance_valid(ladder_dialog) else true
			),
	)
	toolbar.add_child(ladder_config_button)

	plc_controller_option = OptionButton.new()
	plc_controller_option.add_item("PLC: OFF", 0)
	plc_controller_option.add_item("PLC: Modbus", 1)
	plc_controller_option.add_item("PLC: Ladder", 2)
	plc_controller_option.custom_minimum_size = Vector2(114, 26)
	plc_controller_option.add_theme_font_size_override("font_size", 11)
	plc_controller_option.tooltip_text = "Select PLC controller mode (OFF / External Modbus / Internal Ladder)"
	plc_controller_option.select(2 if soft_plc.enabled else (1 if ModbusTCP.enabled else 0))
	plc_controller_option.item_selected.connect(
		func(idx: int):
			_set_controller_mode(idx, true),
	)
	toolbar.add_child(plc_controller_option)

	var toolbar_spacer := Control.new()
	toolbar_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toolbar.add_child(toolbar_spacer)

	# Row 2: Placement, Transform, Layout & Workspace Tools (shown only in Edit Mode)
	edit_tools_row = HFlowContainer.new()
	edit_tools_row.add_theme_constant_override("h_separation", 5)
	edit_tools_row.add_theme_constant_override("v_separation", 4)
	edit_tools_row.visible = false
	column.add_child(edit_tools_row)

	var add_object_button := Button.new()
	add_object_button.text = "Add"
	add_object_button.icon = _make_svg_icon('<rect x="3" y="3" width="18" height="18" rx="2"/><path d="M12 8v8"/><path d="M8 12h8"/>')
	add_object_button.custom_minimum_size = Vector2(62, 26)
	add_object_button.add_theme_font_size_override("font_size", 11)
	add_object_button.tooltip_text = "Add Object..."
	_style_accent_button(add_object_button, "1b4f6e", "23668f", "3b8cb8")
	add_object_button.pressed.connect(
		func():
			_set_object_dialog_visible(
				not object_dialog.visible if is_instance_valid(object_dialog) else true
			),
	)
	edit_tools_row.add_child(add_object_button)

	delete_tool_button = Button.new()
	delete_tool_button.text = ""
	delete_tool_button.icon = _make_svg_icon('<path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/>')
	delete_tool_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	delete_tool_button.custom_minimum_size = Vector2(32, 26)
	delete_tool_button.tooltip_text = "Delete selected (Del)"
	delete_tool_button.disabled = true
	_style_accent_button(delete_tool_button, "592428", "783036", "a34850")
	delete_tool_button.pressed.connect(_delete_selected)
	edit_tools_row.add_child(delete_tool_button)

	edit_tools_row.add_child(_make_ui_divider())

	undo_button = Button.new()
	undo_button.text = ""
	undo_button.icon = _make_svg_icon('<path d="M3 7v6h6"/><path d="M21 17a9 9 0 0 0-9-9 9 9 0 0 0-6 2.3L3 13"/>')
	undo_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	undo_button.custom_minimum_size = Vector2(32, 26)
	undo_button.tooltip_text = "Undo last edit (Ctrl+Z)"
	undo_button.disabled = true
	undo_button.pressed.connect(_undo)
	edit_tools_row.add_child(undo_button)

	redo_button = Button.new()
	redo_button.text = ""
	redo_button.icon = _make_svg_icon('<path d="M21 7v6h-6"/><path d="M3 17a9 9 0 0 1 9-9 9 9 0 0 1 6 2.3l3 2.7"/>')
	redo_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	redo_button.custom_minimum_size = Vector2(32, 26)
	redo_button.tooltip_text = "Redo last edit (Ctrl+Y)"
	redo_button.disabled = true
	redo_button.pressed.connect(_redo)
	edit_tools_row.add_child(redo_button)

	edit_tools_row.add_child(_make_ui_divider())

	var save_btn := Button.new()
	save_btn.text = ""
	save_btn.icon = _make_svg_icon('<path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/>')
	save_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	save_btn.custom_minimum_size = Vector2(32, 26)
	save_btn.tooltip_text = "Save layout"
	save_btn.pressed.connect(func(): _save_layout(false))
	edit_tools_row.add_child(save_btn)

	var load_btn := Button.new()
	load_btn.text = ""
	load_btn.icon = _make_svg_icon('<path d="m6 14 1.5-2.9A2 2 0 0 1 9.24 10H20a2 2 0 0 1 1.94 2.5l-1.54 6a2 2 0 0 1-1.95 1.5H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h3.9a2 2 0 0 1 1.69.9l.81 1.2a2 2 0 0 0 1.67.9H18a2 2 0 0 1 2 2v2"/>')
	load_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	load_btn.custom_minimum_size = Vector2(32, 26)
	load_btn.tooltip_text = "Load layout"
	load_btn.pressed.connect(func(): _load_layout(false))
	edit_tools_row.add_child(load_btn)

	edit_tools_row.add_child(_make_ui_divider())

	floor_dialog_button = Button.new()
	floor_dialog_button.text = "%d×%d" % [workspace_width, workspace_depth]
	floor_dialog_button.icon = _make_svg_icon('<rect x="3" y="3" width="18" height="18" rx="2"/><path d="M3 9h18"/><path d="M3 15h18"/><path d="M9 3v18"/><path d="M15 3v18"/>')
	floor_dialog_button.custom_minimum_size = Vector2(72, 26)
	floor_dialog_button.add_theme_font_size_override("font_size", 11)
	floor_dialog_button.tooltip_text = "Configure Workspace Size, Grid & Environment"
	floor_dialog_button.pressed.connect(
		func():
			_set_floor_dialog_visible(
				not floor_dialog.visible if is_instance_valid(floor_dialog) else true
			),
	)
	edit_tools_row.add_child(floor_dialog_button)

	# Bottom-left sound toggle + keyboard shortcut hint pill
	var bottom_left_bar := HBoxContainer.new()
	bottom_left_bar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bottom_left_bar.offset_left = 14
	bottom_left_bar.offset_top = -42
	bottom_left_bar.offset_bottom = -12
	bottom_left_bar.add_theme_constant_override("separation", 8)
	bottom_left_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(bottom_left_bar)

	sound_toggle_button = Button.new()
	sound_toggle_button.text = ""
	sound_toggle_button.icon = _make_svg_icon('<polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><path d="M15.54 8.46a5 5 0 0 1 0 7.07"/><path d="M19.07 4.93a10 10 0 0 1 0 14.14"/>')
	sound_toggle_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sound_toggle_button.custom_minimum_size = Vector2(34, 30)
	sound_toggle_button.tooltip_text = "Mute or unmute factory machine audio"
	_style_accent_button(sound_toggle_button, "1b4f6e", "23668f", "3b8cb8")
	sound_toggle_button.pressed.connect(_toggle_sound)
	bottom_left_bar.add_child(sound_toggle_button)

	status_toggle_button = Button.new()
	status_toggle_button.text = "Status"
	status_toggle_button.icon = _make_svg_icon('<path d="M3 3v18h18"/><path d="M18 17V9"/><path d="M13 17V5"/><path d="M8 17v-3"/>')
	status_toggle_button.custom_minimum_size = Vector2(74, 30)
	status_toggle_button.add_theme_font_size_override("font_size", 11)
	status_toggle_button.tooltip_text = "Show or hide OBJECT STATUS panel"
	_style_accent_button(status_toggle_button, "1b4f6e", "23668f", "3b8cb8")
	status_toggle_button.pressed.connect(_toggle_io_status_panel)
	bottom_left_bar.add_child(status_toggle_button)

	npc_toggle_button = Button.new()
	npc_toggle_button.text = "NPCs"
	npc_toggle_button.icon = _make_svg_icon('<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>')
	npc_toggle_button.custom_minimum_size = Vector2(68, 30)
	npc_toggle_button.add_theme_font_size_override("font_size", 11)
	npc_toggle_button.tooltip_text = "Configure Factory NPCs"
	_style_accent_button(npc_toggle_button, "1b4f6e", "23668f", "3b8cb8")
	npc_toggle_button.pressed.connect(
		func():
			_set_npc_dialog_visible(
				not npc_dialog.visible if is_instance_valid(npc_dialog) else true
			),
	)
	bottom_left_bar.add_child(npc_toggle_button)

	help_button = Button.new()
	help_button.text = "Guide"
	help_button.icon = _make_svg_icon('<circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><line x1="12" y1="17" x2="12.01" y2="17"/>')
	help_button.custom_minimum_size = Vector2(72, 30)
	help_button.add_theme_font_size_override("font_size", 11)
	help_button.tooltip_text = "User Guide & Example Projects (F1)"
	_style_accent_button(help_button, "1b4f6e", "23668f", "3b8cb8")
	help_button.pressed.connect(
		func():
			_set_help_dialog_visible(
				not help_dialog.visible if is_instance_valid(help_dialog) else true
			),
	)
	bottom_left_bar.add_child(help_button)

	var info_pill := PanelContainer.new()
	desktop_info_pill = info_pill
	info_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_pill.add_theme_stylebox_override(
		"panel",
		_ui_stylebox(Color(0.063, 0.098, 0.137, 0.82), Color("233747"), 8, 1, 12, 4),
	)
	bottom_left_bar.add_child(info_pill)

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
	_build_mobile_camera_bar(ui_root)
	_build_cabinet_canvas_layer()
	_sync_2d_cabinet_customization(_get_cabinet_node())
	_build_object_dialog(ui_root)
	_build_floor_dialog(ui_root)
	_build_npc_dialog(ui_root)
	_build_modbus_dialog(ui_root)
	_build_ladder_dialog(ui_root)
	_build_help_dialog(ui_root)


func _build_io_status_panel(ui_root: Control) -> void:
	io_status_panel = PanelContainer.new()
	io_status_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	io_status_panel.offset_left = 14
	io_status_panel.offset_top = 114
	io_status_panel.offset_right = 384
	var style := _ui_stylebox(Color(0.063, 0.098, 0.137, 0.88), Color("294052"), 10, 1, 10, 10)
	io_status_panel.add_theme_stylebox_override("panel", style)
	ui_root.add_child(io_status_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	io_status_panel.add_child(vbox)

	var header := Label.new()
	header.text = "OBJECT STATUS"
	header.add_theme_font_size_override("font_size", 11)
	header.add_theme_color_override("font_color", Color("7ea7c2"))
	vbox.add_child(header)

	var scroll := ScrollContainer.new()
	io_status_scroll = scroll
	scroll.custom_minimum_size = Vector2(356, 460)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	io_status_list = GridContainer.new()
	io_status_list.columns = 4
	io_status_list.add_theme_constant_override("h_separation", 8)
	io_status_list.add_theme_constant_override("v_separation", 4)
	scroll.add_child(io_status_list)
	_refresh_io_status_list()


func _build_mobile_camera_bar(ui_root: Control) -> void:
	mobile_cam_bar = PanelContainer.new()
	mobile_cam_bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	mobile_cam_bar.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	mobile_cam_bar.grow_vertical = Control.GROW_DIRECTION_END
	mobile_cam_bar.offset_top = 114
	mobile_cam_bar.offset_right = -12
	mobile_cam_bar.add_theme_stylebox_override(
		"panel",
		_ui_stylebox(Color(0.063, 0.098, 0.137, 0.88), Color("294052"), 10, 1, 6, 4),
	)
	ui_root.add_child(mobile_cam_bar)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	mobile_cam_bar.add_child(hbox)

	var zoom_out_btn := Button.new()
	zoom_out_btn.text = "-"
	zoom_out_btn.custom_minimum_size = Vector2(36, 32)
	zoom_out_btn.tooltip_text = "Zoom Out"
	zoom_out_btn.pressed.connect(
		func():
			camera_distance = minf(35.0, camera_distance + 2.0)
			_update_camera(),
	)
	hbox.add_child(zoom_out_btn)

	var zoom_in_btn := Button.new()
	zoom_in_btn.text = "+"
	zoom_in_btn.custom_minimum_size = Vector2(36, 32)
	zoom_in_btn.tooltip_text = "Zoom In"
	zoom_in_btn.pressed.connect(
		func():
			camera_distance = maxf(4.5, camera_distance - 2.0)
			_update_camera(),
	)
	hbox.add_child(zoom_in_btn)

	_mobile_cam_view_btn = Button.new()
	_mobile_cam_view_btn.text = "Top"
	_mobile_cam_view_btn.custom_minimum_size = Vector2(36, 32)
	_mobile_cam_view_btn.add_theme_font_size_override("font_size", 11)
	_mobile_cam_view_btn.tooltip_text = "Toggle Top / Isometric View"
	_mobile_cam_view_btn.pressed.connect(
		func():
			_cam_top_view = not _cam_top_view
			camera_pitch = 1.32 if _cam_top_view else 0.447
			_mobile_cam_view_btn.text = "Iso" if _cam_top_view else "Top"
			_update_camera(),
	)
	hbox.add_child(_mobile_cam_view_btn)

	var reset_btn := Button.new()
	reset_btn.text = "R"
	reset_btn.custom_minimum_size = Vector2(36, 32)
	reset_btn.add_theme_font_size_override("font_size", 11)
	reset_btn.tooltip_text = "Reset Camera (R)"
	reset_btn.pressed.connect(_reset_camera)
	hbox.add_child(reset_btn)


func _is_compact_viewport() -> bool:
	var vp := get_viewport().get_visible_rect().size if get_viewport() != null else Vector2(1280, 720)
	return vp.x < 920.0 or vp.y < 520.0


func _is_mobile_web() -> bool:
	return OS.has_feature("web") and (DisplayServer.is_touchscreen_available() or _is_touch_device or _is_compact_viewport())


func _fit_centered_dialog(dialog: PanelContainer, ideal_w: float, ideal_h: float) -> void:
	if not is_instance_valid(dialog) or get_viewport() == null:
		return
	var vp := get_viewport().get_visible_rect().size
	var w := clampf(ideal_w, 260.0, maxf(260.0, vp.x - 24.0))
	var h := clampf(ideal_h, 220.0, maxf(220.0, vp.y - 24.0)) if ideal_h > 0.0 else 0.0
	dialog.custom_minimum_size = Vector2(w, h)
	dialog.offset_left = -w * 0.5
	dialog.offset_right = w * 0.5
	if h > 0.0:
		dialog.offset_top = -h * 0.5
		dialog.offset_bottom = h * 0.5


func _update_camera_for_viewport() -> void:
	if not is_instance_valid(camera) or get_viewport() == null:
		return
	var vp := get_viewport().get_visible_rect().size
	camera.fov = 56.0 if vp.x < vp.y else 45.0


func _on_viewport_resized() -> void:
	if get_viewport() == null:
		return
	var vp := get_viewport().get_visible_rect().size
	var compact := _is_compact_viewport()
	_update_camera_for_viewport()
	if is_instance_valid(desktop_info_pill):
		desktop_info_pill.visible = not compact and not _is_touch_device
	var top_y := (top_toolbar_panel.offset_top + top_toolbar_panel.size.y + 8.0) if is_instance_valid(top_toolbar_panel) else 114.0
	if is_instance_valid(mobile_cam_bar):
		mobile_cam_bar.offset_top = maxf(64.0, top_y)
		mobile_cam_bar.offset_right = -12.0
		mobile_cam_bar.visible = compact or _is_touch_device or OS.has_feature("web")
	if is_instance_valid(io_status_panel):
		var io_w := clampf(370.0, 240.0, maxf(240.0, vp.x - 28.0))
		io_status_panel.offset_left = 12.0
		io_status_panel.offset_top = maxf(64.0, top_y)
		io_status_panel.offset_right = 12.0 + io_w
		if is_instance_valid(io_status_scroll):
			var max_h := clampf(vp.y - io_status_panel.offset_top - 86.0, 140.0, 460.0)
			io_status_scroll.custom_minimum_size = Vector2(maxf(200.0, io_w - 22.0), max_h)
	_fit_centered_dialog(help_dialog, 720.0, 560.0)
	_fit_centered_dialog(object_dialog, 640.0, 560.0)
	_fit_centered_dialog(ladder_dialog, 680.0, 500.0)
	_fit_centered_dialog(modbus_dialog, 560.0, 460.0)
	_fit_centered_dialog(floor_dialog, 420.0, 0.0)
	_fit_centered_dialog(npc_dialog, 440.0, 0.0)
	_fit_transform_panel()
	_fit_force_panel()
	_update_cabinet_panel_visibility()


func _toggle_io_status_panel() -> void:
	if not is_instance_valid(io_status_panel):
		return
	io_status_panel.visible = not io_status_panel.visible
	if is_instance_valid(status_toggle_button):
		status_toggle_button.text = "Status"
		if io_status_panel.visible:
			_style_accent_button(status_toggle_button, "1b4f6e", "23668f", "3b8cb8")
		else:
			status_toggle_button.remove_theme_stylebox_override("normal")
			status_toggle_button.remove_theme_stylebox_override("hover")
			status_toggle_button.remove_theme_stylebox_override("pressed")
			status_toggle_button.remove_theme_color_override("font_color")
	if io_status_panel.visible:
		_refresh_io_status_list()
	_save_settings()


func _set_label_if_changed(lbl: Label, txt: String, col: Color = Color.TRANSPARENT) -> void:
	if not is_instance_valid(lbl):
		return
	if lbl.text != txt:
		lbl.text = txt
	if col != Color.TRANSPARENT:
		if not lbl.has_meta("_last_font_col") or (lbl.get_meta("_last_font_col") as Color) != col:
			lbl.set_meta("_last_font_col", col)
			lbl.add_theme_color_override("font_color", col)


func _apply_status_btn_style(btn: Button, io_col: Color, is_selected: bool) -> void:
	var style_key := "%s|%s" % [io_col.to_html(false), "1" if is_selected else "0"]
	if str(btn.get_meta("_last_style_key", "")) == style_key:
		return
	btn.set_meta("_last_style_key", style_key)
	var cached = _status_style_cache.get(style_key)
	if cached == null:
		if is_selected:
			var hi_col := Color("ffe066")
			cached = {
				"normal": _ui_stylebox(Color(hi_col.r, hi_col.g, hi_col.b, 0.28), hi_col, 5, 2, 8, 3),
				"hover": _ui_stylebox(Color(hi_col.r, hi_col.g, hi_col.b, 0.38), hi_col, 5, 2, 8, 3),
				"font": Color("ffffff"),
			}
		else:
			cached = {
				"normal": _ui_stylebox(
					Color(io_col.r, io_col.g, io_col.b, 0.14),
					Color(io_col.r, io_col.g, io_col.b, 0.55),
					5,
					1,
					8,
					3,
				),
				"hover": _ui_stylebox(Color(io_col.r, io_col.g, io_col.b, 0.28), io_col, 5, 1, 8, 3),
				"font": io_col.lightened(0.25),
			}
		_status_style_cache[style_key] = cached
	btn.add_theme_stylebox_override("normal", cached["normal"])
	btn.add_theme_stylebox_override("hover", cached["hover"])
	btn.add_theme_color_override("font_color", cached["font"])


func _apply_npcs_enabled(enabled: bool) -> void:
	npcs_enabled = enabled
	_apply_npc_settings()


func _apply_npc_settings() -> void:
	for npc in get_tree().get_nodes_in_group("factory_npcs"):
		if not is_instance_valid(npc) or not (npc is Node3D):
			continue
		var individual := true
		if npc.name == "OperatorNPC":
			individual = npc_operator_enabled
		elif npc.name == "TesterNPC":
			individual = npc_tester_enabled
		elif npc.name == "SafetyNPC":
			individual = npc_safety_enabled
		elif npc.name == "MaintenanceNPC":
			individual = npc_maintenance_enabled
		elif npc.name == "QCNPC":
			individual = npc_qc_enabled
		var active := npcs_enabled and individual
		(npc as Node3D).visible = active
		npc.set_physics_process(active)
		npc.set("walk_speed", npc_walk_speed)
		npc.set("inspect_duration", npc_inspect_duration)
		npc.set("chat_enabled", npc_chat_enabled)
		npc.set("sound_enabled", npc_sound_enabled)
	if is_instance_valid(npc_toggle_button):
		var any_on := npcs_enabled and (npc_operator_enabled or npc_tester_enabled or npc_safety_enabled or npc_maintenance_enabled or npc_qc_enabled)
		npc_toggle_button.text = "NPCs"
		if any_on:
			_style_accent_button(npc_toggle_button, "1b4f6e", "23668f", "3b8cb8")
		else:
			npc_toggle_button.remove_theme_stylebox_override("normal")
			npc_toggle_button.remove_theme_stylebox_override("hover")
			npc_toggle_button.remove_theme_stylebox_override("pressed")
			npc_toggle_button.remove_theme_color_override("font_color")


func _reset_npc_positions() -> void:
	var spawn_map := {
		"OperatorNPC": Vector3(-2.0, 0.0, 2.2),
		"TesterNPC": Vector3(6.5, 0.0, -2.5),
		"SafetyNPC": Vector3(-6.0, 0.0, -3.0),
		"MaintenanceNPC": Vector3(2.5, 0.0, 6.0),
		"QCNPC": Vector3(8.0, 0.0, 2.0),
	}
	for npc in get_tree().get_nodes_in_group("factory_npcs"):
		if is_instance_valid(npc) and npc is Node3D and spawn_map.has(npc.name):
			(npc as Node3D).position = spawn_map[npc.name]
			if "_waypoints" in npc:
				npc.set("_waypoints", [])
				npc.set("_waypoint_idx", 0)
				npc.set("_inspecting", false)
				npc.set("_chatting", false)
	sandbox_label.text = "NPC positions reset"


func _apply_sound_enabled(enabled: bool) -> void:
	sound_enabled = enabled
	var fa := get_node_or_null("/root/FactoryAudio")
	if fa != null:
		fa.call("set_sound_enabled", sound_enabled)
	if is_instance_valid(sound_toggle_button):
		sound_toggle_button.text = ""
		sound_toggle_button.icon = _make_svg_icon(
			'<polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><path d="M15.54 8.46a5 5 0 0 1 0 7.07"/><path d="M19.07 4.93a10 10 0 0 1 0 14.14"/>' if sound_enabled else '<polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><line x1="22" x2="16" y1="9" y2="15"/><line x1="16" x2="22" y1="9" y2="15"/>'
		)
		if sound_enabled:
			_style_accent_button(sound_toggle_button, "1b4f6e", "23668f", "3b8cb8")
		else:
			sound_toggle_button.remove_theme_stylebox_override("normal")
			sound_toggle_button.remove_theme_stylebox_override("hover")
			sound_toggle_button.remove_theme_stylebox_override("pressed")
			sound_toggle_button.remove_theme_color_override("font_color")


func _toggle_sound() -> void:
	_apply_sound_enabled(not sound_enabled)
	if sound_enabled:
		var fa := get_node_or_null("/root/FactoryAudio")
		if fa != null:
			fa.call("play_ui_confirm")
	_save_settings()


func _get_cabinet_node() -> Node3D:
	return get_node_or_null("ControlCabinet") as Node3D

func _get_active_cabinet_node() -> Node3D:
	if is_instance_valid(selected_object) and str(selected_object.get_meta("kind", "")) == "cabinet":
		return selected_object
	var main_cab := _get_cabinet_node()
	if is_instance_valid(main_cab):
		return main_cab
	for obj in get_tree().get_nodes_in_group("sandbox_objects"):
		if str(obj.get_meta("kind", "")) == "cabinet":
			return obj as Node3D
	return null

func _sync_2d_cabinet_customization(cabinet_node: Node3D) -> void:
	if not is_instance_valid(cabinet_node) or not is_instance_valid(cabinet_layer):
		return
	var c3d := cabinet_layer.get("cabinet_3d") as Node3D
	if is_instance_valid(c3d) and cabinet_node.has_method("get_customization") and c3d.has_method("apply_customization"):
		c3d.call("apply_customization", cabinet_node.call("get_customization"))

func _selected_cabinet_slot_kind_str() -> String:
	if not is_instance_valid(cabinet_slot_kind):
		return "lamp"
	match cabinet_slot_kind.selected:
		1:
			return "push_button"
		2:
			return "switch_select"
		3:
			return "switch_3pos"
		4:
			return "potentiometer"
		5:
			return "dpm"
		_:
			return "lamp"

func _on_cabinet_grid_cell_pressed(col: int, row: int) -> void:
	if cabinet_slot_move_mode and is_instance_valid(selected_object) and str(selected_object.get_meta("kind", "")) == "cabinet":
		cabinet_slot_move_mode = false
		if _get_builtin_slot_label(selected_object, col, row).is_empty():
			var pre_move := _build_layout_data()
			if bool(selected_object.call("move_slot_module", cabinet_selected_col, cabinet_selected_row, col, row)):
				_record_undo_snapshot(pre_move)
				cabinet_selected_col = col
				cabinet_selected_row = row
				_sync_2d_cabinet_customization(selected_object)
				_save_settings()
		_refresh_cabinet_slot_grid()
		return
	cabinet_selected_col = col
	cabinet_selected_row = row
	if is_instance_valid(selected_object) and str(selected_object.get_meta("kind", "")) == "cabinet":
		var dyn_slots: Array = selected_object.get("dynamic_slots") if "dynamic_slots" in selected_object else []
		for item in dyn_slots:
			if item is Dictionary and int(item.get("col", -1)) == col and int(item.get("row", -1)) == row:
				var k := str(item.get("kind", "lamp"))
				if is_instance_valid(cabinet_slot_kind):
					if k in ["push_button", "button"]:
						cabinet_slot_kind.select(1)
					elif k == "switch_select":
						cabinet_slot_kind.select(2)
					elif k == "switch_3pos":
						cabinet_slot_kind.select(3)
					elif k == "potentiometer":
						cabinet_slot_kind.select(4)
					elif k == "dpm":
						cabinet_slot_kind.select(5)
					else:
						cabinet_slot_kind.select(0)
				if is_instance_valid(cabinet_slot_color):
					var raw_c = item.get("color", Color("18d97c"))
					cabinet_slot_color.color = raw_c if raw_c is Color else Color(str(raw_c))
				if is_instance_valid(cabinet_slot_label):
					cabinet_slot_label.text = str(item.get("label", "AUX1"))
				if is_instance_valid(cabinet_dpm_unit):
					cabinet_dpm_unit.text = str(item.get("unit", ""))
				if is_instance_valid(cabinet_dpm_decimals):
					cabinet_dpm_decimals.select(clampi(int(item.get("decimals", 0)), 0, 2))
				break
	_refresh_transform_controls()

func _on_live_edit_cabinet_slot() -> void:
	if not is_instance_valid(selected_object) or str(selected_object.get_meta("kind", "")) != "cabinet":
		return
	var props := {
		"kind": _selected_cabinet_slot_kind_str(),
		"color": cabinet_slot_color.color if is_instance_valid(cabinet_slot_color) else Color("18d97c"),
		"label": cabinet_slot_label.text.strip_edges() if is_instance_valid(cabinet_slot_label) else "MOD",
	}
	if str(props["kind"]) == "dpm":
		props["unit"] = cabinet_dpm_unit.text.strip_edges() if is_instance_valid(cabinet_dpm_unit) else ""
		props["decimals"] = clampi(cabinet_dpm_decimals.selected, 0, 2) if is_instance_valid(cabinet_dpm_decimals) else 0
		props["signed"] = true
	if bool(selected_object.call("update_slot_module", cabinet_selected_col, cabinet_selected_row, props)):
		_sync_2d_cabinet_customization(selected_object)
		_refresh_transform_controls()
		_save_settings()
	else:
		_refresh_transform_controls()

func _get_builtin_slot_label(cab: Node3D, col: int, row: int) -> String:
	if not bool(cab.get("show_builtin_items")):
		return ""
	if row == 1:
		if col == 0:
			return str(cab.get("lamp_green_label")).substr(0, 5)
		if col == 1 and bool(cab.get("show_yellow_lamp")):
			return str(cab.get("lamp_yellow_label")).substr(0, 5)
		if col == 2:
			return str(cab.get("lamp_red_label")).substr(0, 5)
	if row == 2:
		if col == 0:
			return str(cab.get("btn_start_label")).substr(0, 5)
		if col == 1:
			return str(cab.get("btn_stop_label")).substr(0, 5)
		if col == 2 and bool(cab.get("show_rev_btn")):
			return str(cab.get("btn01_label")).substr(0, 5)
	if row == 3:
		if col == 0:
			return str(cab.get("switch_auto_label")).substr(0, 5)
		if col == 2:
			return str(cab.get("switch_estop_label")).substr(0, 5)
	return ""

func _refresh_cabinet_slot_grid() -> void:
	if cabinet_slot_buttons.size() != 15:
		return
	if not is_instance_valid(selected_object) or str(selected_object.get_meta("kind", "")) != "cabinet":
		return
	var dyn_slots: Array = selected_object.get("dynamic_slots") if "dynamic_slots" in selected_object else []
	var dyn_map := {}
	for item in dyn_slots:
		if item is Dictionary:
			dyn_map["%d_%d" % [int(item.get("col", 0)), int(item.get("row", 0))]] = item
	for r_i in range(5):
		for c_i in range(3):
			var btn := cabinet_slot_buttons[r_i * 3 + c_i]
			var key := "%d_%d" % [c_i, r_i]
			var builtin := _get_builtin_slot_label(selected_object, c_i, r_i)
			var is_sel := (c_i == cabinet_selected_col and r_i == cabinet_selected_row)
			if not builtin.is_empty():
				btn.text = builtin
				btn.disabled = true
				btn.modulate = Color(0.65, 0.7, 0.78, 0.75)
			elif dyn_map.has(key):
				var mod: Dictionary = dyn_map[key]
				var mkind := str(mod.get("kind", ""))
				var icon := "[B]" if mkind in ["push_button", "button"] else ("[S]" if mkind == "switch_select" else ("[3]" if mkind == "switch_3pos" else ("[P]" if mkind == "potentiometer" else ("[M]" if mkind == "dpm" else "[L]"))))
				var lbl := str(mod.get("label", "MOD")).substr(0, 5)
				btn.text = ("[%s %s]" % [icon, lbl]) if is_sel else ("%s %s" % [icon, lbl])
				btn.disabled = false
				btn.modulate = Color(0.75, 0.92, 1.0, 1.0) if is_sel else Color.WHITE
			else:
				btn.text = "[ + ]" if is_sel else "+"
				btn.disabled = false
				btn.modulate = Color(0.75, 0.92, 1.0, 1.0) if is_sel else Color(0.85, 0.88, 0.92, 0.85)
	var sel_key := "%d_%d" % [cabinet_selected_col, cabinet_selected_row]
	var has_dyn_selected := dyn_map.has(sel_key)
	if is_instance_valid(cabinet_slot_move_btn):
		cabinet_slot_move_btn.disabled = (not has_dyn_selected) and (not cabinet_slot_move_mode)
		cabinet_slot_move_btn.text = "Cancel" if cabinet_slot_move_mode else "Move"
		if cabinet_slot_move_mode:
			_style_accent_button(cabinet_slot_move_btn, "1b4f6e", "23668f", "3b8cb8")
		else:
			cabinet_slot_move_btn.remove_theme_stylebox_override("normal")
			cabinet_slot_move_btn.remove_theme_stylebox_override("hover")
			cabinet_slot_move_btn.remove_theme_stylebox_override("pressed")
			cabinet_slot_move_btn.remove_theme_color_override("font_color")
	_refresh_cabinet_slot_io_preview()

func _on_toggle_cabinet_slot_move() -> void:
	cabinet_slot_move_mode = not cabinet_slot_move_mode
	_refresh_cabinet_slot_grid()

func _get_selected_cabinet_slot_item() -> Dictionary:
	if not is_instance_valid(selected_object) or str(selected_object.get_meta("kind", "")) != "cabinet":
		return {}
	var dyn_slots: Array = selected_object.get("dynamic_slots") if "dynamic_slots" in selected_object else []
	for item in dyn_slots:
		if item is Dictionary and int(item.get("col", -1)) == cabinet_selected_col and int(item.get("row", -1)) == cabinet_selected_row:
			return item
	return {}


func _cabinet_slot_modbus_key(mkind: String) -> String:
	if mkind == "potentiometer":
		return "modbus_input_reg"
	if mkind == "dpm":
		return "modbus_holding_reg"
	if mkind in ["push_button", "button", "switch_select", "switch_3pos"]:
		return "modbus_input"
	return "modbus_coil"


func _refresh_cabinet_slot_io_preview() -> void:
	if not is_instance_valid(cabinet_slot_io_label):
		return
	if not is_instance_valid(selected_object) or str(selected_object.get_meta("kind", "")) != "cabinet":
		return
	if cabinet_slot_move_mode:
		cabinet_slot_io_label.text = "Move (%d,%d) -> Click target slot" % [cabinet_selected_col, cabinet_selected_row]
		return
	var slot_item := _get_selected_cabinet_slot_item()
	var addr_str := "Unassigned"
	if not slot_item.is_empty():
		var mkind := str(slot_item.get("kind", "lamp"))
		if mkind == "potentiometer":
			var ir_addr := int(slot_item.get("modbus_input_reg", -1))
			if ir_addr >= 0:
				addr_str = _format_word_address(ir_addr, "IW")
		elif mkind == "dpm":
			var hr_addr := int(slot_item.get("modbus_holding_reg", -1))
			if hr_addr >= 0:
				addr_str = _format_word_address(hr_addr, "QW")
		elif mkind == "switch_3pos":
			var base_in := int(slot_item.get("modbus_input", -1))
			if base_in >= 0:
				addr_str = "%s / %s" % [_format_iec_address(base_in, "IX"), _format_iec_address(base_in + 1, "IX")]
		elif mkind in ["push_button", "button", "switch_select"]:
			var in_addr := int(slot_item.get("modbus_input", -1))
			if in_addr >= 0:
				addr_str = _format_iec_address(in_addr, "IX")
		else:
			var c_addr := int(slot_item.get("modbus_coil", -1))
			if c_addr >= 0:
				addr_str = _format_iec_address(c_addr, "QX")
	var state_tag := "(%s)" % str(slot_item.get("label", "Placed")) if not slot_item.is_empty() else "(Empty)"
	var slot_txt := "Slot (%d,%d) %s -> %s" % [cabinet_selected_col, cabinet_selected_row, state_tag, addr_str]
	cabinet_slot_io_label.text = slot_txt
	if is_instance_valid(modbus_slot_io_label):
		modbus_slot_io_label.text = slot_txt

func _on_apply_cabinet_slot() -> void:
	if not is_instance_valid(selected_object) or str(selected_object.get_meta("kind", "")) != "cabinet":
		return
	if not _get_builtin_slot_label(selected_object, cabinet_selected_col, cabinet_selected_row).is_empty():
		return
	var col := cabinet_selected_col
	var row := cabinet_selected_row
	cabinet_slot_move_mode = false
	_record_undo_snapshot()
	var kind := _selected_cabinet_slot_kind_str()
	var color: Color = cabinet_slot_color.color if is_instance_valid(cabinet_slot_color) else Color("18d97c")
	var lbl := cabinet_slot_label.text.strip_edges()
	if lbl.is_empty():
		lbl = "BTN" if kind == "push_button" else ("SW" if kind == "switch_select" else ("SW3" if kind == "switch_3pos" else ("VR1" if kind == "potentiometer" else ("DPM1" if kind == "dpm" else "LAMP"))))
	selected_object.call("set_slot_module", col, row, kind, lbl, color)
	if kind == "dpm":
		selected_object.call("update_slot_module", col, row, {
			"kind": "dpm",
			"label": lbl,
			"color": color,
			"unit": cabinet_dpm_unit.text.strip_edges() if is_instance_valid(cabinet_dpm_unit) else "",
			"decimals": clampi(cabinet_dpm_decimals.selected, 0, 2) if is_instance_valid(cabinet_dpm_decimals) else 0,
			"signed": true,
		})
	_sync_2d_cabinet_customization(selected_object)
	_refresh_transform_controls()
	_save_settings()

func _on_clear_cabinet_slot() -> void:
	if not is_instance_valid(selected_object) or str(selected_object.get_meta("kind", "")) != "cabinet":
		return
	_record_undo_snapshot()
	selected_object.call("clear_slot", cabinet_selected_col, cabinet_selected_row)
	_sync_2d_cabinet_customization(selected_object)
	_refresh_transform_controls()
	_save_settings()

func _on_clear_all_cabinet_slots() -> void:
	if not is_instance_valid(selected_object) or str(selected_object.get_meta("kind", "")) != "cabinet":
		return
	_record_undo_snapshot()
	selected_object.call("clear_all_dynamic_slots")
	_sync_2d_cabinet_customization(selected_object)
	_refresh_transform_controls()
	_save_settings()


func _build_cabinet_canvas_layer() -> void:
	var packed := load("res://objects/control_cabinet_2d.tscn") as PackedScene
	cabinet_layer = packed.instantiate() as CanvasLayer
	cabinet_layer.name = "ControlCabinetLayer"
	add_child(cabinet_layer)
	cabinet_panel = cabinet_layer.get_node("CabinetPanel") as PanelContainer
	cabinet_layer.connect(
		"start_triggered",
		func():
			if not plc_mode and not bool(cabinet_layer.get("estop_active")):
				_set_running(true)
				if not edit_mode:
					sandbox_label.text = "Mode: RUN",
	)
	cabinet_layer.connect(
		"stop_triggered",
		func():
			if not plc_mode:
				_set_running(false)
				if not edit_mode:
					sandbox_label.text = "Mode: STOP",
	)
	cabinet_layer.connect(
		"estop_toggled",
		func(is_estop: bool):
			var cab := _get_active_cabinet_node()
			if is_instance_valid(cab):
				cab.set("estop_active", is_estop)
				cab.call("_update_estop")
				cab.call("_update_lights")
			if not plc_mode and is_estop:
				_set_running(false)
				if not edit_mode:
					sandbox_label.text = "Mode: E-STOP"
			_refresh_cabinet_hud(),
	)
	cabinet_layer.connect(
		"mode_toggled",
		func():
			var cab := _get_active_cabinet_node()
			if is_instance_valid(cab):
				cab.set("selector_auto", bool(cabinet_layer.get("switch_auto_active")))
				cab.call("_update_selector"),
	)
	cabinet_layer.connect(
		"dynamic_button_changed",
		func(io_id: String, is_active: bool):
			var cab := _get_active_cabinet_node()
			if is_instance_valid(cab) and "dynamic_button_states" in cab:
				var st: Dictionary = cab.get("dynamic_button_states")
				st[io_id] = is_active,
	)
	cabinet_layer.connect(
		"dynamic_switch_changed",
		func(io_id: String, is_active: bool):
			var cab := _get_active_cabinet_node()
			if is_instance_valid(cab) and "dynamic_button_states" in cab:
				var st: Dictionary = cab.get("dynamic_button_states")
				st[io_id] = is_active
				cab.call("_apply_dynamic_item_visual", io_id, is_active),
	)
	cabinet_layer.connect(
		"dynamic_switch_3pos_changed",
		func(io_id: String, pos: int):
			var cab := _get_active_cabinet_node()
			if is_instance_valid(cab) and cab.has_method("set_dynamic_switch_3pos"):
				cab.call("set_dynamic_switch_3pos", io_id, pos),
	)
	cabinet_layer.connect(
		"dynamic_pot_changed",
		func(io_id: String, val: float):
			var cab := _get_active_cabinet_node()
			if is_instance_valid(cab) and cab.has_method("set_dynamic_pot"):
				cab.call("set_dynamic_pot", io_id, val),
	)
	_update_cabinet_panel_visibility()


func _update_cabinet_panel_visibility() -> void:
	if not is_instance_valid(cabinet_panel):
		return
	var has_selected_cabinet := (
		is_instance_valid(selected_object)
		and str(selected_object.get_meta("kind", "")) == "cabinet"
	)
	cabinet_panel.visible = has_selected_cabinet
	if cabinet_panel.visible:
		var vp_w := get_viewport().get_visible_rect().size.x if get_viewport() != null else 1280.0
		if edit_mode and vp_w >= 560.0:
			cabinet_panel.offset_left = -536
			cabinet_panel.offset_right = -400
		elif edit_mode:
			cabinet_panel.offset_left = maxf(-vp_w + 12.0, -320.0)
			cabinet_panel.offset_right = cabinet_panel.offset_left + 136.0
		else:
			cabinet_panel.offset_left = -240
			cabinet_panel.offset_right = -16
		_sync_2d_cabinet_customization(selected_object)
		_refresh_cabinet_hud()


func _refresh_cabinet_hud() -> void:
	if (
		not is_instance_valid(cabinet_layer)
		or not is_instance_valid(cabinet_panel) or not cabinet_panel.visible
	):
		return
	var spd := float(conveyor.get("speed")) if is_instance_valid(conveyor) and "speed" in conveyor else BELT_SPEED
	var hr0 := ModbusTCP.get_holding_register(0)
	var cab := _get_active_cabinet_node()
	if is_instance_valid(cab):
		var c3d := cabinet_layer.get("cabinet_3d") as Node3D
		if is_instance_valid(c3d) and "forced_items" in cab:
			var cab_forced: Dictionary = cab.get("forced_items")
			if c3d.get("forced_items") != cab_forced:
				c3d.set("forced_items", cab_forced.duplicate())
				c3d.call("_update_lights")
		if not plc_mode:
			if bool(cab.get("active")) != running:
				cab.set("active", running)
			cabinet_layer.set("lamp_green_on", running)
			cabinet_layer.set("lamp_red_on", bool(cab.get("estop_active")))
		var dyn_slots: Array = cab.get("dynamic_slots") if "dynamic_slots" in cab else []
		for slot_item in dyn_slots:
			if slot_item is Dictionary and str(slot_item.get("kind", "")) == "lamp":
				var slot_io := str(slot_item.get("io_id", ""))
				var slot_c := int(slot_item.get("modbus_coil", -1))
				var lit := ModbusTCP.get_coil(slot_c) if slot_c >= 0 else false
				if is_instance_valid(c3d):
					c3d.call("set_dynamic_lamp", slot_io, lit)
	cabinet_layer.call("update_display", running, plc_mode, detected_count, spd, hr0, false)


func _object_io_color(obj: Node3D) -> Color:
	var has_c := (
		int(obj.get_meta("modbus_coil", -1)) >= 0
		or int(obj.get_meta("modbus_holding_reg", -1)) >= 0
	)
	var has_i := (
		int(obj.get_meta("modbus_input", -1)) >= 0 or int(obj.get_meta("modbus_input_reg", -1)) >= 0
	)
	if has_c and has_i:
		return Color("f08a4b") # Coil + Input (Hybrid)
	if has_c:
		return Color("4fd18b") # Coil (DO / %QX)
	if has_i:
		return Color("f0c44d") # Discrete Input (DI / %IX)
	var kind := str(obj.get_meta("kind", ""))
	if kind in ["sensor", "vision_sensor", "rgb_sensor", "light_curtain"]:
		return Color("8b7d4b") # Unassigned Input
	if kind in [
		"conveyor",
		"conveyor_short",
		"turn",
		"pusher",
		"stopper",
		"emitter",
		"remover",
		"stack_light",
		"motor_fan",
		"pump",
		"water_tank",
		"solenoid_valve",
		"reject_bin",
	]:
		return Color("4b7a8c") # Unassigned Coil/Actuator
	return Color("8aa0b0")


func _get_cabinet_io_active(io_id: String) -> bool:
	if not is_instance_valid(cabinet_layer):
		return false
	match io_id:
		"BtnStart":
			return bool(cabinet_layer.get("start_active"))
		"BtnStop":
			return bool(cabinet_layer.get("stop_active"))
		"Btn01":
			return bool(cabinet_layer.get("reverse_active"))
		"SwitchAuto":
			return bool(cabinet_layer.get("switch_auto_active"))
		"SwitchEStop":
			return bool(cabinet_layer.get("estop_active"))
		"LampGreen":
			return bool(cabinet_layer.get("lamp_green_on"))
		"LampRed":
			return bool(cabinet_layer.get("lamp_red_on"))
	return false


func _collect_cabinet_status_items(cab: Node3D) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	var c_addr := int(cab.get_meta("modbus_coil", -1))
	var i_addr := int(cab.get_meta("modbus_input", -1))
	var forced_map: Dictionary = cab.get("forced_items") if "forced_items" in cab else {}
	if bool(cab.get("show_builtin_items")):
		items.append({
			"key": "start",
			"label": "[B] " + str(cab.get("btn_start_label")),
			"dir": "input",
			"addr": i_addr + 0 if i_addr >= 0 else -1,
			"active": bool(cab.get("start_pressed")),
			"forced": false,
		})
		items.append({
			"key": "stop",
			"label": "[B] " + str(cab.get("btn_stop_label")),
			"dir": "input",
			"addr": i_addr + 1 if i_addr >= 0 else -1,
			"active": bool(cab.get("stop_pressed")),
			"forced": false,
		})
		if bool(cab.get("show_rev_btn")):
			items.append({
				"key": "rev",
				"label": "[B] " + str(cab.get("btn01_label")),
				"dir": "input",
				"addr": - 1,
				"active": bool(cab.get("reverse_pressed")),
				"forced": false,
			})
		items.append({
			"key": "auto",
			"label": "[S] " + str(cab.get("switch_auto_label")),
			"dir": "input",
			"addr": - 1,
			"active": bool(cab.get("selector_auto")),
			"forced": false,
		})
		items.append({
			"key": "estop",
			"label": "[S] " + str(cab.get("switch_estop_label")),
			"dir": "input",
			"addr": i_addr + 2 if i_addr >= 0 else -1,
			"active": bool(cab.get("estop_active")),
			"forced": false,
		})
		var g_forced := forced_map.has("lamp_g")
		items.append({
			"key": "lamp_g",
			"label": "[L] " + str(cab.get("lamp_green_label")),
			"dir": "coil",
			"addr": c_addr + 0 if c_addr >= 0 else -1,
			"active": bool(forced_map["lamp_g"]) if g_forced else (bool(cab.get("lamp_green_on")) or bool(cab.get("active"))),
			"forced": g_forced,
		})
		if bool(cab.get("show_yellow_lamp")):
			var y_forced := forced_map.has("lamp_y")
			items.append({
				"key": "lamp_y",
				"label": "[L] " + str(cab.get("lamp_yellow_label")),
				"dir": "coil",
				"addr": c_addr + 1 if c_addr >= 0 else -1,
				"active": bool(forced_map["lamp_y"]) if y_forced else bool(cab.get("lamp_yellow_on")),
				"forced": y_forced,
			})
		var r_forced := forced_map.has("lamp_r")
		items.append({
			"key": "lamp_r",
			"label": "[L] " + str(cab.get("lamp_red_label")),
			"dir": "coil",
			"addr": c_addr + 2 if c_addr >= 0 else -1,
			"active": bool(forced_map["lamp_r"]) if r_forced else bool(cab.get("lamp_red_on")),
			"forced": r_forced,
		})
	var dyn_slots: Array = cab.get("dynamic_slots") if "dynamic_slots" in cab else []
	var dyn_btn_states: Dictionary = cab.get("dynamic_button_states") if "dynamic_button_states" in cab else {}
	var dyn_pot_values: Dictionary = cab.get("dynamic_pot_values") if "dynamic_pot_values" in cab else {}
	for slot_item in dyn_slots:
		if not (slot_item is Dictionary):
			continue
		var mkind := str(slot_item.get("kind", "lamp"))
		var io_id := str(slot_item.get("io_id", ""))
		var lbl := str(slot_item.get("label", "MOD"))
		if mkind == "potentiometer":
			var p_val := clampf(float(dyn_pot_values.get(io_id, slot_item.get("value", 0.0))), 0.0, 1.0)
			var cur_ir := int(slot_item.get("modbus_input_reg", -1))
			items.append({
				"key": "dyn_" + io_id,
				"label": "[P] " + lbl,
				"kind": mkind,
				"dir": "input_reg",
				"addr": cur_ir,
				"addr_text": _format_word_address(cur_ir, "IW") if cur_ir >= 0 else "-",
				"status_text": "%d%% (%.1fV)" % [roundi(p_val * 100.0), p_val * 10.0],
				"active": p_val > 0.0,
				"forced": false,
			})
		elif mkind == "dpm":
			var raw_v := int(slot_item.get("raw_value", 0))
			var signed_v := raw_v - 65536 if (bool(slot_item.get("signed", true)) and raw_v >= 32768) else raw_v
			var dec := clampi(int(slot_item.get("decimals", 0)), 0, 2)
			var disp := ("%d" % signed_v) if dec <= 0 else (("%." + str(dec) + "f") % (float(signed_v) / pow(10.0, float(dec))))
			var u := str(slot_item.get("unit", "")).strip_edges()
			if not u.is_empty():
				disp += " " + u
			var cur_hr := int(slot_item.get("modbus_holding_reg", -1))
			items.append({
				"key": "dyn_" + io_id,
				"label": "[M] " + lbl,
				"kind": mkind,
				"dir": "holding_reg",
				"addr": cur_hr,
				"addr_text": _format_word_address(cur_hr, "QW") if cur_hr >= 0 else "-",
				"status_text": disp,
				"active": signed_v != 0,
				"forced": false,
			})
		elif mkind == "switch_3pos":
			var pos := int(dyn_btn_states.get(io_id, 1))
			var pos_names := ["LEFT", "CENTER", "RIGHT"]
			var cur_in := int(slot_item.get("modbus_input", -1))
			var addr_txt := "-"
			if cur_in >= 0:
				addr_txt = "%s/%s" % [_format_iec_address(cur_in, "IX"), _format_iec_address(cur_in + 1, "IX")]
			items.append({
				"key": "dyn_" + io_id,
				"label": "[3] " + lbl,
				"kind": mkind,
				"dir": "input",
				"addr": cur_in,
				"addr_text": addr_txt,
				"status_text": pos_names[clampi(pos, 0, 2)],
				"active": pos != 1,
				"forced": false,
			})
		elif mkind in ["push_button", "button", "switch_select"]:
			var icon := "[S] " if mkind == "switch_select" else "[B] "
			var cur_in := int(slot_item.get("modbus_input", -1))
			items.append({
				"key": "dyn_" + io_id,
				"label": icon + lbl,
				"kind": mkind,
				"dir": "input",
				"addr": cur_in,
				"active": bool(dyn_btn_states.get(io_id, false)),
				"forced": false,
			})
		else:
			var lamp_key := "dyn_" + io_id
			var l_forced := forced_map.has(lamp_key)
			var cur_coil := int(slot_item.get("modbus_coil", -1))
			var lamp_on := bool(forced_map[lamp_key]) if l_forced else (ModbusTCP.get_coil(cur_coil) if cur_coil >= 0 else false)
			items.append({
				"key": lamp_key,
				"label": "[L] " + lbl,
				"kind": mkind,
				"dir": "coil",
				"addr": cur_coil,
				"active": lamp_on,
				"forced": l_forced,
			})
	return items


func _collect_tank_status_items(tank: Node3D) -> Array[Dictionary]:
	var c_addr := int(tank.get_meta("modbus_coil", -1))
	var i_addr := int(tank.get_meta("modbus_input", -1))
	var ir_addr := int(tank.get_meta("modbus_input_reg", -1))
	var pump_on := bool(tank.get("active"))
	var forced_pump := tank.has_meta("forced_active")
	var v_open := bool(tank.get("valve_open"))
	var v_pct := roundi(float(tank.get("valve_opening")) * 100.0)
	return [
		{
			"key": "pump",
			"label": "Pump (DO)",
			"dir": "coil",
			"addr": c_addr,
			"active": pump_on,
			"forced": forced_pump,
		},
		{
			"key": "low",
			"label": "Low Level",
			"dir": "input",
			"addr": i_addr + 0 if i_addr >= 0 else -1,
			"active": bool(tank.get("low_level")),
			"forced": false,
		},
		{
			"key": "mid",
			"label": "Mid Level",
			"dir": "input",
			"addr": i_addr + 1 if i_addr >= 0 else -1,
			"active": bool(tank.get("mid_level")),
			"forced": false,
		},
		{
			"key": "high",
			"label": "High Level",
			"dir": "input",
			"addr": i_addr + 2 if i_addr >= 0 else -1,
			"active": bool(tank.get("high_level")),
			"forced": false,
		},
		{
			"key": "level",
			"label": "Level % (IR)",
			"dir": "input_reg",
			"addr": ir_addr,
			"addr_text": _format_word_address(ir_addr, "IW") if ir_addr >= 0 else "-",
			"active": int(tank.get("level_percent")) > 0,
			"forced": false,
			"status_text": "%d%%" % int(tank.get("level_percent")),
		},
		{
			"key": "valve",
			"label": "Outlet Valve",
			"dir": "input",
			"addr": -1,
			"active": v_open and v_pct > 0,
			"forced": false,
			"status_text": ("OPEN %d%%" % v_pct) if v_open else "CLOSED",
		},
	]


func _collect_group_status_items(obj: Node3D) -> Array[Dictionary]:
	var kind := str(obj.get_meta("kind", ""))
	if kind == "cabinet":
		return _collect_cabinet_status_items(obj)
	if kind == "water_tank":
		return _collect_tank_status_items(obj)
	return []


func _refresh_io_status_list() -> void:
	if (
		not is_instance_valid(io_status_list)
		or (is_instance_valid(io_status_panel) and not io_status_panel.visible)
	):
		return
	var equipment: Array[Node3D] = []
	var group_items_cache: Dictionary = {}
	var sig_parts: Array[String] = []
	for obj in get_tree().get_nodes_in_group("sandbox_objects"):
		var obj_kind := str(obj.get_meta("kind", ""))
		if obj_kind not in PRODUCT_KINDS and obj_kind not in PROP_KINDS:
			equipment.append(obj as Node3D)
			if obj_kind in ["cabinet", "water_tank"]:
				var grp_id := obj.get_instance_id()
				var expanded := bool(io_status_expanded_cabinets.get(grp_id, true))
				var grp_items := _collect_group_status_items(obj as Node3D)
				group_items_cache[grp_id] = grp_items
				sig_parts.append("%d:%s:%d" % [grp_id, "1" if expanded else "0", grp_items.size()])
			else:
				sig_parts.append(str(obj.get_instance_id()))
	var new_sig := "|".join(sig_parts)
	if io_status_signature != new_sig:
		io_status_signature = new_sig
		for child in io_status_list.get_children():
			child.queue_free()
		io_status_rows.clear()
		for h in ["Object", "Coil", "Input", "Status"]:
			var h_lbl := Label.new()
			h_lbl.text = h
			h_lbl.add_theme_font_size_override("font_size", 11)
			h_lbl.add_theme_color_override("font_color", Color("9cb3c4"))
			io_status_list.add_child(h_lbl)
		for obj in equipment:
			var obj_kind := str(obj.get_meta("kind", ""))
			var btn := Button.new()
			btn.text = obj.name
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.clip_text = true
			btn.custom_minimum_size = Vector2(124, 24)
			btn.add_theme_font_size_override("font_size", 12)
			var target := obj
			btn.pressed.connect(
				func():
					if obj_kind in ["cabinet", "water_tank"] and selected_object == target:
						var cid := target.get_instance_id()
						io_status_expanded_cabinets[cid] = not bool(io_status_expanded_cabinets.get(cid, true))
						_refresh_io_status_list()
					else:
						_set_selection(target),
			)
			io_status_list.add_child(btn)

			var coil_lbl := Label.new()
			coil_lbl.custom_minimum_size.x = 52
			coil_lbl.add_theme_font_size_override("font_size", 11)
			io_status_list.add_child(coil_lbl)

			var input_lbl := Label.new()
			input_lbl.custom_minimum_size.x = 52
			input_lbl.add_theme_font_size_override("font_size", 11)
			io_status_list.add_child(input_lbl)

			var state_lbl := Label.new()
			state_lbl.custom_minimum_size.x = 92
			state_lbl.add_theme_font_size_override("font_size", 11)
			io_status_list.add_child(state_lbl)

			io_status_rows[obj.get_instance_id()] = [btn, coil_lbl, input_lbl, state_lbl]
			if obj_kind in ["cabinet", "water_tank"] and bool(io_status_expanded_cabinets.get(obj.get_instance_id(), true)):
				var cab_items: Array[Dictionary] = group_items_cache.get(obj.get_instance_id(), [])
				for item in cab_items:
					var item_btn := Button.new()
					item_btn.text = "  |- " + str(item["label"])
					item_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
					item_btn.clip_text = true
					item_btn.custom_minimum_size = Vector2(124, 22)
					item_btn.add_theme_font_size_override("font_size", 10)
					item_btn.pressed.connect(func(): _set_selection(target))
					io_status_list.add_child(item_btn)

					var c_coil := Label.new()
					c_coil.custom_minimum_size.x = 52
					c_coil.add_theme_font_size_override("font_size", 10)
					io_status_list.add_child(c_coil)

					var c_input := Label.new()
					c_input.custom_minimum_size.x = 52
					c_input.add_theme_font_size_override("font_size", 10)
					io_status_list.add_child(c_input)

					var c_state := Label.new()
					c_state.custom_minimum_size.x = 92
					c_state.add_theme_font_size_override("font_size", 10)
					io_status_list.add_child(c_state)

					io_status_rows["cab_%d_%s" % [obj.get_instance_id(), str(item["key"])]] = [item_btn, c_coil, c_input, c_state]
	for obj in equipment:
		var row = io_status_rows.get(obj.get_instance_id())
		if row == null:
			continue
		var btn: Button = row[0]
		var coil_lbl: Label = row[1]
		var input_lbl: Label = row[2]
		var state_lbl: Label = row[3]
		var is_selected := is_instance_valid(selected_object) and obj == selected_object
		var kind := str(obj.get_meta("kind", ""))
		if kind in ["cabinet", "water_tank"]:
			var expanded := bool(io_status_expanded_cabinets.get(obj.get_instance_id(), true))
			var grp_title := ("v " if expanded else "> ") + String(obj.name)
			if btn.text != grp_title:
				btn.text = grp_title
		else:
			var target_text: String = ("> " + String(obj.name)) if is_selected else String(obj.name)
			if btn.text != target_text:
				btn.text = target_text
		var io_col := _object_io_color(obj)
		_apply_status_btn_style(btn, io_col, is_selected)
		var c_addr := int(obj.get_meta("modbus_coil", -1))
		var i_addr := int(obj.get_meta("modbus_input", -1))
		if kind in ["vision_sensor", "rgb_sensor"]:
			var hr_addr := int(obj.get_meta("modbus_holding_reg", -1))
			var ir_addr := int(obj.get_meta("modbus_input_reg", -1))
			_set_label_if_changed(
				coil_lbl,
				"-" if hr_addr < 0 else _format_word_address(hr_addr, "QW"),
				Color("4fd18b") if hr_addr >= 0 else Color("687c8c"),
			)
			var next_in_txt := "-"
			if i_addr >= 0 and ir_addr >= 0:
				next_in_txt = "%s/%s" % [
					_format_iec_address(i_addr, "IX"),
					_format_word_address(ir_addr, "IW"),
				]
			elif ir_addr >= 0:
				next_in_txt = _format_word_address(ir_addr, "IW")
			elif i_addr >= 0:
				next_in_txt = _format_iec_address(i_addr, "IX")
			_set_label_if_changed(
				input_lbl,
				next_in_txt,
				Color("f0c44d") if (i_addr >= 0 or ir_addr >= 0) else Color("687c8c"),
			)
		elif kind == "cabinet":
			_set_label_if_changed(coil_lbl, "-", Color("687c8c"))
			_set_label_if_changed(input_lbl, "-", Color("687c8c"))
		else:
			_set_label_if_changed(
				coil_lbl,
				"-" if c_addr < 0 else _format_iec_address(c_addr, "QX"),
				Color("4fd18b") if c_addr >= 0 else Color("687c8c"),
			)
			_set_label_if_changed(
				input_lbl,
				"-" if i_addr < 0 else _format_iec_address(i_addr, "IX"),
				Color("f0c44d") if i_addr >= 0 else Color("687c8c"),
			)
		if kind in ["cabinet", "water_tank"]:
			var expanded := bool(io_status_expanded_cabinets.get(obj.get_instance_id(), true))
			var cab_items: Array[Dictionary] = group_items_cache.get(obj.get_instance_id(), [])
			if expanded:
				for item in cab_items:
					var crow = io_status_rows.get("cab_%d_%s" % [obj.get_instance_id(), str(item["key"])])
					if crow == null:
						continue
					var c_btn: Button = crow[0]
					var c_coil: Label = crow[1]
					var c_input: Label = crow[2]
					var c_state: Label = crow[3]
					var addr := int(item["addr"])
					var is_coil_io: bool = item["dir"] == "coil"
					var c_io_col := Color("4fd18b") if (is_coil_io and addr >= 0) else (
						Color("f0c44d") if (not is_coil_io and addr >= 0) else (
							Color("4b7a8c") if is_coil_io else Color("8b7d4b")
						)
					)
					_apply_status_btn_style(c_btn, c_io_col, false)
					var next_cbtn_txt := "  |- " + str(item["label"])
					if c_btn.text != next_cbtn_txt:
						c_btn.text = next_cbtn_txt
					_set_label_if_changed(
						c_coil,
						_format_iec_address(addr, "QX") if (is_coil_io and addr >= 0) else "-",
						Color("4fd18b") if (is_coil_io and addr >= 0) else Color("687c8c"),
					)
					_set_label_if_changed(
						c_input,
						str(item["addr_text"]) if item.has("addr_text") else (_format_iec_address(addr, "IX") if (not is_coil_io and addr >= 0) else "-"),
						Color("f0c44d") if (not is_coil_io and addr >= 0) else Color("687c8c"),
					)
					var c_active := bool(item["active"])
					var c_forced := bool(item.get("forced", false))
					var default_state := "ACTIVE" if c_active else "DEACTIVE"
					var next_cstate_txt := ("FORCED ON" if c_active else "FORCED OFF") if c_forced else str(item.get("status_text", default_state))
					var next_cstate_col := Color("f7d070") if c_forced else (Color("66e0a3") if c_active else Color("8aa0b0"))
					_set_label_if_changed(c_state, next_cstate_txt, next_cstate_col)
			var grp_state_txt := (
				"%d%% L%d M%d H%d" % [
					int(obj.get("level_percent")),
					1 if bool(obj.get("low_level")) else 0,
					1 if bool(obj.get("mid_level")) else 0,
					1 if bool(obj.get("high_level")) else 0,
				]
			) if kind == "water_tank" else ("%d ITEMS" % cab_items.size())
			_set_label_if_changed(state_lbl, grp_state_txt, Color("9cb3c4"))
			continue
		var is_active := _is_object_active(obj)
		var tag := "FORCED" if obj.has_meta("forced_active") else (
			"ACTIVE" if is_active else "DEACTIVE"
		)
		if kind == "vision_sensor" and not obj.has_meta("forced_active"):
			var det_id := int(obj.get("detected_id"))
			var det_name := "BOX" if det_id == 1 else ("CRATE" if det_id == 2 else ("NG" if det_id == 3 else "NONE"))
			tag = "ID:%d %s" % [det_id, det_name]
		elif kind == "rgb_sensor" and not obj.has_meta("forced_active"):
			var col_id := int(obj.get("detected_color_id"))
			const RGB_NAMES := ["NONE", "ORANGE", "GREEN", "BLUE", "YELLOW", "RED", "PURPLE"]
			var col_name: String = RGB_NAMES[col_id] if col_id >= 0 and col_id < RGB_NAMES.size() else "NONE"
			tag = "ID:%d %s" % [col_id, col_name]
		elif kind == "water_tank" and not obj.has_meta("forced_active"):
			tag = "%d%% L%d M%d H%d" % [
				int(obj.get("level_percent")),
				1 if bool(obj.get("low_level")) else 0,
				1 if bool(obj.get("mid_level")) else 0,
				1 if bool(obj.get("high_level")) else 0,
			]
		var col := Color("f7d070") if obj.has_meta("forced_active") else (
			Color("66e0a3") if is_active else Color("8aa0b0")
		)
		_set_label_if_changed(state_lbl, tag, col)


func _build_force_panel(ui_root: Control) -> void:
	force_panel = PanelContainer.new()
	force_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	force_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	force_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	force_panel.offset_left = -280
	force_panel.offset_top = -155
	force_panel.offset_right = -16
	force_panel.offset_bottom = -46
	force_panel.custom_minimum_size = Vector2(264, 0)
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

	force_item_option = OptionButton.new()
	force_item_option.visible = false
	force_item_option.add_theme_font_size_override("font_size", 11)
	force_item_option.item_selected.connect(func(_idx: int): _refresh_force_panel())
	vbox.add_child(force_item_option)

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
	force_on_button.pressed.connect(
		func():
			_set_object_force(selected_object, true),
	)
	btn_row.add_child(force_on_button)

	force_off_button = Button.new()
	force_off_button.text = "Force OFF"
	force_off_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_accent_button(force_off_button, "7a2e33", "993b41", "cc5a61")
	force_off_button.pressed.connect(
		func():
			_set_object_force(selected_object, false),
	)
	btn_row.add_child(force_off_button)

	force_clear_button = Button.new()
	force_clear_button.text = "Release"
	force_clear_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	force_clear_button.pressed.connect(
		func():
			_clear_object_force(selected_object),
	)
	btn_row.add_child(force_clear_button)

	var tank_ui := _create_tank_sim_box()
	tank_force_box = tank_ui["box"]
	tank_force_sensors_label = tank_ui["sensors_label"]
	tank_force_valve_btn = tank_ui["valve_btn"]
	tank_force_valve_slider = tank_ui["valve_slider"]
	tank_force_valve_pct_label = tank_ui["pct_label"]
	vbox.add_child(tank_force_box)


func _create_tank_sim_box() -> Dictionary:
	var box := VBoxContainer.new()
	box.visible = false
	box.add_theme_constant_override("separation", 6)

	var sep := HSeparator.new()
	box.add_child(sep)

	var sensors_lbl := Label.new()
	sensors_lbl.text = "Level: 25% | L:1 M:0 H:0"
	sensors_lbl.add_theme_font_size_override("font_size", 12)
	sensors_lbl.add_theme_color_override("font_color", Color("7de8ff"))
	box.add_child(sensors_lbl)

	var valve_btn := Button.new()
	valve_btn.text = "Outlet Valve: CLOSED"
	valve_btn.pressed.connect(
		func():
			if is_instance_valid(selected_object) and str(selected_object.get_meta("kind", "")) == "water_tank":
				var next_open := not bool(selected_object.get("valve_open"))
				selected_object.set("valve_open", next_open)
				_refresh_force_panel()
				_refresh_transform_controls()
				_save_layout(true),
	)
	box.add_child(valve_btn)

	var slider_row := HBoxContainer.new()
	slider_row.add_theme_constant_override("separation", 6)
	box.add_child(slider_row)

	var open_lbl := Label.new()
	open_lbl.text = "Opening:"
	open_lbl.add_theme_font_size_override("font_size", 11)
	open_lbl.add_theme_color_override("font_color", Color("9cb3c4"))
	slider_row.add_child(open_lbl)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 5.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(
		func(val: float):
			if is_instance_valid(selected_object) and str(selected_object.get_meta("kind", "")) == "water_tank":
				selected_object.set("valve_opening", val / 100.0)
				_refresh_tank_sim_box(selected_object, sensors_lbl, valve_btn, slider, slider_row.get_child(2) as Label)
				_save_layout(true),
	)
	slider_row.add_child(slider)

	var pct_lbl := Label.new()
	pct_lbl.text = "100%"
	pct_lbl.custom_minimum_size.x = 38
	pct_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct_lbl.add_theme_font_size_override("font_size", 11)
	slider_row.add_child(pct_lbl)

	return {
		"box": box,
		"sensors_label": sensors_lbl,
		"valve_btn": valve_btn,
		"valve_slider": slider,
		"pct_label": pct_lbl,
	}


func _refresh_tank_sim_box(
	tank: Node3D,
	sensors_lbl: Label,
	valve_btn: Button,
	slider: HSlider,
	pct_lbl: Label,
) -> void:
	if not is_instance_valid(tank):
		return
	var lvl := int(tank.get("level_percent"))
	var low_on := bool(tank.get("low_level"))
	var mid_on := bool(tank.get("mid_level"))
	var high_on := bool(tank.get("high_level"))
	var sensors_txt := "Level: %d%%  |  L:%s  M:%s  H:%s" % [
		lvl,
		"ON" if low_on else "OFF",
		"ON" if mid_on else "OFF",
		"ON" if high_on else "OFF",
	]
	_set_label_if_changed(sensors_lbl, sensors_txt, Color("ff6b6b") if high_on else Color("7de8ff"))
	var v_open := bool(tank.get("valve_open"))
	var v_pct := roundi(float(tank.get("valve_opening")) * 100.0)
	var btn_txt := "Outlet Valve: OPEN" if v_open else "Outlet Valve: CLOSED"
	if valve_btn.text != btn_txt:
		valve_btn.text = btn_txt
	var v_open_state := 1 if v_open else 0
	if int(valve_btn.get_meta("_last_valve_open", -1)) != v_open_state:
		valve_btn.set_meta("_last_valve_open", v_open_state)
		if v_open:
			_style_accent_button(valve_btn, "1e6b45", "278758", "3eb87a")
		else:
			_style_accent_button(valve_btn, "2b3945", "384a59", "4d6478")
	if not is_equal_approx(slider.value, float(v_pct)):
		slider.set_value_no_signal(float(v_pct))
	_set_label_if_changed(pct_lbl, "%d%%" % v_pct)


func _is_object_active(obj: Node3D) -> bool:
	var kind := str(obj.get_meta("kind", ""))
	if kind in PROP_KINDS or kind in PRODUCT_KINDS:
		return false
	if kind == "turn":
		var area := obj.get_node_or_null("TransferArea")
		return bool(area.get("active")) if area != null else false
	var val = obj.get("active")
	return bool(val) if val != null else false


func _set_object_force(obj: Node3D, value: bool) -> void:
	var kind := str(obj.get_meta("kind", "")) if is_instance_valid(obj) else ""
	if not is_instance_valid(obj) or kind in PRODUCT_KINDS or kind in PROP_KINDS:
		return
	if kind == "cabinet" and is_instance_valid(force_item_option) and force_item_option.selected >= 0:
		var item_key := str(force_item_option.get_item_metadata(force_item_option.selected))
		if not item_key.is_empty():
			obj.call("set_item_force", item_key, value)
			_refresh_force_panel()
			_refresh_io_status_list()
			_refresh_cabinet_hud()
			return
	obj.set_meta("forced_active", value)
	_apply_object_force(obj, value)
	_refresh_boxes_freeze()
	_refresh_cabinet_hud()
	if not test_mode and is_inside_tree():
		_save_settings()
	_refresh_force_panel()


func _clear_object_force(obj: Node3D) -> void:
	if not is_instance_valid(obj):
		return
	var kind := str(obj.get_meta("kind", ""))
	if kind == "cabinet" and is_instance_valid(force_item_option) and force_item_option.selected >= 0:
		var item_key := str(force_item_option.get_item_metadata(force_item_option.selected))
		if not item_key.is_empty():
			obj.call("clear_item_force", item_key)
			_refresh_force_panel()
			_refresh_io_status_list()
			_refresh_cabinet_hud()
			return
	if obj.has_meta("forced_active"):
		obj.remove_meta("forced_active")
	if kind in ["pusher", "stopper", "emitter", "remover", "cabinet", "stack_light", "motor_fan", "pump", "water_tank", "solenoid_valve", "reject_bin"]:
		obj.set("plc_mode", plc_mode)
		if not plc_mode:
			obj.set("active", false)
	elif kind == "turn":
		var area := obj.get_node_or_null("TransferArea")
		if area != null:
			area.set("plc_mode", plc_mode)
			if not plc_mode:
				area.set("active", false)
	elif kind in ["conveyor", "conveyor_short"] and obj is StaticBody3D:
		_apply_conveyor_speed(obj as StaticBody3D)
	_refresh_boxes_freeze()
	_refresh_cabinet_hud()
	if not test_mode and is_inside_tree():
		_save_settings()
	_refresh_force_panel()


func _has_any_forced_active() -> bool:
	for obj in get_tree().get_nodes_in_group("sandbox_objects"):
		if obj.has_meta("forced_active") and bool(obj.get_meta("forced_active")):
			return true
	return false


func _refresh_boxes_freeze() -> void:
	var should_freeze := not running
	for box in get_tree().get_nodes_in_group("product_boxes"):
		box.freeze = should_freeze


func _apply_object_force(obj: Node3D, value: bool) -> void:
	var kind := str(obj.get_meta("kind", ""))
	match kind:
		"conveyor", "conveyor_short":
			obj.set("active", value)
		"turn":
			var area := obj.get_node_or_null("TransferArea")
			if area != null:
				area.set("plc_mode", true)
				area.set("active", value)
		"pusher", "stopper", "emitter", "remover", "motor_fan", "pump", "water_tank", "solenoid_valve", "reject_bin":
			obj.set("plc_mode", true)
			obj.set("active", value)
		"cabinet", "stack_light":
			obj.set("plc_mode", true)
			obj.set("lamp_green_on", value)
			obj.set("lamp_yellow_on", value)
			obj.set("lamp_red_on", value)
			obj.set("active", value)
		"sensor", "vision_sensor", "rgb_sensor":
			obj.call("set_detected", value)


func _refresh_force_panel() -> void:
	if not is_instance_valid(force_panel):
		return
	var sel_kind := str(selected_object.get_meta("kind", "")) if is_instance_valid(selected_object) else ""
	var show_force := (
		(not edit_mode) and is_instance_valid(selected_object)
		and selected_object.is_in_group("sandbox_objects")
		and (sel_kind not in PRODUCT_KINDS)
		and (sel_kind not in PROP_KINDS)
	)
	force_panel.visible = show_force
	if not show_force:
		_force_panel_layout_sig = ""
		return
	_set_label_if_changed(force_title, "FORCE: " + selected_object.name)
	var is_cab := sel_kind == "cabinet"
	if is_instance_valid(force_item_option):
		force_item_option.visible = is_cab
	if is_cab:
		var cab_items: Array[Dictionary] = []
		for it in _collect_cabinet_status_items(selected_object):
			if str(it.get("dir", "")) == "coil":
				cab_items.append(it)
		if cab_items.is_empty():
			force_panel.visible = false
			_force_panel_layout_sig = ""
			return
		var sig_parts: Array[String] = [str(selected_object.get_instance_id())]
		for it in cab_items:
			sig_parts.append("%s:%s" % [str(it["key"]), str(it["label"])])
		var new_sig := "|".join(sig_parts)
		if _force_item_sig != new_sig:
			_force_item_sig = new_sig
			var prev_key := ""
			if force_item_option.selected >= 0 and force_item_option.selected < force_item_option.item_count:
				prev_key = str(force_item_option.get_item_metadata(force_item_option.selected))
			force_item_option.clear()
			var sel_idx := 0
			for idx in range(cab_items.size()):
				var it := cab_items[idx]
				force_item_option.add_item(str(it["label"]), idx)
				force_item_option.set_item_metadata(idx, str(it["key"]))
				if str(it["key"]) == prev_key:
					sel_idx = idx
			if cab_items.size() > 0:
				force_item_option.select(sel_idx)
		if cab_items.size() > 0:
			var cur_idx := clampi(force_item_option.selected, 0, cab_items.size() - 1)
			var cur_item := cab_items[cur_idx]
			var cur_key := str(cur_item["key"])
			var forced_map: Dictionary = selected_object.get("forced_items") if "forced_items" in selected_object else {}
			if forced_map.has(cur_key):
				var f_val := bool(forced_map[cur_key])
				_set_label_if_changed(force_status_label, "Status: FORCED ON" if f_val else "Status: FORCED OFF", Color("f7d070"))
			else:
				var it_active := bool(cur_item["active"])
				_set_label_if_changed(force_status_label, "Status: ACTIVE" if it_active else "Status: DEACTIVE", Color("66e0a3") if it_active else Color("9cb3c4"))
			force_on_button.disabled = false
			force_off_button.disabled = false
			force_clear_button.disabled = not forced_map.has(cur_key)
		else:
			_set_label_if_changed(force_status_label, "No items on cabinet", Color("9cb3c4"))
			force_on_button.disabled = true
			force_off_button.disabled = true
			force_clear_button.disabled = true
		if is_instance_valid(tank_force_box):
			tank_force_box.visible = false
		var cab_layout_sig := "cab:%s" % new_sig
		if _force_panel_layout_sig != cab_layout_sig:
			_force_panel_layout_sig = cab_layout_sig
			_fit_force_panel()
			_fit_force_panel.call_deferred()
		return
	var is_active := _is_object_active(selected_object)
	if selected_object.has_meta("forced_active"):
		var f_val := bool(selected_object.get_meta("forced_active"))
		_set_label_if_changed(force_status_label, "Status: FORCED ON" if f_val else "Status: FORCED OFF", Color("f7d070"))
	else:
		_set_label_if_changed(
			force_status_label,
			"Status: ACTIVE" if is_active else "Status: DEACTIVE",
			Color("66e0a3") if is_active else Color("9cb3c4"),
		)
	force_on_button.disabled = false
	force_off_button.disabled = false
	force_clear_button.disabled = not selected_object.has_meta("forced_active")
	var is_tank := sel_kind == "water_tank"
	if is_instance_valid(tank_force_box):
		tank_force_box.visible = is_tank
		if is_tank:
			_refresh_tank_sim_box(
				selected_object,
				tank_force_sensors_label,
				tank_force_valve_btn,
				tank_force_valve_slider,
				tank_force_valve_pct_label,
			)
			if force_on_button.text != "Pump ON":
				force_on_button.text = "Pump ON"
			if force_off_button.text != "Pump OFF":
				force_off_button.text = "Pump OFF"
		else:
			if force_on_button.text != "Force ON":
				force_on_button.text = "Force ON"
			if force_off_button.text != "Force OFF":
				force_off_button.text = "Force OFF"
	var layout_sig := "%d:%s:%d" % [selected_object.get_instance_id(), sel_kind, 1 if is_tank else 0]
	if _force_panel_layout_sig != layout_sig:
		_force_panel_layout_sig = layout_sig
		_fit_force_panel()
		_fit_force_panel.call_deferred()


func _fit_force_panel() -> void:
	_fit_bottom_right_panel(force_panel, 264.0)


func _fit_bottom_right_panel(panel: PanelContainer, min_width: float) -> void:
	if not is_instance_valid(panel):
		return
	var vp := get_viewport().get_visible_rect().size if get_viewport() != null else Vector2(1280.0, 720.0)
	var min_sz := panel.get_combined_minimum_size()
	var w := minf(maxf(min_sz.x, min_width), maxf(220.0, vp.x - 24.0))
	var right_margin := 12.0 if vp.x < 920.0 else 16.0
	var bottom_margin := 46.0
	var max_h := maxf(140.0, vp.y - bottom_margin - 60.0)
	var h := minf(min_sz.y, max_h)
	panel.offset_right = -right_margin
	panel.offset_left = -right_margin - w
	panel.offset_bottom = -bottom_margin
	panel.offset_top = -bottom_margin - h


var _object_thumb_requests: Array[Dictionary] = []
var _object_thumbs_rendered: bool = false
var _object_thumbs_rendering: bool = false


func _set_object_dialog_visible(visible_state: bool) -> void:
	if is_instance_valid(object_dialog_backdrop):
		object_dialog_backdrop.visible = visible_state
	if is_instance_valid(object_dialog):
		object_dialog.visible = visible_state
	if visible_state and not _object_thumbs_rendered and not _object_thumbs_rendering:
		_object_thumbs_rendered = true
		_bake_object_thumbnails_async()


func _create_object_thumbnail(kind: String) -> Control:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(68, 68)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override(
		"panel",
		_ui_stylebox(Color(0.04, 0.07, 0.10, 0.9), Color("284357"), 6, 1, 2, 2),
	)

	var tex_rect := TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(64, 64)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(tex_rect)
	_object_thumb_requests.append({"kind": kind, "rect": tex_rect})
	return frame


func _bake_object_thumbnails_async() -> void:
	if _object_thumbs_rendering or _object_thumb_requests.is_empty():
		return
	if DisplayServer.get_name() == "headless" or not is_inside_tree():
		return
	_object_thumbs_rendering = true

	const BATCH_SIZE := 4
	var host := Node.new()
	host.name = "_ThumbBakeHost"
	add_child(host)

	var vps: Array[SubViewport] = []
	var cams: Array[Camera3D] = []
	for i in range(BATCH_SIZE):
		var vp := SubViewport.new()
		vp.size = Vector2i(96, 96)
		vp.own_world_3d = true
		vp.transparent_bg = true
		vp.msaa_3d = SubViewport.MSAA_2X
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		host.add_child(vp)

		var env := Environment.new()
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.62, 0.68, 0.76)
		env.ambient_light_energy = 1.25
		var we := WorldEnvironment.new()
		we.environment = env
		vp.add_child(we)

		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-42.0, 38.0, 0.0)
		light.light_energy = 1.2
		vp.add_child(light)

		var cam := Camera3D.new()
		cam.fov = 38.0
		vp.add_child(cam)

		vps.append(vp)
		cams.append(cam)

	var idx := 0
	while idx < _object_thumb_requests.size():
		if not is_instance_valid(self) or not is_inside_tree() or not is_instance_valid(host):
			break
		var batch_items: Array[Dictionary] = []
		var insts: Array[Node3D] = []
		for b in range(BATCH_SIZE):
			if idx >= _object_thumb_requests.size():
				break
			var req: Dictionary = _object_thumb_requests[idx]
			idx += 1
			var kind := str(req["kind"])
			var vp := vps[b]
			var cam := cams[b]
			var inst: Node3D = null
			var packed := load("res://objects/" + kind + ".tscn") as PackedScene
			if packed != null:
				inst = packed.instantiate() as Node3D
				inst.process_mode = Node.PROCESS_MODE_DISABLED
				vp.add_child(inst)
			var fp := _footprint(kind, 0.0)
			var hr := _height_range(kind, 0.0)
			var center_y := (hr.x + hr.y) * 0.5
			if kind in PRODUCT_KINDS:
				center_y = 0.32 if kind == "box" else 0.16
			elif kind in ["conveyor", "conveyor_short", "turn"]:
				center_y = 0.72
			var span := maxf(maxf(fp.x, fp.y), hr.y - hr.x)
			var cam_dist := clampf(span * 1.15, 1.35, 7.2)
			if kind == "conveyor":
				cam_dist = 6.2
			elif kind == "conveyor_short":
				cam_dist = 3.1
			var cam_pos := Vector3(cam_dist * 0.72, center_y + cam_dist * 0.55, cam_dist * 0.78)
			cam.look_at_from_position(cam_pos, Vector3(0.0, center_y, 0.0), Vector3.UP)
			vp.render_target_update_mode = SubViewport.UPDATE_ONCE
			batch_items.append(req)
			insts.append(inst)

		await RenderingServer.frame_post_draw
		if not is_instance_valid(self) or not is_inside_tree():
			break
		for b in range(batch_items.size()):
			var vp := vps[b]
			var rect := batch_items[b]["rect"] as TextureRect
			if is_instance_valid(vp) and is_instance_valid(rect):
				var vp_tex := vp.get_texture()
				var img := vp_tex.get_image() if vp_tex != null else null
				if img != null and not img.is_empty():
					rect.texture = ImageTexture.create_from_image(img)
			var inst := insts[b]
			if is_instance_valid(inst):
				if inst.get_parent() != null:
					inst.get_parent().remove_child(inst)
				inst.queue_free()

	if is_instance_valid(host):
		host.queue_free()
	_object_thumb_requests.clear()
	_object_thumbs_rendering = false


func _set_floor_dialog_visible(show_dialog: bool) -> void:
	if is_instance_valid(floor_dialog_backdrop):
		floor_dialog_backdrop.visible = show_dialog
	if is_instance_valid(floor_dialog):
		floor_dialog.visible = show_dialog
	if show_dialog:
		if is_instance_valid(width_input):
			width_input.value = workspace_width
		if is_instance_valid(depth_input):
			depth_input.value = workspace_depth
		if is_instance_valid(show_grid_check):
			show_grid_check.set_pressed_no_signal(show_edit_grid)
		if is_instance_valid(decor_option):
			var dkeys := DECOR_THEMES.keys()
			var didx := dkeys.find(decor_style)
			if didx >= 0:
				decor_option.select(didx)


func _build_floor_dialog(ui_root: Control) -> void:
	floor_dialog_backdrop = ColorRect.new()
	floor_dialog_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	floor_dialog_backdrop.color = Color(0.02, 0.04, 0.06, 0.45)
	floor_dialog_backdrop.visible = false
	floor_dialog_backdrop.gui_input.connect(
		func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_set_floor_dialog_visible(false),
	)
	ui_root.add_child(floor_dialog_backdrop)

	floor_dialog = PanelContainer.new()
	floor_dialog.set_anchors_preset(Control.PRESET_CENTER)
	floor_dialog.grow_horizontal = Control.GROW_DIRECTION_BOTH
	floor_dialog.grow_vertical = Control.GROW_DIRECTION_BOTH
	floor_dialog.custom_minimum_size = Vector2(360, 0)
	var style := _ui_stylebox(Color(0.063, 0.098, 0.137, 0.96), Color("2f4c63"), 14, 1, 16, 14)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 14
	floor_dialog.add_theme_stylebox_override("panel", style)
	floor_dialog.visible = false
	ui_root.add_child(floor_dialog)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	floor_dialog.add_child(vbox)

	var hdr_row := HBoxContainer.new()
	vbox.add_child(hdr_row)
	var hdr := Label.new()
	hdr.text = "WORKSPACE & ENV SETTINGS"
	hdr.add_theme_font_size_override("font_size", 14)
	hdr.add_theme_color_override("font_color", Color("eef7fa"))
	hdr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr_row.add_child(hdr)
	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(28, 26)
	close_btn.pressed.connect(func(): _set_floor_dialog_visible(false))
	hdr_row.add_child(close_btn)

	var preset_lbl := Label.new()
	preset_lbl.text = "Floor Presets"
	preset_lbl.add_theme_font_size_override("font_size", 11)
	preset_lbl.add_theme_color_override("font_color", Color("7ea7c2"))
	vbox.add_child(preset_lbl)

	var preset_row := HBoxContainer.new()
	preset_row.add_theme_constant_override("separation", 6)
	vbox.add_child(preset_row)
	for p in [
		["Small 16×12", 16, 12],
		["Med 22×15", 22, 15],
		["Large 36×24", 36, 24],
		["XL 50×35", 50, 35],
	]:
		var pbtn := Button.new()
		pbtn.text = p[0]
		pbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pbtn.add_theme_font_size_override("font_size", 11)
		var pw: int = p[1]
		var pd: int = p[2]
		pbtn.pressed.connect(
			func():
				width_input.value = pw
				depth_input.value = pd
				_apply_workspace_input(),
		)
		preset_row.add_child(pbtn)

	var size_row := HBoxContainer.new()
	size_row.add_theme_constant_override("separation", 6)
	vbox.add_child(size_row)
	var size_title := Label.new()
	size_title.text = "Size (m):"
	size_title.custom_minimum_size.x = 74
	size_row.add_child(size_title)
	width_input = SpinBox.new()
	width_input.min_value = 10
	width_input.max_value = 100
	width_input.step = 1
	width_input.value = workspace_width
	width_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_row.add_child(width_input)
	var x_label := Label.new()
	x_label.text = "×"
	size_row.add_child(x_label)
	depth_input = SpinBox.new()
	depth_input.min_value = 10
	depth_input.max_value = 100
	depth_input.step = 1
	depth_input.value = workspace_depth
	depth_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_row.add_child(depth_input)
	var apply_size := Button.new()
	apply_size.text = "Apply"
	_style_accent_button(apply_size, "1b4f6e", "23668f", "3b8cb8")
	apply_size.pressed.connect(_apply_workspace_input)
	size_row.add_child(apply_size)

	vbox.add_child(HSeparator.new())

	var grid_row := HBoxContainer.new()
	grid_row.add_theme_constant_override("separation", 8)
	vbox.add_child(grid_row)
	var g_lbl := Label.new()
	g_lbl.text = "Grid Snap:"
	g_lbl.custom_minimum_size.x = 74
	grid_row.add_child(g_lbl)
	grid_step_option = OptionButton.new()
	grid_step_option.add_item("0.25 m", 0)
	grid_step_option.add_item("0.50 m", 1)
	grid_step_option.add_item("1.00 m", 2)
	grid_step_option.select(1)
	grid_step_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_step_option.item_selected.connect(
		func(idx: int):
			var steps := [0.25, 0.5, 1.0]
			grid_step = steps[clampi(idx, 0, steps.size() - 1)]
			_rebuild_grid()
			_save_settings(),
	)
	grid_row.add_child(grid_step_option)

	show_grid_check = CheckBox.new()
	show_grid_check.text = "Show Grid in Edit Mode"
	show_grid_check.button_pressed = show_edit_grid
	show_grid_check.toggled.connect(
		func(on: bool):
			show_edit_grid = on
			if is_instance_valid(edit_grid):
				edit_grid.visible = edit_mode and show_edit_grid
			_save_settings(),
	)
	vbox.add_child(show_grid_check)

	vbox.add_child(HSeparator.new())

	var env_row := HBoxContainer.new()
	env_row.add_theme_constant_override("separation", 8)
	vbox.add_child(env_row)
	var env_label := Label.new()
	env_label.text = "Env Theme:"
	env_label.custom_minimum_size.x = 74
	env_row.add_child(env_label)
	decor_option = OptionButton.new()
	decor_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var theme_keys := DECOR_THEMES.keys()
	for i in theme_keys.size():
		var k: String = theme_keys[i]
		decor_option.add_item(DECOR_THEMES[k]["label"], i)
	decor_option.item_selected.connect(
		func(idx: int):
			var keys := DECOR_THEMES.keys()
			if idx >= 0 and idx < keys.size():
				_apply_decor_style(keys[idx]),
	)
	env_row.add_child(decor_option)


func _set_npc_dialog_visible(show_dialog: bool) -> void:
	if is_instance_valid(npc_dialog_backdrop):
		npc_dialog_backdrop.visible = show_dialog
	if is_instance_valid(npc_dialog):
		npc_dialog.visible = show_dialog
	if show_dialog:
		if is_instance_valid(npc_master_check):
			npc_master_check.set_pressed_no_signal(npcs_enabled)
		if is_instance_valid(npc_op_check):
			npc_op_check.set_pressed_no_signal(npc_operator_enabled)
		if is_instance_valid(npc_tester_check):
			npc_tester_check.set_pressed_no_signal(npc_tester_enabled)
		if is_instance_valid(npc_safety_check):
			npc_safety_check.set_pressed_no_signal(npc_safety_enabled)
		if is_instance_valid(npc_chat_check):
			npc_chat_check.set_pressed_no_signal(npc_chat_enabled)
		if is_instance_valid(npc_speed_spin):
			npc_speed_spin.set_value_no_signal(npc_walk_speed)
		if is_instance_valid(npc_inspect_spin):
			npc_inspect_spin.set_value_no_signal(npc_inspect_duration)


func _build_npc_dialog(ui_root: Control) -> void:
	npc_dialog_backdrop = ColorRect.new()
	npc_dialog_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	npc_dialog_backdrop.color = Color(0.02, 0.04, 0.06, 0.45)
	npc_dialog_backdrop.visible = false
	npc_dialog_backdrop.gui_input.connect(
		func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_set_npc_dialog_visible(false),
	)
	ui_root.add_child(npc_dialog_backdrop)

	npc_dialog = PanelContainer.new()
	npc_dialog.set_anchors_preset(Control.PRESET_CENTER)
	npc_dialog.grow_horizontal = Control.GROW_DIRECTION_BOTH
	npc_dialog.grow_vertical = Control.GROW_DIRECTION_BOTH
	npc_dialog.custom_minimum_size = Vector2(340, 0)
	var style := _ui_stylebox(Color(0.063, 0.098, 0.137, 0.96), Color("2f4c63"), 14, 1, 16, 14)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 14
	npc_dialog.add_theme_stylebox_override("panel", style)
	npc_dialog.visible = false
	ui_root.add_child(npc_dialog)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	npc_dialog.add_child(vbox)

	var hdr_row := HBoxContainer.new()
	vbox.add_child(hdr_row)
	var hdr := Label.new()
	hdr.text = "NPC SETTINGS"
	hdr.add_theme_font_size_override("font_size", 14)
	hdr.add_theme_color_override("font_color", Color("eef7fa"))
	hdr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr_row.add_child(hdr)
	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(28, 26)
	close_btn.pressed.connect(func(): _set_npc_dialog_visible(false))
	hdr_row.add_child(close_btn)

	npc_master_check = CheckBox.new()
	npc_master_check.text = "Enable Factory NPCs"
	npc_master_check.button_pressed = npcs_enabled
	npc_master_check.toggled.connect(
		func(on: bool):
			npcs_enabled = on
			_apply_npc_settings()
			_save_settings(),
	)
	vbox.add_child(npc_master_check)

	var role_row := HBoxContainer.new()
	role_row.add_theme_constant_override("separation", 8)
	vbox.add_child(role_row)
	npc_op_check = CheckBox.new()
	npc_op_check.text = "Operator"
	npc_op_check.button_pressed = npc_operator_enabled
	npc_op_check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	npc_op_check.toggled.connect(
		func(on: bool):
			npc_operator_enabled = on
			_apply_npc_settings()
			_save_settings(),
	)
	role_row.add_child(npc_op_check)
	npc_tester_check = CheckBox.new()
	npc_tester_check.text = "Tester"
	npc_tester_check.button_pressed = npc_tester_enabled
	npc_tester_check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	npc_tester_check.toggled.connect(
		func(on: bool):
			npc_tester_enabled = on
			_apply_npc_settings()
			_save_settings(),
	)
	role_row.add_child(npc_tester_check)
	npc_safety_check = CheckBox.new()
	npc_safety_check.text = "Safety"
	npc_safety_check.button_pressed = npc_safety_enabled
	npc_safety_check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	npc_safety_check.toggled.connect(
		func(on: bool):
			npc_safety_enabled = on
			_apply_npc_settings()
			_save_settings(),
	)
	role_row.add_child(npc_safety_check)

	var role_row2 := HBoxContainer.new()
	role_row2.add_theme_constant_override("separation", 8)
	vbox.add_child(role_row2)
	npc_maint_check = CheckBox.new()
	npc_maint_check.text = "Maintenance"
	npc_maint_check.button_pressed = npc_maintenance_enabled
	npc_maint_check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	npc_maint_check.toggled.connect(
		func(on: bool):
			npc_maintenance_enabled = on
			_apply_npc_settings()
			_save_settings(),
	)
	role_row2.add_child(npc_maint_check)
	npc_qc_check = CheckBox.new()
	npc_qc_check.text = "QC Inspector"
	npc_qc_check.button_pressed = npc_qc_enabled
	npc_qc_check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	npc_qc_check.toggled.connect(
		func(on: bool):
			npc_qc_enabled = on
			_apply_npc_settings()
			_save_settings(),
	)
	role_row2.add_child(npc_qc_check)

	vbox.add_child(HSeparator.new())

	var spd_row := HBoxContainer.new()
	spd_row.add_theme_constant_override("separation", 8)
	vbox.add_child(spd_row)
	var spd_lbl := Label.new()
	spd_lbl.text = "Walk Speed:"
	spd_lbl.custom_minimum_size.x = 120
	spd_row.add_child(spd_lbl)
	npc_speed_spin = SpinBox.new()
	npc_speed_spin.min_value = 0.5
	npc_speed_spin.max_value = 4.0
	npc_speed_spin.step = 0.05
	npc_speed_spin.suffix = " m/s"
	npc_speed_spin.value = npc_walk_speed
	npc_speed_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	npc_speed_spin.value_changed.connect(
		func(val: float):
			npc_walk_speed = val
			_apply_npc_settings()
			_save_settings(),
	)
	spd_row.add_child(npc_speed_spin)

	var insp_row := HBoxContainer.new()
	insp_row.add_theme_constant_override("separation", 8)
	vbox.add_child(insp_row)
	var insp_lbl := Label.new()
	insp_lbl.text = "Inspect Time:"
	insp_lbl.custom_minimum_size.x = 120
	insp_row.add_child(insp_lbl)
	npc_inspect_spin = SpinBox.new()
	npc_inspect_spin.min_value = 0.5
	npc_inspect_spin.max_value = 6.0
	npc_inspect_spin.step = 0.1
	npc_inspect_spin.suffix = " s"
	npc_inspect_spin.value = npc_inspect_duration
	npc_inspect_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	npc_inspect_spin.value_changed.connect(
		func(val: float):
			npc_inspect_duration = val
			_apply_npc_settings()
			_save_settings(),
	)
	insp_row.add_child(npc_inspect_spin)

	npc_chat_check = CheckBox.new()
	npc_chat_check.text = "NPC Chat Bubbles"
	npc_chat_check.button_pressed = npc_chat_enabled
	npc_chat_check.toggled.connect(
		func(on: bool):
			npc_chat_enabled = on
			_apply_npc_settings()
			_save_settings(),
	)
	vbox.add_child(npc_chat_check)

	npc_sound_check = CheckBox.new()
	npc_sound_check.text = "NPC Sounds"
	npc_sound_check.button_pressed = npc_sound_enabled
	npc_sound_check.toggled.connect(
		func(on: bool):
			npc_sound_enabled = on
			_apply_npc_settings()
			_save_settings(),
	)
	vbox.add_child(npc_sound_check)

	var reset_btn := Button.new()
	reset_btn.text = "Reset NPC Positions"
	_style_accent_button(reset_btn, "1b4f6e", "23668f", "3b8cb8")
	reset_btn.pressed.connect(_reset_npc_positions)
	vbox.add_child(reset_btn)


func _set_help_dialog_visible(visible_state: bool, tab_idx: int = -1) -> void:
	if is_instance_valid(help_dialog):
		help_dialog.visible = visible_state
	if is_instance_valid(help_dialog_backdrop):
		help_dialog_backdrop.visible = visible_state
	if visible_state and tab_idx >= 0 and _help_select_tab_cb.is_valid():
		_help_select_tab_cb.call(tab_idx)


func _make_guide_theme() -> Theme:
	var t := Theme.new()
	var path := "res://assets/fonts/NotoSansThaiUI-Regular.ttf"
	var thai_font: Font = null
	if FileAccess.file_exists(path):
		var ff := FontFile.new()
		if ff.load_dynamic_font(path) == OK:
			thai_font = ff
	if thai_font == null and ResourceLoader.exists(path):
		thai_font = load(path) as Font
	if thai_font != null:
		var fv := FontVariation.new()
		fv.base_font = ThemeDB.fallback_font
		fv.fallbacks = [thai_font]
		t.default_font = fv
	return t


func _build_help_dialog(ui_root: Control) -> void:
	help_dialog_backdrop = ColorRect.new()
	help_dialog_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	help_dialog_backdrop.color = Color(0.02, 0.04, 0.06, 0.5)
	help_dialog_backdrop.visible = false
	help_dialog_backdrop.gui_input.connect(
		func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_set_help_dialog_visible(false),
	)
	ui_root.add_child(help_dialog_backdrop)

	help_dialog = PanelContainer.new()
	help_dialog.theme = _make_guide_theme()
	help_dialog.set_anchors_preset(Control.PRESET_CENTER)
	help_dialog.custom_minimum_size = Vector2(720, 560)
	help_dialog.offset_left = -360
	help_dialog.offset_right = 360
	help_dialog.offset_top = -280
	help_dialog.offset_bottom = 280
	var style := _ui_stylebox(Color(0.068, 0.106, 0.149, 0.97), Color("36566e"), 14, 1, 18, 16)
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 16
	help_dialog.add_theme_stylebox_override("panel", style)
	help_dialog.visible = false
	ui_root.add_child(help_dialog)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	help_dialog.add_child(vbox)

	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 6)
	vbox.add_child(hdr)
	var title := Label.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color("eef7fa"))
	hdr.add_child(title)

	var en_btn := Button.new()
	en_btn.text = "EN"
	en_btn.custom_minimum_size = Vector2(36, 26)
	en_btn.add_theme_font_size_override("font_size", 11)
	hdr.add_child(en_btn)

	var th_btn := Button.new()
	th_btn.text = "TH"
	th_btn.custom_minimum_size = Vector2(36, 26)
	th_btn.add_theme_font_size_override("font_size", 11)
	hdr.add_child(th_btn)

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(30, 28)
	close_btn.pressed.connect(func(): _set_help_dialog_visible(false))
	hdr.add_child(close_btn)

	var tab_bar := HBoxContainer.new()
	tab_bar.add_theme_constant_override("separation", 6)
	vbox.add_child(tab_bar)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var content_root := VBoxContainer.new()
	content_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_root.add_theme_constant_override("separation", 10)
	scroll.add_child(content_root)

	var pages: Array[VBoxContainer] = []
	var tab_btns: Array[Button] = []

	var add_section := func(parent: VBoxContainer, heading_txt: String, lines: Array) -> void:
		var h := Label.new()
		h.text = heading_txt
		h.add_theme_font_size_override("font_size", 13)
		h.add_theme_color_override("font_color", Color("6ce5ff"))
		parent.add_child(h)
		for ln in lines:
			var l := Label.new()
			l.text = str(ln)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.add_theme_font_size_override("font_size", 12)
			l.add_theme_color_override("font_color", Color("d2e4ef"))
			parent.add_child(l)

	var select_tab := func(idx: int) -> void:
		_help_current_tab = clampi(idx, 0, maxi(0, pages.size() - 1))
		for i in range(pages.size()):
			pages[i].visible = (i == _help_current_tab)
			if i == _help_current_tab:
				_style_accent_button(tab_btns[i], "1b4f6e", "23668f", "3b8cb8")
			else:
				tab_btns[i].remove_theme_stylebox_override("normal")
				tab_btns[i].remove_theme_stylebox_override("hover")
				tab_btns[i].remove_theme_stylebox_override("pressed")
				tab_btns[i].remove_theme_color_override("font_color")
		scroll.scroll_vertical = 0
	_help_select_tab_cb = select_tab

	var rebuild_pages := func() -> void:
		var th := (guide_lang == "th")
		title.text = "คู่มือการใช้งาน - PKS FACTORY SIMULATOR (F1)" if th else "USER GUIDE - PKS FACTORY SIMULATOR (F1)"
		if th:
			_style_accent_button(th_btn, "1b4f6e", "23668f", "3b8cb8")
			en_btn.remove_theme_stylebox_override("normal")
			en_btn.remove_theme_stylebox_override("hover")
			en_btn.remove_theme_stylebox_override("pressed")
			en_btn.remove_theme_color_override("font_color")
		else:
			_style_accent_button(en_btn, "1b4f6e", "23668f", "3b8cb8")
			th_btn.remove_theme_stylebox_override("normal")
			th_btn.remove_theme_stylebox_override("hover")
			th_btn.remove_theme_stylebox_override("pressed")
			th_btn.remove_theme_color_override("font_color")

		for c in tab_bar.get_children():
			c.queue_free()
		for c in content_root.get_children():
			c.queue_free()
		pages.clear()
		tab_btns.clear()

		# Page 0: Quick Start & Examples
		var p_quick := VBoxContainer.new()
		p_quick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p_quick.add_theme_constant_override("separation", 8)
		content_root.add_child(p_quick)
		pages.append(p_quick)
		add_section.call(
			p_quick,
			"1. เริ่มต้นใช้งานด่วน (Quick Start)" if th else "1. Quick Start",
			[
				"- เลือกโหมดควบคุมที่แถบด้านบน: Internal Ladder PLC, Modbus TCP (Desktop), หรือ PLC:OFF",
				"- กดปุ่มสีเขียว Play/Start (หรือปุ่ม Start บนตู้ Control Cabinet) เพื่อเริ่มจำลองการทำงาน",
				"- กดปุ่ม 'Status' เพื่อดูสถานะ Coil, Input และเครื่องจักรทุกตัวแบบเรียลไทม์",
				"- กดปุ่ม 'Edit' เพื่อเพิ่ม ย้าย หมุน หรือจัดวางเครื่องจักรและพร็อพตกแต่ง",
			] if th else [
				"- Choose a controller mode on the top bar: Internal Ladder PLC, Modbus TCP (Desktop), or PLC:OFF.",
				"- Press the green Play/Start button (or Start on the Control Cabinet) to run the simulation.",
				"- Click 'Status' to monitor live Coils, Inputs, and machine states in real time.",
				"- Toggle 'Edit' to add, move, rotate, or wire factory equipment and props.",
			],
		)
		var ex_hdr := Label.new()
		ex_hdr.text = "2. โหลดโปรเจกต์ตัวอย่างสำเร็จรูป" if th else "2. Load Built-in Example Projects"
		ex_hdr.add_theme_font_size_override("font_size", 13)
		ex_hdr.add_theme_color_override("font_color", Color("6ce5ff"))
		p_quick.add_child(ex_hdr)
		var examples := [
			[
				"01 - สายพานคัดแยก Vision" if th else "01 - Vision Sorting Line",
				"สายพาน + Vision Sensor + Pusher + Reject Bin (Ladder PLC)" if th else "Conveyor + Vision Sensor + Pusher + Reject Bin (Ladder PLC)",
				"res://example/01_conveyor_sorting_line.pksfac",
			],
			[
				"02 - ควบคุมระดับน้ำในถัง" if th else "02 - Water Tank Level Control",
				"Water Tank + Pump + Solenoid Valve + Cooling Fan (Ladder PLC)" if th else "Water Tank + Pump + Solenoid Valve + Cooling Fan (Ladder PLC)",
				"res://example/02_water_tank_level_control.pksfac",
			],
			[
				"03 - สายพานเลี้ยว 90° คลังสินค้า" if th else "03 - 90° L-Turn Warehouse",
				"สายพานเลี้ยว 90° + ม่านแสงนิรภัย Light Curtain + พร็อพคลังสินค้า" if th else "L-Turn Conveyor + Safety Light Curtain + Warehouse Props",
				"res://example/03_l_turn_warehouse_line.pksfac",
			],
		]
		for ex in examples:
			var card := PanelContainer.new()
			card.add_theme_stylebox_override("panel", _ui_stylebox(Color(0.09, 0.14, 0.2, 0.9), Color("29485f"), 8, 1, 12, 8))
			p_quick.add_child(card)
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			card.add_child(row)
			var info_col := VBoxContainer.new()
			info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(info_col)
			var ex_name := Label.new()
			ex_name.text = str(ex[0])
			ex_name.add_theme_font_size_override("font_size", 12)
			ex_name.add_theme_color_override("font_color", Color("eef7fa"))
			info_col.add_child(ex_name)
			var ex_desc := Label.new()
			ex_desc.text = str(ex[1])
			ex_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			ex_desc.add_theme_font_size_override("font_size", 11)
			ex_desc.add_theme_color_override("font_color", Color("9cb3c4"))
			info_col.add_child(ex_desc)
			var load_ex_btn := Button.new()
			load_ex_btn.text = "โหลด" if th else "Load"
			load_ex_btn.custom_minimum_size = Vector2(72, 30)
			_style_accent_button(load_ex_btn, "1e6b45", "278758", "3eb87a")
			var ex_path := str(ex[2])
			var ex_title := str(ex[0])
			load_ex_btn.pressed.connect(
				func():
					if _load_project_from_path(ex_path):
						_set_help_dialog_visible(false)
						if is_instance_valid(sandbox_label):
							sandbox_label.text = "Loaded Example: " + ex_title,
			)
			row.add_child(load_ex_btn)

		# Page 1: Controls
		var p_ctrl := VBoxContainer.new()
		p_ctrl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p_ctrl.add_theme_constant_override("separation", 8)
		p_ctrl.visible = false
		content_root.add_child(p_ctrl)
		pages.append(p_ctrl)
		add_section.call(
			p_ctrl,
			"การควบคุมมุมกล้อง (Camera)" if th else "Camera Navigation",
			[
				"- คลิกขวาค้าง + ลาก: หมุนมุมกล้องรอบโรงงาน (Orbit)",
				"- คลิกกลางค้าง + ลาก: เลื่อนมุมกล้อง (Pan)",
				"- ลูกล้อเมาส์ (Scroll Wheel): ซูมเข้า / ซูมออก",
				"- ปุ่ม R: รีเซ็ตมุมกล้องกลับสู่มุมมองเริ่มต้น",
				"- ปุ่ม F11: สลับโหมดเต็มหน้าจอ (Fullscreen)",
			] if th else [
				"- Right-Click + Drag: Orbit camera around the factory floor.",
				"- Middle-Click + Drag: Pan camera horizontally / vertically.",
				"- Mouse Scroll Wheel: Zoom in and out.",
				"- R Key: Reset camera back to the default overview.",
				"- F11 Key: Toggle fullscreen mode.",
			],
		)
		add_section.call(
			p_ctrl,
			"การควบคุม Simulation & หน้าต่าง" if th else "Simulation & Panels",
			[
				"- ปุ่ม Play / Stop: เริ่มหรือหยุดฟิสิกส์, การสแกน PLC และ NPC",
				"- ปุ่ม Status: เปิด/ปิดตารางแสดงสถานะ I/O ของอุปกรณ์ทั้งหมด",
				"- ปุ่ม Sound: เปิด/ปิดเสียงเอฟเฟกต์ทั้งหมดในโรงงาน",
				"- ปุ่ม F1: เปิดหรือปิดหน้าต่างคู่มือนี้ได้ทุกเมื่อ",
				"- ปุ่ม Esc: ยกเลิกการวางวัตถุหรือปิดหน้าต่างที่เปิดอยู่",
			] if th else [
				"- Play / Stop button: Start or pause physics, PLC scan, and NPC patrols.",
				"- Status button: Toggle the Object Status & I/O live monitor panel.",
				"- Sound button: Mute or unmute factory audio.",
				"- F1 Key: Open or close this User Guide at any time.",
				"- Esc Key: Cancel object placement or close active dialogs.",
			],
		)

		# Page 2: Edit Mode
		var p_edit := VBoxContainer.new()
		p_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p_edit.add_theme_constant_override("separation", 8)
		p_edit.visible = false
		content_root.add_child(p_edit)
		pages.append(p_edit)
		add_section.call(
			p_edit,
			"การสร้างและแก้ไขเลย์เอาต์ (Edit Mode)" if th else "Building & Layout Editing",
			[
				"- กดปุ่ม 'Edit' เพื่อเข้าโหมดแก้ไข (ระบบจะหยุด Simulation อัตโนมัติ)",
				"- คลิกขวา (ไม่ลาก): เปิดหน้าต่าง 'Add Factory Object' เพื่อเลือกวางอุปกรณ์",
				"- คลิกขวาขณะกำลังวางวัตถุ: ยกเลิกการวางและกลับสู่โหมด Select ทันที",
				"- คลิกซ้ายเลือกวัตถุ และลากซ้ายเพื่อย้ายตำแหน่งบนตาราง Grid",
				"- Shift + ลากซ้าย (หรือกด Q / E): หมุนวัตถุทีละ 90°",
				"- ปุ่ม PageUp / PageDown: ปรับระดับความสูง (แกน Z)",
				"- ปุ่ม Delete: ลบวัตถุที่เลือกอยู่",
				"- Ctrl+Z / Ctrl+Y (หรือ Ctrl+Shift+Z): ย้อนกลับ (Undo) และทำซ้ำ (Redo)",
			] if th else [
				"- Click 'Edit' on the top toolbar to enter Edit Mode (simulation pauses safely).",
				"- Right-Click (without dragging): Open 'Add Factory Object'.",
				"- Right-Click while placing an object: Cancel placement and return to Select mode.",
				"- Left-Click an object to select it; Left-Drag to move it on the grid.",
				"- Shift + Left-Drag (or Q / E keys): Rotate selected or placing object in 90° steps.",
				"- PageUp / PageDown: Adjust vertical height offset (Z).",
				"- Delete Key: Remove selected object.",
				"- Ctrl+Z / Ctrl+Y (or Ctrl+Shift+Z): Undo and Redo layout edits.",
			],
		)
		add_section.call(
			p_edit,
			"การบันทึกโปรเจกต์และขนาดพื้นโรงงาน" if th else "Projects & Environment",
			[
				"- ใช้ Open / Save / Save As เพื่อบันทึกฉากและโค้ด PLC เป็นไฟล์ .pksfac",
				"- กดปุ่มขนาดพื้น (เช่น 40×40) เพื่อปรับขนาดโรงงานและเปลี่ยนธีม Decor",
			] if th else [
				"- Use Open / Save / Save As to store complete layouts + PLC programs as .pksfac files.",
				"- Click the Floor Size button (e.g. 40×40) to resize the workspace or change Decor Theme.",
			],
		)

		# Page 3: PLC & Modbus
		var p_plc := VBoxContainer.new()
		p_plc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p_plc.add_theme_constant_override("separation", 8)
		p_plc.visible = false
		content_root.add_child(p_plc)
		pages.append(p_plc)
		add_section.call(
			p_plc,
			"โหมดควบคุม PLC (Controller Modes)" if th else "Controller Modes",
			[
				"- PLC:OFF: อุปกรณ์ Actuator ทั้งหมด (สายพาน, Pusher, Valve ฯลฯ) จะหยุดนิ่ง ยกเว้นกด Force ON เอง ส่วน Sensor ยังตรวจจับตามจริง",
				"- Internal Ladder PLC: ซอฟต์แวร์ PLC ในตัว รองรับภาษา Mitsubishi (X0/Y0/M0/T0/C0) และ IEC (%IX0.0/%QX0.0) ใช้งานได้ทั้ง Desktop และ Web",
				"- Modbus TCP (เฉพาะ Desktop): เชื่อมต่อ PLC ภายนอกหรือ Python/Node-RED ผ่าน Modbus TCP Server (พอร์ต 1502) หรือ Client",
			] if th else [
				"- PLC:OFF: All actuators (Conveyors, Pushers, Valves, etc.) remain stopped unless manually Forced ON. Sensors still detect parts.",
				"- Internal Ladder PLC: Built-in soft PLC supporting Mitsubishi (X0/Y0/M0/T0/C0) and IEC (%IX0.0/%QX0.0) syntax. Works on both Desktop and Web.",
				"- Modbus TCP (Desktop only): Connect external PLCs or Python/Node-RED scripts via Modbus TCP Server (port 1502) or Client mode.",
			],
		)
		add_section.call(
			p_plc,
			"การผูก I/O และการทดสอบ Force" if th else "I/O Mapping & Force Panel",
			[
				"- เปิดหน้าต่าง 'Modbus' เพื่อกำหนดเลข Address ของ Coil (DO), Discrete Input (DI), และ Register (IR/HR)",
				"- คลิกเลือกเครื่องจักรใดก็ได้เพื่อเปิดแถบ Force ด้านขวาสำหรับทดลองสั่ง ON/OFF ด้วยมือ",
			] if th else [
				"- Open 'Modbus' to assign Coil (DO), Discrete Input (DI), and Register (IR/HR) addresses.",
				"- Select any machine to open the right-side Force panel and test outputs manually.",
			],
		)

		# Page 4: NPCs & Props
		var p_npc := VBoxContainer.new()
		p_npc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p_npc.add_theme_constant_override("separation", 8)
		p_npc.visible = false
		content_root.add_child(p_npc)
		pages.append(p_npc)
		add_section.call(
			p_npc,
			"ตัวละคร NPC อัตโนมัติในโรงงาน" if th else "Autonomous Factory NPCs",
			[
				"- Operator: เดินตรวจสายพาน, Emitter, Pusher, Stopper และเครื่องจักรหลัก",
				"- Supervisor (Tester): ตรวจ Sensor, Turn Table, Control Cabinet และถังน้ำ",
				"- Safety: เฝ้าระวัง Light Curtain, Stack Light, E-STOP และวิ่งไปจุดแจ้งเตือนทันทีเมื่อเกิด Alert",
				"- Maintenance: ตรวจปั๊มน้ำ, พัดลม, Solenoid Valve และ Water Tank",
				"- QC Inspector: ตรวจ Vision/RGB Sensor, Reject Bin และ Remover",
			] if th else [
				"- Operator: Patrols conveyors, emitters, pushers, stoppers, and process units.",
				"- Supervisor (Tester): Audits sensors, turn tables, cabinets, and tanks.",
				"- Safety: Monitors light curtains, stack lights, E-STOP, and responds immediately to alerts.",
				"- Maintenance: Checks pumps, fans, solenoid valves, and water tanks.",
				"- QC Inspector: Checks vision/RGB sensors, reject bins, and removers.",
			],
		)
		add_section.call(
			p_npc,
			"พฤติกรรมและการตั้งค่า NPC" if th else "NPC Behavior & Settings",
			[
				"- NPC เดินอ้อมสิ่งกีดขวางด้วย A* Pathfinding และแวะพัก/ลงบันทึกที่ QC Desk, Production Board, Workbench หรือ Locker เมื่อตรวจครบรอบ",
				"- เมื่อกด STOP หรือเข้า Edit Mode ตัวละคร NPC จะหยุดเดินและยืน Standby ทันที",
				"- กดปุ่ม 'NPCs' ด้านล่างเพื่อเปิด/ปิดรายตัว ปรับความเร็ว ปิดแชท หรือปิดเสียง NPC แยกจากเครื่องจักร",
			] if th else [
				"- NPCs automatically avoid props/equipment using A* pathfinding and take brief shift breaks at QC Desk, Production Board, Workbench, or Locker stations.",
				"- In STOP Mode or Edit Mode, NPCs pause immediately and stand idle.",
				"- Click 'NPCs' on the bottom bar to toggle roles, walk speed, chat bubbles, or mute NPC sounds separately.",
			],
		)

		# Page 5: Ladder Guide (Detailed)
		var p_ladder := VBoxContainer.new()
		p_ladder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p_ladder.add_theme_constant_override("separation", 8)
		p_ladder.visible = false
		content_root.add_child(p_ladder)
		pages.append(p_ladder)
		add_section.call(
			p_ladder,
			"1. หลักการทำงานของ PLC (Scan Cycle) & ข้อควรระวัง" if th else "1. PLC Scan Cycle & Best Practices",
			[
				"PLC ทำงานวนซ้ำต่อเนื่องเป็นรอบเรียกว่า Scan Cycle ประกอบด้วย 3 ขั้นตอน:",
				"  ขั้นที่ 1 - อ่านอินพุต (Read Inputs): อ่านค่าเซ็นเซอร์ ปุ่มกด และค่าแอนะล็อกทั้งหมด (X / %IX / IW)",
				"  ขั้นที่ 2 - ประมวลผลลอจิก (Execute Logic): รันคำสั่งทีละบรรทัดจากบนลงล่างจนถึง END",
				"  ขั้นที่ 3 - ส่งเอาต์พุต (Write Outputs): อัปเดตคอยล์ มอเตอร์ สายพาน และไฟสถานะ (Y / %QX / QW)",
				"ข้อควรระวัง (Double Coil): ห้ามใช้คำสั่ง OUT Y0 ซ้ำกัน 2 จุดในโปรแกรมเดียว เพราะบรรทัดล่างจะทับค่าบรรทัดบน ให้รวมเงื่อนไขด้วย OR / M-bit หรือใช้ SET / RST แทน",
			] if th else [
				"A PLC executes your program repeatedly in a continuous loop (Scan Cycle):",
				"  Step 1 - Read Inputs: Snapshots all sensors, buttons, and analog inputs (X / %IX / IW).",
				"  Step 2 - Execute Logic: Evaluates rungs top-to-bottom from line 1 until END.",
				"  Step 3 - Write Outputs: Updates all coils, actuators, lamps, and registers (Y / %QX / QW).",
				"Rule of Thumb: Avoid writing to the same output coil (OUT Y0) twice in one program (Double Coil). Combine conditions with OR/M-bits instead, or use SET / RST.",
			],
		)
		add_section.call(
			p_ladder,
			"2. ตารางอ้างอิงแอดเดรส (FX3U vs OpenPLC IEC)" if th else "2. Addressing Reference (FX3U vs OpenPLC IEC)",
			[
				"- อินพุตดิจิทัล (DI):   X0..X7, X10.. (ฐาน 8)   |  IEC: %IX0.0 .. %IX0.7, %IX1.0..",
				"- เอาต์พุตดิจิทัล (DO): Y0..Y7, Y10.. (ฐาน 8)   |  IEC: %QX0.0 .. %QX0.7, %QX1.0..",
				"- รีเลย์ช่วยภายใน:      M0 .. M255              |  IEC: %MX0.0 .. %MX31.7",
				"- ตัวตั้งเวลา / ตัวนับ: T0 .. T63 (ฐาน 100ms)   |  C0 .. C63 (นับขึ้น/นับลง)",
				"- รีจิสเตอร์คำ (Word):  IW0 (Input Reg), QW0 (Holding Reg), D0..D127 (Data), K100 (ค่าคงที่)",
				"ทิป: ใช้หน้าต่าง 'Modbus' เพื่อผูกเลข Coil/Input/Register ของเครื่องจักรให้ตรงกับแอดเดรสในแลดเดอร์",
			] if th else [
				"- Digital Inputs (DI):  X0..X7, X10.. (octal)   |  IEC: %IX0.0 .. %IX0.7, %IX1.0..",
				"- Digital Outputs (DO): Y0..Y7, Y10.. (octal)   |  IEC: %QX0.0 .. %QX0.7, %QX1.0..",
				"- Internal Memory Bits: M0 .. M255              |  IEC: %MX0.0 .. %MX31.7",
				"- Timers & Counters:    T0 .. T63 (100ms base)  |  C0 .. C63 (Up/Down counters)",
				"- Word / Analog Regs:   IW0 (Input Reg), QW0 (Holding Reg), D0..D127 (Data), K100 (Constant)",
				"Tip: Use 'Modbus' dialog to map each machine's Coil/Input/Register address to your Ladder tags.",
			],
		)
		add_section.call(
			p_ladder,
			"3. คำสั่งทั้งหมดที่ SoftPLC รองรับ (Instruction Set)" if th else "3. Complete Instruction Set (SoftPLC)",
			[
				"[Bit Logic]  LD / LDN(LDI) = เริ่มแถว NO/NC  |  LDP / LDF = ตรวจจับขอบขาขึ้น / ขาลง",
				"             AND / ANDN(ANI) / ANDP / ANDF = ต่ออนุกรม  |  OR / ORN(ORI) / ORP / ORF = ต่อขนาน",
				"[Branching]  MPS (เก็บค่า) / MRD (อ่านค่า) / MPP (ดึงออก)  |  AND( ... ) / OR( ... ) = วงเล็บกลุ่ม",
				"[Outputs]    OUT Y0 = สั่งคอยล์ทำงาน  |  SET Y0 / M0 = ค้างสถานะ ON  |  RST Y0 / M0 / T0 / C0 = รีเซ็ต",
				"[Timers]     TON T0 PT=2000ms หรือ OUT T0 K20 (20 x 100ms = 2.0s)  |  TOF T0 PT=1500ms (หน่วงดับ)",
				"[Counters]   CTU C0 PV=5 หรือ OUT C0 K5 (นับขึ้น)  |  CTD C0 PV=5 (นับลง)  |  RST C0 (ล้างค่านับ)",
				"[Compare]    LD= / LD> / LD< / LD>= / LD<= / LD<> (มีแบบ AND/OR ด้วย) เช่น LD>= IW0 K85",
				"[Data/End]   MOV <src> <dst> (เช่น MOV IW0 QW0 หรือ MOV K100 D0)  |  END = จบรอบสแกน",
			] if th else [
				"[Bit Logic]  LD / LDN(LDI) = Start rung NO/NC  |  LDP / LDF = Rising / Falling edge",
				"             AND / ANDN(ANI) / ANDP / ANDF = Series logic  |  OR / ORN(ORI) / ORP / ORF = Parallel",
				"[Branching]  MPS (push) / MRD (read) / MPP (pop)  |  AND( ... ) / OR( ... ) = Block grouping",
				"[Outputs]    OUT Y0 = Energize coil  |  SET Y0 / M0 = Latch ON  |  RST Y0 / M0 / T0 / C0 = Reset",
				"[Timers]     TON T0 PT=2000ms  or  OUT T0 K20 (20 x 100ms = 2.0s)  |  TOF T0 PT=1500ms (Off-delay)",
				"[Counters]   CTU C0 PV=5  or  OUT C0 K5 (Count Up)  |  CTD C0 PV=5 (Count Down)  |  RST C0",
				"[Compare]    LD= / LD> / LD< / LD>= / LD<= / LD<> (also AND>, OR<, etc.) e.g. LD>= IW0 K85",
				"[Data/End]   MOV <src> <dst> (e.g. MOV IW0 QW0 or MOV K100 D0)  |  END = End of scan",
			],
		)
		var pat_hdr := Label.new()
		pat_hdr.text = "4. วงจรมาตรฐานพร้อมทดลอง (กด 'โหลดลง Editor' เพื่อทดสอบ)" if th else "4. Standard Ladder Patterns (Click 'Load into Editor' to test)"
		pat_hdr.add_theme_font_size_override("font_size", 13)
		pat_hdr.add_theme_color_override("font_color", Color("6ce5ff"))
		p_ladder.add_child(pat_hdr)

		var ladder_patterns := [
			[
				"วงจร Start-Stop แบบล็อกสถานะ (Seal-In Latch)" if th else "Start-Stop Seal-In Latch",
				"X0=ปุ่ม Start, X1=ปุ่ม Stop, Y0=มอเตอร์/สายพาน (ค้างทำงานจนกว่าจะกด Stop)" if th else "X0=Start (NO), X1=Stop (NC/Press to stop), Y0=Motor/Conveyor",
				"// Start-Stop Seal-In Latch\nLD X0\nOR Y0\nANI X1\nOUT Y0\nEND\n",
			],
			[
				"วงจรหน่วงเวลาเปิด (On-Delay Timer - 2.0s)" if th else "On-Delay Timer (TON - 2.0s)",
				"เมื่อ X0 ติดค้างครบ 2.0 วินาที (K20 = 20x100ms) ตัวจับเวลา T0 จะสั่งเปิด Y0" if th else "When X0 stays ON for 2.0s (K20 = 20x100ms), T0 turns ON Y0",
				"// On-Delay Timer (2.0s)\nLD X0\nOUT T0 K20\nLD T0\nOUT Y0\nEND\n",
			],
			[
				"วงจรนับจำนวนชิ้นงาน (Batch Counter + Reset)" if th else "Batch Counter (Count 5 + Reset)",
				"นับสัญญาณขาขึ้นที่ X0 ครบ 5 ครั้ง -> เปิด Y1; กด X1 เพื่อรีเซ็ตตัวนับ C0" if th else "Counts 5 rising edges on X0 -> energizes Y1; X1 resets C0",
				"// Batch Counter (PV=5)\nLDP X0\nOUT C0 K5\nLD C0\nOUT Y1\nLD X1\nRST C0\nEND\n",
			],
			[
				"วงจรคุมระดับน้ำแบบช่วง (Tank Hysteresis)" if th else "Water Tank Hysteresis (Comparator)",
				"สั่งปั๊ม Y0 ทำงานเมื่อระดับน้ำ IW0 < 30% และหยุดเมื่อ IW0 >= 85%" if th else "Start Pump Y0 when Level IW0 < 30%, stop when IW0 >= 85%",
				"// Water Tank Hysteresis\nLD< IW0 K30\nSET Y0\nLD>= IW0 K85\nRST Y0\nEND\n",
			],
			[
				"วงจรตรวจจับขอบขาขึ้น (One-Shot Edge Trigger)" if th else "One-Shot Edge Trigger (LDP + SET/RST)",
				"จับจังหวะกด X0 เพื่อค้าง M0 และจับจังหวะกด X1 เพื่อสั่งรีเซ็ต M0" if th else "Rising edge on X0 latches M0; rising edge on X1 resets M0",
				"// Edge Trigger Latch\nLDP X0\nSET M0\nLDP X1\nRST M0\nLD M0\nOUT Y0\nEND\n",
			],
		]
		for pat in ladder_patterns:
			var card := PanelContainer.new()
			card.add_theme_stylebox_override("panel", _ui_stylebox(Color(0.09, 0.14, 0.2, 0.9), Color("29485f"), 8, 1, 12, 8))
			p_ladder.add_child(card)
			var pv := VBoxContainer.new()
			pv.add_theme_constant_override("separation", 4)
			card.add_child(pv)
			var top_r := HBoxContainer.new()
			top_r.add_theme_constant_override("separation", 8)
			pv.add_child(top_r)
			var t_col := VBoxContainer.new()
			t_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			top_r.add_child(t_col)
			var p_name := Label.new()
			p_name.text = str(pat[0])
			p_name.add_theme_font_size_override("font_size", 12)
			p_name.add_theme_color_override("font_color", Color("eef7fa"))
			t_col.add_child(p_name)
			var p_desc := Label.new()
			p_desc.text = str(pat[1])
			p_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p_desc.add_theme_font_size_override("font_size", 11)
			p_desc.add_theme_color_override("font_color", Color("9cb3c4"))
			t_col.add_child(p_desc)
			var load_pat_btn := Button.new()
			load_pat_btn.text = "โหลดลง Editor" if th else "Load into Editor"
			load_pat_btn.custom_minimum_size = Vector2(118, 28)
			load_pat_btn.add_theme_font_size_override("font_size", 11)
			_style_accent_button(load_pat_btn, "1e6b45", "278758", "3eb87a")
			var pat_code := str(pat[2])
			load_pat_btn.pressed.connect(
				func():
					if is_instance_valid(ladder_code_edit):
						ladder_code_edit.text = pat_code
						_apply_ladder_code(true)
					_set_controller_mode(2, true)
					_set_help_dialog_visible(false)
					_set_ladder_dialog_visible(true),
			)
			top_r.add_child(load_pat_btn)
			var code_lbl := Label.new()
			code_lbl.text = str(pat[2]).strip_edges()
			code_lbl.add_theme_font_size_override("font_size", 11)
			code_lbl.add_theme_color_override("font_color", Color("8ce8ff"))
			pv.add_child(code_lbl)

		var tab_names := (
			["เริ่มต้น", "ควบคุม", "Edit Mode", "PLC & Modbus", "NPC & Props", "คู่มือ Ladder"]
			if th
			else ["Quick Start", "Controls", "Edit Mode", "PLC & Modbus", "NPCs & Props", "Ladder Guide"]
		)
		for i in range(tab_names.size()):
			var tbtn := Button.new()
			tbtn.text = tab_names[i]
			tbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tbtn.custom_minimum_size = Vector2(0, 30)
			tbtn.add_theme_font_size_override("font_size", 11)
			var tab_i := i
			tbtn.pressed.connect(func(): select_tab.call(tab_i))
			tab_bar.add_child(tbtn)
			tab_btns.append(tbtn)
		select_tab.call(_help_current_tab)

	_help_rebuild_cb = rebuild_pages
	en_btn.pressed.connect(
		func():
			if guide_lang != "en":
				guide_lang = "en"
				rebuild_pages.call()
				_save_settings(),
	)
	th_btn.pressed.connect(
		func():
			if guide_lang != "th":
				guide_lang = "th"
				rebuild_pages.call()
				_save_settings(),
	)
	rebuild_pages.call()


func _build_object_dialog(ui_root: Control) -> void:
	object_dialog_backdrop = ColorRect.new()
	object_dialog_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	object_dialog_backdrop.color = Color(0.02, 0.04, 0.06, 0.45)
	object_dialog_backdrop.visible = false
	object_dialog_backdrop.gui_input.connect(
		func(event: InputEvent):
			if (
				event is InputEventMouseButton and event.pressed
				and event.button_index == MOUSE_BUTTON_LEFT
			):
				_set_object_dialog_visible(false),
	)
	ui_root.add_child(object_dialog_backdrop)

	object_dialog = PanelContainer.new()
	object_dialog.set_anchors_preset(Control.PRESET_CENTER)
	object_dialog.custom_minimum_size = Vector2(640, 560)
	object_dialog.offset_left = -320
	object_dialog.offset_right = 320
	object_dialog.offset_top = -280
	object_dialog.offset_bottom = 280
	var dialog_style := _ui_stylebox(
		Color(0.068, 0.106, 0.149, 0.97),
		Color("36566e"),
		14,
		1,
		18,
		16,
	)
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
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(30, 28)
	close_btn.pressed.connect(
		func():
			_set_object_dialog_visible(false),
	)
	header.add_child(close_btn)

	var tab_bar := HBoxContainer.new()
	tab_bar.add_theme_constant_override("separation", 6)
	vbox.add_child(tab_bar)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var list_vbox := VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(list_vbox)

	var categories := [
		[
			"CONVEYORS & HANDLING",
			[
				["Conveyor Belt", "9.0m straight belt", "conveyor"],
				["Short Conveyor (3m)", "3.0m compact belt", "conveyor_short"],
				["Turn Table", "90° pop-up transfer", "turn"],
				["Box Emitter", "Spawns boxes when active", "emitter"],
				["Box Remover", "Removes boxes at belt end", "remover"],
				["Reject Bin", "Compact chute for pusher", "reject_bin"],
			],
		],
		[
			"SENSORS & SAFETY",
			[
				["Photo Sensor", "Optical beam detector", "sensor"],
				["Vision Sensor", "Detects box type (All/Box/Crate)", "vision_sensor"],
				["RGB Sensor", "Detects box color (ID 1..6)", "rgb_sensor"],
				["Light Curtain", "Safety beam (boxes & NPCs)", "light_curtain"],
			],
		],
		[
			"PROCESS & ACTUATORS",
			[
				["Pusher", "Pneumatic diverter", "pusher"],
				["Pneumatic Stopper", "Queue gate before turn", "stopper"],
				["Motor Fan", "Industrial cooling fan (1 coil)", "motor_fan"],
				["Centrifugal Pump", "Industrial fluid pump (1 coil)", "pump"],
				["Water Tank", "Tank + L/M/H sensors + Pump + Outlet Valve", "water_tank"],
				["Solenoid Valve", "Electric fluid valve (1 coil)", "solenoid_valve"],
			],
		],
		[
			"CONTROL & SIGNAL",
			[
				["Stack Light", "3-color signal tower (3 coils)", "stack_light"],
				["Control Cabinet", "Buttons, stack light & gauge", "cabinet"],
			],
		],
		[
			"PRODUCTS",
			[
				["Cardboard Box", "Standard carton", "box"],
				["Plastic Crate", "Euro stackable crate", "box_plastic"],
				["Small Box", "Compact parcel carton", "box_small"],
				["Metal Crate", "Heavy steel industrial crate", "box_metal"],
				["Pallet", "Wooden Euro pallet", "pallet"],
				["Workpiece", "Machined metal part", "workpiece"],
			],
		],
		[
			"PROPS / DECOR",
			[
				["Pallet Rack", "2-tier warehouse storage rack", "prop_rack"],
				["Safety Barrier", "Yellow industrial guardrail", "prop_barrier"],
				["Steel Drum", "Industrial storage barrel", "prop_barrel"],
				["Workbench", "Steel frame shop table", "prop_workbench"],
				["Forklift", "Warehouse counterbalance forklift", "prop_forklift"],
				["Pallet Stack", "Stacked Euro pallets & cartons", "prop_pallet_stack"],
				["Pallet Jack", "Manual hydraulic pallet truck", "prop_pallet_jack"],
				["Safety Bollard", "Yellow-black steel corner post", "prop_bollard"],
				["Safety Sign", "A-frame caution floor stand", "prop_safety_sign"],
				["QC Desk", "Inspection table with monitor", "prop_qc_desk"],
				["Production Board", "KPI whiteboard on rolling stand", "prop_production_board"],
				["Locker Station", "3-bay PPE & staff locker", "prop_locker"],
			],
		],
	]

	var cat_sections: Array[Dictionary] = []
	for cat in categories:
		var section := VBoxContainer.new()
		section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		section.add_theme_constant_override("separation", 6)
		list_vbox.add_child(section)

		var cat_label := Label.new()
		cat_label.text = cat[0]
		cat_label.add_theme_font_size_override("font_size", 11)
		cat_label.add_theme_color_override("font_color", Color("7ea7c2"))
		section.add_child(cat_label)

		var grid := GridContainer.new()
		grid.columns = 2
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		section.add_child(grid)

		for item in cat[1]:
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(280, 82)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var card := HBoxContainer.new()
			card.set_anchors_preset(Control.PRESET_FULL_RECT)
			card.offset_left = 8
			card.offset_right = -8
			card.offset_top = 6
			card.offset_bottom = -6
			card.add_theme_constant_override("separation", 10)
			card.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(card)

			var kind: String = item[2]
			card.add_child(_create_object_thumbnail(kind))

			var text_col := VBoxContainer.new()
			text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			text_col.alignment = BoxContainer.ALIGNMENT_CENTER
			text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(text_col)

			var title_lbl := Label.new()
			title_lbl.text = item[0]
			title_lbl.add_theme_font_size_override("font_size", 13)
			title_lbl.add_theme_color_override("font_color", Color("eef7fa"))
			title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			text_col.add_child(title_lbl)

			var desc_lbl := Label.new()
			desc_lbl.text = item[1]
			desc_lbl.add_theme_font_size_override("font_size", 11)
			desc_lbl.add_theme_color_override("font_color", Color("95b2c7"))
			desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			text_col.add_child(desc_lbl)

			btn.pressed.connect(
				func():
					_set_object_dialog_visible(false)
					_enter_edit_mode()
					_set_placement(kind),
			)
			grid.add_child(btn)
		cat_sections.append({"name": cat[0], "node": section})

	var tab_defs := [
		["All", "ALL"],
		["Conveyors", "CONVEYORS & HANDLING"],
		["Sensors", "SENSORS & SAFETY"],
		["Process", "PROCESS & ACTUATORS"],
		["Control", "CONTROL & SIGNAL"],
		["Products", "PRODUCTS"],
		["Props", "PROPS / DECOR"],
	]
	var tab_buttons: Array[Button] = []
	for tdef in tab_defs:
		var tbtn := Button.new()
		tbtn.text = tdef[0]
		tbtn.custom_minimum_size = Vector2(0, 28)
		tbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tbtn.add_theme_font_size_override("font_size", 11)
		var filter_key: String = tdef[1]
		tbtn.pressed.connect(
			func():
				for b in tab_buttons:
					b.remove_theme_stylebox_override("normal")
					b.remove_theme_stylebox_override("hover")
					b.remove_theme_color_override("font_color")
				_style_accent_button(tbtn, "1b4f6e", "23668f", "3b8cb8")
				for sec in cat_sections:
					var sec_node := sec["node"] as Control
					sec_node.visible = (filter_key == "ALL" or sec["name"] == filter_key)
				scroll.scroll_vertical = 0,
		)
		tab_bar.add_child(tbtn)
		tab_buttons.append(tbtn)
	if tab_buttons.size() > 0:
		_style_accent_button(tab_buttons[0], "1b4f6e", "23668f", "3b8cb8")


func _set_modbus_dialog_visible(visible_state: bool) -> void:
	if visible_state:
		_refresh_modbus_dialog()
	else:
		_save_settings()
		_refresh_io_status_list()
		_refresh_transform_controls()
	if is_instance_valid(modbus_dialog_backdrop):
		modbus_dialog_backdrop.visible = visible_state
	if is_instance_valid(modbus_dialog):
		modbus_dialog.visible = visible_state


func _build_modbus_dialog(ui_root: Control) -> void:
	modbus_dialog_backdrop = ColorRect.new()
	modbus_dialog_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	modbus_dialog_backdrop.color = Color(0.02, 0.04, 0.06, 0.45)
	modbus_dialog_backdrop.visible = false
	modbus_dialog_backdrop.gui_input.connect(
		func(event: InputEvent):
			if (
				event is InputEventMouseButton and event.pressed
				and event.button_index == MOUSE_BUTTON_LEFT
			):
				_set_modbus_dialog_visible(false),
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

	modbus_enabled_check = CheckBox.new()
	modbus_enabled_check.text = "Enable Modbus"
	modbus_enabled_check.tooltip_text = "Enable external Modbus TCP (automatically disables Internal Ladder PLC)"
	modbus_enabled_check.button_pressed = ModbusTCP.enabled
	modbus_enabled_check.toggled.connect(
		func(pressed: bool):
			_set_controller_mode(1 if pressed else 0, true),
	)
	header.add_child(modbus_enabled_check)

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(30, 28)
	close_btn.pressed.connect(
		func():
			_set_modbus_dialog_visible(false),
	)
	header.add_child(close_btn)

	# Mode + Server/Client settings row
	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 8)
	vbox.add_child(mode_row)

	var mode_lbl := Label.new()
	mode_lbl.text = "Mode:"
	mode_row.add_child(mode_lbl)

	modbus_mode_option = OptionButton.new()
	modbus_mode_option.add_item("Server (Slave)", 0)
	modbus_mode_option.add_item("Client (Master)", 1)
	modbus_mode_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modbus_mode_option.item_selected.connect(
		func(idx: int):
			var is_client := idx == 1
			modbus_ip_label.text = "PLC IP:" if is_client else "Bind IP:"
			modbus_ip_input.text = ModbusTCP.remote_host if is_client else ModbusTCP.bind_address
			modbus_port_input.value = ModbusTCP.remote_port if is_client else ModbusTCP.port,
	)
	mode_row.add_child(modbus_mode_option)

	var poll_lbl := Label.new()
	poll_lbl.text = "Poll:"
	mode_row.add_child(poll_lbl)

	modbus_poll_input = SpinBox.new()
	modbus_poll_input.min_value = 5
	modbus_poll_input.max_value = 1000
	modbus_poll_input.step = 5
	modbus_poll_input.suffix = " ms"
	modbus_poll_input.value = int(round(ModbusTCP.poll_interval * 1000.0))
	modbus_poll_input.custom_minimum_size.x = 96
	modbus_poll_input.tooltip_text = "Client mode polling interval (ms)"
	mode_row.add_child(modbus_poll_input)

	var srv_row := HBoxContainer.new()
	srv_row.add_theme_constant_override("separation", 8)
	vbox.add_child(srv_row)

	modbus_ip_label = Label.new()
	modbus_ip_label.text = "Bind IP:"
	srv_row.add_child(modbus_ip_label)

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

	modbus_restart_btn = Button.new()
	modbus_restart_btn.text = "Apply & Restart"
	_style_accent_button(modbus_restart_btn, "1b4f6e", "23668f", "3b8cb8")
	modbus_restart_btn.pressed.connect(_apply_modbus_server_settings)
	srv_row.add_child(modbus_restart_btn)

	modbus_srv_status = Label.new()
	modbus_srv_status.add_theme_font_size_override("font_size", 12)
	vbox.add_child(modbus_srv_status)

	var profile_row := HBoxContainer.new()
	profile_row.add_theme_constant_override("separation", 8)
	vbox.add_child(profile_row)

	var prof_lbl := Label.new()
	prof_lbl.text = "PLC Profile:"
	profile_row.add_child(prof_lbl)

	modbus_profile_option = OptionButton.new()
	modbus_profile_option.add_item("OpenPLC (IEC %IX/%QX)", 0)
	modbus_profile_option.add_item("Mitsubishi FX3U (X/Y Octal, D)", 1)
	modbus_profile_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modbus_profile_option.item_selected.connect(
		func(idx: int):
			_set_plc_notation("fx3u" if idx == 1 else "iec", true),
	)
	profile_row.add_child(modbus_profile_option)

	var uid_lbl := Label.new()
	uid_lbl.text = "Unit ID:"
	profile_row.add_child(uid_lbl)

	modbus_unit_id_input = SpinBox.new()
	modbus_unit_id_input.min_value = 0
	modbus_unit_id_input.max_value = 247
	modbus_unit_id_input.step = 1
	modbus_unit_id_input.custom_minimum_size.x = 72
	modbus_unit_id_input.tooltip_text = "Server: 0 = any Unit ID | Client: Target Slave ID (1..247)"
	profile_row.add_child(modbus_unit_id_input)

	modbus_pack_di_check = CheckBox.new()
	modbus_pack_di_check.text = "Pack DI->HR"
	modbus_pack_di_check.tooltip_text = "Client mode: pack DI 0..63 into Holding Registers 0..3 (OpenPLC)"
	modbus_pack_di_check.button_pressed = ModbusTCP.client_packed_di
	profile_row.add_child(modbus_pack_di_check)

	modbus_fx_row = HBoxContainer.new()
	modbus_fx_row.add_theme_constant_override("separation", 6)
	modbus_fx_row.visible = (plc_notation == "fx3u")
	vbox.add_child(modbus_fx_row)

	var fx_off_lbl := Label.new()
	fx_off_lbl.text = "FX3U Offsets:"
	fx_off_lbl.add_theme_font_size_override("font_size", 11)
	fx_off_lbl.add_theme_color_override("font_color", Color("9cb3c4"))
	modbus_fx_row.add_child(fx_off_lbl)

	for spec in [
		["Y:", "fx_coil_offset"],
		["X:", "fx_di_offset"],
		["D(HR):", "fx_hr_offset"],
		["IR:", "fx_ir_offset"],
	]:
		var lbl := Label.new()
		lbl.text = spec[0]
		lbl.add_theme_font_size_override("font_size", 11)
		modbus_fx_row.add_child(lbl)
		var sp := SpinBox.new()
		sp.min_value = 0
		sp.max_value = 65535
		sp.step = 1
		sp.custom_minimum_size.x = 74
		sp.value = int(ModbusTCP.get(spec[1]))
		modbus_fx_row.add_child(sp)
		match spec[1]:
			"fx_coil_offset":
				modbus_fx_coil_off_input = sp
			"fx_di_offset":
				modbus_fx_di_off_input = sp
			"fx_hr_offset":
				modbus_fx_hr_off_input = sp
			"fx_ir_offset":
				modbus_fx_ir_off_input = sp

	modbus_table_title = Label.new()
	modbus_table_title.text = "OBJECT I/O ADDRESSES (IEC: %QX/%IX or FX3U: Y0/X0 Octal, D0; empty = unused)"
	modbus_table_title.add_theme_font_size_override("font_size", 11)
	modbus_table_title.add_theme_color_override("font_color", Color("7ea7c2"))
	vbox.add_child(modbus_table_title)

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

	modbus_auto_map_btn = Button.new()
	modbus_auto_map_btn.text = "Auto-Map FX3U" if plc_notation == "fx3u" else "Auto-Map IEC"
	modbus_auto_map_btn.tooltip_text = "Auto-assign I/O addresses for all objects"
	_style_accent_button(modbus_auto_map_btn, "1e6b45", "278758", "3eb87a")
	modbus_auto_map_btn.pressed.connect(_auto_map_modbus_iec)
	footer.add_child(modbus_auto_map_btn)

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
	done_btn.pressed.connect(
		func():
			_set_modbus_dialog_visible(false),
	)
	footer.add_child(done_btn)


func _set_controller_mode(mode_idx: int, save_cfg: bool = true) -> void:
	# 0 = OFF, 1 = Modbus, 2 = Ladder
	var want_modbus := mode_idx == 1
	var want_ladder := mode_idx == 2
	var want_plc := want_modbus or want_ladder
	soft_plc.enabled = want_ladder
	ModbusTCP.enabled = want_modbus
	if plc_mode != want_plc:
		_apply_plc_mode(want_plc, false)
	if want_ladder:
		_apply_ladder_code(false)
	if is_instance_valid(plc_controller_option):
		plc_controller_option.select(clampi(mode_idx, 0, 2))
	if is_instance_valid(modbus_enabled_check):
		modbus_enabled_check.set_pressed_no_signal(want_modbus)
	if is_instance_valid(ladder_enabled_check):
		ladder_enabled_check.set_pressed_no_signal(want_ladder)
	_refresh_modbus_dialog()
	_refresh_ladder_watch()
	if save_cfg:
		_save_settings()


func _set_ladder_dialog_visible(visible_state: bool) -> void:
	if visible_state:
		if is_instance_valid(ladder_enabled_check):
			ladder_enabled_check.set_pressed_no_signal(soft_plc.enabled)
		if is_instance_valid(ladder_code_edit) and ladder_code_edit.text.strip_edges().is_empty() and not soft_plc.source_code.is_empty():
			ladder_code_edit.text = soft_plc.source_code
		_refresh_ladder_watch()
	if is_instance_valid(ladder_dialog_backdrop):
		ladder_dialog_backdrop.visible = visible_state
	if is_instance_valid(ladder_dialog):
		ladder_dialog.visible = visible_state


func _get_ladder_presets() -> Dictionary:
	var tank_low := "%IX0.0"
	var tank_high := "%IX0.2"
	var tank_pump := "%QX0.0"
	var tank_iw := "%IW0"
	for obj in get_tree().get_nodes_in_group("sandbox_objects"):
		if str(obj.get_meta("kind", "")) == "water_tank":
			var in_a := int(obj.get_meta("modbus_input", -1))
			var co_a := int(obj.get_meta("modbus_coil", -1))
			var ir_a := int(obj.get_meta("modbus_input_reg", -1))
			if in_a >= 0:
				tank_low = _format_iec_address(in_a, "IX")
				tank_high = _format_iec_address(in_a + 2, "IX")
			if co_a >= 0:
				tank_pump = _format_iec_address(co_a, "QX")
			if ir_a >= 0:
				tank_iw = _format_word_address(ir_a, "IW")
			break
	return {
		"Auto Water Tank (Low/High)": """// Auto Water Tank: Pump ON below Low (%s=0), OFF at High (%s=1)
LDN %s
OR %%MX0.0
ANDN %s
ST %%MX0.0
ST %s
""" % [tank_low, tank_high, tank_low, tank_high, tank_pump],
		"Conveyor Start/Stop Latch": """// Start (%IX0.0) / Stop NC (%IX0.1) -> Conveyor (%QX0.0)
LD %IX0.0
OR %QX0.0
ANDN %IX0.1
ST %QX0.0
""",
		"Timer TON Pulse (2s)": """// Sensor %IX0.0 triggers Output %QX0.0 after 2.0s delay
LD %IX0.0
TON T0 2.0s
ST %QX0.0
""",
		"Counter CTU (5 items)": """// Count 5 rising edges on %IX0.0 -> %QX0.0 ON; %IX0.1 resets C0
LD %IX0.0
CTU C0 5
ST %QX0.0
LD %IX0.1
RST C0
""",
		"Tank Analog Compare (>80%)": """// Turn on %s when %s > 80
LD_GT %s 80
ST %s
""" % [tank_pump, tank_iw, tank_iw, tank_pump],
		"[FX3U] Start/Stop Latch (X/Y)": """// FX3U: X0=Start, X1=Stop(NC), Y0=Conveyor
LD X0
OR Y0
ANI X1
OUT Y0
END
""",
		"[FX3U] Timer 2s (OUT T0 K20)": """// FX3U: T0 uses 100ms base -> K20 = 2.0s
LD X0
OUT T0 K20
LD T0
OUT Y0
END
""",
		"[FX3U] Counter 5 (OUT C0 K5)": """// FX3U: Count 5 pulses on X0 -> Y0 ON, X1 resets C0
LD X0
OUT C0 K5
LD C0
OUT Y0
LD X1
RST C0
END
""",
		"[FX3U] Tank Compare (LD> IW0 K80)": """// FX3U: Turn on Y0 when IW0 > 80 (copy IW0 to D0)
LD X0
MOV IW0 D0
LD> D0 K80
OUT Y0
END
""",
	}


func _set_plc_notation(notation: String, save_cfg: bool = true) -> void:
	plc_notation = "fx3u" if notation == "fx3u" else "iec"
	var is_fx := plc_notation == "fx3u"
	ModbusTCP.address_profile = ModbusTCP.AddressProfile.FX3U_OFFSET if is_fx else ModbusTCP.AddressProfile.STANDARD_OPENPLC
	if is_instance_valid(modbus_profile_option):
		modbus_profile_option.select(1 if is_fx else 0)
	if is_instance_valid(ladder_notation_option):
		ladder_notation_option.select(1 if is_fx else 0)
	if is_instance_valid(modbus_fx_row):
		modbus_fx_row.visible = is_fx
	_refresh_modbus_dialog()
	_refresh_transform_controls()
	_refresh_io_status_list()
	_refresh_ladder_watch()
	if save_cfg and not test_mode and is_inside_tree():
		_save_settings()


func _build_ladder_dialog(ui_root: Control) -> void:
	ladder_dialog_backdrop = ColorRect.new()
	ladder_dialog_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	ladder_dialog_backdrop.color = Color(0.02, 0.04, 0.06, 0.45)
	ladder_dialog_backdrop.visible = false
	ladder_dialog_backdrop.gui_input.connect(
		func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_set_ladder_dialog_visible(false),
	)
	ui_root.add_child(ladder_dialog_backdrop)

	ladder_dialog = PanelContainer.new()
	ladder_dialog.set_anchors_preset(Control.PRESET_CENTER)
	ladder_dialog.custom_minimum_size = Vector2(680, 500)
	ladder_dialog.offset_left = -340
	ladder_dialog.offset_right = 340
	ladder_dialog.offset_top = -250
	ladder_dialog.offset_bottom = 250
	var style := _ui_stylebox(Color(0.063, 0.098, 0.137, 0.96), Color("294052"), 12, 1, 16, 16)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 16
	ladder_dialog.add_theme_stylebox_override("panel", style)
	ladder_dialog.visible = false
	ui_root.add_child(ladder_dialog)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	ladder_dialog.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)

	var heading := Label.new()
	heading.text = "LADDER / IL SOFT-PLC (OpenPLC & FX3U)"
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_font_size_override("font_size", 15)
	heading.add_theme_color_override("font_color", Color("eef7fa"))
	header.add_child(heading)

	ladder_notation_option = OptionButton.new()
	ladder_notation_option.add_item("OpenPLC (IEC)", 0)
	ladder_notation_option.add_item("FX3U (X/Y/D)", 1)
	ladder_notation_option.select(1 if plc_notation == "fx3u" else 0)
	ladder_notation_option.item_selected.connect(
		func(idx: int):
			_set_plc_notation("fx3u" if idx == 1 else "iec", true),
	)
	header.add_child(ladder_notation_option)

	ladder_enabled_check = CheckBox.new()
	ladder_enabled_check.text = "Enable Internal PLC"
	ladder_enabled_check.tooltip_text = "Enable Internal Ladder PLC (automatically disables external Modbus TCP)"
	ladder_enabled_check.button_pressed = soft_plc.enabled
	ladder_enabled_check.toggled.connect(
		func(pressed: bool):
			_set_controller_mode(2 if pressed else 0, true),
	)
	header.add_child(ladder_enabled_check)

	var manual_btn := Button.new()
	manual_btn.text = "Manual"
	manual_btn.tooltip_text = "Open Detailed Ladder PLC Programming Guide"
	manual_btn.custom_minimum_size = Vector2(68, 28)
	manual_btn.add_theme_font_size_override("font_size", 11)
	_style_accent_button(manual_btn, "1b4f6e", "23668f", "3b8cb8")
	manual_btn.pressed.connect(
		func():
			_set_help_dialog_visible(true, 5),
	)
	header.add_child(manual_btn)

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(30, 28)
	close_btn.pressed.connect(
		func():
			_set_ladder_dialog_visible(false),
	)
	header.add_child(close_btn)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	vbox.add_child(bar)

	var preset_lbl := Label.new()
	preset_lbl.text = "Preset:"
	preset_lbl.add_theme_font_size_override("font_size", 12)
	bar.add_child(preset_lbl)

	var presets := _get_ladder_presets()
	var preset_opt := OptionButton.new()
	preset_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preset_opt.add_item("-- Select Example Preset --", 0)
	var p_names := presets.keys()
	for i in range(p_names.size()):
		preset_opt.add_item(str(p_names[i]), i + 1)
	preset_opt.item_selected.connect(
		func(idx: int):
			if idx > 0 and idx - 1 < p_names.size():
				var cur_presets := _get_ladder_presets()
				var key := str(p_names[idx - 1])
				ladder_code_edit.text = str(cur_presets[key])
				_apply_ladder_code(true),
	)
	bar.add_child(preset_opt)

	var reset_plc_btn := Button.new()
	reset_plc_btn.text = "Reset T/C/M"
	reset_plc_btn.tooltip_text = "Reset Timers, Counters, and %MX memory"
	reset_plc_btn.pressed.connect(
		func():
			soft_plc.reset_runtime()
			_refresh_ladder_watch(),
	)
	bar.add_child(reset_plc_btn)

	var help_lbl := Label.new()
	help_lbl.text = "IEC: LD LDN AND ANDN OR ORN ST S R TON TOF CTU LD_GT | FX3U: LDI ANI ORI OUT(T0 K20 / C0 K5) SET RST PLS MOV MPS/MRD/MPP LD> END | X/Y Octal, M, D, K"
	help_lbl.add_theme_font_size_override("font_size", 11)
	help_lbl.add_theme_color_override("font_color", Color("7ea7c2"))
	help_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(help_lbl)

	ladder_code_edit = CodeEdit.new()
	ladder_code_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ladder_code_edit.gutters_draw_line_numbers = true
	ladder_code_edit.highlight_current_line = true
	ladder_code_edit.text = str(presets["Auto Water Tank (Low/High)"]) if soft_plc.source_code.is_empty() else soft_plc.source_code
	ladder_code_edit.add_theme_font_size_override("font_size", 13)
	vbox.add_child(ladder_code_edit)

	ladder_status_label = Label.new()
	ladder_status_label.text = "Ready"
	ladder_status_label.add_theme_font_size_override("font_size", 12)
	ladder_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(ladder_status_label)

	ladder_watch_label = Label.new()
	ladder_watch_label.text = "Scans: 0"
	ladder_watch_label.add_theme_font_size_override("font_size", 11)
	ladder_watch_label.add_theme_color_override("font_color", Color("9cb3c4"))
	ladder_watch_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(ladder_watch_label)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	vbox.add_child(footer)

	var compile_btn := Button.new()
	compile_btn.text = "Compile & Apply"
	_style_accent_button(compile_btn, "1e6b45", "278758", "3eb87a")
	compile_btn.pressed.connect(func(): _apply_ladder_code(true))
	footer.add_child(compile_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)

	var done_btn := Button.new()
	done_btn.text = "Done"
	done_btn.custom_minimum_size = Vector2(84, 30)
	done_btn.pressed.connect(func(): _set_ladder_dialog_visible(false))
	footer.add_child(done_btn)

	_apply_ladder_code(false)


func _apply_ladder_code(save_cfg: bool = true) -> void:
	if not is_instance_valid(ladder_code_edit):
		return
	var res: Dictionary = soft_plc.compile(ladder_code_edit.text)
	if is_instance_valid(ladder_status_label):
		if bool(res["ok"]):
			ladder_status_label.text = "Compiled OK (%d instructions)" % int(res["instruction_count"])
			ladder_status_label.add_theme_color_override("font_color", Color("66e0a3"))
		else:
			var errs: Array = res["errors"]
			ladder_status_label.text = "Error: " + str(errs[0])
			ladder_status_label.add_theme_color_override("font_color", Color("f06d6d"))
	if save_cfg:
		_save_settings()


func _refresh_ladder_watch() -> void:
	if not is_instance_valid(ladder_watch_label):
		return
	var state_str := "RUN" if (soft_plc.enabled and running and plc_mode) else ("IDLE" if soft_plc.enabled else "OFF")
	var parts: Array[String] = ["PLC: %s | Scans: %d" % [state_str, soft_plc.scan_count]]
	var active_m: Array[String] = []
	for i in range(64):
		if soft_plc.memory_bits[i]:
			active_m.append(("M%d" % i) if plc_notation == "fx3u" else ("%%MX%d.%d" % [i / 8, i % 8]))
	if not active_m.is_empty():
		parts.append("M: " + ", ".join(active_m.slice(0, 6)))
	var active_t: Array[String] = []
	for i in range(8):
		var t: Dictionary = soft_plc.timers[i]
		if float(t["et_ms"]) > 0.0 or bool(t["q"]):
			active_t.append("T%d(Q=%d, %.1fs)" % [i, 1 if bool(t["q"]) else 0, float(t["et_ms"]) / 1000.0])
	if not active_t.is_empty():
		parts.append(" ".join(active_t))
	var active_c: Array[String] = []
	for i in range(8):
		var c: Dictionary = soft_plc.counters[i]
		if int(c["cv"]) != 0 or bool(c["q"]):
			active_c.append("C%d(Q=%d, CV=%d)" % [i, 1 if bool(c["q"]) else 0, int(c["cv"])])
	if not active_c.is_empty():
		parts.append(" ".join(active_c))
	var next_watch := "  |  ".join(parts)
	if ladder_watch_label.text != next_watch:
		ladder_watch_label.text = next_watch


func _apply_modbus_server_settings() -> void:
	var is_client := is_instance_valid(modbus_mode_option) and modbus_mode_option.selected == 1
	var ip_txt := modbus_ip_input.text.strip_edges()
	ModbusTCP.mode = ModbusTCP.Mode.CLIENT if is_client else ModbusTCP.Mode.SERVER
	if is_instance_valid(modbus_poll_input):
		ModbusTCP.poll_interval = clampf(float(modbus_poll_input.value) / 1000.0, 0.005, 1.0)
	if is_instance_valid(modbus_profile_option):
		var is_fx := modbus_profile_option.selected == 1
		plc_notation = "fx3u" if is_fx else "iec"
		ModbusTCP.address_profile = ModbusTCP.AddressProfile.FX3U_OFFSET if is_fx else ModbusTCP.AddressProfile.STANDARD_OPENPLC
	if is_instance_valid(modbus_unit_id_input):
		var uid := int(modbus_unit_id_input.value)
		if is_client:
			ModbusTCP.client_unit_id = clampi(uid if uid > 0 else 1, 1, 247)
		else:
			ModbusTCP.unit_id_filter = clampi(uid, 0, 247)
	if is_instance_valid(modbus_pack_di_check):
		ModbusTCP.client_packed_di = modbus_pack_di_check.button_pressed
	if is_instance_valid(modbus_fx_coil_off_input):
		ModbusTCP.fx_coil_offset = int(modbus_fx_coil_off_input.value)
	if is_instance_valid(modbus_fx_di_off_input):
		ModbusTCP.fx_di_offset = int(modbus_fx_di_off_input.value)
	if is_instance_valid(modbus_fx_hr_off_input):
		ModbusTCP.fx_hr_offset = int(modbus_fx_hr_off_input.value)
	if is_instance_valid(modbus_fx_ir_off_input):
		ModbusTCP.fx_ir_offset = int(modbus_fx_ir_off_input.value)
	if is_client:
		ModbusTCP.remote_host = ip_txt if not ip_txt.is_empty() else "127.0.0.1"
		ModbusTCP.remote_port = int(modbus_port_input.value)
	else:
		ModbusTCP.bind_address = ip_txt if not ip_txt.is_empty() else "0.0.0.0"
		ModbusTCP.port = int(modbus_port_input.value)
	var want_mb := modbus_enabled_check.button_pressed if is_instance_valid(modbus_enabled_check) else ModbusTCP.enabled
	_set_controller_mode(1 if want_mb else 0, false)
	if ModbusTCP.enabled:
		ModbusTCP.start_service()
	else:
		ModbusTCP.stop_service()
	_refresh_modbus_dialog()
	_save_settings()


func _auto_map_modbus_iec() -> void:
	var next_coil := 0
	var next_input := 0
	var next_ir := 0
	var next_hr := 10
	for item in CABINET_IO_DEFS:
		var io_id: String = item["id"]
		if item["dir"] == "coil":
			cabinet_io_addrs[io_id] = next_coil
			next_coil += 1
		else:
			cabinet_io_addrs[io_id] = next_input
			next_input += 1
	for obj in get_tree().get_nodes_in_group("sandbox_objects"):
		var kind := str(obj.get_meta("kind", ""))
		if kind in PRODUCT_KINDS or kind in PROP_KINDS:
			continue
		if kind == "cabinet":
			obj.set_meta("modbus_coil", -1)
			obj.set_meta("modbus_input", -1)
			obj.set_meta("modbus_input_reg", -1)
			var dyn_slots: Array = obj.get("dynamic_slots") if "dynamic_slots" in obj else []
			for slot_item in dyn_slots:
				if slot_item is Dictionary:
					var mk := str(slot_item.get("kind", "lamp"))
					if mk == "potentiometer":
						slot_item["modbus_input_reg"] = next_ir
						next_ir += 1
					elif mk == "dpm":
						slot_item["modbus_holding_reg"] = next_hr
						next_hr += 1
					elif mk == "switch_3pos":
						slot_item["modbus_input"] = next_input
						next_input += 2
					elif mk in ["push_button", "button", "switch_select"]:
						slot_item["modbus_input"] = next_input
						next_input += 1
					else:
						slot_item["modbus_coil"] = next_coil
						next_coil += 1
			continue
		if kind in [
			"conveyor",
			"conveyor_short",
			"turn",
			"pusher",
			"stopper",
			"emitter",
			"remover",
			"stack_light",
			"motor_fan",
			"pump",
			"water_tank",
			"solenoid_valve",
			"reject_bin",
		]:
			obj.set_meta("modbus_coil", next_coil)
			next_coil += 3 if kind == "stack_light" else 1
		if kind in ["sensor", "vision_sensor", "rgb_sensor", "stopper", "water_tank", "light_curtain"]:
			obj.set_meta("modbus_input", next_input)
			next_input += 3 if kind == "water_tank" else 1
		if kind in ["vision_sensor", "rgb_sensor", "water_tank"]:
			obj.set_meta("modbus_input_reg", next_ir)
			next_ir += 1
		if kind in ["vision_sensor", "rgb_sensor"]:
			obj.set_meta("modbus_holding_reg", next_hr)
			next_hr += 1
	_refresh_modbus_dialog()
	_refresh_transform_controls()
	_refresh_io_status_list()
	_save_settings()
	_save_layout(true)


func _clear_all_modbus_tags() -> void:
	for item in CABINET_IO_DEFS:
		cabinet_io_addrs[item["id"]] = -1
	for obj in get_tree().get_nodes_in_group("sandbox_objects"):
		var kind := str(obj.get_meta("kind", ""))
		if kind not in PRODUCT_KINDS:
			obj.set_meta("modbus_coil", -1)
			obj.set_meta("modbus_input", -1)
			obj.set_meta("modbus_input_reg", -1)
			obj.set_meta("modbus_holding_reg", -1)
			if kind == "cabinet":
				var dyn_slots: Array = obj.get("dynamic_slots") if "dynamic_slots" in obj else []
				for slot_item in dyn_slots:
					if slot_item is Dictionary:
						slot_item["modbus_coil"] = -1
						slot_item["modbus_input"] = -1
						slot_item["modbus_input_reg"] = -1
						slot_item["modbus_holding_reg"] = -1
	_refresh_modbus_dialog()
	_refresh_transform_controls()
	_refresh_io_status_list()
	_save_settings()
	_save_layout(true)


func _refresh_modbus_dialog() -> void:
	if not is_instance_valid(modbus_io_grid):
		return
	var mb_enabled := ModbusTCP.enabled
	if is_instance_valid(modbus_enabled_check):
		modbus_enabled_check.set_pressed_no_signal(mb_enabled)
	var is_client := ModbusTCP.mode == ModbusTCP.Mode.CLIENT
	if is_instance_valid(modbus_mode_option):
		modbus_mode_option.select(1 if is_client else 0)
		modbus_mode_option.disabled = not mb_enabled
	if is_instance_valid(modbus_ip_label):
		modbus_ip_label.text = "PLC IP:" if is_client else "Bind IP:"
	if is_instance_valid(modbus_ip_input):
		modbus_ip_input.text = ModbusTCP.remote_host if is_client else ModbusTCP.bind_address
		modbus_ip_input.editable = mb_enabled
	if is_instance_valid(modbus_port_input):
		modbus_port_input.value = ModbusTCP.remote_port if is_client else ModbusTCP.port
		modbus_port_input.editable = mb_enabled
	if is_instance_valid(modbus_poll_input):
		modbus_poll_input.value = int(round(ModbusTCP.poll_interval * 1000.0))
		modbus_poll_input.editable = mb_enabled
	if is_instance_valid(modbus_profile_option):
		modbus_profile_option.select(1 if plc_notation == "fx3u" else 0)
	if is_instance_valid(modbus_unit_id_input):
		modbus_unit_id_input.value = ModbusTCP.client_unit_id if is_client else ModbusTCP.unit_id_filter
	if is_instance_valid(modbus_pack_di_check):
		modbus_pack_di_check.set_pressed_no_signal(ModbusTCP.client_packed_di)
		modbus_pack_di_check.disabled = not is_client
	if is_instance_valid(modbus_fx_row):
		modbus_fx_row.visible = (plc_notation == "fx3u")
	if is_instance_valid(modbus_fx_coil_off_input):
		modbus_fx_coil_off_input.value = ModbusTCP.fx_coil_offset
	if is_instance_valid(modbus_fx_di_off_input):
		modbus_fx_di_off_input.value = ModbusTCP.fx_di_offset
	if is_instance_valid(modbus_fx_hr_off_input):
		modbus_fx_hr_off_input.value = ModbusTCP.fx_hr_offset
	if is_instance_valid(modbus_fx_ir_off_input):
		modbus_fx_ir_off_input.value = ModbusTCP.fx_ir_offset
	if is_instance_valid(modbus_table_title):
		modbus_table_title.text = (
			"OBJECT I/O ADDRESSES (FX3U: Y0/X0 Octal, D0 or %QX/%IX; empty = unused)"
			if plc_notation == "fx3u"
			else "OBJECT I/O ADDRESSES (IEC 61131-3: %QX/%IX or FX3U Y0/X0; empty = unused)"
		)
	if is_instance_valid(modbus_auto_map_btn):
		modbus_auto_map_btn.text = "Auto-Map FX3U" if plc_notation == "fx3u" else "Auto-Map IEC"
	if is_instance_valid(modbus_restart_btn):
		modbus_restart_btn.disabled = not mb_enabled
	if is_instance_valid(modbus_srv_status):
		if not mb_enabled:
			modbus_srv_status.text = "Modbus TCP: DISABLED"
			modbus_srv_status.add_theme_color_override("font_color", Color("8aa0b0"))
		elif is_client:
			if ModbusTCP.is_client_connected():
				modbus_srv_status.text = "Client: CONNECTED to %s:%d (FC01 Coils, FC16 DI->Reg 0..3)" % [
					ModbusTCP.remote_host,
					ModbusTCP.remote_port,
				]
				modbus_srv_status.add_theme_color_override("font_color", Color("66e0a3"))
			else:
				modbus_srv_status.text = "Client: CONNECTING to %s:%d..." % [
					ModbusTCP.remote_host,
					ModbusTCP.remote_port,
				]
				modbus_srv_status.add_theme_color_override("font_color", Color("f7d070"))
		elif ModbusTCP.is_listening():
			modbus_srv_status.text = "Server: LISTENING on %s:%d (%d clients)" % [
				ModbusTCP.bind_address,
				ModbusTCP.port,
				ModbusTCP.client_count(),
			]
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

	# Control Cabinet individual button / switch / lamp Modbus I/O rows
	for item in CABINET_IO_DEFS:
		var io_id: String = item["id"]
		var is_coil_io: bool = item["dir"] == "coil"
		var is_input_io: bool = item["dir"] == "input"

		var io_name := Label.new()
		io_name.text = item["label"]
		io_name.custom_minimum_size.x = 135
		modbus_io_grid.add_child(io_name)

		var io_type := Label.new()
		io_type.text = item["kind"]
		io_type.custom_minimum_size.x = 75
		io_type.add_theme_color_override("font_color", Color("8aa0b0"))
		modbus_io_grid.add_child(io_type)

		var io_coil := LineEdit.new()
		io_coil.custom_minimum_size.x = 130
		io_coil.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		io_coil.editable = is_coil_io
		io_coil.placeholder_text = "%QX0.0" if is_coil_io else "-"
		io_coil.text = _format_iec_address(int(cabinet_io_addrs.get(io_id, -1)), "QX") if is_coil_io else ""
		if is_coil_io:
			var target_id := io_id
			io_coil.text_changed.connect(
				func(txt: String):
					var p := _parse_iec_or_int_address(txt)
					if p >= -1:
						cabinet_io_addrs[target_id] = p
						_save_settings(),
			)
			io_coil.focus_exited.connect(
				func():
					io_coil.text = _format_iec_address(
						int(cabinet_io_addrs.get(target_id, -1)),
						"QX",
					),
			)
		modbus_io_grid.add_child(io_coil)

		var io_input := LineEdit.new()
		io_input.custom_minimum_size.x = 130
		io_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		io_input.editable = is_input_io
		io_input.placeholder_text = "%IX0.0" if is_input_io else "-"
		io_input.text = _format_iec_address(int(cabinet_io_addrs.get(io_id, -1)), "IX") if is_input_io else ""
		if is_input_io:
			var target_id := io_id
			io_input.text_changed.connect(
				func(txt: String):
					var p := _parse_iec_or_int_address(txt)
					if p >= -1:
						cabinet_io_addrs[target_id] = p
						_save_settings(),
			)
			io_input.focus_exited.connect(
				func():
					io_input.text = _format_iec_address(
						int(cabinet_io_addrs.get(target_id, -1)),
						"IX",
					),
			)
		modbus_io_grid.add_child(io_input)

	for obj in get_tree().get_nodes_in_group("sandbox_objects"):
		var kind := str(obj.get_meta("kind", ""))
		if kind in PRODUCT_KINDS or kind in PROP_KINDS:
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
		var has_coil := kind in [
			"conveyor",
			"conveyor_short",
			"turn",
			"pusher",
			"stopper",
			"emitter",
			"remover",
			"stack_light",
			"motor_fan",
			"pump",
			"water_tank",
			"solenoid_valve",
			"reject_bin",
		]
		coil_edit.editable = has_coil
		coil_edit.placeholder_text = "%QX0.0" if has_coil else "-"
		coil_edit.text = _format_iec_address(int(obj.get_meta("modbus_coil", -1)), "QX") if has_coil else ("-" if kind == "cabinet" else "")
		if has_coil:
			var target_obj := obj
			coil_edit.text_changed.connect(
				func(txt: String):
					var p := _parse_iec_or_int_address(txt)
					if p >= -1:
						target_obj.set_meta("modbus_coil", p)
						_save_settings(),
			)
			coil_edit.focus_exited.connect(
				func():
					coil_edit.text = _format_iec_address(
						int(target_obj.get_meta("modbus_coil", -1)),
						"QX",
					)
					_refresh_modbus_conflict_warning()
					if kind in ["stack_light", "cabinet"]:
						_refresh_modbus_dialog.call_deferred(),
			)
		modbus_io_grid.add_child(coil_edit)

		var input_edit := LineEdit.new()
		input_edit.custom_minimum_size.x = 130
		input_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var has_input := kind in ["sensor", "vision_sensor", "rgb_sensor", "stopper", "water_tank", "light_curtain"]
		input_edit.editable = has_input
		input_edit.placeholder_text = "%IX0.0" if has_input else "-"
		input_edit.text = _format_iec_address(int(obj.get_meta("modbus_input", -1)), "IX") if has_input else ("-" if kind == "cabinet" else "")
		if has_input:
			var target_obj := obj
			input_edit.text_changed.connect(
				func(txt: String):
					var p := _parse_iec_or_int_address(txt)
					if p >= -1:
						target_obj.set_meta("modbus_input", p)
						_save_settings(),
			)
			input_edit.focus_exited.connect(
				func():
					input_edit.text = _format_iec_address(
						int(target_obj.get_meta("modbus_input", -1)),
						"IX",
					)
					_refresh_modbus_conflict_warning()
					if kind in ["water_tank", "cabinet"]:
						_refresh_modbus_dialog.call_deferred(),
			)
		modbus_io_grid.add_child(input_edit)

		if kind == "water_tank":
			var base_in := int(obj.get_meta("modbus_input", -1))
			for idx in range(3):
				var lvl_names := ["Low Level (>=20%)", "Mid Level (>=50%)", "High Level (>=85%)"]
				var ix_txt := _format_iec_address(base_in + idx, "IX") if base_in >= 0 else "-"
				_add_modbus_subrow_label("  |- " + lvl_names[idx], "DI +%d" % idx, "-", ix_txt)
			_add_modbus_word_subrow(obj, "  |- Level % (IR)", "modbus_input_reg", "IW", false)
		elif kind == "stack_light":
			var base_coil := int(obj.get_meta("modbus_coil", -1))
			for idx in range(3):
				var lamp_names := ["Green Lamp", "Yellow Lamp", "Red Lamp"]
				var qx_txt := _format_iec_address(base_coil + idx, "QX") if base_coil >= 0 else "-"
				_add_modbus_subrow_label("  |- " + lamp_names[idx], "DO +%d" % idx, qx_txt, "-")
		elif kind in ["vision_sensor", "rgb_sensor"]:
			_add_modbus_word_subrow(obj, "  |- Out Word (IR)", "modbus_input_reg", "IW", false)
			_add_modbus_word_subrow(obj, "  |- Cmd Word (HR)", "modbus_holding_reg", "QW", true)
		elif kind == "cabinet":
			var dyn_slots: Array = obj.get("dynamic_slots") if "dynamic_slots" in obj else []
			for slot_item in dyn_slots:
				if not (slot_item is Dictionary):
					continue
				var mk := str(slot_item.get("kind", "lamp"))
				var slbl := str(slot_item.get("label", "MOD"))
				_add_cabinet_slot_modbus_row(obj, slot_item, "  |- " + slbl, mk)


func _add_cabinet_slot_modbus_row(_cab: Node3D, slot_item: Dictionary, label_text: String, mkind: String) -> void:
	var n_lbl := Label.new()
	n_lbl.text = label_text
	n_lbl.custom_minimum_size.x = 135
	n_lbl.add_theme_font_size_override("font_size", 11)
	n_lbl.add_theme_color_override("font_color", Color("b8ccd8"))
	modbus_io_grid.add_child(n_lbl)

	var t_lbl := Label.new()
	t_lbl.text = mkind
	t_lbl.custom_minimum_size.x = 75
	t_lbl.add_theme_font_size_override("font_size", 11)
	t_lbl.add_theme_color_override("font_color", Color("6f8696"))
	modbus_io_grid.add_child(t_lbl)

	var dash := Label.new()
	dash.text = "-"
	dash.add_theme_font_size_override("font_size", 11)
	dash.add_theme_color_override("font_color", Color("5c6e7c"))

	var edit := LineEdit.new()
	edit.custom_minimum_size.x = 130
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if mkind == "potentiometer":
		edit.placeholder_text = "D0" if plc_notation == "fx3u" else "%IW0"
		edit.text = _format_word_address(int(slot_item.get("modbus_input_reg", -1)), "IW")
		edit.text_changed.connect(func(txt: String):
			var p := _parse_word_register_address(txt)
			if p >= -1:
				slot_item["modbus_input_reg"] = p
				_save_settings()
				_save_layout(true)
		)
		edit.focus_exited.connect(func():
			edit.text = _format_word_address(int(slot_item.get("modbus_input_reg", -1)), "IW")
			_refresh_io_status_list()
		)
		modbus_io_grid.add_child(dash)
		modbus_io_grid.add_child(edit)
	elif mkind == "dpm":
		edit.placeholder_text = "D10" if plc_notation == "fx3u" else "%QW10"
		edit.text = _format_word_address(int(slot_item.get("modbus_holding_reg", -1)), "QW")
		edit.text_changed.connect(func(txt: String):
			var p := _parse_word_register_address(txt)
			if p >= -1:
				slot_item["modbus_holding_reg"] = p
				_save_settings()
				_save_layout(true)
		)
		edit.focus_exited.connect(func():
			edit.text = _format_word_address(int(slot_item.get("modbus_holding_reg", -1)), "QW")
			_refresh_io_status_list()
		)
		modbus_io_grid.add_child(edit)
		modbus_io_grid.add_child(dash)
	elif mkind in ["push_button", "button", "switch_select", "switch_3pos"]:
		edit.placeholder_text = "X0" if plc_notation == "fx3u" else "%IX0.0"
		edit.text = _format_iec_address(int(slot_item.get("modbus_input", -1)), "IX")
		edit.text_changed.connect(func(txt: String):
			var p := _parse_iec_or_int_address(txt)
			if p >= -1:
				slot_item["modbus_input"] = p
				_save_settings()
				_save_layout(true)
		)
		edit.focus_exited.connect(func():
			edit.text = _format_iec_address(int(slot_item.get("modbus_input", -1)), "IX")
			_refresh_io_status_list()
		)
		modbus_io_grid.add_child(dash)
		modbus_io_grid.add_child(edit)
	else:
		edit.placeholder_text = "Y0" if plc_notation == "fx3u" else "%QX0.0"
		edit.text = _format_iec_address(int(slot_item.get("modbus_coil", -1)), "QX")
		edit.text_changed.connect(func(txt: String):
			var p := _parse_iec_or_int_address(txt)
			if p >= -1:
				slot_item["modbus_coil"] = p
				_save_settings()
				_save_layout(true)
		)
		edit.focus_exited.connect(func():
			edit.text = _format_iec_address(int(slot_item.get("modbus_coil", -1)), "QX")
			_refresh_io_status_list()
		)
		modbus_io_grid.add_child(edit)
		modbus_io_grid.add_child(dash)


func _add_modbus_subrow_label(label_text: String, type_text: String, coil_text: String, input_text: String) -> void:
	var n_lbl := Label.new()
	n_lbl.text = label_text
	n_lbl.custom_minimum_size.x = 135
	n_lbl.add_theme_font_size_override("font_size", 11)
	n_lbl.add_theme_color_override("font_color", Color("b8ccd8"))
	modbus_io_grid.add_child(n_lbl)

	var t_lbl := Label.new()
	t_lbl.text = type_text
	t_lbl.custom_minimum_size.x = 75
	t_lbl.add_theme_font_size_override("font_size", 11)
	t_lbl.add_theme_color_override("font_color", Color("6f8696"))
	modbus_io_grid.add_child(t_lbl)

	var c_lbl := Label.new()
	c_lbl.text = coil_text
	c_lbl.add_theme_font_size_override("font_size", 11)
	c_lbl.add_theme_color_override("font_color", Color("4fd18b") if coil_text != "-" else Color("5c6e7c"))
	modbus_io_grid.add_child(c_lbl)

	var i_lbl := Label.new()
	i_lbl.text = input_text
	i_lbl.add_theme_font_size_override("font_size", 11)
	i_lbl.add_theme_color_override("font_color", Color("f0c44d") if input_text != "-" else Color("5c6e7c"))
	modbus_io_grid.add_child(i_lbl)


func _add_modbus_word_subrow(obj: Node3D, label_text: String, meta_key: String, prefix: String, in_coil_col: bool) -> void:
	var n_lbl := Label.new()
	n_lbl.text = label_text
	n_lbl.custom_minimum_size.x = 135
	n_lbl.add_theme_font_size_override("font_size", 11)
	n_lbl.add_theme_color_override("font_color", Color("67c8ff"))
	modbus_io_grid.add_child(n_lbl)

	var t_lbl := Label.new()
	t_lbl.text = "word"
	t_lbl.custom_minimum_size.x = 75
	t_lbl.add_theme_font_size_override("font_size", 11)
	t_lbl.add_theme_color_override("font_color", Color("6f8696"))
	modbus_io_grid.add_child(t_lbl)

	var word_edit := LineEdit.new()
	word_edit.custom_minimum_size.x = 130
	word_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	word_edit.placeholder_text = "%" + prefix + "0"
	word_edit.text = _format_word_address(int(obj.get_meta(meta_key, -1)), prefix)
	var target_obj := obj
	word_edit.text_changed.connect(
		func(txt: String):
			var p := _parse_word_register_address(txt)
			if p >= -1:
				target_obj.set_meta(meta_key, p)
				_save_settings(),
	)
	word_edit.focus_exited.connect(
		func():
			word_edit.text = _format_word_address(int(target_obj.get_meta(meta_key, -1)), prefix)
			_refresh_io_status_list()
			_refresh_modbus_conflict_warning(),
	)

	var dash_lbl := Label.new()
	dash_lbl.text = "-"
	dash_lbl.add_theme_font_size_override("font_size", 11)
	dash_lbl.add_theme_color_override("font_color", Color("5c6e7c"))

	if in_coil_col:
		modbus_io_grid.add_child(word_edit)
		modbus_io_grid.add_child(dash_lbl)
	else:
		modbus_io_grid.add_child(dash_lbl)
		modbus_io_grid.add_child(word_edit)


func _draw_axis_gizmo() -> void:
	axis_gizmo.draw_rect(Rect2(Vector2.ZERO, axis_gizmo.size), Color(0.08, 0.13, 0.18, 0.88), true)
	axis_gizmo.draw_rect(Rect2(Vector2.ZERO, axis_gizmo.size), Color("4b6575"), false, 1.0)
	var font := ThemeDB.fallback_font
	axis_gizmo.draw_string(
		font,
		Vector2(12, 21),
		"WORLD AXES (Z UP)",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		13,
		Color("e5f2f3"),
	)
	var origin := Vector2(69, 84)
	# Right-handed editor coordinates: X = Godot X, Y = -Godot Z, Z = Godot Y.
	for item in [
		["+X", Vector3.RIGHT, Color("f06d6d")],
		["+Y", Vector3.FORWARD, Color("78d989")],
		["+Z", Vector3.UP, Color("78afff")],
	]:
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
		axis_gizmo.draw_string(
			font,
			tip + Vector2(4, 5),
			item[0],
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			13,
			color,
		)
	axis_gizmo.draw_circle(origin, 3.0, Color.WHITE)


func _build_transform_controls(ui_root: Control) -> void:
	transform_panel = PanelContainer.new()
	transform_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	transform_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	transform_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	transform_panel.offset_left = -300
	transform_panel.offset_top = -46
	transform_panel.offset_right = -16
	transform_panel.offset_bottom = -46
	transform_panel.custom_minimum_size = Vector2(284, 0)
	var panel_style := _ui_stylebox(
		Color(0.063, 0.098, 0.137, 0.92),
		Color("294052"),
		12,
		1,
		12,
		12,
	)
	panel_style.shadow_color = Color(0, 0, 0, 0.35)
	panel_style.shadow_size = 8
	transform_panel.add_theme_stylebox_override("panel", panel_style)
	ui_root.add_child(transform_panel)
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 12)
	transform_panel.add_child(margin)
	transform_scroll = ScrollContainer.new()
	transform_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	transform_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	transform_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(transform_scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 6)
	transform_scroll.add_child(column)
	transform_column = column
	transform_title = Label.new()
	transform_title.text = "OBJECT CONTROLS"
	column.add_child(transform_title)
	transform_value = Label.new()
	column.add_child(transform_value)
	var move_row := HBoxContainer.new()
	column.add_child(move_row)
	for item in [
		["X -", Vector3(-1, 0, 0)],
		["X +", Vector3(1, 0, 0)],
		["Y -", Vector3(0, 0, 1)],
		["Y +", Vector3(0, 0, -1)],
	]:
		var button := Button.new()
		button.text = item[0]
		button.tooltip_text = "Move 1 grid unit"
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var dir: Vector3 = item[1]
		button.pressed.connect(
			func():
				_move_selected(dir * grid_step),
		)
		move_row.add_child(button)
	var height_row := HBoxContainer.new()
	column.add_child(height_row)
	for item in [["Z -  Down", -1], ["Z +  Up", 1]]:
		var button := Button.new()
		button.text = item[0]
		button.tooltip_text = "Move 0.25 unit vertically"
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var direction: int = item[1]
		button.pressed.connect(
			func():
				_move_selected_height(direction),
		)
		height_row.add_child(button)
	var rotate_row := HBoxContainer.new()
	column.add_child(rotate_row)
	for item in [["Rotate Z -90°", -1], ["Rotate Z +90°", 1]]:
		var button := Button.new()
		button.text = item[0]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var direction: int = item[1]
		button.pressed.connect(
			func():
				_rotate_selected(direction),
		)
		rotate_row.add_child(button)
	var name_row := HBoxContainer.new()
	column.add_child(name_row)
	var name_label := Label.new()
	name_label.text = "Name:"
	name_label.custom_minimum_size.x = 92
	name_row.add_child(name_label)
	object_name_input = LineEdit.new()
	object_name_input.placeholder_text = "Object name"
	object_name_input.tooltip_text = "Rename selected object (Enter to apply)"
	object_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	object_name_input.text_submitted.connect(
		func(_t: String):
			_commit_object_name()
			if is_instance_valid(object_name_input):
				object_name_input.release_focus(),
	)
	object_name_input.focus_exited.connect(_commit_object_name)
	name_row.add_child(object_name_input)
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
	vision_mode_row = HBoxContainer.new()
	vision_mode_row.visible = false
	column.add_child(vision_mode_row)
	var vmode_label := Label.new()
	vmode_label.text = "Detect:"
	vmode_label.custom_minimum_size.x = 92
	vision_mode_row.add_child(vmode_label)
	vision_mode_option = OptionButton.new()
	vision_mode_option.add_item("All Boxes", 0)
	vision_mode_option.add_item("Cardboard (box)", 1)
	vision_mode_option.add_item("Plastic (crate)", 2)
	vision_mode_option.add_item("Defective (NG)", 3)
	vision_mode_option.add_item("Good (OK)", 4)
	vision_mode_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vision_mode_option.item_selected.connect(
		func(idx: int):
			if (
				is_instance_valid(selected_object)
				and str(selected_object.get_meta("kind", "")) == "vision_sensor"
			):
				selected_object.set("detect_mode", idx)
				_save_layout(true),
	)
	vision_mode_row.add_child(vision_mode_option)
	rgb_mode_row = HBoxContainer.new()
	rgb_mode_row.visible = false
	column.add_child(rgb_mode_row)
	var rmode_label := Label.new()
	rmode_label.text = "Color:"
	rmode_label.custom_minimum_size.x = 92
	rgb_mode_row.add_child(rmode_label)
	rgb_mode_option = OptionButton.new()
	rgb_mode_option.add_item("All Colors", 0)
	rgb_mode_option.add_item("1: Orange", 1)
	rgb_mode_option.add_item("2: Green", 2)
	rgb_mode_option.add_item("3: Blue", 3)
	rgb_mode_option.add_item("4: Yellow", 4)
	rgb_mode_option.add_item("5: Red", 5)
	rgb_mode_option.add_item("6: Purple", 6)
	rgb_mode_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rgb_mode_option.item_selected.connect(
		func(idx: int):
			if (
				is_instance_valid(selected_object)
				and str(selected_object.get_meta("kind", "")) == "rgb_sensor"
			):
				selected_object.set("detect_color", idx),
	)
	rgb_mode_row.add_child(rgb_mode_option)
	emitter_mode_row = HBoxContainer.new()
	emitter_mode_row.visible = false
	column.add_child(emitter_mode_row)
	var emode_label := Label.new()
	emode_label.text = "Emit Product:"
	emode_label.custom_minimum_size.x = 92
	emitter_mode_row.add_child(emode_label)
	emitter_mode_option = OptionButton.new()
	emitter_mode_option.add_item("Alternate (Box / Crate)", 0)
	emitter_mode_option.add_item("Cardboard Box", 1)
	emitter_mode_option.add_item("Plastic Crate", 2)
	emitter_mode_option.add_item("Small Box", 3)
	emitter_mode_option.add_item("Metal Crate", 4)
	emitter_mode_option.add_item("Pallet", 5)
	emitter_mode_option.add_item("Workpiece", 6)
	emitter_mode_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	emitter_mode_option.item_selected.connect(
		func(idx: int):
			if (
				is_instance_valid(selected_object)
				and str(selected_object.get_meta("kind", "")) == "emitter"
			):
				selected_object.set("box_mode", idx)
				_save_settings(),
	)
	emitter_mode_row.add_child(emitter_mode_option)
	emitter_defect_row = HBoxContainer.new()
	emitter_defect_row.visible = false
	column.add_child(emitter_defect_row)
	var edefect_label := Label.new()
	edefect_label.text = "Defect %:"
	edefect_label.custom_minimum_size.x = 92
	emitter_defect_row.add_child(edefect_label)
	emitter_defect_input = SpinBox.new()
	emitter_defect_input.min_value = 0
	emitter_defect_input.max_value = 100
	emitter_defect_input.step = 5
	emitter_defect_input.suffix = "%"
	emitter_defect_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	emitter_defect_input.value_changed.connect(
		func(val: float):
			if (
				is_instance_valid(selected_object)
				and str(selected_object.get_meta("kind", "")) == "emitter"
			):
				selected_object.set("defect_rate", clampi(int(round(val)), 0, 100))
				_save_layout(true)
				_save_settings(),
	)
	emitter_defect_row.add_child(emitter_defect_input)
	cabinet_title_row = HBoxContainer.new()
	cabinet_title_row.visible = false
	column.add_child(cabinet_title_row)
	var ctitle_label := Label.new()
	ctitle_label.text = "Title:"
	ctitle_label.custom_minimum_size.x = 92
	cabinet_title_row.add_child(ctitle_label)
	cabinet_title_input = LineEdit.new()
	cabinet_title_input.placeholder_text = "MAIN CONTROL"
	cabinet_title_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabinet_title_input.text_changed.connect(
		func(txt: String):
			if (
				is_instance_valid(selected_object)
				and str(selected_object.get_meta("kind", "")) == "cabinet"
			):
				selected_object.set("cabinet_title", txt)
				_sync_2d_cabinet_customization(selected_object),
	)
	cabinet_title_row.add_child(cabinet_title_input)
	cabinet_parts_row = HBoxContainer.new()
	cabinet_parts_row.visible = false
	column.add_child(cabinet_parts_row)

	cabinet_slot_box = VBoxContainer.new()
	cabinet_slot_box.visible = false
	cabinet_slot_box.add_theme_constant_override("separation", 4)
	column.add_child(cabinet_slot_box)
	var slot_hdr := Label.new()
	slot_hdr.text = "MODULAR FACEPLATE (3x5)"
	slot_hdr.add_theme_font_size_override("font_size", 11)
	slot_hdr.add_theme_color_override("font_color", Color("7ea7c2"))
	cabinet_slot_box.add_child(slot_hdr)
	cabinet_slot_grid = GridContainer.new()
	cabinet_slot_grid.columns = 3
	cabinet_slot_grid.add_theme_constant_override("h_separation", 4)
	cabinet_slot_grid.add_theme_constant_override("v_separation", 4)
	cabinet_slot_box.add_child(cabinet_slot_grid)
	cabinet_slot_buttons.clear()
	for r_i in range(5):
		for c_i in range(3):
			var cell_btn := Button.new()
			cell_btn.custom_minimum_size = Vector2(0, 22)
			cell_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell_btn.add_theme_font_size_override("font_size", 10)
			cell_btn.pressed.connect(_on_cabinet_grid_cell_pressed.bind(c_i, r_i))
			cabinet_slot_grid.add_child(cell_btn)
			cabinet_slot_buttons.append(cell_btn)
	cabinet_slot_io_label = Label.new()
	cabinet_slot_io_label.add_theme_font_size_override("font_size", 11)
	cabinet_slot_io_label.add_theme_color_override("font_color", Color("8fd1a6"))
	cabinet_slot_io_label.text = "Slot (0, 0)"
	cabinet_slot_box.add_child(cabinet_slot_io_label)
	var slot_cfg_row := HBoxContainer.new()
	cabinet_slot_box.add_child(slot_cfg_row)
	cabinet_slot_kind = OptionButton.new()
	cabinet_slot_kind.add_item("Lamp", 0)
	cabinet_slot_kind.add_item("Push Button", 1)
	cabinet_slot_kind.add_item("Switch Select", 2)
	cabinet_slot_kind.add_item("Switch 3-Pos", 3)
	cabinet_slot_kind.add_item("Potentiometer", 4)
	cabinet_slot_kind.add_item("Digital Panel Meter (DPM)", 5)
	cabinet_slot_kind.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabinet_slot_kind.item_selected.connect(func(_idx: int): _on_live_edit_cabinet_slot())
	slot_cfg_row.add_child(cabinet_slot_kind)
	cabinet_slot_color = ColorPickerButton.new()
	cabinet_slot_color.color = Color("18d97c")
	cabinet_slot_color.custom_minimum_size = Vector2(44, 0)
	cabinet_slot_color.edit_alpha = false
	cabinet_slot_color.color_changed.connect(func(_c: Color): _on_live_edit_cabinet_slot())
	slot_cfg_row.add_child(cabinet_slot_color)
	cabinet_slot_label = LineEdit.new()
	cabinet_slot_label.placeholder_text = "Tag (e.g. AUX1)"
	cabinet_slot_label.text = "AUX1"
	cabinet_slot_label.text_changed.connect(func(_t: String): _on_live_edit_cabinet_slot())
	cabinet_slot_box.add_child(cabinet_slot_label)
	cabinet_dpm_row = HBoxContainer.new()
	cabinet_dpm_row.visible = false
	cabinet_slot_box.add_child(cabinet_dpm_row)
	cabinet_dpm_unit = LineEdit.new()
	cabinet_dpm_unit.placeholder_text = "Unit (V, A, Hz, °C)"
	cabinet_dpm_unit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabinet_dpm_unit.text_changed.connect(func(_t: String): _on_live_edit_cabinet_slot())
	cabinet_dpm_row.add_child(cabinet_dpm_unit)
	cabinet_dpm_decimals = OptionButton.new()
	cabinet_dpm_decimals.add_item("0 dec", 0)
	cabinet_dpm_decimals.add_item("1 dec (0.0)", 1)
	cabinet_dpm_decimals.add_item("2 dec (0.00)", 2)
	cabinet_dpm_decimals.item_selected.connect(func(_idx: int): _on_live_edit_cabinet_slot())
	cabinet_dpm_row.add_child(cabinet_dpm_decimals)
	var slot_btn_row := HBoxContainer.new()
	cabinet_slot_box.add_child(slot_btn_row)
	var slot_apply_btn := Button.new()
	slot_apply_btn.text = "Place"
	slot_apply_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_apply_btn.pressed.connect(_on_apply_cabinet_slot)
	slot_btn_row.add_child(slot_apply_btn)
	cabinet_slot_move_btn = Button.new()
	cabinet_slot_move_btn.text = "Move"
	cabinet_slot_move_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabinet_slot_move_btn.pressed.connect(_on_toggle_cabinet_slot_move)
	slot_btn_row.add_child(cabinet_slot_move_btn)
	var slot_clear_btn := Button.new()
	slot_clear_btn.text = "Clear"
	slot_clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_clear_btn.pressed.connect(_on_clear_cabinet_slot)
	slot_btn_row.add_child(slot_clear_btn)
	var slot_clear_all_btn := Button.new()
	slot_clear_all_btn.text = "Clear All"
	slot_clear_all_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_clear_all_btn.pressed.connect(_on_clear_all_cabinet_slots)
	slot_btn_row.add_child(slot_clear_all_btn)
	modbus_section_sep = HSeparator.new()
	modbus_section_sep.visible = false
	column.add_child(modbus_section_sep)
	modbus_section_header = Label.new()
	modbus_section_header.text = "PLC / MODBUS I/O"
	modbus_section_header.add_theme_font_size_override("font_size", 11)
	modbus_section_header.add_theme_color_override("font_color", Color("7ea7c2"))
	modbus_section_header.visible = false
	column.add_child(modbus_section_header)
	modbus_slot_io_label = Label.new()
	modbus_slot_io_label.add_theme_font_size_override("font_size", 11)
	modbus_slot_io_label.add_theme_color_override("font_color", Color("8fd1a6"))
	modbus_slot_io_label.visible = false
	column.add_child(modbus_slot_io_label)
	modbus_coil_row = HBoxContainer.new()
	modbus_coil_row.visible = false
	column.add_child(modbus_coil_row)
	var coil_label := Label.new()
	coil_label.text = "Coil (DO):"
	coil_label.custom_minimum_size.x = 92
	coil_label.add_theme_color_override("font_color", Color("4fd18b"))
	modbus_coil_row.add_child(coil_label)
	modbus_coil_input = LineEdit.new()
	modbus_coil_input.placeholder_text = "%QX0.0 or 0..255"
	modbus_coil_input.tooltip_text = "Modbus Coil (%QX0.0..%QX31.7 or 0..255); leave empty if unused"
	modbus_coil_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modbus_coil_input.text_changed.connect(
		func(txt: String):
			_on_modbus_tag_changed("modbus_coil", txt),
	)
	modbus_coil_input.text_submitted.connect(
		func(_t: String):
			_commit_modbus_field("modbus_coil", modbus_coil_input, "QX"),
	)
	modbus_coil_input.focus_exited.connect(
		func():
			_commit_modbus_field("modbus_coil", modbus_coil_input, "QX"),
	)
	modbus_coil_row.add_child(modbus_coil_input)
	_add_modbus_row_buttons(modbus_coil_row, "modbus_coil", modbus_coil_input, "QX", false)

	modbus_input_row = HBoxContainer.new()
	modbus_input_row.visible = false
	column.add_child(modbus_input_row)
	var input_label := Label.new()
	input_label.text = "Input (DI):"
	input_label.custom_minimum_size.x = 92
	input_label.add_theme_color_override("font_color", Color("f0c44d"))
	modbus_input_row.add_child(input_label)
	modbus_input_field = LineEdit.new()
	modbus_input_field.placeholder_text = "%IX0.0 or 0..255"
	modbus_input_field.tooltip_text = "Modbus Discrete Input (%IX0.0..%IX31.7 or 0..255); leave empty if unused"
	modbus_input_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modbus_input_field.text_changed.connect(
		func(txt: String):
			_on_modbus_tag_changed("modbus_input", txt),
	)
	modbus_input_field.text_submitted.connect(
		func(_t: String):
			_commit_modbus_field("modbus_input", modbus_input_field, "IX"),
	)
	modbus_input_field.focus_exited.connect(
		func():
			_commit_modbus_field("modbus_input", modbus_input_field, "IX"),
	)
	modbus_input_row.add_child(modbus_input_field)
	_add_modbus_row_buttons(modbus_input_row, "modbus_input", modbus_input_field, "IX", false)

	vision_ir_row = HBoxContainer.new()
	vision_ir_row.visible = false
	column.add_child(vision_ir_row)
	var ir_label := Label.new()
	ir_label.text = "Out Word (IR):"
	ir_label.custom_minimum_size.x = 92
	ir_label.add_theme_color_override("font_color", Color("67c8ff"))
	vision_ir_row.add_child(ir_label)
	vision_ir_field = LineEdit.new()
	vision_ir_field.placeholder_text = "%IW0 or 0..255"
	vision_ir_field.tooltip_text = "Vision Output Input Register (FC04): 0=None, 1=Box, 2=Crate"
	vision_ir_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vision_ir_field.text_changed.connect(
		func(txt: String):
			_on_word_tag_changed("modbus_input_reg", txt),
	)
	vision_ir_field.text_submitted.connect(
		func(_t: String):
			_commit_word_field("modbus_input_reg", vision_ir_field, "IW"),
	)
	vision_ir_field.focus_exited.connect(
		func():
			_commit_word_field("modbus_input_reg", vision_ir_field, "IW"),
	)
	vision_ir_row.add_child(vision_ir_field)
	_add_modbus_row_buttons(vision_ir_row, "modbus_input_reg", vision_ir_field, "IW", true)

	vision_hr_row = HBoxContainer.new()
	vision_hr_row.visible = false
	column.add_child(vision_hr_row)
	var hr_label := Label.new()
	hr_label.text = "Cmd Word (HR):"
	hr_label.custom_minimum_size.x = 92
	hr_label.add_theme_color_override("font_color", Color("67c8ff"))
	vision_hr_row.add_child(hr_label)
	vision_hr_field = LineEdit.new()
	vision_hr_field.placeholder_text = "%QW10 or 10..255"
	vision_hr_field.tooltip_text = "Vision Command Holding Register (FC06/16): 0=All, 1=Box, 2=Crate (avoid HR 0..3 in Client mode)"
	vision_hr_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vision_hr_field.text_changed.connect(
		func(txt: String):
			_on_word_tag_changed("modbus_holding_reg", txt),
	)
	vision_hr_field.text_submitted.connect(
		func(_t: String):
			_commit_word_field("modbus_holding_reg", vision_hr_field, "QW"),
	)
	vision_hr_field.focus_exited.connect(
		func():
			_commit_word_field("modbus_holding_reg", vision_hr_field, "QW"),
	)
	vision_hr_row.add_child(vision_hr_field)
	_add_modbus_row_buttons(vision_hr_row, "modbus_holding_reg", vision_hr_field, "QW", true)
	var tank_edit_ui := _create_tank_sim_box()
	tank_edit_box = tank_edit_ui["box"]
	tank_edit_sensors_label = tank_edit_ui["sensors_label"]
	tank_edit_valve_btn = tank_edit_ui["valve_btn"]
	tank_edit_valve_slider = tank_edit_ui["valve_slider"]
	tank_edit_valve_pct_label = tank_edit_ui["pct_label"]
	column.add_child(tank_edit_box)
	modbus_conflict_label = Label.new()
	modbus_conflict_label.visible = false
	modbus_conflict_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modbus_conflict_label.add_theme_font_size_override("font_size", 11)
	modbus_conflict_label.add_theme_color_override("font_color", Color("ff8c69"))
	column.add_child(modbus_conflict_label)
	transform_panel.visible = false


func _refresh_transform_controls() -> void:
	if not is_instance_valid(transform_panel):
		return
	var active := (
		edit_mode and is_instance_valid(selected_object)
		and selected_object.is_in_group("sandbox_objects")
	)
	transform_panel.visible = active
	_refresh_force_panel()
	if is_instance_valid(delete_tool_button):
		delete_tool_button.disabled = not (active and not selected_object.has_meta("base_id"))
	if active:
		var pos: Vector3 = selected_object.get_meta("grid_position")
		var display_y := 0.0 if is_zero_approx(pos.z) else -pos.z
		var display_z := selected_object.global_position.y - (floor_body.position.y + 0.125)
		var direction := " (REVERSE)" if (
			selected_object.get_meta("kind") == "turn"
			and selected_object.get_meta("reversed", false)
		) else ""
		transform_title.text = "OBJECT: " + str(selected_object.get_meta("kind")) \
				.replace("_", " ") \
				.to_upper() + direction
		transform_value.text = "X: %.1f   Y: %.1f   Z: %.2f\nRotate Z: %.0f°" % [
			pos.x,
			display_y,
			display_z,
			selected_object.rotation_degrees.y,
		]
		if is_instance_valid(object_name_input) and not object_name_input.has_focus():
			object_name_input.text = String(selected_object.name)
		var is_conveyor: bool = str(selected_object.get_meta("kind")) in [
			"conveyor",
			"conveyor_short",
		]
		conveyor_speed_row.visible = is_conveyor
		if is_conveyor and is_instance_valid(conveyor_speed_input):
			var fallback_speed := float(selected_object.get("speed")) if "speed" in selected_object else BELT_SPEED
			conveyor_speed_input.set_value_no_signal(
				float(selected_object.get_meta("configured_speed", fallback_speed))
			)
		var kind_str: String = str(selected_object.get_meta("kind"))
		var is_vision: bool = kind_str == "vision_sensor"
		var is_rgb: bool = kind_str == "rgb_sensor"
		var is_word_sensor: bool = is_vision or is_rgb
		vision_mode_row.visible = is_vision
		if is_vision and is_instance_valid(vision_mode_option):
			vision_mode_option.select(int(selected_object.get("detect_mode")))
		rgb_mode_row.visible = is_rgb
		if is_rgb and is_instance_valid(rgb_mode_option):
			rgb_mode_option.select(int(selected_object.get("detect_color")))
		var is_emitter: bool = kind_str == "emitter"
		emitter_mode_row.visible = is_emitter
		if is_emitter and is_instance_valid(emitter_mode_option):
			emitter_mode_option.select(int(selected_object.get("box_mode")))
		emitter_defect_row.visible = is_emitter
		if is_emitter and is_instance_valid(emitter_defect_input):
			emitter_defect_input.set_value_no_signal(int(selected_object.get("defect_rate")))
		var is_tank: bool = kind_str == "water_tank"
		if is_instance_valid(tank_edit_box):
			tank_edit_box.visible = is_tank
			if is_tank:
				_refresh_tank_sim_box(
					selected_object,
					tank_edit_sensors_label,
					tank_edit_valve_btn,
					tank_edit_valve_slider,
					tank_edit_valve_pct_label,
				)
		var is_cabinet: bool = kind_str == "cabinet"
		cabinet_title_row.visible = is_cabinet
		cabinet_parts_row.visible = is_cabinet and bool(selected_object.get("show_builtin_items"))
		cabinet_slot_box.visible = is_cabinet
		if is_cabinet:
			if is_instance_valid(cabinet_title_input) and not cabinet_title_input.has_focus():
				cabinet_title_input.text = str(selected_object.get("cabinet_title"))
			if is_instance_valid(cabinet_yellow_check):
				cabinet_yellow_check.set_pressed_no_signal(bool(selected_object.get("show_yellow_lamp")))
			if is_instance_valid(cabinet_rev_check):
				cabinet_rev_check.set_pressed_no_signal(bool(selected_object.get("show_rev_btn")))
			_refresh_cabinet_slot_grid()
		var has_coil: bool = kind_str in [
			"conveyor",
			"conveyor_short",
			"turn",
			"pusher",
			"stopper",
			"emitter",
			"remover",
			"stack_light",
			"motor_fan",
			"pump",
			"water_tank",
			"solenoid_valve",
			"reject_bin",
		]
		var has_input: bool = kind_str in [
			"sensor",
			"vision_sensor",
			"rgb_sensor",
			"stopper",
			"water_tank",
		]
		var has_input_reg := is_word_sensor or kind_str == "water_tank"
		var has_holding_reg := is_word_sensor
		var c_addr := int(selected_object.get_meta("modbus_coil", -1))
		var i_addr := int(selected_object.get_meta("modbus_input", -1))
		var ir_addr := int(selected_object.get_meta("modbus_input_reg", -1))
		var hr_addr := int(selected_object.get_meta("modbus_holding_reg", -1))
		if is_instance_valid(cabinet_dpm_row):
			cabinet_dpm_row.visible = is_cabinet and _selected_cabinet_slot_kind_str() == "dpm"
		if is_cabinet:
			var sel_slot := _get_selected_cabinet_slot_item()
			if sel_slot.is_empty():
				has_coil = false
				has_input = false
				has_input_reg = false
				has_holding_reg = false
			else:
				var skind := str(sel_slot.get("kind", "lamp"))
				if skind == "potentiometer":
					has_input_reg = true
					ir_addr = int(sel_slot.get("modbus_input_reg", -1))
				elif skind == "dpm":
					has_holding_reg = true
					hr_addr = int(sel_slot.get("modbus_holding_reg", -1))
				elif skind in ["push_button", "button", "switch_select", "switch_3pos"]:
					has_input = true
					i_addr = int(sel_slot.get("modbus_input", -1))
				else:
					has_coil = true
					c_addr = int(sel_slot.get("modbus_coil", -1))
		var is_fx_not := plc_notation == "fx3u"
		modbus_coil_row.visible = has_coil
		if has_coil and is_instance_valid(modbus_coil_input):
			modbus_coil_input.placeholder_text = "Y0 or 0..255" if is_fx_not else "%QX0.0 or 0..255"
			if not modbus_coil_input.has_focus():
				modbus_coil_input.text = _format_iec_address(c_addr, "QX")
		modbus_input_row.visible = has_input
		if has_input and is_instance_valid(modbus_input_field):
			modbus_input_field.placeholder_text = "X0 or 0..255" if is_fx_not else "%IX0.0 or 0..255"
			if not modbus_input_field.has_focus():
				modbus_input_field.text = _format_iec_address(i_addr, "IX")
		vision_ir_row.visible = has_input_reg
		if has_input_reg and is_instance_valid(vision_ir_field):
			vision_ir_field.placeholder_text = "D0 or 0..255" if is_fx_not else "%IW0 or 0..255"
			if not vision_ir_field.has_focus():
				vision_ir_field.text = _format_word_address(ir_addr, "IW")
		vision_hr_row.visible = has_holding_reg
		if has_holding_reg and is_instance_valid(vision_hr_field):
			vision_hr_field.placeholder_text = "D10 or 10..255" if is_fx_not else "%QW10 or 10..255"
			if not vision_hr_field.has_focus():
				vision_hr_field.text = _format_word_address(hr_addr, "QW")
		var show_modbus: bool = is_cabinet or has_coil or has_input or has_input_reg or has_holding_reg
		if is_instance_valid(modbus_section_sep):
			modbus_section_sep.visible = show_modbus
		if is_instance_valid(modbus_section_header):
			modbus_section_header.visible = show_modbus
		if is_instance_valid(modbus_slot_io_label):
			modbus_slot_io_label.visible = is_cabinet and show_modbus
		_refresh_modbus_conflict_warning()
		_fit_transform_panel()
		_fit_transform_panel.call_deferred()


func _fit_transform_panel() -> void:
	if is_instance_valid(transform_scroll) and is_instance_valid(transform_column):
		var col_sz := transform_column.get_combined_minimum_size()
		var vp_h := get_viewport().get_visible_rect().size.y if get_viewport() != null else 720.0
		var max_scroll_h := maxf(200.0, vp_h - 150.0)
		transform_scroll.custom_minimum_size = Vector2(maxf(col_sz.x, 260.0), minf(col_sz.y, max_scroll_h))
	_fit_bottom_right_panel(transform_panel, 284.0)


func _parse_iec_or_int_address(raw_text: String) -> int:
	var s := raw_text.strip_edges().to_upper()
	if s.is_empty():
		return -1
	if s.is_valid_int():
		return clampi(s.to_int(), 0, 255)
	if (s.begins_with("X") or s.begins_with("Y")) and not s.contains("."):
		var oct_str := s.substr(1)
		if oct_str.is_empty():
			return -2
		var oct_val := 0
		for i in range(oct_str.length()):
			var ch := oct_str.unicode_at(i)
			if ch < 48 or ch > 55:
				return -2
			oct_val = oct_val * 8 + (ch - 48)
		return clampi(oct_val, 0, 255)
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
	if plc_notation == "fx3u":
		var fx_pfx := "Y" if prefix == "QX" else "X"
		return "%s%o" % [fx_pfx, addr]
	return "%%%s%d.%d" % [prefix, addr / 8, addr % 8]


func _set_selected_modbus_addr(meta_key: String, addr: int) -> void:
	if not is_instance_valid(selected_object):
		return
	if str(selected_object.get_meta("kind", "")) == "cabinet":
		var sel_slot := _get_selected_cabinet_slot_item()
		if not sel_slot.is_empty():
			sel_slot[meta_key] = addr
		return
	selected_object.set_meta(meta_key, addr)


func _get_selected_modbus_addr(meta_key: String) -> int:
	if not is_instance_valid(selected_object):
		return -1
	if str(selected_object.get_meta("kind", "")) == "cabinet":
		var sel_slot := _get_selected_cabinet_slot_item()
		return int(sel_slot.get(meta_key, -1)) if not sel_slot.is_empty() else -1
	return int(selected_object.get_meta(meta_key, -1))


func _on_modbus_tag_changed(meta_key: String, raw_text: String) -> void:
	if not edit_mode or not is_instance_valid(selected_object):
		return
	var parsed := _parse_iec_or_int_address(raw_text)
	if parsed >= -1:
		_set_selected_modbus_addr(meta_key, parsed)
		_refresh_cabinet_slot_io_preview()
		_save_settings()


func _commit_object_name() -> void:
	if not is_instance_valid(selected_object) or not is_instance_valid(object_name_input):
		return
	var raw := object_name_input.text.strip_edges()
	for ch in [".", ":", "@", "/", "\"", "%"]:
		raw = raw.replace(ch, "")
	if raw.is_empty():
		object_name_input.text = String(selected_object.name)
		return
	var final_name := _unique_sandbox_name(raw, selected_object)
	if String(selected_object.name) == final_name:
		object_name_input.text = final_name
		return
	selected_object.name = final_name
	object_name_input.text = final_name
	_refresh_io_status_list()
	_refresh_force_panel()
	_save_settings()
	sandbox_label.text = "Edit: renamed to " + final_name


func _add_modbus_row_buttons(
	row: HBoxContainer,
	meta_key: String,
	field: LineEdit,
	prefix: String,
	is_word: bool,
) -> void:
	var auto_btn := Button.new()
	auto_btn.text = "Auto"
	auto_btn.custom_minimum_size = Vector2(44, 0)
	auto_btn.tooltip_text = "Auto-assign next free %s address" % prefix
	auto_btn.pressed.connect(
		func():
			_auto_assign_modbus(meta_key, field, prefix, is_word),
	)
	row.add_child(auto_btn)
	var clr_btn := Button.new()
	clr_btn.text = "×"
	clr_btn.custom_minimum_size = Vector2(26, 0)
	clr_btn.tooltip_text = "Clear address"
	clr_btn.pressed.connect(
		func():
			_clear_modbus_field(meta_key, field),
	)
	row.add_child(clr_btn)


func _auto_assign_modbus(meta_key: String, field: LineEdit, prefix: String, is_word: bool) -> void:
	if not is_instance_valid(selected_object) or not is_instance_valid(field):
		return
	var is_cab := str(selected_object.get_meta("kind", "")) == "cabinet"
	var sel_slot := _get_selected_cabinet_slot_item() if is_cab else {}
	var used := {}
	for obj in get_tree().get_nodes_in_group("sandbox_objects"):
		var okind := str(obj.get_meta("kind", ""))
		if okind == "cabinet":
			var dslots: Array = obj.get("dynamic_slots") if "dynamic_slots" in obj else []
			for s in dslots:
				if s is Dictionary and s != sel_slot:
					var sv := int(s.get(meta_key, -1))
					if sv >= 0:
						used[sv] = true
						if meta_key == "modbus_input" and str(s.get("kind", "")) == "switch_3pos":
							used[sv + 1] = true
			continue
		if obj == selected_object:
			continue
		var v := int(obj.get_meta(meta_key, -1))
		if v >= 0:
			used[v] = true
	var start_addr := 10 if meta_key == "modbus_holding_reg" else 0
	var next_addr := start_addr
	while used.has(next_addr) and next_addr <= 255:
		next_addr += 1
	if next_addr > 255:
		sandbox_label.text = "No free %s address" % prefix
		return
	_set_selected_modbus_addr(meta_key, next_addr)
	field.text = _format_word_address(next_addr, prefix) if is_word else _format_iec_address(next_addr, prefix)
	_refresh_cabinet_slot_io_preview()
	_refresh_io_status_list()
	_refresh_modbus_conflict_warning()
	_save_settings()
	_save_layout(true)


func _clear_modbus_field(meta_key: String, field: LineEdit) -> void:
	if not is_instance_valid(selected_object) or not is_instance_valid(field):
		return
	_set_selected_modbus_addr(meta_key, -1)
	field.text = ""
	_refresh_cabinet_slot_io_preview()
	_refresh_io_status_list()
	_refresh_modbus_conflict_warning()
	_save_settings()
	_save_layout(true)


func _modbus_addr_span(obj: Node3D, meta_key: String) -> int:
	var kind := str(obj.get_meta("kind", ""))
	if meta_key == "modbus_input" and kind == "water_tank":
		return 3
	if meta_key == "modbus_coil" and kind == "stack_light":
		return 3
	if kind == "cabinet" and meta_key in ["modbus_coil", "modbus_input"]:
		var dir_match := "coil" if meta_key == "modbus_coil" else "input"
		var cnt := 0
		for it in _collect_cabinet_status_items(obj):
			if str(it.get("dir", "")) == dir_match:
				cnt += 1
		return maxi(1, cnt)
	return 1


func _refresh_modbus_conflict_warning() -> void:
	if not is_instance_valid(modbus_conflict_label):
		return
	if not is_instance_valid(selected_object):
		modbus_conflict_label.visible = false
		return
	var checks := [
		["modbus_coil", "QX", false],
		["modbus_input", "IX", false],
		["modbus_input_reg", "IW", true],
		["modbus_holding_reg", "QW", true],
	]
	var warnings: Array[String] = []
	for chk in checks:
		var key: String = chk[0]
		var pfx: String = chk[1]
		var is_w: bool = chk[2]
		var addr := int(selected_object.get_meta(key, -1))
		if addr < 0:
			continue
		var span_a := _modbus_addr_span(selected_object, key)
		for obj in get_tree().get_nodes_in_group("sandbox_objects"):
			if obj == selected_object:
				continue
			var other_addr := int(obj.get_meta(key, -1))
			if other_addr < 0:
				continue
			var span_b := _modbus_addr_span(obj as Node3D, key)
			if addr < other_addr + span_b and other_addr < addr + span_a:
				var overlap_addr := maxi(addr, other_addr)
				var fmt := _format_word_address(overlap_addr, pfx) if is_w else _format_iec_address(overlap_addr, pfx)
				warnings.append("[!] %s overlaps with %s" % [fmt, obj.name])
				break
	modbus_conflict_label.visible = not warnings.is_empty()
	modbus_conflict_label.text = "\n".join(warnings)
	_fit_transform_panel()


func _commit_modbus_field(meta_key: String, field: LineEdit, prefix: String) -> void:
	if not is_instance_valid(selected_object) or not is_instance_valid(field):
		return
	var parsed := _parse_iec_or_int_address(field.text)
	if parsed >= -1:
		_set_selected_modbus_addr(meta_key, parsed)
		field.text = _format_iec_address(parsed, prefix)
		_refresh_cabinet_slot_io_preview()
		_refresh_io_status_list()
		_refresh_modbus_conflict_warning()
		_save_settings()
		_save_layout(true)
	else:
		field.text = _format_iec_address(_get_selected_modbus_addr(meta_key), prefix)


func _parse_word_register_address(raw_text: String) -> int:
	var s := raw_text.strip_edges().to_upper()
	if s.is_empty():
		return -1
	if s.begins_with("%"):
		s = s.substr(1)
	for pfx in ["IW", "QW", "IR", "HR", "D"]:
		if s.begins_with(pfx):
			s = s.substr(pfx.length())
			break
	if s.is_valid_int():
		return clampi(s.to_int(), 0, 255)
	return -2


func _format_word_address(addr: int, prefix: String) -> String:
	if addr < 0:
		return ""
	if plc_notation == "fx3u":
		return "D%d" % addr
	return "%%%s%d" % [prefix, addr]


func _on_word_tag_changed(meta_key: String, raw_text: String) -> void:
	if not edit_mode or not is_instance_valid(selected_object):
		return
	var parsed := _parse_word_register_address(raw_text)
	if parsed >= -1:
		_set_selected_modbus_addr(meta_key, parsed)
		_refresh_cabinet_slot_io_preview()
		_save_settings()


func _commit_word_field(meta_key: String, field: LineEdit, prefix: String) -> void:
	if not is_instance_valid(selected_object) or not is_instance_valid(field):
		return
	var parsed := _parse_word_register_address(field.text)
	if parsed >= -1:
		_set_selected_modbus_addr(meta_key, parsed)
		field.text = _format_word_address(parsed, prefix)
		_refresh_cabinet_slot_io_preview()
		_refresh_io_status_list()
		_refresh_modbus_conflict_warning()
		_save_settings()
		_save_layout(true)
	else:
		field.text = _format_word_address(_get_selected_modbus_addr(meta_key), prefix)


func _on_conveyor_speed_changed(value: float) -> void:
	if not edit_mode or not is_instance_valid(selected_object):
		return
	if selected_object.get_meta("kind") not in ["conveyor", "conveyor_short"]:
		return
	selected_object.set_meta("configured_speed", value)
	if selected_object is StaticBody3D:
		_apply_conveyor_speed(selected_object as StaticBody3D)
	_save_settings()


func spawn_emitted_box(world_pos: Vector3, kind: String, is_defective: bool = false) -> RigidBody3D:
	var box: RigidBody3D
	match kind:
		"box_plastic":
			box = _spawn_plastic_box()
		"box":
			box = _spawn_cardboard_box()
		_:
			box = _spawn_product_by_kind(kind)
	if is_instance_valid(box):
		var spawn_y := world_pos.y + 1.12
		if kind != "pallet":
			spawn_y = maxf(spawn_y, _support_surface_y(world_pos, true) + 0.04)
			for p in get_tree().get_nodes_in_group("product_boxes"):
				if p == box or not is_instance_valid(p) or str(p.get_meta("kind", "")) != "pallet":
					continue
				if absf(p.global_position.x - world_pos.x) <= 0.65 and absf(p.global_position.z - world_pos.z) <= 0.65:
					spawn_y = maxf(spawn_y, p.global_position.y + 0.20)
		box.position = Vector3(world_pos.x, spawn_y, world_pos.z)
		box.freeze = (not running) and (not _has_any_forced_active())
		if is_defective:
			_apply_defective_visual(box, kind)
	return box


func _apply_defective_visual(box: RigidBody3D, kind: String) -> void:
	box.set_meta("is_defective", true)
	var top_y := 0.66
	match kind:
		"box":
			top_y = 0.66
		"box_plastic":
			top_y = 0.33
		"box_small":
			top_y = 0.37
		"box_metal":
			top_y = 0.45
		"pallet":
			top_y = 0.17
		"workpiece":
			top_y = 0.23
	for child in box.get_children():
		if child is Node3D and not (child is CollisionShape3D):
			(child as Node3D).scale = Vector3(1.05, 0.88, 0.94)
			break
	var marker := Node3D.new()
	marker.name = "DefectMarker"
	marker.position = Vector3(0.0, top_y, 0.0)
	var x_mat := StandardMaterial3D.new()
	x_mat.albedo_color = Color("e62229")
	x_mat.emission_enabled = true
	x_mat.emission = Color("ff3038")
	x_mat.emission_energy_multiplier = 0.7
	x_mat.roughness = 0.4
	for angle in [45.0, -45.0]:
		var bar := MeshInstance3D.new()
		var bar_mesh := BoxMesh.new()
		bar_mesh.size = Vector3(0.36, 0.014, 0.06)
		bar.mesh = bar_mesh
		bar.material_override = x_mat
		bar.rotation_degrees.y = angle
		marker.add_child(bar)
	var ng_label := Label3D.new()
	ng_label.position = Vector3(0.0, 0.22, 0.0)
	ng_label.text = "NG"
	ng_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	ng_label.pixel_size = 0.005
	ng_label.font_size = 32
	ng_label.outline_size = 6
	ng_label.modulate = Color("ff3b3b")
	ng_label.outline_modulate = Color(0.08, 0.02, 0.02, 0.95)
	marker.add_child(ng_label)
	box.add_child(marker)


func _spawn_product_by_kind(kind: String) -> RigidBody3D:
	var scene_path := "res://objects/" + kind + ".tscn"
	var packed := load(scene_path) as PackedScene
	if packed == null:
		return _spawn_cardboard_box()
	var box := packed.instantiate() as RigidBody3D
	box.set_meta("kind", kind)
	box.position = _product_world_position(kind, Vector3(-4.0, 0, 0))
	box.freeze = not running
	add_child(box, true)
	box.add_to_group("product_boxes")
	_set_product_color(box, kind, random.randi_range(0, BOX_COLORS.size() - 1))
	return box


func _spawn_box() -> RigidBody3D:
	if spawn_plastic_next:
		spawn_plastic_next = false
		return _spawn_plastic_box()
	spawn_plastic_next = true
	return _spawn_cardboard_box()


func _spawn_cardboard_box() -> RigidBody3D:
	var box := (load("res://objects/box.tscn") as PackedScene).instantiate() as RigidBody3D
	box.name = "ProductBox"
	box.set_meta("kind", "box")
	box.position = _product_world_position("box", Vector3(-4.0, 0, 0))
	box.freeze = not running
	add_child(box, true)
	box.add_to_group("product_boxes")
	var cardboard := box.find_child("CardboardBody", true, false) as MeshInstance3D
	var color_idx := random.randi_range(0, BOX_COLORS.size() - 1)
	cardboard.material_override = _get_product_material("box", color_idx)
	box.set_meta("color_index", color_idx)
	return box


func _spawn_plastic_box() -> RigidBody3D:
	var box := (load("res://objects/box_plastic.tscn") as PackedScene).instantiate() as RigidBody3D
	box.name = "PlasticBox"
	box.set_meta("kind", "box_plastic")
	box.position = _product_world_position("box_plastic", Vector3(-4.0, 0, 0)) + Vector3(0, 1.0, 0)
	box.freeze = not running
	add_child(box, true)
	box.add_to_group("product_boxes")
	var plastic := box.find_child("Box", true, false) as MeshInstance3D
	var color_idx := random.randi_range(0, BOX_COLORS.size() - 1)
	plastic.material_override = _get_product_material("box_plastic", color_idx)
	box.set_meta("color_index", color_idx)
	return box


func _has_placed_products() -> bool:
	for object in get_tree().get_nodes_in_group("sandbox_objects"):
		if object.get_meta("kind", "") in PRODUCT_KINDS:
			return true
	return false


func _support_surface_y(pos: Vector3, allow_pallet: bool = true) -> float:
	var top := floor_body.position.y + 0.125
	for object in get_tree().get_nodes_in_group("sandbox_objects"):
		var kind: String = object.get_meta("kind", "")
		if kind not in ["conveyor", "conveyor_short", "turn", "pallet"]:
			continue
		if kind == "pallet" and not allow_pallet:
			continue
		var center: Vector3 = object.get_meta("grid_position")
		var size := _object_footprint(object)
		if absf(pos.x - center.x) <= size.x * 0.5 and absf(pos.z - center.z) <= size.y * 0.5:
			var collision_name := "BeltCollision" if kind in ["conveyor", "conveyor_short"] else (
				"PalletCollision" if kind == "pallet" else "TurnCollision"
			)
			var collision := object.get_node_or_null(collision_name) as CollisionShape3D
			if collision != null:
				var half_h: float = (collision.shape as BoxShape3D).size.y * 0.5 if collision.shape is BoxShape3D else 0.125
				top = maxf(top, object.position.y + collision.position.y + half_h)
	return top


func _product_world_position(kind: String, pos: Vector3) -> Vector3:
	var support_y := _support_surface_y(pos, kind != "pallet")
	var floor_y := floor_body.position.y + 0.125
	var bottom := support_y + (0.005 if is_equal_approx(support_y, floor_y) else 0.02)
	return Vector3(pos.x, bottom, pos.z)


func _get_product_material(kind: String, color_index: int) -> StandardMaterial3D:
	var is_plastic := kind == "box_plastic"
	var cache := _plastic_color_materials if is_plastic else _cardboard_color_materials
	var cached := cache.get(color_index) as StandardMaterial3D
	if cached != null:
		return cached
	var base := _plastic_material() if is_plastic else _cardboard_material()
	var mat := base.duplicate() as StandardMaterial3D
	mat.albedo_color = BOX_COLORS[color_index]
	cache[color_index] = mat
	return mat


func _set_product_color(object: RigidBody3D, kind: String, color_index: int) -> void:
	object.set_meta("color_index", color_index)
	if kind not in ["box", "box_plastic", "box_small"]:
		return
	var visual_name := "Box" if kind == "box_plastic" else "CardboardBody"
	var visual := object.find_child(visual_name, true, false) as MeshInstance3D
	if visual == null:
		return
	visual.material_override = _get_product_material(kind, color_index)


func _restore_placed_products() -> void:
	for box in get_tree().get_nodes_in_group("product_boxes"):
		if box.is_in_group("sandbox_objects"):
			box.freeze = true
			box.visible = true
			box.linear_velocity = Vector3.ZERO
			box.angular_velocity = Vector3.ZERO
			box.position = _product_world_position(
				box.get_meta("kind"),
				box.get_meta("grid_position"),
			) + Vector3(0, float(box.get_meta("height_offset", 0.0)), 0)
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
		print("SENSOR_A_DETECTED count=", detected_count)


func _on_sensor_body_exited(body: Node3D) -> void:
	sensor_bodies.erase(body)
	_update_sensor_indicator()


func _update_sensor_indicator() -> void:
	var active := not sensor_bodies.is_empty()
	if is_instance_valid(sensor):
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
	if is_instance_valid(conveyor):
		_apply_conveyor_speed(conveyor)
	for object in get_tree().get_nodes_in_group("sandbox_conveyors"):
		if object is StaticBody3D:
			_apply_conveyor_speed(object as StaticBody3D)
	for obj in get_tree().get_nodes_in_group("sandbox_objects"):
		if str(obj.get_meta("kind", "")) == "turn":
			var area := obj.get_node_or_null("TransferArea")
			if area != null and not obj.has_meta("forced_active") and not plc_mode:
				area.set("active", false)
	if is_instance_valid(start_button):
		start_button.text = ""
		start_button.icon = _make_svg_icon(
			'<rect x="6" y="4" width="4" height="16"/><rect x="14" y="4" width="4" height="16"/>' if running else '<polygon points="6 3 20 12 6 21 6 3"/>'
		)
		if running:
			_style_accent_button(start_button, "7a2e33", "993b41", "cc5a61")
		else:
			_style_accent_button(start_button, "1e6b45", "278758", "3eb87a")
	_refresh_boxes_freeze()
	_refresh_cabinet_hud()
	if not test_mode and is_inside_tree():
		_save_settings()


func _apply_conveyor_speed(belt: StaticBody3D) -> void:
	if not belt.has_meta("configured_speed"):
		var initial_speed = belt.get("speed")
		belt.set_meta(
			"configured_speed",
			float(initial_speed) if initial_speed != null else BELT_SPEED,
		)
	var target_speed := float(belt.get_meta("configured_speed"))
	if "speed" in belt:
		belt.set("speed", target_speed)
	if "active" in belt:
		if belt.has_meta("forced_active"):
			belt.set("active", bool(belt.get_meta("forced_active")))
		elif not plc_mode:
			belt.set("active", running if test_mode else false)
		elif belt.has_method("_update_velocity"):
			belt.call("_update_velocity")
	else:
		belt.constant_linear_velocity = belt.global_basis.x.normalized() * (
			target_speed if (running and (plc_mode or test_mode)) else 0.0
		)


func _toggle_plc_mode() -> void:
	_apply_plc_mode(not plc_mode)


func _apply_plc_mode(enabled: bool, save_cfg: bool = true) -> void:
	plc_mode = enabled
	_refresh_cabinet_hud()
	for obj in get_tree().get_nodes_in_group("sandbox_objects"):
		var kind := str(obj.get_meta("kind", ""))
		if kind in ["pusher", "stopper", "emitter", "remover", "cabinet", "stack_light", "motor_fan", "pump", "water_tank", "solenoid_valve", "reject_bin"]:
			obj.set("plc_mode", plc_mode)
			if not plc_mode and kind != "cabinet":
				if obj.has_meta("forced_active"):
					obj.set("active", bool(obj.get_meta("forced_active")))
				else:
					if kind == "stack_light":
						obj.set("lamp_green_on", false)
						obj.set("lamp_yellow_on", false)
						obj.set("lamp_red_on", false)
					else:
						obj.set("active", false)
		elif kind == "turn":
			var area := obj.get_node_or_null("TransferArea")
			if area != null:
				area.set("plc_mode", plc_mode)
	if plc_mode:
		_sync_modbus_io()
	else:
		_set_running(running)
	if save_cfg and not test_mode and is_inside_tree():
		_save_settings()


func _save_settings() -> void:
	if test_mode or _is_loading_settings or not is_inside_tree():
		return
	var cfg := ConfigFile.new()
	cfg.set_value(
		"ui",
		"io_status_visible",
		io_status_panel.visible if is_instance_valid(io_status_panel) else true,
	)
	cfg.set_value("ui", "npcs_enabled", npcs_enabled)
	cfg.set_value("ui", "npc_operator_enabled", npc_operator_enabled)
	cfg.set_value("ui", "npc_tester_enabled", npc_tester_enabled)
	cfg.set_value("ui", "npc_safety_enabled", npc_safety_enabled)
	cfg.set_value("ui", "npc_maintenance_enabled", npc_maintenance_enabled)
	cfg.set_value("ui", "npc_qc_enabled", npc_qc_enabled)
	cfg.set_value("ui", "npc_walk_speed", npc_walk_speed)
	cfg.set_value("ui", "npc_inspect_duration", npc_inspect_duration)
	cfg.set_value("ui", "npc_chat_enabled", npc_chat_enabled)
	cfg.set_value("ui", "npc_sound_enabled", npc_sound_enabled)
	cfg.set_value("ui", "guide_lang", guide_lang)
	cfg.set_value("ui", "sound_enabled", sound_enabled)
	cfg.set_value("ui", "plc_mode", plc_mode)
	cfg.set_value("ui", "running", running)
	cfg.set_value("ui", "decor_style", decor_style)
	cfg.set_value("ui", "grid_step", grid_step)
	cfg.set_value("ui", "show_edit_grid", show_edit_grid)
	cfg.set_value("modbus", "enabled", ModbusTCP.enabled)
	cfg.set_value("modbus", "mode", int(ModbusTCP.mode))
	cfg.set_value("modbus", "bind_address", ModbusTCP.bind_address)
	cfg.set_value("modbus", "port", ModbusTCP.port)
	cfg.set_value("modbus", "remote_host", ModbusTCP.remote_host)
	cfg.set_value("modbus", "remote_port", ModbusTCP.remote_port)
	cfg.set_value("modbus", "poll_interval", ModbusTCP.poll_interval)
	cfg.set_value("modbus", "plc_notation", plc_notation)
	cfg.set_value("modbus", "address_profile", int(ModbusTCP.address_profile))
	cfg.set_value("modbus", "fx_coil_offset", ModbusTCP.fx_coil_offset)
	cfg.set_value("modbus", "fx_di_offset", ModbusTCP.fx_di_offset)
	cfg.set_value("modbus", "fx_hr_offset", ModbusTCP.fx_hr_offset)
	cfg.set_value("modbus", "fx_ir_offset", ModbusTCP.fx_ir_offset)
	cfg.set_value("modbus", "unit_id_filter", ModbusTCP.unit_id_filter)
	cfg.set_value("modbus", "client_unit_id", ModbusTCP.client_unit_id)
	cfg.set_value("modbus", "client_packed_di", ModbusTCP.client_packed_di)
	cfg.set_value("modbus", "cabinet_coil", cabinet_coil_addr)
	cfg.set_value("modbus", "cabinet_input", cabinet_input_addr)
	cfg.set_value("ladder", "enabled", soft_plc.enabled)
	cfg.set_value("ladder", "code", soft_plc.source_code)
	for item in CABINET_IO_DEFS:
		var io_id: String = item["id"]
		cfg.set_value("cabinet_io", io_id, int(cabinet_io_addrs.get(io_id, -1)))
	for obj in get_tree().get_nodes_in_group("sandbox_objects"):
		var kind := str(obj.get_meta("kind", ""))
		if kind in PRODUCT_KINDS or kind in PROP_KINDS:
			continue
		var key := obj.name
		cfg.set_value("objects", key + "_coil", int(obj.get_meta("modbus_coil", -1)))
		cfg.set_value("objects", key + "_input", int(obj.get_meta("modbus_input", -1)))
		if kind in ["vision_sensor", "rgb_sensor"]:
			cfg.set_value("objects", key + "_input_reg", int(obj.get_meta("modbus_input_reg", -1)))
			cfg.set_value(
				"objects",
				key + "_holding_reg",
				int(obj.get_meta("modbus_holding_reg", -1)),
			)
		if kind in ["conveyor", "conveyor_short"]:
			cfg.set_value(
				"objects",
				key + "_speed",
				float(obj.get_meta("configured_speed", BELT_SPEED)),
			)
		elif kind == "cabinet" and obj.has_method("get_customization"):
			cfg.set_value("objects", key + "_input_reg", int(obj.get_meta("modbus_input_reg", -1)))
			cfg.set_value("objects", key + "_cabinet_cfg", obj.call("get_customization"))
		elif kind == "water_tank" and obj.has_method("get_tank_config"):
			cfg.set_value("objects", key + "_input_reg", int(obj.get_meta("modbus_input_reg", -1)))
			cfg.set_value("objects", key + "_tank_cfg", obj.call("get_tank_config"))
	cfg.save(SETTINGS_PATH)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	_is_loading_settings = true
	var saved_enabled := bool(cfg.get_value("modbus", "enabled", true))
	var saved_mode := int(cfg.get_value("modbus", "mode", int(ModbusTCP.mode)))
	var saved_ip := str(cfg.get_value("modbus", "bind_address", ModbusTCP.bind_address))
	var saved_port := int(cfg.get_value("modbus", "port", ModbusTCP.port))
	var saved_remote_ip := str(cfg.get_value("modbus", "remote_host", ModbusTCP.remote_host))
	var saved_remote_port := int(cfg.get_value("modbus", "remote_port", ModbusTCP.remote_port))
	ModbusTCP.poll_interval = clampf(
		float(cfg.get_value("modbus", "poll_interval", ModbusTCP.poll_interval)),
		0.005,
		1.0,
	)
	plc_notation = str(cfg.get_value("modbus", "plc_notation", "iec"))
	if plc_notation not in ["iec", "fx3u"]:
		plc_notation = "iec"
	ModbusTCP.address_profile = (
		ModbusTCP.AddressProfile.FX3U_OFFSET
		if int(cfg.get_value("modbus", "address_profile", 1 if plc_notation == "fx3u" else 0)) == 1
		else ModbusTCP.AddressProfile.STANDARD_OPENPLC
	)
	ModbusTCP.fx_coil_offset = int(cfg.get_value("modbus", "fx_coil_offset", 0))
	ModbusTCP.fx_di_offset = int(cfg.get_value("modbus", "fx_di_offset", 0))
	ModbusTCP.fx_hr_offset = int(cfg.get_value("modbus", "fx_hr_offset", 0))
	ModbusTCP.fx_ir_offset = int(cfg.get_value("modbus", "fx_ir_offset", 0))
	ModbusTCP.unit_id_filter = int(cfg.get_value("modbus", "unit_id_filter", 0))
	ModbusTCP.client_unit_id = clampi(int(cfg.get_value("modbus", "client_unit_id", 1)), 1, 247)
	ModbusTCP.client_packed_di = bool(cfg.get_value("modbus", "client_packed_di", true))
	if is_instance_valid(ladder_notation_option):
		ladder_notation_option.select(1 if plc_notation == "fx3u" else 0)
	cabinet_coil_addr = int(cfg.get_value("modbus", "cabinet_coil", -1))
	cabinet_input_addr = int(cfg.get_value("modbus", "cabinet_input", -1))
	for item in CABINET_IO_DEFS:
		var io_id: String = item["id"]
		cabinet_io_addrs[io_id] = int(cfg.get_value("cabinet_io", io_id, -1))
	if (
		saved_enabled != ModbusTCP.enabled
		or saved_mode != int(ModbusTCP.mode) or saved_ip != ModbusTCP.bind_address
		or saved_port != ModbusTCP.port or saved_remote_ip != ModbusTCP.remote_host
		or saved_remote_port != ModbusTCP.remote_port
	):
		ModbusTCP.mode = saved_mode as ModbusTCP.Mode
		ModbusTCP.bind_address = saved_ip
		ModbusTCP.port = saved_port
		ModbusTCP.remote_host = saved_remote_ip
		ModbusTCP.remote_port = saved_remote_port
		ModbusTCP.enabled = saved_enabled
		if ModbusTCP.enabled:
			ModbusTCP.start_service()
		else:
			ModbusTCP.stop_service()

	soft_plc.enabled = bool(cfg.get_value("ladder", "enabled", false))
	if soft_plc.enabled and ModbusTCP.enabled:
		ModbusTCP.enabled = false
		ModbusTCP.stop_service()
	var saved_ladder_code := str(cfg.get_value("ladder", "code", ""))
	if not saved_ladder_code.is_empty():
		soft_plc.compile(saved_ladder_code)
		if is_instance_valid(ladder_code_edit):
			ladder_code_edit.text = saved_ladder_code
	if is_instance_valid(ladder_enabled_check):
		ladder_enabled_check.set_pressed_no_signal(soft_plc.enabled)
	if is_instance_valid(plc_controller_option):
		plc_controller_option.select(2 if soft_plc.enabled else (1 if ModbusTCP.enabled else 0))

	var status_vis := bool(cfg.get_value("ui", "io_status_visible", true))
	if is_instance_valid(io_status_panel) and io_status_panel.visible != status_vis:
		_toggle_io_status_panel()

	var saved_npcs := bool(cfg.get_value("ui", "npcs_enabled", true))
	npc_operator_enabled = bool(cfg.get_value("ui", "npc_operator_enabled", true))
	npc_tester_enabled = bool(cfg.get_value("ui", "npc_tester_enabled", true))
	npc_safety_enabled = bool(cfg.get_value("ui", "npc_safety_enabled", true))
	npc_maintenance_enabled = bool(cfg.get_value("ui", "npc_maintenance_enabled", true))
	npc_qc_enabled = bool(cfg.get_value("ui", "npc_qc_enabled", true))
	if is_instance_valid(npc_maint_check):
		npc_maint_check.set_pressed_no_signal(npc_maintenance_enabled)
	if is_instance_valid(npc_qc_check):
		npc_qc_check.set_pressed_no_signal(npc_qc_enabled)
	npc_walk_speed = clampf(float(cfg.get_value("ui", "npc_walk_speed", 1.85)), 0.5, 4.0)
	npc_inspect_duration = clampf(float(cfg.get_value("ui", "npc_inspect_duration", 2.2)), 0.5, 6.0)
	npc_chat_enabled = bool(cfg.get_value("ui", "npc_chat_enabled", true))
	npc_sound_enabled = bool(cfg.get_value("ui", "npc_sound_enabled", true))
	if is_instance_valid(npc_sound_check):
		npc_sound_check.set_pressed_no_signal(npc_sound_enabled)
	guide_lang = str(cfg.get_value("ui", "guide_lang", "en"))
	if guide_lang != "th":
		guide_lang = "en"
	if _help_rebuild_cb.is_valid():
		_help_rebuild_cb.call()
	_apply_npcs_enabled(saved_npcs)
	var saved_sound := bool(cfg.get_value("ui", "sound_enabled", true))
	_apply_sound_enabled(saved_sound)

	var want_plc: bool = bool(soft_plc.enabled) or ModbusTCP.enabled
	if want_plc != plc_mode:
		_apply_plc_mode(want_plc, false)

	var saved_running := bool(cfg.get_value("ui", "running", false))
	_set_running(saved_running)
	if not edit_mode:
		sandbox_label.text = "Mode: RUN" if saved_running else "Mode: STOP"
	var saved_decor := str(cfg.get_value("ui", "decor_style", "factory"))
	_apply_decor_style(saved_decor)
	grid_step = clampf(float(cfg.get_value("ui", "grid_step", GRID_STEP)), 0.25, 1.0)
	show_edit_grid = bool(cfg.get_value("ui", "show_edit_grid", true))
	if is_instance_valid(grid_step_option):
		var step_idx := 0 if grid_step < 0.35 else (2 if grid_step > 0.75 else 1)
		grid_step_option.select(step_idx)
	if is_instance_valid(show_grid_check):
		show_grid_check.set_pressed_no_signal(show_edit_grid)
	if is_instance_valid(edit_grid):
		_rebuild_grid()
		edit_grid.visible = edit_mode and show_edit_grid

	for obj in get_tree().get_nodes_in_group("sandbox_objects"):
		var kind := str(obj.get_meta("kind", ""))
		if kind in PRODUCT_KINDS or kind in PROP_KINDS:
			continue
		var key := obj.name
		if cfg.has_section_key("objects", key + "_coil"):
			var c_val := int(cfg.get_value("objects", key + "_coil", -1))
			if c_val >= 0 or int(obj.get_meta("modbus_coil", -1)) < 0:
				obj.set_meta("modbus_coil", c_val)
		if cfg.has_section_key("objects", key + "_input"):
			var i_val := int(cfg.get_value("objects", key + "_input", -1))
			if i_val >= 0 or int(obj.get_meta("modbus_input", -1)) < 0:
				obj.set_meta("modbus_input", i_val)
		if kind in ["vision_sensor", "rgb_sensor"]:
			if cfg.has_section_key("objects", key + "_input_reg"):
				var ir_val := int(cfg.get_value("objects", key + "_input_reg", -1))
				if ir_val >= 0 or int(obj.get_meta("modbus_input_reg", -1)) < 0:
					obj.set_meta("modbus_input_reg", ir_val)
			if cfg.has_section_key("objects", key + "_holding_reg"):
				var hr_val := int(cfg.get_value("objects", key + "_holding_reg", -1))
				if hr_val >= 0 or int(obj.get_meta("modbus_holding_reg", -1)) < 0:
					obj.set_meta("modbus_holding_reg", hr_val)
		if kind in ["conveyor", "conveyor_short"] and cfg.has_section_key("objects", key + "_speed"):
			obj.set_meta(
				"configured_speed",
				float(cfg.get_value("objects", key + "_speed", BELT_SPEED)),
			)
			if obj is StaticBody3D:
				_apply_conveyor_speed(obj as StaticBody3D)
		elif kind == "cabinet":
			if cfg.has_section_key("objects", key + "_input_reg"):
				var cab_ir := int(cfg.get_value("objects", key + "_input_reg", -1))
				if cab_ir >= 0 or int(obj.get_meta("modbus_input_reg", -1)) < 0:
					obj.set_meta("modbus_input_reg", cab_ir)
			if cfg.has_section_key("objects", key + "_cabinet_cfg"):
				var cab_cfg = cfg.get_value("objects", key + "_cabinet_cfg", {})
				if cab_cfg is Dictionary and obj.has_method("apply_customization"):
					obj.call("apply_customization", cab_cfg)
		elif kind == "water_tank":
			if cfg.has_section_key("objects", key + "_input_reg"):
				var wt_ir := int(cfg.get_value("objects", key + "_input_reg", -1))
				if wt_ir >= 0 or int(obj.get_meta("modbus_input_reg", -1)) < 0:
					obj.set_meta("modbus_input_reg", wt_ir)
			if cfg.has_section_key("objects", key + "_tank_cfg"):
				var wt_cfg = cfg.get_value("objects", key + "_tank_cfg", {})
				if wt_cfg is Dictionary and obj.has_method("apply_tank_config"):
					obj.call("apply_tank_config", wt_cfg)
	_is_loading_settings = false
	_refresh_modbus_dialog()
	_refresh_io_status_list()
	_refresh_transform_controls()
	_sync_2d_cabinet_customization(_get_active_cabinet_node())


func _clear_all_forces() -> void:
	for obj in get_tree().get_nodes_in_group("sandbox_objects"):
		if obj.has_meta("forced_active"):
			obj.remove_meta("forced_active")
		var kind := str(obj.get_meta("kind", ""))
		if kind in ["pusher", "stopper", "emitter", "remover", "cabinet", "stack_light", "motor_fan", "pump", "water_tank", "solenoid_valve", "reject_bin"]:
			obj.set("plc_mode", plc_mode)
			if not plc_mode and kind != "cabinet":
				if obj.has_meta("forced_active"):
					obj.set("active", bool(obj.get_meta("forced_active")))
				else:
					if kind == "stack_light":
						obj.set("lamp_green_on", false)
						obj.set("lamp_yellow_on", false)
						obj.set("lamp_red_on", false)
					else:
						obj.set("active", false)
			obj.set("active", false)
			if kind == "cabinet" and obj.has_method("clear_all_item_forces"):
				obj.call("clear_all_item_forces")
		elif kind == "turn":
			var area := obj.get_node_or_null("TransferArea")
			if area != null:
				area.set("plc_mode", plc_mode)
				area.set("active", false)
		elif kind in ["conveyor", "conveyor_short"]:
			obj.set("active", false)


func _on_modbus_coil_written(_addr: int, _value: bool) -> void:
	if plc_mode and is_inside_tree():
		_sync_modbus_io()
		_refresh_cabinet_hud()
		_refresh_io_status_list()


func _sync_modbus_io() -> void:
	if is_instance_valid(cabinet_layer):
		var di_start := int(cabinet_io_addrs.get("BtnStart", -1))
		var di_stop := int(cabinet_io_addrs.get("BtnStop", -1))
		var di_btn01 := int(cabinet_io_addrs.get("Btn01", -1))
		var di_auto := int(cabinet_io_addrs.get("SwitchAuto", -1))
		var di_estop := int(cabinet_io_addrs.get("SwitchEStop", -1))
		var do_green := int(cabinet_io_addrs.get("LampGreen", -1))
		var do_red := int(cabinet_io_addrs.get("LampRed", -1))
		if di_start >= 0:
			ModbusTCP.set_discrete_input(di_start, bool(cabinet_layer.get("start_active")))
		if di_stop >= 0:
			ModbusTCP.set_discrete_input(di_stop, bool(cabinet_layer.get("stop_active")))
		if di_btn01 >= 0:
			ModbusTCP.set_discrete_input(di_btn01, bool(cabinet_layer.get("reverse_active")))
		if di_auto >= 0:
			ModbusTCP.set_discrete_input(di_auto, bool(cabinet_layer.get("switch_auto_active")))
		if di_estop >= 0:
			ModbusTCP.set_discrete_input(di_estop, bool(cabinet_layer.get("estop_active")))
		if do_green >= 0:
			cabinet_layer.set("lamp_green_on", ModbusTCP.get_coil(do_green))
		if do_red >= 0:
			cabinet_layer.set("lamp_red_on", ModbusTCP.get_coil(do_red))
	for obj in get_tree().get_nodes_in_group("sandbox_objects"):
		var kind := str(obj.get_meta("kind", ""))
		if kind in PRODUCT_KINDS or kind in PROP_KINDS:
			continue
		var coil_addr := int(obj.get_meta("modbus_coil", -1))
		var input_addr := int(obj.get_meta("modbus_input", -1))
		# Always publish Discrete Inputs & Input Registers even when held
		if kind in ["sensor", "vision_sensor", "rgb_sensor", "light_curtain"] and input_addr >= 0:
			ModbusTCP.set_discrete_input(input_addr, bool(obj.get("active")))
		elif kind == "water_tank":
			if input_addr >= 0:
				ModbusTCP.set_discrete_input(input_addr, bool(obj.get("low_level")))
				ModbusTCP.set_discrete_input(input_addr + 1, bool(obj.get("mid_level")))
				ModbusTCP.set_discrete_input(input_addr + 2, bool(obj.get("high_level")))
			var wt_ir := int(obj.get_meta("modbus_input_reg", -1))
			if wt_ir >= 0:
				ModbusTCP.set_input_register(wt_ir, int(obj.get("level_percent")))
		if kind in ["vision_sensor", "rgb_sensor"]:
			var ir_addr := int(obj.get_meta("modbus_input_reg", -1))
			if ir_addr >= 0:
				var reg_val := int(obj.get("detected_id")) if kind == "vision_sensor" else int(
					obj.get("detected_color_id")
				)
				ModbusTCP.set_input_register(ir_addr, reg_val)
			var hr_addr := int(obj.get_meta("modbus_holding_reg", -1))
			if plc_mode and hr_addr >= 0:
				if kind == "vision_sensor":
					var cmd_mode := clampi(ModbusTCP.get_holding_register(hr_addr), 0, 4)
					if int(obj.get("detect_mode")) != cmd_mode:
						obj.set("detect_mode", cmd_mode)
						if selected_object == obj and is_instance_valid(vision_mode_option):
							vision_mode_option.select(cmd_mode)
				else:
					var cmd_color := clampi(ModbusTCP.get_holding_register(hr_addr), 0, 6)
					if int(obj.get("detect_color")) != cmd_color:
						obj.set("detect_color", cmd_color)
						if selected_object == obj and is_instance_valid(rgb_mode_option):
							rgb_mode_option.select(cmd_color)
		elif kind == "stopper" and input_addr >= 0:
			ModbusTCP.set_discrete_input(input_addr, bool(obj.get("part_at_gate")))
		elif kind == "stack_light":
			if coil_addr >= 0:
				obj.set("lamp_green_on", ModbusTCP.get_coil(coil_addr))
				obj.set("lamp_yellow_on", ModbusTCP.get_coil(coil_addr + 1))
				obj.set("lamp_red_on", ModbusTCP.get_coil(coil_addr + 2))
			continue
		elif kind == "cabinet":
			var dyn_slots: Array = obj.get("dynamic_slots") if "dynamic_slots" in obj else []
			var dyn_btn_states: Dictionary = obj.get("dynamic_button_states") if "dynamic_button_states" in obj else {}
			var dyn_pot_values: Dictionary = obj.get("dynamic_pot_values") if "dynamic_pot_values" in obj else {}
			for slot_item in dyn_slots:
				if not (slot_item is Dictionary):
					continue
				var mkind := str(slot_item.get("kind", "lamp"))
				var slot_io := str(slot_item.get("io_id", ""))
				if mkind == "potentiometer":
					var p_ir := int(slot_item.get("modbus_input_reg", -1))
					if p_ir >= 0:
						var pot_val := clampf(float(dyn_pot_values.get(slot_io, slot_item.get("value", 0.0))), 0.0, 1.0)
						ModbusTCP.set_input_register(p_ir, roundi(pot_val * 10000.0))
				elif mkind == "dpm":
					var d_hr := int(slot_item.get("modbus_holding_reg", -1))
					var d_val := ModbusTCP.get_holding_register(d_hr) if d_hr >= 0 else 0
					obj.call("set_dynamic_dpm", slot_io, d_val)
				elif mkind == "switch_3pos":
					var sw_in := int(slot_item.get("modbus_input", -1))
					if sw_in >= 0:
						ModbusTCP.set_discrete_input(sw_in, bool(dyn_btn_states.get(slot_io + "_L", false)))
						ModbusTCP.set_discrete_input(sw_in + 1, bool(dyn_btn_states.get(slot_io + "_R", false)))
				elif mkind in ["push_button", "button", "switch_select"]:
					var b_in := int(slot_item.get("modbus_input", -1))
					if b_in >= 0:
						ModbusTCP.set_discrete_input(b_in, bool(dyn_btn_states.get(slot_io, false)))
				else:
					var l_coil := int(slot_item.get("modbus_coil", -1))
					if l_coil >= 0:
						obj.call("set_dynamic_lamp", slot_io, ModbusTCP.get_coil(l_coil))
			continue
		if not running:
			continue
		if obj.has_meta("forced_active"):
			_apply_object_force(obj, bool(obj.get_meta("forced_active")))
			continue
		match kind:
			"conveyor", "conveyor_short":
				obj.set("active", running and coil_addr >= 0 and ModbusTCP.get_coil(coil_addr))
			"turn":
				var area := obj.get_node_or_null("TransferArea")
				if area != null:
					area.set("active", running and coil_addr >= 0 and ModbusTCP.get_coil(coil_addr))
			"pusher", "emitter", "motor_fan", "pump", "water_tank", "solenoid_valve", "remover", "reject_bin", "stopper":
				obj.set("active", running and coil_addr >= 0 and ModbusTCP.get_coil(coil_addr))


func _reset_simulation() -> void:
	_set_running(false)
	_set_selection(null)
	soft_plc.reset_runtime()
	_refresh_ladder_watch()
	_restore_placed_products()
	sensor_bodies.clear()
	_update_sensor_indicator()
	detected_count = 0
	if not _has_placed_products():
		var box := _spawn_box()
		box.freeze = true


func _enter_edit_mode() -> void:
	_clear_preview()
	edit_mode = true
	if is_instance_valid(edit_tools_row):
		edit_tools_row.visible = true
	if is_instance_valid(edit_mode_button):
		_style_accent_button(edit_mode_button, "1b4f6e", "23668f", "3b8cb8")
	edit_grid.visible = show_edit_grid
	dragging_object = false
	rotating_object = false
	placement = "select"
	_set_running(false)
	axis_gizmo.visible = true
	_restore_placed_products()
	sandbox_label.text = "Edit: select"
	_refresh_transform_controls()
	_update_cabinet_panel_visibility()


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
	if _edit_grid_material == null:
		_edit_grid_material = StandardMaterial3D.new()
		_edit_grid_material.vertex_color_use_as_albedo = true
		_edit_grid_material.roughness = 0.8
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var add_strip := func(cx: float, cz: float, hw: float, hd: float, col: Color) -> void:
		const GRID_Y := -0.052
		var p0 := Vector3(cx - hw, GRID_Y, cz - hd)
		var p1 := Vector3(cx + hw, GRID_Y, cz - hd)
		var p2 := Vector3(cx + hw, GRID_Y, cz + hd)
		var p3 := Vector3(cx - hw, GRID_Y, cz + hd)
		st.set_normal(Vector3.UP)
		st.set_color(col)
		st.add_vertex(p0)
		st.add_vertex(p1)
		st.add_vertex(p2)
		st.add_vertex(p0)
		st.add_vertex(p2)
		st.add_vertex(p3)
	var half_d := float(workspace_depth) * 0.5
	var half_w := float(workspace_width) * 0.5
	var steps_x := roundi(float(workspace_width) / (2.0 * grid_step))
	for ix in range(-steps_x, steps_x + 1):
		var x := float(ix) * grid_step
		var z_axis := ix == 0
		var is_major := ix % 2 == 0
		var w := 0.025 if z_axis else (0.012 if is_major else 0.007)
		var col := Color("78d989") if z_axis else (Color("54717b") if is_major else Color("384c54"))
		add_strip.call(x, 0.0, w * 0.5, half_d, col)
	var steps_z := roundi(float(workspace_depth) / (2.0 * grid_step))
	for iz in range(-steps_z, steps_z + 1):
		var z := float(iz) * grid_step
		var x_axis := iz == 0
		var is_major := iz % 2 == 0
		var w := 0.025 if x_axis else (0.012 if is_major else 0.007)
		var col := Color("f06d6d") if x_axis else (Color("54717b") if is_major else Color("384c54"))
		add_strip.call(0.0, z, half_w, w * 0.5, col)
	var grid_mi := MeshInstance3D.new()
	grid_mi.name = "EditGridMesh"
	grid_mi.mesh = st.commit()
	grid_mi.material_override = _edit_grid_material
	grid_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	edit_grid.add_child(grid_mi)


func _fits_workspace(pos: Vector3, size: Vector2, width: int, depth: int) -> bool:
	return absf(pos.x) + size.x * 0.5 <= width * 0.5 and absf(pos.z) + size.y * 0.5 <= depth * 0.5


func _apply_workspace_input() -> void:
	if not edit_mode:
		sandbox_label.text = "Switch to Edit before resizing"
		return
	var width := int(width_input.value)
	var depth := int(depth_input.value)
	for object in get_tree().get_nodes_in_group("sandbox_objects"):
		if not _fits_workspace(
			object.get_meta("grid_position"),
			_object_footprint(object),
			width,
			depth,
		):
			sandbox_label.text = "Resize blocked: equipment outside new area"
			return
	_record_undo_snapshot()
	_set_workspace_size(width, depth)
	sandbox_label.text = "Workspace: %d x %d" % [width, depth]
	_save_layout(true)


func _set_workspace_size(width: int, depth: int) -> void:
	workspace_width = width
	workspace_depth = depth
	var dimensions := Vector3(width, 0.25, depth)
	(floor_body.get_child(0) as MeshInstance3D).mesh.size = dimensions
	(floor_body.get_child(1) as CollisionShape3D).shape.size = dimensions
	_build_factory_decor()
	_rebuild_grid()
	if is_instance_valid(width_input):
		width_input.value = width
		depth_input.value = depth
	if is_instance_valid(floor_dialog_button):
		floor_dialog_button.text = "%d×%d" % [width, depth]
	_update_preview_color()


func _place_at(screen_position: Vector2) -> void:
	var point = _ground_point(screen_position)
	if point == null:
		return
	var snapped := _snap_placement(
		placement,
		Vector3(snappedf(point.x, grid_step), 0, snappedf(point.z, grid_step)),
		placement_angle,
	)
	if not _placement_valid(placement, snapped, placement_angle):
		sandbox_label.text = "Cannot place: overlaps same type or outside floor"
		return
	_record_undo_snapshot()
	var object := _create_sandbox_object(placement, snapped)
	if object != null:
		object.rotation_degrees.y = placement_angle
		if placement == "turn":
			_set_turn_direction(object, placement_reversed)
		elif placement == "cabinet":
			object.set("show_builtin_items", false)
			object.set("cabinet_title", "CABINET")
		if placement in PRODUCT_KINDS:
			object.set_meta("placed_rotation", placement_angle)
			var placed_kind := placement
			_set_placement("select")
			_set_selection(object)
			sandbox_label.text = "Placed " + placed_kind + " | drag or use object controls"
		else:
			sandbox_label.text = "Placed " + placement + " | click to add more; Esc to finish"
		_save_layout(true)


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
		"conveyor_short":
			dimensions = Vector3(3.0, 0.25, 1.5)
		"turn":
			dimensions = Vector3(1.5, 0.25, 1.5)
		"sensor":
			dimensions = Vector3(0.28, 1.0, 1.5)
			height = 1.55
		"vision_sensor", "rgb_sensor":
			dimensions = Vector3(0.50, 2.15, 1.15)
			height = 1.075
		"pusher":
			dimensions = Vector3(0.7, 1.35, 0.7)
			height = 0.675
		"stopper":
			dimensions = Vector3(0.50, 1.35, 1.65)
			height = 0.675
		"emitter":
			dimensions = Vector3(1.00, 2.45, 1.85)
			height = 1.225
		"remover":
			dimensions = Vector3(1.50, 1.25, 1.70)
			height = 0.625
		"stack_light":
			dimensions = Vector3(0.38, 2.25, 0.38)
			height = 1.125
		"motor_fan":
			dimensions = Vector3(1.00, 1.35, 1.00)
			height = 0.675
		"pump":
			dimensions = Vector3(1.00, 1.05, 1.00)
			height = 0.525
		"water_tank":
			dimensions = Vector3(1.50, 1.85, 1.50)
			height = 0.925
		"solenoid_valve":
			dimensions = Vector3(0.50, 0.72, 0.50)
			height = 0.36
		"light_curtain":
			dimensions = Vector3(0.50, 1.75, 1.85)
			height = 0.875
		"reject_bin":
			dimensions = Vector3(1.00, 0.65, 1.00)
			height = 0.325
		"cabinet":
			dimensions = Vector3(0.78, 1.98, 0.54)
			height = 0.99
		"box":
			dimensions = Vector3(0.65, 0.65, 0.65)
			height = _product_world_position(kind, Vector3.ZERO).y + 0.325
		"box_plastic":
			dimensions = Vector3(0.657, 0.314, 0.899)
			height = _product_world_position(kind, Vector3.ZERO).y + 0.157
		"box_small":
			dimensions = Vector3(0.36, 0.36, 0.36)
			height = _product_world_position(kind, Vector3.ZERO).y + 0.18
		"box_metal":
			dimensions = Vector3(0.68, 0.44, 0.68)
			height = _product_world_position(kind, Vector3.ZERO).y + 0.22
		"pallet":
			dimensions = Vector3(1.10, 0.16, 1.10)
			height = _product_world_position(kind, Vector3.ZERO).y + 0.08
		"workpiece":
			dimensions = Vector3(0.34, 0.22, 0.34)
			height = _product_world_position(kind, Vector3.ZERO).y + 0.11
		"prop_rack":
			dimensions = Vector3(2.00, 2.40, 1.00)
			height = 1.20
		"prop_barrier":
			dimensions = Vector3(1.50, 1.00, 0.24)
			height = 0.50
		"prop_barrel":
			dimensions = Vector3(0.70, 0.92, 0.70)
			height = 0.46
		"prop_workbench":
			dimensions = Vector3(1.60, 0.92, 0.80)
			height = 0.46
		"prop_forklift":
			dimensions = Vector3(1.20, 2.05, 2.20)
			height = 1.025
		"prop_pallet_stack":
			dimensions = Vector3(1.10, 1.04, 1.10)
			height = 0.52
		"prop_pallet_jack":
			dimensions = Vector3(0.62, 1.18, 1.50)
			height = 0.59
		"prop_bollard":
			dimensions = Vector3(0.32, 0.95, 0.32)
			height = 0.475
		"prop_safety_sign":
			dimensions = Vector3(0.56, 0.90, 0.56)
			height = 0.45
		"prop_qc_desk":
			dimensions = Vector3(1.40, 1.38, 0.76)
			height = 0.69
		"prop_production_board":
			dimensions = Vector3(1.60, 1.85, 0.56)
			height = 0.925
		"prop_locker":
			dimensions = Vector3(1.20, 1.90, 0.50)
			height = 0.95
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
		placement_preview.position = _snap_placement(
			placement,
			Vector3(snappedf(point.x, grid_step), 0, snappedf(point.z, grid_step)),
			placement_angle,
		)
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
	preview_material.albedo_color = Color(0.2, 0.9, 0.85, 0.45) if valid else Color(
		1.0,
		0.16,
		0.14,
		0.55,
	)
	if not valid:
		sandbox_label.text = reason
	else:
		sandbox_label.text = "Place " + placement + " | Q/E rotate | Esc cancel"


func _footprint(kind: String, angle: float) -> Vector2:
	var size := Vector2(9.0, 1.5)
	match kind:
		"conveyor_short":
			size = Vector2(3.0, 1.5)
		"turn":
			size = Vector2(1.5, 1.5)
		"sensor":
			size = Vector2(0.28, 1.5)
		"vision_sensor", "rgb_sensor":
			size = Vector2(0.50, 1.15)
		"pusher":
			size = Vector2(0.7, 0.7)
		"stopper":
			size = Vector2(0.50, 1.65)
		"emitter":
			size = Vector2(1.00, 1.85)
		"remover":
			size = Vector2(1.50, 1.70)
		"stack_light":
			size = Vector2(0.50, 0.50)
		"motor_fan", "pump", "reject_bin":
			size = Vector2(1.00, 1.00)
		"water_tank":
			size = Vector2(1.50, 1.50)
		"solenoid_valve":
			size = Vector2(0.50, 0.50)
		"light_curtain":
			size = Vector2(0.50, 1.85)
		"cabinet":
			size = Vector2(1.00, 0.50)
		"box":
			size = Vector2(0.65, 0.65)
		"box_plastic":
			size = Vector2(0.657, 0.899)
		"box_small":
			size = Vector2(0.36, 0.36)
		"box_metal":
			size = Vector2(0.68, 0.68)
		"pallet":
			size = Vector2(1.10, 1.10)
		"workpiece":
			size = Vector2(0.34, 0.34)
		"prop_rack":
			size = Vector2(2.00, 1.00)
		"prop_barrier":
			size = Vector2(1.50, 0.24)
		"prop_barrel":
			size = Vector2(0.70, 0.70)
		"prop_workbench":
			size = Vector2(1.60, 0.80)
		"prop_forklift":
			size = Vector2(1.20, 2.20)
		"prop_pallet_stack":
			size = Vector2(1.10, 1.10)
		"prop_pallet_jack":
			size = Vector2(0.62, 1.50)
		"prop_bollard":
			size = Vector2(0.32, 0.32)
		"prop_safety_sign":
			size = Vector2(0.56, 0.56)
		"prop_qc_desk":
			size = Vector2(1.40, 0.76)
		"prop_production_board":
			size = Vector2(1.60, 0.56)
		"prop_locker":
			size = Vector2(1.20, 0.50)
	var turns := posmod(roundi(angle / 90.0), 2)
	return Vector2(size.y, size.x) if turns == 1 else size


func _snap_placement(kind: String, pos: Vector3, angle: float, ignored: Node3D = null) -> Vector3:
	if kind in ["sensor", "vision_sensor", "rgb_sensor", "stopper", "emitter", "light_curtain"]:
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
				var dist := absf(candidate.z - pos.z) if belt_axis == 0 else absf(
					candidate.x - pos.x
				)
				if dist < best_push_dist and _placement_valid(kind, candidate, angle, ignored):
					best_push = candidate
					best_push_dist = dist
		return best_push
	if kind == "remover":
		var best_rem := pos
		var best_rem_dist := 0.85
		for other in get_tree().get_nodes_in_group("sandbox_objects"):
			if other == ignored:
				continue
			var other_kind: String = other.get_meta("kind")
			if other_kind not in ["conveyor", "conveyor_short", "turn"]:
				continue
			var center: Vector3 = other.get_meta("grid_position")
			var belt_axis := posmod(roundi(other.rotation_degrees.y / 90.0), 2)
			var snap_dist := 5.25
			if other_kind == "conveyor_short":
				snap_dist = 2.25
			elif other_kind == "turn":
				snap_dist = 1.50
			for side in [-1.0, 1.0]:
				var offset := Vector3(snap_dist * side, 0, 0) if belt_axis == 0 else Vector3(
					0,
					0,
					snap_dist * side,
				)
				var candidate := center + offset
				var distance := Vector2(pos.x - candidate.x, pos.z - candidate.z).length()
				if distance < best_rem_dist and _placement_valid(kind, candidate, angle, ignored):
					best_rem = candidate
					best_rem_dist = distance
		return best_rem
	if kind not in ["conveyor", "conveyor_short", "turn"]:
		return pos
	var axis := posmod(roundi(angle / 90.0), 2)
	var best := pos
	var best_distance := 0.76
	# Align a corner with either end of a belt, or a belt with a corner.
	for other in get_tree().get_nodes_in_group("sandbox_objects"):
		if other == ignored:
			continue
		var other_kind: String = other.get_meta("kind")
		var is_belt_kind := kind in ["conveyor", "conveyor_short"]
		var other_is_belt := other_kind in ["conveyor", "conveyor_short"]
		if not ((kind == "turn" and other_is_belt) or (is_belt_kind and other_kind == "turn")):
			continue
		var center: Vector3 = other.get_meta("grid_position")
		var belt_axis := posmod(roundi(other.rotation_degrees.y / 90.0), 2) if kind == "turn" else axis
		var snap_dist := 2.25 if (kind == "conveyor_short" or other_kind == "conveyor_short") else 5.25
		for side in [-1.0, 1.0]:
			var offset := Vector3(snap_dist * side, 0, 0) if belt_axis == 0 else Vector3(
				0,
				0,
				snap_dist * side,
			)
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
	return (
		absf(a.x - b.x) < (a_size.x + b_size.x) * 0.5 - 0.001
		and absf(a.z - b.z) < (a_size.y + b_size.y) * 0.5 - 0.001
	)


func _height_range(kind: String, height_offset: float) -> Vector2:
	var base := Vector2(0.0, 1.1)
	match kind:
		"conveyor", "conveyor_short":
			base = Vector2(0.0, 1.075)
		"turn":
			base = Vector2(0.0, 1.105)
		"sensor":
			base = Vector2(1.0, 1.65)
		"vision_sensor", "rgb_sensor":
			base = Vector2(0.0, 2.2)
		"stopper":
			base = Vector2(0.0, 1.40)
		"emitter":
			base = Vector2(0.0, 2.50)
		"remover":
			base = Vector2(0.0, 1.35)
		"stack_light":
			base = Vector2(0.0, 2.25)
		"motor_fan":
			base = Vector2(0.0, 1.35)
		"pump":
			base = Vector2(0.0, 1.05)
		"water_tank":
			base = Vector2(0.0, 1.85)
		"solenoid_valve":
			base = Vector2(0.0, 0.72)
		"light_curtain":
			base = Vector2(0.0, 1.75)
		"reject_bin":
			base = Vector2(0.0, 0.65)
		"cabinet":
			base = Vector2(0.0, 2.00)
		"pusher":
			base = Vector2(0.0, 1.38)
		"box":
			base = Vector2(1.075, 1.725)
		"box_plastic":
			base = Vector2(1.075, 1.39)
		"box_small":
			base = Vector2(1.075, 1.435)
		"box_metal":
			base = Vector2(1.075, 1.515)
		"pallet":
			base = Vector2(1.075, 1.235)
		"workpiece":
			base = Vector2(1.075, 1.295)
		"prop_rack":
			base = Vector2(0.0, 2.40)
		"prop_barrier":
			base = Vector2(0.0, 1.00)
		"prop_barrel":
			base = Vector2(0.0, 0.92)
		"prop_workbench":
			base = Vector2(0.0, 0.92)
		"prop_forklift":
			base = Vector2(0.0, 2.05)
		"prop_pallet_stack":
			base = Vector2(0.0, 1.04)
		"prop_pallet_jack":
			base = Vector2(0.0, 1.18)
		"prop_bollard":
			base = Vector2(0.0, 0.95)
		"prop_safety_sign":
			base = Vector2(0.0, 0.90)
		"prop_qc_desk":
			base = Vector2(0.0, 1.38)
		"prop_production_board":
			base = Vector2(0.0, 1.85)
		"prop_locker":
			base = Vector2(0.0, 1.90)
	return base + Vector2(height_offset, height_offset)


func _heights_overlap(a: Vector2, b: Vector2) -> bool:
	return a.x < b.y - 0.001 and b.x < a.y - 0.001


func _placement_conflict_reason(
	kind: String,
	pos: Vector3,
	angle: float,
	ignored: Node3D = null,
) -> String:
	if kind not in [
		"conveyor",
		"conveyor_short",
		"turn",
		"sensor",
		"vision_sensor",
		"rgb_sensor",
		"pusher",
		"stopper",
		"emitter",
		"remover",
		"stack_light",
		"motor_fan",
		"pump",
		"water_tank",
		"solenoid_valve",
		"light_curtain",
		"reject_bin",
		"cabinet",
		"box",
		"box_plastic",
		"box_small",
		"box_metal",
		"pallet",
		"workpiece",
	] and kind not in PROP_KINDS:
		return "Unsupported object type"
	var size := _footprint(kind, angle)
	if is_instance_valid(ignored) and ignored.get_meta("base_id", "") == "base_conveyor":
		size = Vector2(1.5, 9.0) if posmod(roundi(angle / 90.0), 2) == 1 else Vector2(9.0, 1.5)
	if not _fits_workspace(pos, size, workspace_width, workspace_depth):
		return "Outside floor bounds"
	var height_offset := float(ignored.get_meta("height_offset", 0.0)) if is_instance_valid(ignored) else 0.0
	var height_span := _height_range(kind, height_offset)
	# Sensors, stoppers, and emitters can span conveyors/turns, but cannot overlap each other or same-type objects.
	for object in get_tree().get_nodes_in_group("sandbox_objects"):
		var other_kind: String = object.get_meta("kind")
		if object == ignored:
			continue
		if kind in PRODUCT_KINDS or other_kind in PRODUCT_KINDS:
			if not (kind in PRODUCT_KINDS and other_kind in PRODUCT_KINDS):
				continue
			if (
				(other_kind == "pallet" and kind != "pallet")
				or (kind == "pallet" and other_kind != "pallet")
			):
				continue
		elif (
			kind in ["sensor", "vision_sensor", "rgb_sensor", "stopper", "emitter", "light_curtain"]
			or other_kind in ["sensor", "vision_sensor", "rgb_sensor", "stopper", "emitter", "light_curtain"]
		):
			if (
				other_kind in ["conveyor", "conveyor_short", "turn"]
				or kind in ["conveyor", "conveyor_short", "turn"]
			):
				continue
		var other_size := _object_footprint(object)
		var other_height := _height_range(other_kind, float(object.get_meta("height_offset", 0.0)))
		if (
			_rectangles_overlap(pos, size, object.get_meta("grid_position"), other_size)
			and _heights_overlap(height_span, other_height)
		):
			return "Overlaps: " + object.name
	return ""


func _placement_valid(kind: String, pos: Vector3, angle: float, ignored: Node3D = null) -> bool:
	return _placement_conflict_reason(kind, pos, angle, ignored).is_empty()


func _object_footprint(object: Node3D) -> Vector2:
	if object.get_meta("base_id", "") == "base_conveyor":
		return Vector2(1.5, 9.0) if posmod(roundi(object.rotation_degrees.y / 90.0), 2) == 1 else Vector2(
			9.0,
			1.5,
		)
	return _footprint(object.get_meta("kind"), object.rotation_degrees.y)


func _ground_point(screen_position: Vector2):
	return Plane(Vector3.UP, 0.0).intersects_ray(
		camera.project_ray_origin(screen_position),
		camera.project_ray_normal(screen_position),
	)


func _start_object_drag(screen_position: Vector2) -> void:
	if not is_instance_valid(selected_object) or not selected_object.is_in_group("sandbox_objects"):
		return
	_drag_undo_snapshot = _build_layout_data()
	var point = _ground_point(screen_position)
	if point == null:
		return
	drag_grid_offset = selected_object.get_meta("grid_position") - point
	dragging_object = true


func _start_rotation_drag() -> void:
	if (
		not edit_mode or not is_instance_valid(selected_object)
		or not selected_object.is_in_group("sandbox_objects")
	):
		return
	dragging_object = false
	rotating_object = true
	rotation_drag_pixels = 0.0
	_drag_undo_snapshot = _build_layout_data()


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
	if (
		not edit_mode or not is_instance_valid(selected_object)
		or not selected_object.is_in_group("sandbox_objects")
	):
		dragging_object = false
		return
	var point = _ground_point(screen_position)
	if point == null:
		return
	var new_grid := Vector3(
		snappedf(point.x + drag_grid_offset.x, grid_step),
		0,
		snappedf(point.z + drag_grid_offset.z, grid_step),
	)
	new_grid = _snap_placement(
		selected_object.get_meta("kind"),
		new_grid,
		selected_object.rotation_degrees.y,
		selected_object,
	)
	var previous: Vector3 = selected_object.get_meta("grid_position")
	if not _placement_valid(
		selected_object.get_meta("kind"),
		new_grid,
		selected_object.rotation_degrees.y,
		selected_object,
	):
		sandbox_label.text = "Cannot move: overlaps same type or outside floor"
		return
	_record_undo_snapshot()
	if selected_object.get_meta("kind") in PRODUCT_KINDS:
		selected_object.position = _product_world_position(
			selected_object.get_meta("kind"),
			new_grid,
		) + Vector3(0, float(selected_object.get_meta("height_offset", 0.0)), 0)
	else:
		selected_object.position += new_grid - previous
	selected_object.set_meta("grid_position", new_grid)
	_refresh_transform_controls()
	sandbox_label.text = "Edit: moved " + str(selected_object.get_meta("kind"))


func _unique_sandbox_name(base_name: String, exclude: Node = null) -> String:
	var clean_base := base_name.strip_edges()
	if clean_base.is_empty() or clean_base.begins_with("@"):
		clean_base = "Object"
	var existing := {}
	for child in get_children():
		if child != exclude:
			existing[String(child.name)] = true
	if not existing.has(clean_base):
		return clean_base
	var idx := 2
	while existing.has("%s%d" % [clean_base, idx]):
		idx += 1
	return "%s%d" % [clean_base, idx]


func _create_sandbox_object(kind: String, position: Vector3, is_base: bool = false) -> Node3D:
	var scene_path := "res://objects/" + kind + ".tscn"
	if kind not in [
		"conveyor",
		"conveyor_short",
		"turn",
		"sensor",
		"vision_sensor",
		"rgb_sensor",
		"pusher",
		"stopper",
		"emitter",
		"remover",
		"stack_light",
		"motor_fan",
		"pump",
		"water_tank",
		"solenoid_valve",
		"light_curtain",
		"reject_bin",
		"cabinet",
		"box",
		"box_plastic",
		"box_small",
		"box_metal",
		"pallet",
		"workpiece",
	] and kind not in PROP_KINDS:
		return null
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("Could not load equipment scene: " + scene_path)
		return null
	var object := packed.instantiate() as Node3D
	object.position = _product_world_position(kind, position) if kind in PRODUCT_KINDS else position + Vector3(
		0,
		float(EQUIPMENT_BASE_HEIGHT[kind]),
		0,
	)
	object.name = _unique_sandbox_name(object.name)
	add_child(object, true)
	object.add_to_group("sandbox_objects")
	object.set_meta("kind", kind)
	object.set_meta("grid_position", position)
	object.set_meta("height_offset", 0.0)
	if kind not in PRODUCT_KINDS and kind not in PROP_KINDS:
		object.set_meta("modbus_coil", -1)
		object.set_meta("modbus_input", -1)
		object.set_meta("modbus_input_reg", -1)
		object.set_meta("modbus_holding_reg", -1)
	if kind in PRODUCT_KINDS:
		var product := object as RigidBody3D
		product.freeze = true
		product.add_to_group("product_boxes")
		product.set_meta("placed_rotation", 0.0)
		_set_product_color(product, kind, random.randi_range(0, BOX_COLORS.size() - 1))
	elif kind in ["conveyor", "conveyor_short"]:
		object.add_to_group("sandbox_conveyors")
		if object is StaticBody3D:
			_apply_conveyor_speed(object as StaticBody3D)
	elif kind == "turn":
		_set_turn_direction(object, false)
		var turn_area := object.get_node_or_null("TransferArea")
		if turn_area != null:
			turn_area.set("plc_mode", plc_mode)
	elif kind in ["pusher", "stopper", "emitter", "remover", "stack_light", "motor_fan", "pump", "water_tank", "solenoid_valve", "reject_bin"]:
		object.set("plc_mode", plc_mode)
		if kind == "water_tank" and object.has_signal("valve_toggled_3d"):
			object.connect(
				"valve_toggled_3d",
				func(_open: bool):
					if selected_object == object:
						_refresh_force_panel()
						_refresh_transform_controls()
					_save_layout(true),
			)
	elif kind == "cabinet":
		object.set("plc_mode", plc_mode)
		object.connect(
			"estop_toggled_3d",
			func(is_estop: bool):
				if object == _get_active_cabinet_node() and is_instance_valid(cabinet_layer):
					cabinet_layer.set("estop_active", is_estop)
					var c3d := cabinet_layer.get("cabinet_3d") as Node3D
					if is_instance_valid(c3d):
						c3d.set("estop_active", is_estop)
						c3d.call("_update_estop")
						c3d.call("_update_lights")
				if not plc_mode and is_estop and not edit_mode:
					sandbox_label.text = "Mode: E-STOP"
				_refresh_cabinet_hud(),
		)
		object.connect(
			"selector_toggled_3d",
			func(is_auto: bool):
				if object == _get_active_cabinet_node() and is_instance_valid(cabinet_layer):
					cabinet_layer.set("switch_auto_active", is_auto)
					var c3d := cabinet_layer.get("cabinet_3d") as Node3D
					if is_instance_valid(c3d):
						c3d.set("selector_auto", is_auto)
						c3d.call("_update_selector"),
		)
		object.connect(
			"dynamic_pot_changed",
			func(val: float, io_id: String):
				if object == _get_active_cabinet_node() and is_instance_valid(cabinet_layer):
					var c3d := cabinet_layer.get("cabinet_3d") as Node3D
					if is_instance_valid(c3d) and c3d.has_method("set_dynamic_pot"):
						c3d.call("set_dynamic_pot", io_id, val),
		)
	elif kind == "sensor":
		var area := object as Area3D
		if is_base:
			area.body_entered.connect(_on_sensor_body_entered)
			area.body_exited.connect(_on_sensor_body_exited)
		else:
			var detected: Array[Node3D] = []
			area.body_entered.connect(
				func(body):
					if body.is_in_group("product_boxes"):
						detected.append(body)
						area.set_detected(true),
			)
			area.body_exited.connect(
				func(body):
					detected.erase(body)
					if detected.is_empty():
						area.set_detected(false),
			)
	return object


func _set_turn_direction(object: Node3D, reversed: bool) -> void:
	object.set_meta("reversed", reversed)
	for child in object.get_children():
		if child.is_in_group("belt_direction_arrows"):
			child.rotation_degrees.y = float(child.get_meta("normal_yaw")) + (
				180.0 if reversed else 0.0
			)


func _toggle_turn_direction() -> void:
	if not edit_mode:
		return
	if placement == "turn":
		placement_reversed = not placement_reversed
		sandbox_label.text = "Place turn: " + ("reverse" if placement_reversed else "forward")
		return
	if (
		placement != "select" or not is_instance_valid(selected_object)
		or selected_object.get_meta("kind", "") != "turn"
	):
		sandbox_label.text = "Select a turn to reverse"
		return
	_record_undo_snapshot()
	_set_turn_direction(selected_object, not selected_object.get_meta("reversed", false))
	_refresh_transform_controls()
	sandbox_label.text = "Turn: " + (
		"reverse" if selected_object.get_meta("reversed") else "forward"
	)
	_save_layout(true)


func _delete_selected() -> void:
	if (
		edit_mode and is_instance_valid(selected_object)
		and selected_object.is_in_group("sandbox_objects")
	):
		if selected_object.has_meta("base_id"):
			sandbox_label.text = "Base equipment can be moved and rotated"
			return
		_record_undo_snapshot()
		var object := selected_object
		_set_selection(null)
		object.remove_from_group("sandbox_objects")
		if object.get_parent() == self:
			remove_child(object)
		object.queue_free()
		sandbox_label.text = "Edit: object deleted"
		_save_layout(true)


func _move_selected(delta: Vector3) -> void:
	if (
		not edit_mode or not is_instance_valid(selected_object)
		or not selected_object.is_in_group("sandbox_objects")
	):
		return
	var target: Vector3 = selected_object.get_meta("grid_position") + delta
	if not _placement_valid(
		selected_object.get_meta("kind"),
		target,
		selected_object.rotation_degrees.y,
		selected_object,
	):
		sandbox_label.text = "Cannot move: overlaps same type or outside floor"
		return
	_record_undo_snapshot()
	if selected_object.get_meta("kind") in PRODUCT_KINDS:
		selected_object.position = _product_world_position(selected_object.get_meta("kind"), target) + Vector3(
			0,
			float(selected_object.get_meta("height_offset", 0.0)),
			0,
		)
	else:
		selected_object.position += delta
	selected_object.set_meta("grid_position", target)
	_refresh_transform_controls()
	sandbox_label.text = "Edit: moved " + str(selected_object.get_meta("kind"))
	_save_layout(true)


func _move_selected_height(direction: int) -> void:
	if (
		not edit_mode or not is_instance_valid(selected_object)
		or not selected_object.is_in_group("sandbox_objects")
	):
		return
	var previous := float(selected_object.get_meta("height_offset", 0.0))
	var next := clampf(previous + 0.25 * direction, -5.0, 10.0)
	if is_equal_approx(previous, next):
		return
	_record_undo_snapshot()
	selected_object.position.y += next - previous
	selected_object.set_meta("height_offset", next)
	_refresh_transform_controls()
	sandbox_label.text = "Z height: %.2f" % (
		selected_object.global_position.y - (floor_body.position.y + 0.125)
	)
	_save_layout(true)


func _rotate_selected(steps: int) -> void:
	if edit_mode and placement != "select":
		placement_angle = fposmod(placement_angle + 90.0 * steps, 360.0)
		if is_instance_valid(placement_preview):
			placement_preview.rotation_degrees.y = placement_angle
			_update_preview_color()
		sandbox_label.text = "Place " + placement + " | rotation: %d deg" % int(placement_angle)
		return
	if (
		not edit_mode or not is_instance_valid(selected_object)
		or not selected_object.is_in_group("sandbox_objects")
	):
		return
	var new_angle := fposmod(selected_object.rotation_degrees.y + 90.0 * steps, 360.0)
	if not _placement_valid(
		selected_object.get_meta("kind"),
		selected_object.get_meta("grid_position"),
		new_angle,
		selected_object,
	):
		sandbox_label.text = "Cannot rotate: overlaps same type or outside floor"
		return
	_record_undo_snapshot()
	selected_object.rotation_degrees.y = new_angle
	if selected_object.get_meta("kind") in PRODUCT_KINDS:
		selected_object.set_meta("placed_rotation", new_angle)
	_refresh_transform_controls()
	sandbox_label.text = "Edit: rotated " + str(selected_object.get_meta("kind"))
	_save_layout(true)


func _record_undo_snapshot(snap: Dictionary = {}) -> void:
	if test_mode or _is_loading_settings or not is_inside_tree():
		return
	var data := snap if not snap.is_empty() else _build_layout_data()
	undo_stack.append(data)
	if undo_stack.size() > MAX_UNDO_STEPS:
		undo_stack.remove_at(0)
	redo_stack.clear()
	_refresh_undo_buttons()


func _refresh_undo_buttons() -> void:
	if is_instance_valid(undo_button):
		undo_button.disabled = undo_stack.is_empty()
	if is_instance_valid(redo_button):
		redo_button.disabled = redo_stack.is_empty()


func _undo() -> void:
	if not edit_mode or undo_stack.is_empty():
		return
	redo_stack.append(_build_layout_data())
	var snap: Dictionary = undo_stack.pop_back()
	_apply_layout_data(snap, true)
	_refresh_undo_buttons()
	_save_layout(true)
	sandbox_label.text = "Undo (%d)" % undo_stack.size()


func _redo() -> void:
	if not edit_mode or redo_stack.is_empty():
		return
	undo_stack.append(_build_layout_data())
	var snap: Dictionary = redo_stack.pop_back()
	_apply_layout_data(snap, true)
	_refresh_undo_buttons()
	_save_layout(true)
	sandbox_label.text = "Redo (%d)" % redo_stack.size()


func _build_layout_data() -> Dictionary:
	var objects: Array = []
	for object in get_tree().get_nodes_in_group("sandbox_objects"):
		var pos: Vector3 = object.get_meta("grid_position")
		var kind: String = object.get_meta("kind")
		var rotation: float = object.get_meta("placed_rotation", object.rotation_degrees.y) if kind in PRODUCT_KINDS else object \
				.rotation_degrees \
				.y
		var entry := {
			"name": object.name,
			"kind": kind,
			"x": pos.x,
			"z": pos.z,
			"height_offset": object.get_meta("height_offset", 0.0),
			"rotation": rotation,
			"base_id": object.get_meta("base_id", ""),
			"reversed": object.get_meta("reversed", false),
		}
		if kind in PRODUCT_KINDS:
			entry["color_index"] = object.get_meta("color_index", 0)
		else:
			entry["modbus_coil"] = int(object.get_meta("modbus_coil", -1))
			entry["modbus_input"] = int(object.get_meta("modbus_input", -1))
			if kind in ["conveyor", "conveyor_short"]:
				entry["speed"] = float(object.get_meta("configured_speed", BELT_SPEED))
			elif kind == "vision_sensor":
				entry["detect_mode"] = int(object.get("detect_mode"))
				entry["modbus_input_reg"] = int(object.get_meta("modbus_input_reg", -1))
				entry["modbus_holding_reg"] = int(object.get_meta("modbus_holding_reg", -1))
			elif kind == "rgb_sensor":
				entry["detect_color"] = int(object.get("detect_color"))
				entry["modbus_input_reg"] = int(object.get_meta("modbus_input_reg", -1))
				entry["modbus_holding_reg"] = int(object.get_meta("modbus_holding_reg", -1))
			elif kind == "emitter":
				entry["box_mode"] = int(object.get("box_mode"))
				entry["defect_rate"] = int(object.get("defect_rate"))
			elif kind == "cabinet" and object.has_method("get_customization"):
				entry["modbus_input_reg"] = int(object.get_meta("modbus_input_reg", -1))
				entry["cabinet_cfg"] = object.call("get_customization")
			elif kind == "water_tank" and object.has_method("get_tank_config"):
				entry["modbus_input_reg"] = int(object.get_meta("modbus_input_reg", -1))
				entry["tank_cfg"] = object.call("get_tank_config")
		objects.append(entry)
	return {
		"version": 1,
		"workspace": {"width": workspace_width, "depth": workspace_depth},
		"objects": objects,
	}


func _save_layout(quiet: bool = false) -> void:
	if test_mode or _is_loading_settings or not is_inside_tree():
		return
	var file := FileAccess.open(SANDBOX_PATH, FileAccess.WRITE)
	if file == null:
		if not quiet:
			sandbox_label.text = "Save failed"
		return
	file.store_string(JSON.stringify(_build_layout_data(), "  "))
	if not quiet:
		sandbox_label.text = "Layout saved"


func _load_layout(auto_start: bool = false) -> void:
	if not FileAccess.file_exists(SANDBOX_PATH):
		if not auto_start:
			sandbox_label.text = "No saved layout"
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SANDBOX_PATH))
	if not data is Dictionary or data.get("version") != 1 or not data.get("objects") is Array:
		if not auto_start:
			sandbox_label.text = "Invalid layout"
		return
	var workspace = data.get("workspace", {"width": 22, "depth": 15})
	if (
		not workspace is Dictionary
		or not (workspace.get("width") is float or workspace.get("width") is int)
		or not (workspace.get("depth") is float or workspace.get("depth") is int)
	):
		if not auto_start:
			sandbox_label.text = "Invalid workspace size"
		return
	var new_width := int(workspace.width)
	var new_depth := int(workspace.depth)
	if (
		new_width < 10 or new_width > 100 or new_depth < 10 or new_depth > 100
		or float(new_width) != float(workspace.width) or float(new_depth) != float(workspace.depth)
	):
		if not auto_start:
			sandbox_label.text = "Invalid workspace size"
		return
	for entry in data.objects:
		if (
			not entry is Dictionary
			or entry.get("kind") not in [
				"sensor",
				"vision_sensor",
				"rgb_sensor",
				"conveyor",
				"conveyor_short",
				"turn",
				"pusher",
				"stopper",
				"emitter",
				"remover",
				"stack_light",
				"motor_fan",
				"pump",
				"water_tank",
				"solenoid_valve",
				"light_curtain",
				"reject_bin",
				"cabinet",
				"box",
				"box_plastic",
				"box_small",
				"box_metal",
				"pallet",
				"workpiece",
			] and entry.get("kind", "") not in PROP_KINDS
			or not (entry.get("x") is float or entry.get("x") is int)
			or not (entry.get("z") is float or entry.get("z") is int)
			or not (entry.get("rotation", 0) is float or entry.get("rotation", 0) is int)
		):
			if not auto_start:
				sandbox_label.text = "Invalid layout"
			return
		if (
			entry.get("base_id", "") not in ["", "base_conveyor", "base_sensor"]
			or (entry.get("base_id", "") == "base_conveyor" and entry.kind != "conveyor")
			or (entry.get("base_id", "") == "base_sensor" and entry.kind != "sensor")
		):
			if not auto_start:
				sandbox_label.text = "Invalid layout"
			return
		if not entry.get("reversed", false) is bool:
			if not auto_start:
				sandbox_label.text = "Invalid layout"
			return
		var height_offset = entry.get("height_offset", 0.0)
		if (
			not (height_offset is float or height_offset is int)
			or float(height_offset) < -5.0 or float(height_offset) > 10.0
		):
			if not auto_start:
				sandbox_label.text = "Invalid Z height"
			return
		if entry.kind in PRODUCT_KINDS and entry.has("color_index"):
			var color_index = entry.color_index
			if (
				not (color_index is float or color_index is int)
				or float(color_index) != float(int(color_index))
				or int(color_index) < 0 or int(color_index) >= BOX_COLORS.size()
			):
				if not auto_start:
					sandbox_label.text = "Invalid box color"
				return
	if not auto_start:
		_enter_edit_mode()
	_apply_layout_data(data, auto_start)


func _apply_layout_data(data: Dictionary, auto_start: bool = false) -> void:
	var workspace = data.get("workspace", {"width": 22, "depth": 15})
	var new_width := int(workspace.width)
	var new_depth := int(workspace.depth)
	_set_selection(null)
	_set_workspace_size(new_width, new_depth)
	var entries: Array = []
	for raw_entry in data.objects:
		if raw_entry.get("base_id", "") == "base_conveyor" and int(raw_entry.get("modbus_coil", -1)) < 0:
			var rx := float(raw_entry.x)
			var rz := float(raw_entry.z)
			var rh := float(raw_entry.get("height_offset", 0.0))
			var rrot := float(raw_entry.get("rotation", 0.0))
			var has_overlapping_conveyor := false
			for other in data.objects:
				if (
					other.get("kind", "") == "conveyor"
					and other.get("base_id", "") == ""
					and is_equal_approx(float(other.x), rx)
					and is_equal_approx(float(other.z), rz)
					and is_equal_approx(float(other.get("height_offset", 0.0)), rh)
					and is_equal_approx(float(other.get("rotation", 0.0)), rrot)
				):
					has_overlapping_conveyor = true
					break
			if has_overlapping_conveyor:
				continue
		entries.append(raw_entry)
	var has_base_conveyor := false
	var has_base_sensor := false
	for entry in entries:
		var base_id := str(entry.get("base_id", ""))
		if base_id == "base_conveyor":
			has_base_conveyor = true
		elif base_id == "base_sensor":
			has_base_sensor = true
	for object in get_tree().get_nodes_in_group("sandbox_objects"):
		var obj_base_id := str(object.get_meta("base_id", ""))
		if obj_base_id == "base_conveyor":
			if has_base_conveyor:
				object.set_meta("modbus_coil", -1)
				object.set_meta("modbus_input", -1)
				continue
			object.remove_from_group("sandbox_objects")
			object.remove_from_group("sandbox_conveyors")
			if object.get_parent() == self:
				remove_child(object)
			object.queue_free()
			conveyor = null
		elif obj_base_id == "base_sensor":
			if has_base_sensor:
				object.set_meta("modbus_coil", -1)
				object.set_meta("modbus_input", -1)
				continue
			object.remove_from_group("sandbox_objects")
			if object.get_parent() == self:
				remove_child(object)
			object.queue_free()
			sensor = null
			sensor_indicator = null
			sensor_indicator_material = null
		else:
			object.remove_from_group("sandbox_objects")
			if object.is_in_group("sandbox_conveyors"):
				object.remove_from_group("sandbox_conveyors")
			if object.get_parent() == self:
				remove_child(object)
			object.queue_free()
	for entry in entries:
		var position := Vector3(float(entry.x), 0, float(entry.z))
		var object: Node3D
		if entry.get("base_id", "") == "base_conveyor":
			if not is_instance_valid(conveyor):
				conveyor = _create_sandbox_object("conveyor", position, true) as StaticBody3D
				conveyor.name = "MainConveyor"
				conveyor.set_meta("base_id", "base_conveyor")
			object = conveyor
			object.position = position + Vector3(0, EQUIPMENT_BASE_HEIGHT.conveyor, 0)
			object.set_meta("grid_position", position)
		elif entry.get("base_id", "") == "base_sensor":
			if not is_instance_valid(sensor):
				sensor = _create_sandbox_object("sensor", position, true) as Area3D
				sensor.name = "EntrySensor"
				sensor.set_meta("base_id", "base_sensor")
				sensor_indicator = sensor.get_node("Indicator") as MeshInstance3D
				sensor_indicator_material = sensor_indicator.material_override as StandardMaterial3D
			object = sensor
			object.position = position + Vector3(0, EQUIPMENT_BASE_HEIGHT.sensor, 0)
			object.set_meta("grid_position", position)
		else:
			object = _create_sandbox_object(entry.kind, position)
			if object != null and entry.has("name"):
				var saved_name := str(entry.name)
				if not saved_name.is_empty() and not saved_name.begins_with("@"):
					object.name = _unique_sandbox_name(saved_name, object)
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
		if entry.kind not in PRODUCT_KINDS:
			if entry.has("modbus_coil"):
				object.set_meta("modbus_coil", int(entry.modbus_coil))
			if entry.has("modbus_input"):
				object.set_meta("modbus_input", int(entry.modbus_input))
			if (
				entry.kind in ["conveyor", "conveyor_short"]
				and entry.has("speed") and object is StaticBody3D
			):
				object.set_meta("configured_speed", float(entry.speed))
				_apply_conveyor_speed(object as StaticBody3D)
			elif entry.kind == "rgb_sensor":
				if entry.has("detect_color"):
					object.set("detect_color", int(entry.detect_color))
				if entry.has("modbus_input_reg"):
					object.set_meta("modbus_input_reg", int(entry.modbus_input_reg))
				if entry.has("modbus_holding_reg"):
					object.set_meta("modbus_holding_reg", int(entry.modbus_holding_reg))
			elif entry.kind == "vision_sensor":
				if entry.has("detect_mode"):
					object.set("detect_mode", int(entry.detect_mode))
				if entry.has("modbus_input_reg"):
					object.set_meta("modbus_input_reg", int(entry.modbus_input_reg))
				if entry.has("modbus_holding_reg"):
					object.set_meta("modbus_holding_reg", int(entry.modbus_holding_reg))
			elif entry.kind == "emitter":
				if entry.has("box_mode"):
					object.set("box_mode", int(entry.box_mode))
				if entry.has("defect_rate"):
					object.set("defect_rate", clampi(int(entry.defect_rate), 0, 100))
			elif entry.kind == "cabinet":
				if entry.has("modbus_input_reg"):
					object.set_meta("modbus_input_reg", int(entry.modbus_input_reg))
				if entry.has("cabinet_cfg") and entry.cabinet_cfg is Dictionary and object.has_method("apply_customization"):
					object.call("apply_customization", entry.cabinet_cfg)
			elif entry.kind == "water_tank":
				if entry.has("modbus_input_reg"):
					object.set_meta("modbus_input_reg", int(entry.modbus_input_reg))
				if entry.has("tank_cfg") and entry.tank_cfg is Dictionary and object.has_method("apply_tank_config"):
					object.call("apply_tank_config", entry.tank_cfg)
	_restore_placed_products()
	_refresh_io_status_list()
	_sync_2d_cabinet_customization(_get_active_cabinet_node())
	_refresh_cabinet_hud()
	if not auto_start:
		sandbox_label.text = "Layout loaded"


func _update_project_file_label() -> void:
	if not is_instance_valid(project_file_label):
		return
	if current_project_path.is_empty():
		project_file_label.text = "Unsaved"
		project_file_label.tooltip_text = "No project file opened yet"
	else:
		project_file_label.text = current_project_path.get_file()
		project_file_label.tooltip_text = current_project_path


func _on_new_project_pressed() -> void:
	if is_instance_valid(new_project_confirm_dialog):
		new_project_confirm_dialog.popup_centered()
	else:
		_create_new_project()


func _create_new_project() -> void:
	_is_loading_settings = true
	_set_running(false)
	_clear_all_forces()
	_set_selection(null)
	_set_workspace_size(30, 30)
	for object in get_tree().get_nodes_in_group("sandbox_objects"):
		if object.has_meta("base_id"):
			object.set_meta("modbus_coil", -1)
			object.set_meta("modbus_input", -1)
			continue
		object.remove_from_group("sandbox_objects")
		if object.get_parent() == self:
			remove_child(object)
		object.queue_free()
	cabinet_io_addrs.clear()
	cabinet_coil_addr = -1
	cabinet_input_addr = -1
	soft_plc.enabled = false
	soft_plc.source_code = ""
	if is_instance_valid(ladder_code_edit):
		ladder_code_edit.text = ""
	if is_instance_valid(ladder_enabled_check):
		ladder_enabled_check.set_pressed_no_signal(false)
	ModbusTCP.enabled = false
	ModbusTCP.stop_service()
	_apply_plc_mode(false, false)
	if is_instance_valid(plc_controller_option):
		plc_controller_option.select(0)
	_is_loading_settings = false
	current_project_path = ""
	_update_project_file_label()
	_refresh_modbus_dialog()
	_refresh_transform_controls()
	_refresh_io_status_list()
	_refresh_cabinet_hud()
	_update_cabinet_panel_visibility()
	_save_layout(true)
	_save_settings()
	if is_instance_valid(sandbox_label):
		sandbox_label.text = "New project"


func _on_open_project_pressed() -> void:
	if not is_instance_valid(project_file_dialog):
		return
	project_file_dialog_mode = "open"
	project_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	project_file_dialog.title = "Open Factory Project (.pksfac)"
	if not current_project_path.is_empty():
		project_file_dialog.current_dir = current_project_path.get_base_dir()
	project_file_dialog.popup_centered_ratio(0.6)


func _on_save_project_pressed() -> void:
	if current_project_path.is_empty():
		_on_save_project_as_pressed()
		return
	_save_project_to_path(current_project_path)


func _on_save_project_as_pressed() -> void:
	if not is_instance_valid(project_file_dialog):
		return
	project_file_dialog_mode = "save_as"
	project_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	project_file_dialog.title = "Save Factory Project (.pksfac)"
	if not current_project_path.is_empty():
		project_file_dialog.current_path = current_project_path
	else:
		project_file_dialog.current_file = "factory_project.pksfac"
	project_file_dialog.popup_centered_ratio(0.6)


func _on_project_file_selected(path: String) -> void:
	if project_file_dialog_mode == "open":
		_load_project_from_path(path)
	elif project_file_dialog_mode == "save_as":
		_save_project_to_path(path)


func _build_project_data() -> Dictionary:
	var data := _build_layout_data()
	data["format"] = "pks_factory_project"
	data["project_version"] = 1
	data["plc"] = {
		"plc_mode": plc_mode,
		"plc_notation": plc_notation,
		"modbus_enabled": ModbusTCP.enabled,
		"modbus_mode": int(ModbusTCP.mode),
		"bind_address": ModbusTCP.bind_address,
		"port": ModbusTCP.port,
		"remote_host": ModbusTCP.remote_host,
		"remote_port": ModbusTCP.remote_port,
		"poll_interval": ModbusTCP.poll_interval,
		"address_profile": int(ModbusTCP.address_profile),
		"fx_coil_offset": ModbusTCP.fx_coil_offset,
		"fx_di_offset": ModbusTCP.fx_di_offset,
		"fx_hr_offset": ModbusTCP.fx_hr_offset,
		"fx_ir_offset": ModbusTCP.fx_ir_offset,
		"unit_id_filter": ModbusTCP.unit_id_filter,
		"client_unit_id": ModbusTCP.client_unit_id,
		"client_packed_di": ModbusTCP.client_packed_di,
		"cabinet_coil_addr": cabinet_coil_addr,
		"cabinet_input_addr": cabinet_input_addr,
		"cabinet_io_addrs": cabinet_io_addrs.duplicate(true),
	}
	data["ladder"] = {
		"enabled": soft_plc.enabled,
		"code": ladder_code_edit.text if is_instance_valid(ladder_code_edit) else soft_plc.source_code,
	}
	data["ui"] = {
		"decor_style": decor_style,
		"grid_step": grid_step,
		"show_edit_grid": show_edit_grid,
	}
	return data


func _save_project_to_path(path: String) -> bool:
	var target := path
	if not target.to_lower().ends_with("." + PROJECT_FILE_EXT):
		target += "." + PROJECT_FILE_EXT
	var file := FileAccess.open(target, FileAccess.WRITE)
	if file == null:
		if is_instance_valid(sandbox_label):
			sandbox_label.text = "Project save failed"
		return false
	file.store_string(JSON.stringify(_build_project_data(), "  "))
	current_project_path = target
	_update_project_file_label()
	if is_instance_valid(sandbox_label):
		sandbox_label.text = "Saved: " + target.get_file()
	return true


func _load_project_from_path(path: String) -> bool:
	if not FileAccess.file_exists(path):
		if is_instance_valid(sandbox_label):
			sandbox_label.text = "Project file not found"
		return false
	var raw_text := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(raw_text)
	if not data is Dictionary or not data.get("objects") is Array:
		if is_instance_valid(sandbox_label):
			sandbox_label.text = "Invalid project file"
		return false
	_is_loading_settings = true
	_set_running(false)
	_apply_layout_data(data, true)
	if data.has("ui") and data.ui is Dictionary:
		var ui_cfg: Dictionary = data.ui
		var saved_decor := str(ui_cfg.get("decor_style", decor_style))
		_apply_decor_style(saved_decor)
		grid_step = clampf(float(ui_cfg.get("grid_step", grid_step)), 0.25, 1.0)
		show_edit_grid = bool(ui_cfg.get("show_edit_grid", show_edit_grid))
		if is_instance_valid(grid_step_option):
			var step_idx := 0 if grid_step < 0.35 else (2 if grid_step > 0.75 else 1)
			grid_step_option.select(step_idx)
		if is_instance_valid(show_grid_check):
			show_grid_check.set_pressed_no_signal(show_edit_grid)
		if is_instance_valid(edit_grid):
			_rebuild_grid()
			edit_grid.visible = edit_mode and show_edit_grid
	if data.has("plc") and data.plc is Dictionary:
		var plc_cfg: Dictionary = data.plc
		plc_notation = str(plc_cfg.get("plc_notation", plc_notation))
		ModbusTCP.mode = clampi(int(plc_cfg.get("modbus_mode", int(ModbusTCP.mode))), 0, 1)
		ModbusTCP.bind_address = str(plc_cfg.get("bind_address", ModbusTCP.bind_address))
		ModbusTCP.port = int(plc_cfg.get("port", ModbusTCP.port))
		ModbusTCP.remote_host = str(plc_cfg.get("remote_host", ModbusTCP.remote_host))
		ModbusTCP.remote_port = int(plc_cfg.get("remote_port", ModbusTCP.remote_port))
		ModbusTCP.poll_interval = float(plc_cfg.get("poll_interval", ModbusTCP.poll_interval))
		ModbusTCP.address_profile = clampi(int(plc_cfg.get("address_profile", int(ModbusTCP.address_profile))), 0, 1)
		ModbusTCP.fx_coil_offset = int(plc_cfg.get("fx_coil_offset", ModbusTCP.fx_coil_offset))
		ModbusTCP.fx_di_offset = int(plc_cfg.get("fx_di_offset", ModbusTCP.fx_di_offset))
		ModbusTCP.fx_hr_offset = int(plc_cfg.get("fx_hr_offset", ModbusTCP.fx_hr_offset))
		ModbusTCP.fx_ir_offset = int(plc_cfg.get("fx_ir_offset", ModbusTCP.fx_ir_offset))
		ModbusTCP.unit_id_filter = int(plc_cfg.get("unit_id_filter", ModbusTCP.unit_id_filter))
		ModbusTCP.client_unit_id = int(plc_cfg.get("client_unit_id", ModbusTCP.client_unit_id))
		ModbusTCP.client_packed_di = bool(plc_cfg.get("client_packed_di", ModbusTCP.client_packed_di))
		cabinet_coil_addr = int(plc_cfg.get("cabinet_coil_addr", cabinet_coil_addr))
		cabinet_input_addr = int(plc_cfg.get("cabinet_input_addr", cabinet_input_addr))
		if plc_cfg.has("cabinet_io_addrs") and plc_cfg.cabinet_io_addrs is Dictionary:
			cabinet_io_addrs = plc_cfg.cabinet_io_addrs.duplicate(true)
		ModbusTCP.enabled = bool(plc_cfg.get("modbus_enabled", false))
		if ModbusTCP.enabled:
			ModbusTCP.start_service()
		else:
			ModbusTCP.stop_service()
	if data.has("ladder") and data.ladder is Dictionary:
		var lad_cfg: Dictionary = data.ladder
		soft_plc.enabled = bool(lad_cfg.get("enabled", false))
		if soft_plc.enabled and ModbusTCP.enabled:
			ModbusTCP.enabled = false
			ModbusTCP.stop_service()
		var lad_code := str(lad_cfg.get("code", ""))
		if not lad_code.is_empty():
			soft_plc.compile(lad_code)
			if is_instance_valid(ladder_code_edit):
				ladder_code_edit.text = lad_code
	var want_plc: bool = bool(soft_plc.enabled) or ModbusTCP.enabled
	if want_plc != plc_mode:
		_apply_plc_mode(want_plc, false)
	if is_instance_valid(ladder_enabled_check):
		ladder_enabled_check.set_pressed_no_signal(soft_plc.enabled)
	if is_instance_valid(plc_controller_option):
		plc_controller_option.select(2 if soft_plc.enabled else (1 if ModbusTCP.enabled else 0))
	_is_loading_settings = false
	current_project_path = path
	_update_project_file_label()
	_refresh_modbus_dialog()
	_refresh_transform_controls()
	_refresh_io_status_list()
	_refresh_cabinet_hud()
	_update_cabinet_panel_visibility()
	_save_layout(true)
	_save_settings()
	if is_instance_valid(sandbox_label):
		sandbox_label.text = "Opened: " + path.get_file()
	return true
