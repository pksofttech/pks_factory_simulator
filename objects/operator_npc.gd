extends Node3D

@export var walk_speed: float = 1.85
@export var inspect_duration: float = 2.2
@export var is_tester: bool = false
@export var is_safety: bool = false
@export var role_id: String = ""
@export var start_target_offset: int = 0
@export var chat_enabled: bool = true
@export var sound_enabled: bool = true

const CELL_SIZE := 0.5
const NPC_CLEARANCE := 0.55
const PRODUCT_KINDS := ["box", "box_plastic", "box_small", "box_metal", "pallet", "workpiece"]
const CHAT_PAIRS := [
	["Line running smooth!", "Good job, carry on!"],
	["Conveyors checked!", "Keep an eye on Turn!"],
	["Sensors all green!", "Great, check next unit!"],
	["No jams so far!", "Nice work, operator!"],
]

var _targets: Array[Node3D] = []
var _target_idx: int = 0
var _inspect_timer: float = 0.0
var _walk_phase: float = 0.0
var _inspecting: bool = false
var _chatting: bool = false
var _chat_timer: float = 0.0
var _chat_cooldown: float = 0.0
var _chat_partner: Node3D = null
var _chat_text: String = ""
var _chat_seq: int = 0
var _current_stand_pos: Vector3 = Vector3.ZERO
var _waypoints: Array[Vector3] = []
var _waypoint_idx: int = 0
var _stuck_timer: float = 0.0
var _stuck_check_timer: float = 0.0
var _replan_cooldown: float = 0.0
var _replan_attempts: int = 0
var _last_pos: Vector3 = Vector3.ZERO
var _was_edit_mode: bool = false
var _current_target: Node3D = null
var _alert_check_timer: float = 0.0
var _empty_refresh_timer: float = 0.0
var _rounds_completed: int = 0
var _on_shift_break: bool = false
var _break_station: Node3D = null
var _last_status_text: String = ""
var _last_status_color: Color = Color.TRANSPARENT
var _astar := AStarGrid2D.new()
var _half_w: float = 19.0
var _half_d: float = 19.0

@onready var left_leg: Node3D = $Body/LeftLegPivot
@onready var right_leg: Node3D = $Body/RightLegPivot
@onready var left_arm: Node3D = $Body/LeftArmPivot
@onready var right_arm: Node3D = $Body/RightArmPivot
@onready var head_node: Node3D = $Body/HeadPivot
@onready var status_label: Label3D = $StatusLabel
@onready var propeller_node: Node3D = get_node_or_null("Body/HeadPivot/Propeller")

func _ready() -> void:
	add_to_group("factory_npcs")
	_last_pos = global_position
	_target_idx = start_target_offset
	if status_label != null:
		status_label.visibility_range_end = 18.0
	call_deferred("_refresh_targets")

func _world_to_cell(pos: Vector3) -> Vector2i:
	return Vector2i(int(round(pos.x / CELL_SIZE)), int(round(pos.z / CELL_SIZE)))

func _cell_to_world(cell: Vector2i) -> Vector3:
	return Vector3(float(cell.x) * CELL_SIZE, 0.0, float(cell.y) * CELL_SIZE)

func _get_equipment_half_extents(obj: Node3D) -> Vector2:
	var kind := str(obj.get_meta("kind", ""))
	match kind:
		"conveyor":
			return Vector2(4.55, 0.80)
		"conveyor_short":
			return Vector2(1.55, 0.80)
		"turn":
			return Vector2(0.85, 0.85)
		"emitter":
			return Vector2(0.85, 1.05)
		"remover":
			return Vector2(0.85, 0.95)
		"pusher":
			return Vector2(0.85, 0.75)
		"stopper":
			return Vector2(0.65, 0.85)
		"sensor":
			return Vector2(0.55, 0.85)
		"vision_sensor", "rgb_sensor":
			return Vector2(0.45, 0.85)
		"stack_light":
			return Vector2(0.40, 0.40)
		"motor_fan", "pump", "reject_bin":
			return Vector2(0.55, 0.55)
		"water_tank":
			return Vector2(0.80, 0.80)
		"solenoid_valve":
			return Vector2(0.35, 0.35)
		"light_curtain":
			return Vector2(0.35, 0.80)
		"cabinet":
			return Vector2(0.55, 0.45)
		"prop_rack":
			return Vector2(1.00, 0.50)
		"prop_barrier":
			return Vector2(0.75, 0.12)
		"prop_barrel":
			return Vector2(0.35, 0.35)
		"prop_workbench":
			return Vector2(0.80, 0.40)
		"prop_forklift":
			return Vector2(0.60, 1.10)
		"prop_pallet_stack":
			return Vector2(0.55, 0.55)
		"prop_pallet_jack":
			return Vector2(0.31, 0.75)
		"prop_bollard":
			return Vector2(0.16, 0.16)
		"prop_safety_sign":
			return Vector2(0.28, 0.28)
		"prop_qc_desk":
			return Vector2(0.70, 0.38)
		"prop_production_board":
			return Vector2(0.80, 0.28)
		"prop_locker":
			return Vector2(0.60, 0.25)
		_:
			return Vector2(0.75, 0.75)

