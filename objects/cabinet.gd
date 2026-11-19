extends StaticBody3D

signal start_pressed_3d
signal stop_pressed_3d
signal reverse_pressed_3d
signal estop_toggled_3d(active: bool)
signal selector_toggled_3d(active: bool)
signal dynamic_button_pressed(io_id: String)
signal dynamic_button_released(io_id: String)
signal dynamic_switch_toggled(active: bool, io_id: String)
signal dynamic_switch_3pos_changed(pos: int, io_id: String)
signal dynamic_pot_changed(val: float, io_id: String)

const BTN_Z_RELEASED := 0.28
const BTN_Z_PRESSED := 0.273
const ESTOP_Z_RELEASED := 0.288
const ESTOP_Z_ACTIVE := 0.276
const BTN_TRAVEL_SPEED := 0.14
const SLOT_COL_X := [-0.13, 0.0, 0.13]
const SLOT_ROW_Y := [1.63, 1.48, 1.33, 1.18, 1.03]
const SLOT_Z := 0.276
const CABINET_LAMP_SCENE := preload("res://objects/cabinet_modules/cabinet_lamp.tscn")
const CABINET_BTN_SCENE := preload("res://objects/cabinet_modules/cabinet_button.tscn")
const CABINET_SWITCH_SCENE := preload("res://objects/cabinet_modules/cabinet_switch.tscn")
const CABINET_POT_SCENE := preload("res://objects/cabinet_modules/cabinet_pot.tscn")
const CABINET_DPM_SCENE := preload("res://objects/cabinet_modules/cabinet_dpm.tscn")

var dynamic_slots: Array[Dictionary] = []
var dynamic_button_states: Dictionary = {}
var dynamic_pot_values: Dictionary = {}
var forced_items: Dictionary = {}
var _dynamic_container: Node3D = null

@export var active: bool = false:
	set(value):
		active = value
		_update_lights()

@export var plc_mode: bool = false

@export_group("Customization")
@export var cabinet_title: String = "MAIN CONTROL":
	set(value):
		cabinet_title = value
		if is_node_ready():
			_apply_appearance()

@export var show_builtin_items: bool = true:
	set(value):
		show_builtin_items = value
		if is_node_ready():
			_apply_appearance()

@export var show_yellow_lamp: bool = true:
	set(value):
		show_yellow_lamp = value
		if is_node_ready():
			_apply_appearance()

@export var show_rev_btn: bool = true:
	set(value):
		show_rev_btn = value
		if is_node_ready():
			_apply_appearance()

@export var lamp_green_label: String = "GREEN":
	set(value):
		lamp_green_label = value
		if is_node_ready():
			_apply_appearance()

@export var lamp_yellow_label: String = "YELLOW":
	set(value):
		lamp_yellow_label = value
		if is_node_ready():
			_apply_appearance()

@export var lamp_red_label: String = "RED":
	set(value):
		lamp_red_label = value
		if is_node_ready():
			_apply_appearance()

@export var btn_start_label: String = "START":
	set(value):
		btn_start_label = value
		if is_node_ready():
			_apply_appearance()

@export var btn_stop_label: String = "STOP":
	set(value):
		btn_stop_label = value
		if is_node_ready():
			_apply_appearance()

@export var btn01_label: String = "BTN01":
	set(value):
		btn01_label = value
		if is_node_ready():
			_apply_appearance()

@export var switch_auto_label: String = "MAN  AUTO":
	set(value):
		switch_auto_label = value
		if is_node_ready():
			_apply_appearance()

@export var switch_estop_label: String = "E-STOP":
	set(value):
		switch_estop_label = value
		if is_node_ready():
			_apply_appearance()

@export var start_btn_color: Color = Color(0.14, 0.62, 0.28, 1):
	set(value):
		start_btn_color = value
		if is_node_ready():
			_apply_appearance()

@export var stop_btn_color: Color = Color(0.86, 0.16, 0.16, 1):
	set(value):
		stop_btn_color = value
		if is_node_ready():
			_apply_appearance()

@export var rev_btn_color: Color = Color(0.95, 0.8, 0.18, 1):
	set(value):
		rev_btn_color = value
		if is_node_ready():
			_apply_appearance()