func _rebuild_nav_grid(avoid_npcs: bool = false) -> void:
	var scene := get_parent()
	var w := 40
	var d := 40
	if scene != null:
		var sw = scene.get("workspace_width")
		var sd = scene.get("workspace_depth")
		if sw is int or sw is float:
			w = int(sw)
		if sd is int or sd is float:
			d = int(sd)
	_half_w = maxf(4.0, float(w) * 0.5 - 0.8)
	_half_d = maxf(4.0, float(d) * 0.5 - 0.8)

	var min_cx := int(floor(-_half_w / CELL_SIZE))
	var max_cx := int(ceil(_half_w / CELL_SIZE))
	var min_cz := int(floor(-_half_d / CELL_SIZE))
	var max_cz := int(ceil(_half_d / CELL_SIZE))

	_astar = AStarGrid2D.new()
	_astar.region = Rect2i(min_cx, min_cz, max_cx - min_cx + 1, max_cz - min_cz + 1)
	_astar.cell_size = Vector2(CELL_SIZE, CELL_SIZE)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.update()

	for obj in get_tree().get_nodes_in_group("sandbox_objects"):
		if not is_instance_valid(obj) or not (obj is Node3D):
			continue
		var node := obj as Node3D
		var kind := str(node.get_meta("kind", ""))
		if kind in PRODUCT_KINDS or kind == "light_curtain":
			continue
		var ext := _get_equipment_half_extents(node) + Vector2(NPC_CLEARANCE, NPC_CLEARANCE)
		var inv := node.global_transform.affine_inverse()
		var max_r := ext.length() + CELL_SIZE
		var c0 := _world_to_cell(node.global_position - Vector3(max_r, 0.0, max_r))
		var c1 := _world_to_cell(node.global_position + Vector3(max_r, 0.0, max_r))
		for cx in range(maxi(min_cx, c0.x), mini(max_cx, c1.x) + 1):
			for cz in range(maxi(min_cz, c0.y), mini(max_cz, c1.y) + 1):
				var wp := _cell_to_world(Vector2i(cx, cz))
				var local_pt := inv * wp
				if absf(local_pt.x) <= ext.x and absf(local_pt.z) <= ext.y:
					_astar.set_point_solid(Vector2i(cx, cz), true)

	if avoid_npcs:
		for other in get_tree().get_nodes_in_group("factory_npcs"):
			if other == self or not is_instance_valid(other) or not (other is Node3D):
				continue
			var opos := (other as Node3D).global_position
			var oc := _world_to_cell(opos)
			for dx in range(-1, 2):
				for dz in range(-1, 2):
					var nc := Vector2i(oc.x + dx, oc.y + dz)
					if _astar.is_in_boundsv(nc) and not _astar.is_point_solid(nc):
						_astar.set_point_weight_scale(nc, 35.0)

	var cur_cell := _clamp_cell(_world_to_cell(global_position))
	if _astar.is_in_boundsv(cur_cell):
		_astar.set_point_solid(cur_cell, false)

func _clamp_cell(cell: Vector2i) -> Vector2i:
	var r := _astar.region
	return Vector2i(
		clampi(cell.x, r.position.x, r.position.x + r.size.x - 1),
		clampi(cell.y, r.position.y, r.position.y + r.size.y - 1)
	)

func _matches_role(kind: String) -> bool:
	if role_id == "maintenance":
		return kind in ["pump", "motor_fan", "solenoid_valve", "water_tank", "pusher", "stopper"]
	if role_id == "qc":
		return kind in ["vision_sensor", "rgb_sensor", "reject_bin", "remover", "sensor"]
	if is_safety:
		return kind in ["light_curtain", "stack_light", "cabinet", "remover", "reject_bin", "motor_fan", "pump"]
	if is_tester:
		return kind in ["sensor", "vision_sensor", "rgb_sensor", "turn", "cabinet", "water_tank"]
	return kind in ["conveyor", "conveyor_short", "emitter", "pusher", "stopper", "motor_fan", "pump", "water_tank", "solenoid_valve"]

func _is_target_claimed(cand: Node3D) -> bool:
	for other in get_tree().get_nodes_in_group("factory_npcs"):
		if other == self or not is_instance_valid(other):
			continue
		if other.get("_current_target") == cand:
			return true
	return false

func _refresh_targets() -> void:
	_targets.clear()
	var all_equip: Array[Node3D] = []
	for obj in get_tree().get_nodes_in_group("sandbox_objects"):
		if not is_instance_valid(obj) or not (obj is Node3D):
			continue
		var kind := str(obj.get_meta("kind", ""))
		if kind in PRODUCT_KINDS or kind.begins_with("prop_"):
			continue
		all_equip.append(obj as Node3D)
		if _matches_role(kind):
			_targets.append(obj as Node3D)
	if _targets.is_empty():
		_targets = all_equip
	_rebuild_nav_grid()
	if _targets.size() > 0:
		_target_idx = _target_idx % _targets.size()
		_current_target = _targets[_target_idx]
		_pick_stand_position(_current_target)
	else:
		_current_target = null
		_inspecting = false
		_waypoints.clear()

func _find_shift_break_station() -> Node3D:
	var preferred: Array = (
		["prop_workbench", "prop_locker", "prop_production_board"]
		if role_id == "maintenance"
		else (
			["prop_qc_desk", "prop_production_board", "prop_workbench"]
			if role_id == "qc"
			else (
				["prop_production_board", "prop_safety_sign", "prop_locker"]
				if is_safety
				else (["prop_qc_desk", "prop_production_board"] if is_tester else ["prop_workbench", "prop_locker", "prop_qc_desk"])
			)
		)
	)
	for want_kind in preferred:
		for obj in get_tree().get_nodes_in_group("sandbox_objects"):
			if not is_instance_valid(obj) or not (obj is Node3D):
				continue
			if str(obj.get_meta("kind", "")) == want_kind:
				return obj as Node3D
	return null


func _advance_to_next_target() -> void:
	if _on_shift_break:
		_on_shift_break = false
		_break_station = null
		_refresh_targets()
		return
	if _targets.is_empty():
		_refresh_targets()
		return
	for pass_idx in range(2):
		for _attempt in range(_targets.size()):
			var next_idx := (_target_idx + 1) % _targets.size()
			if next_idx == 0 and pass_idx == 0:
				_target_idx = 0
				_rounds_completed += 1
				if _rounds_completed % 2 == 0:
					var station := _find_shift_break_station()
					if is_instance_valid(station):
						_on_shift_break = true
						_break_station = station
						_current_target = station
						_inspecting = false
						if _pick_stand_position(station):
							return
						_on_shift_break = false
						_break_station = null
				_refresh_targets()
				return
			_target_idx = next_idx
			var cand := _targets[_target_idx]
			if not is_instance_valid(cand):
				_refresh_targets()
				return
			if pass_idx == 0 and _targets.size() > 1 and _is_target_claimed(cand):
				continue
			if _pick_stand_position(cand):
				_current_target = cand
				return

func _find_walkable_start_cell() -> Vector2i:
	var start_cell := _clamp_cell(_world_to_cell(global_position))
	var offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for off in offsets:
		var nb := start_cell + off
		if _astar.is_in_boundsv(nb) and not _astar.is_point_solid(nb):
			return start_cell
	var best_cell := start_cell
	var best_d2 := INF
	for r in range(1, 5):
		for dx in range(-r, r + 1):
			for dz in range(-r, r + 1):
				var c := start_cell + Vector2i(dx, dz)
				if _astar.is_in_boundsv(c) and not _astar.is_point_solid(c):
					var d2 := float(dx * dx + dz * dz)
					if d2 < best_d2:
						best_d2 = d2
						best_cell = c
		if best_d2 < INF:
			break
	return best_cell