var estop_active := false
var selector_auto := false
var start_held := false
var stop_held := false
var reverse_held := false
var start_pressed := false
var stop_pressed := false
var reverse_pressed := false
var start_pulse := 0.0
var stop_pulse := 0.0
var reverse_pulse := 0.0

var lamp_green_on := false
var lamp_yellow_on := false
var lamp_red_on := false
var _ui_timer := 0.0
var _last_light_mask := -1

@onready var lamp_fwd: MeshInstance3D = $LampGreen
@onready var lamp_yellow: MeshInstance3D = $LampYellow
@onready var lamp_rev: MeshInstance3D = $LampRed
@onready var start_btn_mesh: MeshInstance3D = $StartBtnMesh
@onready var stop_btn_mesh: MeshInstance3D = $StopBtnMesh
@onready var rev_btn_mesh: MeshInstance3D = $RevBtnMesh
@onready var selector_knob: Node3D = $SelectorKnob
@onready var estop_btn_mesh: MeshInstance3D = $EStopMesh

func _ready() -> void:
	$StartBtnArea.input_event.connect(_on_start_input)
	$StopBtnArea.input_event.connect(_on_stop_input)
	$RevBtnArea.input_event.connect(_on_rev_input)
	$SelectorArea.input_event.connect(_on_selector_input)
	$EStopArea.input_event.connect(_on_estop_input)
	_apply_appearance()
	_update_lights()
	_update_selector()
	_update_estop()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		start_held = false
		stop_held = false
		reverse_held = false

func _process(delta: float) -> void:
	if start_pulse > 0.0:
		start_pulse = maxf(0.0, start_pulse - delta)
	if stop_pulse > 0.0:
		stop_pulse = maxf(0.0, stop_pulse - delta)
	if reverse_pulse > 0.0:
		reverse_pulse = maxf(0.0, reverse_pulse - delta)
	start_pressed = bool(forced_items["start"]) if forced_items.has("start") else (start_held or start_pulse > 0.0)
	stop_pressed = bool(forced_items["stop"]) if forced_items.has("stop") else (stop_held or stop_pulse > 0.0)
	reverse_pressed = reverse_held or reverse_pulse > 0.0
	if forced_items.has("estop"):
		estop_active = bool(forced_items["estop"])
	_update_button_z(start_btn_mesh, start_pressed, delta)
	_update_button_z(stop_btn_mesh, stop_pressed, delta)
	_update_button_z(rev_btn_mesh, reverse_pressed, delta)
	_ui_timer += delta
	if _ui_timer >= 0.1 and not (get_parent() is SubViewport):
		_ui_timer = 0.0
		_update_lights()

func _update_button_z(mesh: MeshInstance3D, pressed: bool, delta: float) -> void:
	if mesh == null:
		return
	var target_z := BTN_Z_PRESSED if pressed else BTN_Z_RELEASED
	if not is_equal_approx(mesh.position.z, target_z):
		mesh.position.z = move_toward(mesh.position.z, target_z, delta * BTN_TRAVEL_SPEED)

func _can_click_buttons() -> bool:
	var scene := get_parent()
	if scene is SubViewport:
		return true
	return scene != null and not bool(scene.get("edit_mode"))

func trigger_start() -> void:
	start_pulse = 0.15
	start_pressed = true
	start_pressed_3d.emit()
	_play_cabinet_sound("npc_check", -5.0, 1.05)
	if not plc_mode and not estop_active:
		var scene := get_parent()
		if scene != null and scene.has_method("_set_running"):
			scene.call("_set_running", true)

func trigger_stop() -> void:
	stop_pulse = 0.15
	stop_pressed = true
	stop_pressed_3d.emit()
	_play_cabinet_sound("npc_check", -5.0, 0.85)
	if not plc_mode:
		var scene := get_parent()
		if scene != null and scene.has_method("_set_running"):
			scene.call("_set_running", false)

func trigger_reverse() -> void:
	reverse_pulse = 0.15
	reverse_pressed = true
	reverse_pressed_3d.emit()
	_play_cabinet_sound("npc_check", -5.0, 1.2)