func _pick_stand_position(target: Node3D, avoid_npcs: bool = false) -> bool:
	if not is_instance_valid(target):
		return false
	_rebuild_nav_grid(avoid_npcs)
	var base := Vector3(target.global_position.x, 0.0, target.global_position.z)
	var ext := _get_equipment_half_extents(target)
	var basis := target.global_transform.basis
	var local_dirs: Array[Vector3] = [
		Vector3(0, 0, ext.y + 0.85),
		Vector3(0, 0, -(ext.y + 0.85)),
		Vector3(ext.x + 0.85, 0, 0),
		Vector3(-(ext.x + 0.85), 0, 0),
		Vector3(ext.x + 0.75, 0, ext.y + 0.75),
		Vector3(-(ext.x + 0.75), 0, ext.y + 0.75),
		Vector3(ext.x + 0.75, 0, -(ext.y + 0.75)),
		Vector3(-(ext.x + 0.75), 0, -(ext.y + 0.75)),
	]
	var best_pos := Vector3.ZERO
	var best_score := INF
	var start_cell := _find_walkable_start_cell()

	for ld in local_dirs:
		var cand := base + (basis * ld)
		cand.y = 0.0
		cand.x = clampf(cand.x, -_half_w, _half_w)
		cand.z = clampf(cand.z, -_half_d, _half_d)
		var cell := _clamp_cell(_world_to_cell(cand))
		if not _astar.is_in_boundsv(cell) or _astar.is_point_solid(cell):
			continue
		var path := _astar.get_point_path(start_cell, cell)
		if path.is_empty():
			continue
		var world_pt := _cell_to_world(cell)
		var score := float(path.size()) + cand.distance_to(global_position) * 0.1
		for other in get_tree().get_nodes_in_group("factory_npcs"):
			if other == self or not is_instance_valid(other) or not (other is Node3D):
				continue
			var other_node := other as Node3D
			var other_stand = other_node.get("_current_stand_pos")
			if other_node.global_position.distance_to(world_pt) < 1.1 or (other_stand is Vector3 and (other_stand as Vector3).distance_to(world_pt) < 1.1):
				score += 50.0
		if score < best_score:
			best_score = score
			best_pos = world_pt

	if best_score == INF:
		return false

	_current_stand_pos = best_pos
	_waypoints.clear()
	_waypoint_idx = 0
	var goal_cell := _clamp_cell(_world_to_cell(_current_stand_pos))
	if _astar.is_in_boundsv(goal_cell) and not _astar.is_point_solid(goal_cell):
		var grid_path := _astar.get_point_path(start_cell, goal_cell)
		for pt in grid_path:
			_waypoints.append(Vector3(pt.x, 0.0, pt.y))
	if _waypoints.is_empty():
		_waypoints.append(_current_stand_pos)
	_stuck_timer = 0.0
	_stuck_check_timer = 0.0
	_replan_attempts = 0
	_last_pos = global_position
	return true

func _physics_process(delta: float) -> void:
	var scene := get_parent()
	var in_edit := scene != null and scene.get("edit_mode") != null and bool(scene.get("edit_mode"))
	if in_edit:
		_was_edit_mode = true
		_animate_idle(delta)
		_set_status_label("Standby (Edit Mode)", Color("9cb3c4"))
		return
	if _was_edit_mode:
		_was_edit_mode = false
		_refresh_targets()
		return
	if is_safety and not _chatting:
		_alert_check_timer += delta
		if _alert_check_timer >= 0.6:
			_alert_check_timer = 0.0
			var alert_obj := _find_safety_alert_target()
			if is_instance_valid(alert_obj) and alert_obj != _current_target:
				var idx := _targets.find(alert_obj)
				if idx == -1:
					_targets.append(alert_obj)
					idx = _targets.size() - 1
				_target_idx = idx
				_current_target = alert_obj
				_inspecting = false
				_play_npc_sound("safety_alert", -2.0, 1.0, 26.0)
				_pick_stand_position(alert_obj)
				return
	if _chat_cooldown > 0.0:
		_chat_cooldown = maxf(0.0, _chat_cooldown - delta)
	if _replan_cooldown > 0.0:
		_replan_cooldown = maxf(0.0, _replan_cooldown - delta)
	if _targets.is_empty() and not _on_shift_break:
		_animate_idle(delta)
		_set_status_label("Standby (No Equipment)", Color("9cb3c4"))
		_empty_refresh_timer += delta
		if _empty_refresh_timer >= 1.0:
			_empty_refresh_timer = 0.0
			_refresh_targets()
		return
	_empty_refresh_timer = 0.0
	var target: Node3D = _break_station if _on_shift_break else _targets[_target_idx]
	if not is_instance_valid(target):
		_on_shift_break = false
		_break_station = null
		_refresh_targets()
		return

	if propeller_node != null:
		propeller_node.rotation.y += delta * (14.0 if (_inspecting or _chatting) else 7.0)

	if _chatting:
		_chat_timer -= delta
		_animate_idle(delta)
		var pre_pos := global_position
		_separate_from_npcs()
		if global_position.distance_squared_to(pre_pos) > 0.000001:
			_push_out_of_equipment()
		if is_instance_valid(_chat_partner):
			_face_point(Vector3(_chat_partner.global_position.x, global_position.y, _chat_partner.global_position.z), delta * 8.0)
		_set_status_label(_chat_text, Color("66e88a") if is_safety else (Color("ffd57e") if is_tester else Color("8ce8ff")))
		if _chat_timer <= 0.0:
			_chatting = false
			_chat_partner = null
			_chat_cooldown = 8.0
			_advance_to_next_target()
		return

	if _inspecting:
		_inspect_timer -= delta
		_animate_idle(delta)
		var pre_pos := global_position
		_separate_from_npcs()
		if global_position.distance_squared_to(pre_pos) > 0.000001:
			_push_out_of_equipment()
		var look_target := Vector3(target.global_position.x, global_position.y, target.global_position.z)
		_face_point(look_target, delta * 6.0)
		_update_status_label(target, true)
		if _inspect_timer <= 0.0:
			_inspecting = false
			_advance_to_next_target()
		return

	if _waypoint_idx >= _waypoints.size():
		_start_inspecting(target)
		return

	var wp := _waypoints[_waypoint_idx]
	var to_wp := Vector3(wp.x - global_position.x, 0.0, wp.z - global_position.z)
	var dist := to_wp.length()
	var is_last_wp := _waypoint_idx >= _waypoints.size() - 1
	var reach_dist := 0.24 if is_last_wp else 0.34
	if dist <= reach_dist:
		_waypoint_idx += 1
		if _waypoint_idx >= _waypoints.size():
			_start_inspecting(target)
		return

	if is_last_wp and _is_other_npc_blocking_point(wp, 0.90):
		var target_flat := Vector3(target.global_position.x, 0.0, target.global_position.z)
		if global_position.distance_to(target_flat) < 2.8:
			_start_inspecting(target)
			return
		_advance_to_next_target()
		return

	if _try_start_chat():
		return

	var dir := to_wp / dist
	var steer := _compute_npc_steer(dir)
	var move_dir: Vector3 = steer["dir"]
	var speed_scale: float = steer["speed_scale"]
	if bool(steer["should_replan"]) and _replan_cooldown <= 0.0:
		_replan_cooldown = 0.8
		_pick_stand_position(target, true)
		return
	global_position += move_dir * minf(walk_speed * speed_scale * delta, dist)
	_separate_from_npcs()
	_push_out_of_equipment()
	global_position.x = clampf(global_position.x, -_half_w, _half_w)
	global_position.z = clampf(global_position.z, -_half_d, _half_d)
	_face_point(global_position + move_dir, delta * 8.0)
	_animate_walk(delta)
	_update_status_label(target, false)

	_stuck_check_timer += delta
	if _stuck_check_timer >= 0.5:
		var moved := global_position.distance_to(_last_pos)
		_last_pos = global_position
		_stuck_check_timer = 0.0
		if moved < 0.12:
			_stuck_timer += 0.5
			if _stuck_timer >= 1.5:
				_stuck_timer = 0.0
				if _replan_attempts < 1:
					_replan_attempts += 1
					_replan_cooldown = 0.8
					if not _pick_stand_position(target, true):
						_advance_to_next_target()
				else:
					_advance_to_next_target()
		else:
			_stuck_timer = 0.0

func _try_start_chat() -> bool:
	if _chat_cooldown > 0.0 or _chatting:
		return false
	for other in get_tree().get_nodes_in_group("factory_npcs"):
		if other == self or not is_instance_valid(other) or not (other is Node3D):
			continue
		var partner := other as Node3D
		if bool(partner.get("_chatting")) or float(partner.get("_chat_cooldown")) > 0.0:
			continue
		var d := Vector2(global_position.x - partner.global_position.x, global_position.z - partner.global_position.z).length()
		if d < 1.05:
			var pair: Array = CHAT_PAIRS[_chat_seq % CHAT_PAIRS.size()]
			_chat_seq += 1
			var my_line: String = (
				"Maint: Motors & valves nominal!"
				if role_id == "maintenance"
				else (
					"QC: Quality checks on track!"
					if role_id == "qc"
					else ("Safety: PPE & zones clear!" if is_safety else (("Sup: " + str(pair[1])) if is_tester else ("Op: " + str(pair[0]))))
				)
			)
			var partner_is_tester := bool(partner.get("is_tester"))
			var partner_is_safety := bool(partner.get("is_safety"))
			var partner_role := str(partner.get("role_id"))
			var partner_line: String = (
				"Maint: Tools & pumps good!"
				if partner_role == "maintenance"
				else (
					"QC: Specs look solid!"
					if partner_role == "qc"
					else ("Safety: Keep aisle clear!" if partner_is_safety else (("Sup: " + str(pair[1])) if partner_is_tester else ("Op: " + str(pair[0]))))
				)
			)
			start_chat(partner, my_line, 2.2, false)
			if partner.has_method("start_chat"):
				partner.call("start_chat", self, partner_line, 2.2, true)
			return true
	return false