func toggle_estop() -> void:
	estop_active = not estop_active
	estop_toggled_3d.emit(estop_active)
	_play_cabinet_sound("alarm" if estop_active else "npc_check", -3.0, 1.0)
	if not plc_mode and estop_active:
		var scene := get_parent()
		if scene != null and scene.has_method("_set_running"):
			scene.call("_set_running", false)
	_update_lights()
	_update_selector()
	_update_estop()

func _on_start_input(_cam: Node, event: InputEvent, _pos: Vector3, _norm: Vector3, _idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _can_click_buttons():
			start_held = true
			trigger_start()
		elif not event.pressed:
			start_held = false

func _on_stop_input(_cam: Node, event: InputEvent, _pos: Vector3, _norm: Vector3, _idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _can_click_buttons():
			stop_held = true
			trigger_stop()
		elif not event.pressed:
			stop_held = false

func _on_rev_input(_cam: Node, event: InputEvent, _pos: Vector3, _norm: Vector3, _idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _can_click_buttons():
			reverse_held = true
			trigger_reverse()
		elif not event.pressed:
			reverse_held = false

func _on_selector_input(_cam: Node, event: InputEvent, _pos: Vector3, _norm: Vector3, _idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _can_click_buttons():
		selector_auto = not selector_auto
		selector_toggled_3d.emit(selector_auto)
		_play_cabinet_sound("npc_check", -6.0, 0.95)
		_update_selector()

func _on_estop_input(_cam: Node, event: InputEvent, _pos: Vector3, _norm: Vector3, _idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _can_click_buttons():
		toggle_estop()

func _set_lamp(mesh: MeshInstance3D, lit: bool, color: Color) -> void:
	if mesh == null:
		return
	var mat := mesh.material_override as StandardMaterial3D
	if mat == null:
		return
	mat.albedo_color = color if lit else color.darkened(0.65)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.4 if lit else 0.0

func _update_selector() -> void:
	if selector_knob != null:
		selector_knob.rotation_degrees.z = -35.0 if selector_auto else 35.0

func _update_estop() -> void:
	if estop_btn_mesh != null:
		estop_btn_mesh.position.z = ESTOP_Z_ACTIVE if estop_active else ESTOP_Z_RELEASED

func _play_cabinet_sound(sound_id: String, volume_db: float = -5.0, pitch: float = 1.0) -> void:
	var fa := get_node_or_null("/root/FactoryAudio")
	if fa != null:
		fa.call("play_one_shot", self, sound_id, volume_db, 24.0, pitch)

func _update_lights() -> void:
	var green_lit := bool(forced_items["lamp_g"]) if forced_items.has("lamp_g") else (lamp_green_on or active)
	var yellow_lit := bool(forced_items["lamp_y"]) if forced_items.has("lamp_y") else lamp_yellow_on
	var red_lit := bool(forced_items["lamp_r"]) if forced_items.has("lamp_r") else lamp_red_on
	var mask := (1 if green_lit else 0) | (2 if yellow_lit else 0) | (4 if red_lit else 0)
	if mask == _last_light_mask:
		return
	_last_light_mask = mask
	_set_lamp(lamp_fwd, green_lit, Color("18d97c"))
	_set_lamp(lamp_yellow, yellow_lit, Color("f5c518"))
	_set_lamp(lamp_rev, red_lit, Color("f03a3a"))
	if start_btn_mesh != null:
		var smat := start_btn_mesh.material_override as StandardMaterial3D
		if smat != null:
			smat.emission_enabled = green_lit
			smat.emission = Color("18d97c")
			smat.emission_energy_multiplier = 0.8 if green_lit else 0.0

func set_item_force(item_key: String, value: bool) -> void:
	forced_items[item_key] = value
	if item_key == "estop":
		estop_active = value
		_update_estop()
	elif item_key.begins_with("dyn_"):
		var io_id := item_key.substr(4)
		dynamic_button_states[io_id] = value
		_apply_dynamic_item_visual(io_id, value)
	_update_lights()

func clear_item_force(item_key: String) -> void:
	forced_items.erase(item_key)
	if item_key == "estop":
		_update_estop()
	elif item_key.begins_with("dyn_"):
		var io_id := item_key.substr(4)
		_apply_dynamic_item_visual(io_id, false)
	_update_lights()

func clear_all_item_forces() -> void:
	forced_items.clear()
	_update_estop()
	_update_lights()
	var container := _ensure_dynamic_container()
	for child in container.get_children():
		if "lit" in child:
			child.set("lit", false)

func _apply_dynamic_item_visual(io_id: String, value: bool) -> void:
	var container := _ensure_dynamic_container()
	for child in container.get_children():
		if str(child.get("io_id")) == io_id:
			if "lit" in child:
				child.set("lit", value)
			if "active" in child:
				child.set("active", value)
			if "is_lit" in child:
				child.set("is_lit", value)

func _apply_appearance() -> void:
	var nameplate := get_node_or_null("Nameplate/NameplateText") as Label3D
	if nameplate != null:
		nameplate.text = cabinet_title
	for node_name in [
		"LampGreenBezel", "LampGreen", "TagFwdLamp",
		"LampRedBezel", "LampRed", "TagRevLamp",
		"StartBtnBezel", "StartBtnMesh", "TagStartBtn", "StartBtnArea",
		"StopBtnBezel", "StopBtnMesh", "TagStopBtn", "StopBtnArea",
		"SelectorBezel", "SelectorKnob", "TagOffOn", "SelectorArea",
		"EStopCollar", "EStopMesh", "TagEStop", "EStopArea",
	]:
		var n := get_node_or_null(node_name) as Node3D
		if n != null:
			n.visible = show_builtin_items
	for area_name in ["StartBtnArea", "StopBtnArea", "SelectorArea", "EStopArea"]:
		var col := get_node_or_null(area_name + "/Col") as CollisionShape3D
		if col != null:
			col.disabled = not show_builtin_items
	for node_name in ["LampYellowBezel", "LampYellow", "TagYellowLamp"]:
		var n := get_node_or_null(node_name) as Node3D
		if n != null:
			n.visible = show_builtin_items and show_yellow_lamp
	for node_name in ["RevBtnBezel", "RevBtnMesh", "TagRevBtn", "RevBtnArea"]:
		var n := get_node_or_null(node_name) as Node3D
		if n != null:
			n.visible = show_builtin_items and show_rev_btn
	var rev_col := get_node_or_null("RevBtnArea/Col") as CollisionShape3D
	if rev_col != null:
		rev_col.disabled = not (show_builtin_items and show_rev_btn)
	var label_map := {
		"TagFwdLamp": lamp_green_label,
		"TagYellowLamp": lamp_yellow_label,
		"TagRevLamp": lamp_red_label,
		"TagStartBtn": btn_start_label,
		"TagStopBtn": btn_stop_label,
		"TagRevBtn": btn01_label,
		"TagOffOn": switch_auto_label,
		"TagEStop": switch_estop_label,
	}
	for tag_name in label_map:
		var lbl := get_node_or_null(tag_name) as Label3D
		if lbl != null:
			lbl.text = label_map[tag_name]
	_set_button_color(start_btn_mesh, start_btn_color)
	_set_button_color(stop_btn_mesh, stop_btn_color)
	_set_button_color(rev_btn_mesh, rev_btn_color)

func _set_button_color(mesh: MeshInstance3D, color: Color) -> void:
	if mesh == null:
		return
	var mat := mesh.material_override as StandardMaterial3D
	if mat != null:
		mat.albedo_color = color

func get_customization() -> Dictionary:
	var serialized_slots: Array[Dictionary] = []
	for item in dynamic_slots:
		var s: Dictionary = item.duplicate(true)
		if s.get("color") is Color:
			s["color"] = (s["color"] as Color).to_html()
		serialized_slots.append(s)
	return {
		"cabinet_title": cabinet_title,
		"show_builtin_items": show_builtin_items,
		"show_yellow_lamp": show_yellow_lamp,
		"show_rev_btn": show_rev_btn,
		"lamp_green_label": lamp_green_label,
		"lamp_yellow_label": lamp_yellow_label,
		"lamp_red_label": lamp_red_label,
		"btn_start_label": btn_start_label,
		"btn_stop_label": btn_stop_label,
		"btn01_label": btn01_label,
		"switch_auto_label": switch_auto_label,
		"switch_estop_label": switch_estop_label,
		"dynamic_slots": serialized_slots,
	}

func apply_customization(cfg: Dictionary) -> void:
	if cfg.has("cabinet_title"):
		cabinet_title = str(cfg["cabinet_title"])
	if cfg.has("show_builtin_items"):
		show_builtin_items = bool(cfg["show_builtin_items"])
	if cfg.has("show_yellow_lamp"):
		show_yellow_lamp = bool(cfg["show_yellow_lamp"])
	if cfg.has("show_rev_btn"):
		show_rev_btn = bool(cfg["show_rev_btn"])
	for key in [
		"lamp_green_label",
		"lamp_yellow_label",
		"lamp_red_label",
		"btn_start_label",
		"btn_stop_label",
		"btn01_label",
		"switch_auto_label",
		"switch_estop_label",
	]:
		if cfg.has(key):
			set(key, str(cfg[key]))
	if cfg.has("dynamic_slots"):
		_rebuild_dynamic_slots(cfg["dynamic_slots"])
	if is_node_ready():
		_apply_appearance()

func get_slot_position(col: int, row: int) -> Vector3:
	var c := clampi(col, 0, SLOT_COL_X.size() - 1)
	var r := clampi(row, 0, SLOT_ROW_Y.size() - 1)
	return Vector3(SLOT_COL_X[c], SLOT_ROW_Y[r], SLOT_Z)

func _ensure_dynamic_container() -> Node3D:
	if _dynamic_container == null or not is_instance_valid(_dynamic_container):
		_dynamic_container = get_node_or_null("DynamicSlots") as Node3D
		if _dynamic_container == null:
			_dynamic_container = Node3D.new()
			_dynamic_container.name = "DynamicSlots"
			add_child(_dynamic_container)
	return _dynamic_container

func set_slot_module(col: int, row: int, kind: String, label: String, color: Color, io_id: String = "") -> Node3D:
	var c := clampi(col, 0, SLOT_COL_X.size() - 1)
	var r := clampi(row, 0, SLOT_ROW_Y.size() - 1)
	clear_slot(c, r)
	var resolved_io := io_id if not io_id.is_empty() else "Slot_%d_%d" % [c, r]
	var entry := {
		"col": c,
		"row": r,
		"kind": kind,
		"label": label,
		"color": color,
		"io_id": resolved_io,
		"modbus_coil": -1,
		"modbus_input": -1,
		"modbus_input_reg": -1,
	}
	dynamic_slots.append(entry)
	return _spawn_slot_node(entry)

func move_slot_module(from_col: int, from_row: int, to_col: int, to_row: int) -> bool:
	var fc := clampi(from_col, 0, SLOT_COL_X.size() - 1)
	var fr := clampi(from_row, 0, SLOT_ROW_Y.size() - 1)
	var tc := clampi(to_col, 0, SLOT_COL_X.size() - 1)
	var tr := clampi(to_row, 0, SLOT_ROW_Y.size() - 1)
	if fc == tc and fr == tr:
		return false
	var from_idx := -1
	var to_idx := -1
	for i in range(dynamic_slots.size()):
		var item := dynamic_slots[i]
		if int(item.get("col", -1)) == fc and int(item.get("row", -1)) == fr:
			from_idx = i
		elif int(item.get("col", -1)) == tc and int(item.get("row", -1)) == tr:
			to_idx = i
	if from_idx < 0:
		return false
	var container := _ensure_dynamic_container()
	var from_node := container.get_node_or_null("Slot_%d_%d" % [fc, fr]) as Node3D
	var to_node := container.get_node_or_null("Slot_%d_%d" % [tc, tr]) as Node3D
	dynamic_slots[from_idx]["col"] = tc
	dynamic_slots[from_idx]["row"] = tr
	if to_idx >= 0:
		dynamic_slots[to_idx]["col"] = fc
		dynamic_slots[to_idx]["row"] = fr
	if from_node != null:
		from_node.name = "Slot_%d_%d_tmp" % [tc, tr]
		from_node.position = get_slot_position(tc, tr)
	if to_node != null:
		to_node.name = "Slot_%d_%d" % [fc, fr]
		to_node.position = get_slot_position(fc, fr)
	if from_node != null:
		from_node.name = "Slot_%d_%d" % [tc, tr]
	return true

func clear_slot(col: int, row: int) -> void:
	var slot_name := "Slot_%d_%d" % [col, row]
	var container := _ensure_dynamic_container()
	var existing := container.get_node_or_null(slot_name)
	if existing != null:
		existing.queue_free()
	for i in range(dynamic_slots.size() - 1, -1, -1):
		if int(dynamic_slots[i].get("col", -1)) == col and int(dynamic_slots[i].get("row", -1)) == row:
			dynamic_slots.remove_at(i)

func clear_all_dynamic_slots() -> void:
	dynamic_slots.clear()
	dynamic_button_states.clear()
	dynamic_pot_values.clear()
	var container := _ensure_dynamic_container()
	for child in container.get_children():
		child.queue_free()

func set_dynamic_lamp(io_id: String, lit: bool) -> void:
	var effective := bool(forced_items["dyn_" + io_id]) if forced_items.has("dyn_" + io_id) else lit
	var container := _ensure_dynamic_container()
	for child in container.get_children():
		if str(child.get("io_id")) == io_id and "lit" in child:
			if bool(child.get("lit")) != effective:
				child.set("lit", effective)

func set_dynamic_switch_3pos(io_id: String, pos: int) -> void:
	dynamic_button_states[io_id] = pos
	dynamic_button_states[io_id + "_L"] = (pos == 0)
	dynamic_button_states[io_id + "_R"] = (pos == 2)
	var container := _ensure_dynamic_container()
	for child in container.get_children():
		if str(child.get("io_id")) == io_id and "switch_pos" in child:
			child.set("switch_pos", pos)

func set_dynamic_pot(io_id: String, val: float) -> void:
	var clamped := clampf(val, 0.0, 1.0)
	dynamic_pot_values[io_id] = clamped
	for item in dynamic_slots:
		if item is Dictionary and str(item.get("io_id", "")) == io_id:
			item["value"] = clamped
	var container := _ensure_dynamic_container()
	for child in container.get_children():
		if str(child.get("io_id")) == io_id and "value" in child:
			child.set("value", clamped)

func set_dynamic_dpm(io_id: String, raw_val: int) -> void:
	var clamped := clampi(raw_val, -32768, 65535)
	for item in dynamic_slots:
		if item is Dictionary and str(item.get("io_id", "")) == io_id:
			item["raw_value"] = clamped
	var container := _ensure_dynamic_container()
	for child in container.get_children():
		if str(child.get("io_id")) == io_id and "raw_value" in child:
			if int(child.get("raw_value")) != clamped:
				child.set("raw_value", clamped)

func update_slot_module(col: int, row: int, props: Dictionary) -> bool:
	for i in range(dynamic_slots.size()):
		var item := dynamic_slots[i]
		if int(item.get("col", -1)) == col and int(item.get("row", -1)) == row:
			var old_kind := str(item.get("kind", "lamp"))
			for k in props:
				item[k] = props[k]
			var new_kind := str(item.get("kind", "lamp"))
			var container := _ensure_dynamic_container()
			var node := container.get_node_or_null("Slot_%d_%d" % [col, row]) as Node3D
			if node == null or old_kind != new_kind:
				if node != null:
					node.queue_free()
				_spawn_slot_node(item)
			else:
				if props.has("label"):
					node.set("label_text", str(props["label"]))
				if props.has("color"):
					var raw_c = props["color"]
					var c: Color = raw_c if raw_c is Color else Color(str(raw_c))
					if new_kind == "lamp":
						node.set("lamp_color", c)
					elif new_kind in ["push_button", "button"]:
						node.set("button_color", c)
					elif new_kind in ["switch_select", "switch_3pos"]:
						node.set("switch_color", c)
					elif new_kind == "potentiometer":
						node.set("knob_color", c)
					elif new_kind == "dpm":
						node.set("led_color", c)
				if new_kind == "dpm":
					if props.has("unit"):
						node.set("unit_text", str(props["unit"]))
					if props.has("decimals"):
						node.set("decimals", int(props["decimals"]))
					if props.has("signed"):
						node.set("signed_mode", bool(props["signed"]))
				if props.has("io_id"):
					node.set("io_id", str(props["io_id"]))
			return true
	return false

func _rebuild_dynamic_slots(slots_data: Array) -> void:
	clear_all_dynamic_slots()
	for item in slots_data:
		if item is Dictionary:
			var entry: Dictionary = item.duplicate(true)
			dynamic_slots.append(entry)
			_spawn_slot_node(entry)

func _spawn_slot_node(entry: Dictionary) -> Node3D:
	var container := _ensure_dynamic_container()
	var col := int(entry.get("col", 0))
	var row := int(entry.get("row", 0))
	var kind := str(entry.get("kind", "lamp"))
	var label := str(entry.get("label", "MOD"))
	var raw_color = entry.get("color", Color("18d97c"))
	var color: Color = raw_color if raw_color is Color else Color(str(raw_color))
	var io_id := str(entry.get("io_id", "Slot_%d_%d" % [col, row]))
	var node: Node3D = null
	if kind in ["push_button", "button"]:
		node = CABINET_BTN_SCENE.instantiate() as Node3D
		node.set("label_text", label)
		node.set("button_color", color)
		node.set("io_id", io_id)
		node.connect("pressed", func(id: String):
			dynamic_button_states[id] = true
			dynamic_button_pressed.emit(id)
		)
		node.connect("released", func(id: String):
			dynamic_button_states[id] = false
			dynamic_button_released.emit(id)
		)
	elif kind == "switch_select":
		node = CABINET_SWITCH_SCENE.instantiate() as Node3D
		node.set("positions", 2)
		node.set("label_text", label)
		node.set("switch_color", color)
		node.set("io_id", io_id)
		node.connect("toggled", func(is_on: bool, id: String):
			dynamic_button_states[id] = is_on
			dynamic_switch_toggled.emit(is_on, id)
		)
	elif kind == "switch_3pos":
		node = CABINET_SWITCH_SCENE.instantiate() as Node3D
		node.set("positions", 3)
		node.set("switch_pos", 1)
		node.set("label_text", label)
		node.set("switch_color", color)
		node.set("io_id", io_id)
		dynamic_button_states[io_id] = 1
		dynamic_button_states[io_id + "_L"] = false
		dynamic_button_states[io_id + "_R"] = false
		node.connect("position_changed", func(pos: int, id: String):
			dynamic_button_states[id] = pos
			dynamic_button_states[id + "_L"] = (pos == 0)
			dynamic_button_states[id + "_R"] = (pos == 2)
			dynamic_switch_3pos_changed.emit(pos, id)
		)
	elif kind == "potentiometer":
		node = CABINET_POT_SCENE.instantiate() as Node3D
		var init_val := clampf(float(entry.get("value", dynamic_pot_values.get(io_id, 0.0))), 0.0, 1.0)
		node.set("label_text", label)
		node.set("knob_color", color)
		node.set("value", init_val)
		node.set("io_id", io_id)
		dynamic_pot_values[io_id] = init_val
		node.connect("value_changed", func(v: float, id: String):
			dynamic_pot_values[id] = v
			entry["value"] = v
			dynamic_pot_changed.emit(v, id)
		)
	elif kind == "dpm":
		node = CABINET_DPM_SCENE.instantiate() as Node3D
		node.set("label_text", label)
		node.set("led_color", color)
		node.set("unit_text", str(entry.get("unit", "")))
		node.set("decimals", int(entry.get("decimals", 0)))
		node.set("signed_mode", bool(entry.get("signed", true)))
		node.set("raw_value", int(entry.get("raw_value", 0)))
		node.set("io_id", io_id)
	else:
		node = CABINET_LAMP_SCENE.instantiate() as Node3D
		node.set("label_text", label)
		node.set("lamp_color", color)
		node.set("io_id", io_id)
	node.name = "Slot_%d_%d" % [col, row]
	node.position = get_slot_position(col, row)
	container.add_child(node)
	return node

func apply_hud_state(_is_running: bool, is_plc: bool, _count: int, _belt_spd: float, _hr0: int, g_on: bool, y_on: bool, r_on: bool) -> void:
	if plc_mode == is_plc and lamp_green_on == g_on and lamp_yellow_on == y_on and lamp_red_on == r_on:
		return
	plc_mode = is_plc
	lamp_green_on = g_on
	lamp_yellow_on = y_on
	lamp_red_on = r_on
	_update_lights()