func start_chat(partner: Node3D, text_line: String, duration: float = 2.2, is_reply: bool = false) -> void:
	if not chat_enabled:
		return
	_inspecting = false
	_chatting = true
	_chat_partner = partner
	_chat_text = text_line
	_chat_timer = duration
	_stuck_timer = 0.0
	var base_pitch := (
		0.85
		if role_id == "maintenance"
		else (1.06 if role_id == "qc" else (1.12 if is_safety else (0.90 if is_tester else 1.0)))
	)
	var pitch := base_pitch + randf_range(-0.04, 0.04)
	if is_reply:
		get_tree().create_timer(0.28).timeout.connect(
			func():
				if is_instance_valid(self):
					_play_npc_sound("npc_chat_reply", -5.0, pitch, 24.0),
		)
	else:
		var chat_id := "npc_chat" if (_chat_seq % 2 == 0) else "npc_chat_2"
		_play_npc_sound(chat_id, -5.0, pitch, 24.0)

func _start_inspecting(target: Node3D) -> void:
	_inspecting = true
	_inspect_timer = inspect_duration
	_update_status_label(target, true)
	var role_pitch := (
		0.85
		if role_id == "maintenance"
		else (1.06 if role_id == "qc" else (1.12 if is_safety else (0.90 if is_tester else 1.0)))
	)
	if _on_shift_break and target == _break_station:
		_play_npc_sound("npc_log", -7.5, role_pitch, 20.0)
	else:
		var kind := str(target.get_meta("kind", ""))
		var is_warn := _is_target_alert(target) or (kind == "water_tank" and int(target.get("level_percent")) >= 85) or (kind == "reject_bin" and int(target.get("rejected_count")) >= 10)
		if is_warn:
			_play_npc_sound("npc_warn", -5.5, role_pitch, 24.0)
		else:
			_play_npc_sound("npc_check", -7.5, role_pitch, 20.0)

func _play_npc_sound(sound_id: String, volume_db: float = -6.0, pitch: float = 1.0, max_dist: float = 22.0) -> void:
	if not sound_enabled:
		return
	var fa := get_node_or_null("/root/FactoryAudio")
	if fa != null:
		fa.call("play_one_shot", self, sound_id, volume_db, max_dist, pitch)

func _is_other_npc_blocking_point(world_pt: Vector3, radius: float) -> bool:
	for other in get_tree().get_nodes_in_group("factory_npcs"):
		if other == self or not is_instance_valid(other) or not (other is Node3D):
			continue
		var opos := (other as Node3D).global_position
		if Vector2(opos.x - world_pt.x, opos.z - world_pt.z).length() < radius:
			return true
	return false

func _compute_npc_steer(dir: Vector3) -> Dictionary:
	var steer_dir := dir
	var speed_scale := 1.0
	var should_replan := false
	var right := Vector3(-dir.z, 0.0, dir.x)
	for other in get_tree().get_nodes_in_group("factory_npcs"):
		if other == self or not is_instance_valid(other) or not (other is Node3D):
			continue
		var diff := Vector3((other as Node3D).global_position.x - global_position.x, 0.0, (other as Node3D).global_position.z - global_position.z)
		var d := diff.length()
		if d > 0.001 and d < 1.35:
			var to_other := diff / d
			if dir.dot(to_other) > 0.25:
				var right_dot := right.dot(to_other)
				# Consistent right-hand rule when nearly head-on so two NPCs don't dodge to the same side.
				var sidestep := -right if right_dot > 0.25 else right
				steer_dir = (steer_dir + sidestep * 1.15).normalized()
				if d < 0.90:
					var other_stationary := bool(other.get("_inspecting")) or bool(other.get("_chatting"))
					if other_stationary or get_instance_id() < other.get_instance_id():
						speed_scale = minf(speed_scale, 0.45)
					if d < 0.85 and other_stationary:
						should_replan = true
	return {"dir": steer_dir, "speed_scale": speed_scale, "should_replan": should_replan}

func _separate_from_npcs() -> void:
	const MIN_NPC_DIST := 0.85
	for other in get_tree().get_nodes_in_group("factory_npcs"):
		if other == self or not is_instance_valid(other) or not (other is Node3D):
			continue
		var diff := Vector3(global_position.x - (other as Node3D).global_position.x, 0.0, global_position.z - (other as Node3D).global_position.z)
		var d := diff.length()
		if d < MIN_NPC_DIST:
			var push_dir := diff / d if d > 0.001 else Vector3(1.0, 0.0, 0.0)
			global_position += push_dir * ((MIN_NPC_DIST - d) * 0.5)

func _push_out_of_equipment() -> void:
	for obj in get_tree().get_nodes_in_group("sandbox_objects"):
		if not is_instance_valid(obj) or not (obj is Node3D):
			continue
		var node := obj as Node3D
		var kind := str(node.get_meta("kind", ""))
		if kind in PRODUCT_KINDS or kind == "light_curtain":
			continue
		var ext := _get_equipment_half_extents(node) + Vector2(0.38, 0.38)
		var inv := node.global_transform.affine_inverse()
		var local_pt := inv * global_position
		if absf(local_pt.x) < ext.x and absf(local_pt.z) < ext.y:
			var pen_x := ext.x - absf(local_pt.x)
			var pen_z := ext.y - absf(local_pt.z)
			if pen_x < pen_z:
				local_pt.x = ext.x if local_pt.x >= 0.0 else -ext.x
			else:
				local_pt.z = ext.y if local_pt.z >= 0.0 else -ext.y
			var world_pt := node.global_transform * local_pt
			global_position.x = world_pt.x
			global_position.z = world_pt.z

func _face_point(world_pt: Vector3, weight: float) -> void:
	var flat := Vector3(world_pt.x - global_position.x, 0.0, world_pt.z - global_position.z)
	if flat.length_squared() < 0.0001:
		return
	var target_yaw := atan2(flat.x, flat.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(weight, 0.0, 1.0))

func _animate_walk(delta: float) -> void:
	_walk_phase += delta * 8.5
	var swing := sin(_walk_phase) * 0.55
	if left_leg != null:
		left_leg.rotation.x = swing
	if right_leg != null:
		right_leg.rotation.x = -swing
	if left_arm != null:
		left_arm.rotation.x = -swing * 0.45
	if right_arm != null:
		right_arm.rotation.x = (swing * 0.45) if is_tester else ((-0.55 + swing * 0.15) if is_safety else (swing * 0.25))
	if head_node != null:
		head_node.rotation.x = lerp(head_node.rotation.x, 0.0, clampf(delta * 6.0, 0.0, 1.0))
		head_node.rotation.y = lerp(head_node.rotation.y, 0.0, clampf(delta * 6.0, 0.0, 1.0))

func _find_safety_alert_target() -> Node3D:
	for obj in get_tree().get_nodes_in_group("sandbox_objects"):
		if not is_instance_valid(obj) or not (obj is Node3D):
			continue
		var kind := str(obj.get_meta("kind", ""))
		if kind == "light_curtain" and bool(obj.get("active")):
			return obj as Node3D
		if kind == "cabinet" and bool(obj.get("estop_active")):
			return obj as Node3D
		if kind == "stack_light" and bool(obj.get("lamp_red_on")):
			return obj as Node3D
		if kind == "water_tank" and bool(obj.get("high_level")):
			return obj as Node3D
	return null

func _is_target_alert(target: Node3D) -> bool:
	if not is_instance_valid(target):
		return false
	var kind := str(target.get_meta("kind", ""))
	if kind == "light_curtain" and bool(target.get("active")):
		return true
	if kind == "cabinet" and bool(target.get("estop_active")):
		return true
	if kind == "stack_light" and bool(target.get("lamp_red_on")):
		return true
	if kind == "water_tank" and bool(target.get("high_level")):
		return true
	return false

func _animate_idle(delta: float) -> void:
	_walk_phase += delta * 3.0
	var alert_pose := is_safety and _inspecting and _is_target_alert(_current_target)
	if left_leg != null:
		left_leg.rotation.x = lerp(left_leg.rotation.x, 0.0, clampf(delta * 8.0, 0.0, 1.0))
	if right_leg != null:
		right_leg.rotation.x = lerp(right_leg.rotation.x, 0.0, clampf(delta * 8.0, 0.0, 1.0))
	if left_arm != null:
		var target_l := -0.15
		if is_safety and _inspecting:
			target_l = -0.52 + sin(_walk_phase * 2.2) * 0.14
		elif is_tester and _inspecting:
			target_l = -0.48
		elif _inspecting:
			target_l = -0.58 + sin(_walk_phase * 1.8) * 0.14
		left_arm.rotation.x = lerp(left_arm.rotation.x, target_l, clampf(delta * 6.0, 0.0, 1.0))
	if right_arm != null:
		var target_r := -0.12 if is_tester else (-0.78 if is_safety else -0.16)
		if alert_pose:
			target_r = -1.25 + sin(_walk_phase * 4.5) * 0.25
		elif is_tester and _inspecting:
			target_r = -0.55 + sin(_walk_phase * 3.5) * 0.14
		elif _inspecting and not is_safety:
			target_r = -0.45 + cos(_walk_phase * 1.8) * 0.12
		elif not _inspecting and not _chatting and fmod(_walk_phase, 18.0) < 3.5:
			target_r = -1.85 + sin(_walk_phase * 3.2) * 0.25
		right_arm.rotation.x = lerp(right_arm.rotation.x, target_r, clampf(delta * 6.0, 0.0, 1.0))
	if head_node != null:
		var target_hx := sin(_walk_phase) * 0.12 + 0.08
		var target_hy := 0.0
		if is_tester and _inspecting:
			target_hx = 0.18 + sin(_walk_phase * 2.0) * 0.08
		elif not _inspecting and not _chatting:
			target_hy = sin(_walk_phase * 0.55) * 0.42
		head_node.rotation.x = lerp(head_node.rotation.x, target_hx, clampf(delta * 6.0, 0.0, 1.0))
		head_node.rotation.y = lerp(head_node.rotation.y, target_hy, clampf(delta * 5.0, 0.0, 1.0))

func _set_status_label(txt: String, col: Color) -> void:
	if status_label == null:
		return
	if txt != _last_status_text:
		_last_status_text = txt
		status_label.text = txt
	if col != _last_status_color:
		_last_status_color = col
		status_label.modulate = col


func _update_status_label(target: Node3D, checking: bool) -> void:
	if status_label == null or not is_instance_valid(target):
		return
	var scene := get_parent()
	var is_active := false
	if scene != null and scene.has_method("_is_object_active"):
		is_active = bool(scene.call("_is_object_active", target))
	var kind := str(target.get_meta("kind", ""))
	if _on_shift_break and target == _break_station:
		if checking:
			var msg := "Updating KPI board..." if kind == "prop_production_board" else ("Logging QC report..." if kind == "prop_qc_desk" else ("Quick shift break" if kind == "prop_locker" else "Checking tools..."))
			_set_status_label(msg, Color("9ad4ff"))
		else:
			_set_status_label("Break -> %s" % target.name, Color("9ad4ff"))
		return
	var state_str := "ACTIVE" if is_active else "OK"
	if kind == "water_tank":
		var lvl := int(target.get("level_percent"))
		state_str = ("%d%% HIGH!" % lvl) if lvl >= 85 else ("%d%%" % lvl)
	elif kind == "remover":
		state_str = "OUT:%d" % int(target.get("removed_count"))
	elif kind == "reject_bin":
		var rej := int(target.get("rejected_count"))
		state_str = ("REJ:%d HIGH" % rej) if rej >= 10 else ("REJ:%d" % rej)
	elif kind in ["conveyor", "conveyor_short"]:
		state_str = "RUN" if is_active else "STOP"
	if role_id == "maintenance":
		if checking:
			_set_status_label("Maint Check: %s [%s]" % [target.name, state_str], Color("ffb85c") if is_active else Color("ffd08a"))
		else:
			_set_status_label("Maint -> %s" % target.name, Color("ffd08a"))
		return
	if role_id == "qc":
		if checking:
			_set_status_label("QC Inspect: %s [%s]" % [target.name, state_str], Color("6ce5ff") if is_active else Color("9beeff"))
		else:
			_set_status_label("QC -> %s" % target.name, Color("9beeff"))
		return
	if is_safety:
		if kind == "light_curtain" and is_active:
			_set_status_label("ALERT: %s TRIPPED!" % target.name, Color("ff6b6b"))
			return
		if kind == "stack_light" and bool(target.get("lamp_red_on")):
			_set_status_label("ALERT: %s RED ALARM!" % target.name, Color("ff6b6b"))
			return
		if kind == "cabinet" and bool(target.get("estop_active")):
			_set_status_label("ALERT: E-STOP ACTIVE!", Color("ff6b6b"))
			return
		if checking:
			_set_status_label("Safety Check: %s [%s]" % [target.name, state_str], Color("66e88a") if not is_active else Color("ff9e5e"))
		else:
			_set_status_label("Safety -> %s" % target.name, Color("8cf5aa"))
		return
	if is_tester:
		if checking:
			_set_status_label("Supervisor Audit: %s [%s]" % [target.name, state_str], Color("66e0a3") if is_active else Color("f7d070"))
		else:
			_set_status_label("Supervisor -> %s" % target.name, Color("f5e6b3"))
		return
	if checking:
		_set_status_label("Inspecting: %s [%s]" % [target.name, state_str], Color("66e0a3") if is_active else Color("f7d070"))
	else:
		_set_status_label("Operator -> %s" % target.name, Color("bfe3f7"))
