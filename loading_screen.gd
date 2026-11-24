extends Control

const TARGET_SCENE := "res://main.tscn"
const LOGO_PATH := "res://assets/branding/app_logo.svg"
const TIP_ROTATE_INTERVAL := 3.6
const FADE_IN_DURATION := 0.28
const FADE_OUT_DURATION := 0.25

const LOAD_STAGES: Array[Dictionary] = [
	{
		"index": 1,
		"label": "CORE ENGINE",
		"required": true,
		"paths": [
			"res://main.tscn",
		],
	},
	{
		"index": 2,
		"label": "3D EQUIPMENT",
		"required": false,
		"paths": [
			"res://objects/conveyor.tscn",
			"res://objects/conveyor_short.tscn",
			"res://objects/turn.tscn",
			"res://objects/sensor.tscn",
			"res://objects/pusher.tscn",
			"res://objects/stopper.tscn",
			"res://objects/emitter.tscn",
			"res://objects/remover.tscn",
			"res://objects/cabinet.tscn",
			"res://objects/box.tscn",
			"res://objects/box_plastic.tscn",
		],
	},
	{
		"index": 3,
		"label": "NPCS & CONTROL UI",
		"required": false,
		"paths": [
			"res://objects/control_cabinet_2d.tscn",
			"res://objects/operator_npc.tscn",
			"res://objects/tester_npc.tscn",
			"res://objects/safety_npc.tscn",
			"res://objects/maintenance_npc.tscn",
			"res://objects/qc_npc.tscn",
		],
	},
]

const TIPS: Array[String] = [
	"In Edit Mode, right-click anywhere to open Add Factory Object, or right-click again to return to Select.",
	"Press Q / E while placing or selecting equipment to rotate it in 90-degree increments.",
	"Switch between Internal Ladder PLC and Modbus TCP inside the Control & PLC settings.",
	"Operator, Supervisor, Safety, Maintenance, and QC NPCs patrol matching machines automatically.",
	"Right-drag to orbit the camera, middle-drag to pan, and use the scroll wheel to zoom.",
	"Press R at any time to reset the camera back to the factory overview.",
]

@onready var _blueprint_canvas: Control = $BlueprintCanvas
@onready var _card_frame: MarginContainer = $CenterContainer/CardFrame
@onready var _margin: MarginContainer = $CenterContainer/CardFrame/Card/Margin
@onready var _logo_rect: TextureRect = $CenterContainer/CardFrame/Card/Margin/ContentVBox/HeaderRow/LogoRect
@onready var _title_label: Label = $CenterContainer/CardFrame/Card/Margin/ContentVBox/HeaderRow/TitleCol/TitleLabel
@onready var _spinner_host: Control = $CenterContainer/CardFrame/Card/Margin/ContentVBox/HeaderRow/SpinnerHost
@onready var _stage_tag_label: Label = $CenterContainer/CardFrame/Card/Margin/ContentVBox/StageHeaderRow/StageTagLabel
@onready var _percent_label: Label = $CenterContainer/CardFrame/Card/Margin/ContentVBox/StageHeaderRow/PercentLabel
@onready var _progress_bar: ProgressBar = $CenterContainer/CardFrame/Card/Margin/ContentVBox/BarWrapper/ProgressBar
@onready var _shimmer_overlay: Control = $CenterContainer/CardFrame/Card/Margin/ContentVBox/BarWrapper/ShimmerOverlay
@onready var _status_label: Label = $CenterContainer/CardFrame/Card/Margin/ContentVBox/StatusRow/StatusLabel
@onready var _asset_count_label: Label = $CenterContainer/CardFrame/Card/Margin/ContentVBox/StatusRow/AssetCountLabel
@onready var _error_box: VBoxContainer = $CenterContainer/CardFrame/Card/Margin/ContentVBox/ErrorBox
@onready var _error_label: Label = $CenterContainer/CardFrame/Card/Margin/ContentVBox/ErrorBox/ErrorLabel
@onready var _retry_button: Button = $CenterContainer/CardFrame/Card/Margin/ContentVBox/ErrorBox/ErrorButtons/RetryButton
@onready var _fallback_button: Button = $CenterContainer/CardFrame/Card/Margin/ContentVBox/ErrorBox/ErrorButtons/FallbackButton
@onready var _tip_label: Label = $CenterContainer/CardFrame/Card/Margin/ContentVBox/TipRow/TipLabel
@onready var _corner_brackets: Control = $CenterContainer/CardFrame/CornerBrackets
@onready var _fade_overlay: ColorRect = $FadeOverlay

var _shimmer_layer: _ShimmerLayer
var _spinner_icon: _SpinnerIcon
var _queue: Array[Dictionary] = []
var _preloaded_cache: Array[Resource] = []
var _main_packed: PackedScene = null
var _current_index: int = 0
var _active_requested: bool = false
var _queue_complete: bool = false
var _has_error: bool = false
var _transitioning: bool = false
var _fast_mode: bool = false
var _display_progress: float = 0.0
var _target_progress: float = 0.0
var _elapsed: float = 0.0
var _min_show_time: float = 0.65
var _tip_idx: int = 0
var _tip_timer: float = 0.0
var _tip_tween: Tween = null
var _fade_tween: Tween = null


func _ready() -> void:
	_fast_mode = DisplayServer.get_name() == "headless" or "--smoke-test" in OS.get_cmdline_user_args()
	if _fast_mode:
		_min_show_time = 0.0

	_ensure_logo_texture()
	_mount_custom_visuals()

	_retry_button.pressed.connect(_on_retry_pressed)
	_fallback_button.pressed.connect(_on_fallback_pressed)

	if get_viewport() != null:
		get_viewport().size_changed.connect(_update_responsive_layout)
	_update_responsive_layout()

	_tip_idx = randi() % TIPS.size()
	_tip_label.text = TIPS[_tip_idx]

	_play_fade_in()
	_start_loading_queue()


func _process(delta: float) -> void:
	_elapsed += delta

	if not _has_error and not _transitioning:
		_tip_timer += delta
		if _tip_timer >= TIP_ROTATE_INTERVAL:
			_tip_timer = 0.0
			_rotate_tip()

	if _transitioning or _has_error:
		return

	if not _queue_complete:
		_poll_current_item()

	if _fast_mode and _queue_complete:
		_display_progress = 100.0
	else:
		_display_progress = move_toward(_display_progress, _target_progress, delta * 145.0)

	_progress_bar.value = _display_progress
	_percent_label.text = "%d%%" % int(round(_display_progress))
	if is_instance_valid(_shimmer_layer):
		_shimmer_layer.progress_ratio = clampf(_display_progress / 100.0, 0.0, 1.0)

	if _queue_complete and (_fast_mode or (_display_progress >= 99.5 and _elapsed >= _min_show_time)):
		_begin_scene_transition()


func _mount_custom_visuals() -> void:
	var backdrop := _BlueprintBackdrop.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_blueprint_canvas.add_child(backdrop)

	var brackets := _CornerBrackets.new()
	brackets.set_anchors_preset(Control.PRESET_FULL_RECT)
	brackets.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_corner_brackets.add_child(brackets)

	_spinner_icon = _SpinnerIcon.new()
	_spinner_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	_spinner_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spinner_host.add_child(_spinner_icon)

	_shimmer_layer = _ShimmerLayer.new()
	_shimmer_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shimmer_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shimmer_overlay.add_child(_shimmer_layer)


func _ensure_logo_texture() -> void:
	if _logo_rect.texture != null:
		return
	var fallback_tex := _load_svg_texture(LOGO_PATH, 2.0)
	if fallback_tex != null:
		_logo_rect.texture = fallback_tex


func _load_svg_texture(path: String, svg_scale: float = 2.0) -> Texture2D:
	if not FileAccess.file_exists(path):
		return null
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return null
	var img := Image.new()
	if img.load_svg_from_buffer(bytes, svg_scale) != OK:
		return null
	return ImageTexture.create_from_image(img)


func _play_fade_in() -> void:
	if _fast_mode:
		_fade_overlay.modulate.a = 0.0
		_fade_overlay.visible = false
		return
	_fade_overlay.visible = true
	_fade_overlay.modulate.a = 1.0
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_fade_overlay, "modulate:a", 0.0, FADE_IN_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _start_loading_queue() -> void:
	_queue.clear()
	_preloaded_cache.clear()
	_main_packed = null
	_current_index = 0
	_active_requested = false
	_queue_complete = false
	_has_error = false
	_display_progress = 0.0
	_target_progress = 0.0
	_elapsed = 0.0

	_error_box.visible = false
	_spinner_host.visible = true
	_progress_bar.value = 0.0
	_percent_label.text = "0%"
	if is_instance_valid(_shimmer_layer):
		_shimmer_layer.progress_ratio = 0.0

	_build_queue()
	_update_stage_header(0)
	_asset_count_label.text = "0 / %d" % _queue.size()
	_request_next_item()


func _build_queue() -> void:
	if _fast_mode:
		_queue.append({
			"path": TARGET_SCENE,
			"stage_index": 1,
			"stage_label": "CORE ENGINE",
			"required": true,
		})
		return

	for stage: Dictionary in LOAD_STAGES:
		var stage_index: int = int(stage["index"])
		var stage_label: String = String(stage["label"])
		var is_required: bool = bool(stage["required"])
		var paths: Array = stage["paths"]
		for raw_path in paths:
			var path := String(raw_path)
			if path == TARGET_SCENE or ResourceLoader.exists(path):
				_queue.append({
					"path": path,
					"stage_index": stage_index,
					"stage_label": stage_label,
					"required": is_required,
				})


func _request_next_item() -> void:
	while _current_index < _queue.size():
		var item: Dictionary = _queue[_current_index]
		var path: String = String(item["path"])
		var is_required: bool = bool(item["required"])

		_update_stage_header(_current_index)
		_status_label.text = "Loading %s..." % _format_asset_name(path)
		_asset_count_label.text = "%d / %d" % [_current_index, _queue.size()]

		var err := ResourceLoader.load_threaded_request(path)
		if err == OK:
			_active_requested = true
			return

		if is_required:
			_handle_required_error("Failed to start loading core scene (%s). Error code: %d." % [path, err])
			return

		push_warning("LoadingScreen: skipping optional asset '%s' (request error %d)." % [path, err])
		_current_index += 1

	_finish_queue()


func _poll_current_item() -> void:
	if not _active_requested or _current_index >= _queue.size():
		return

	var item: Dictionary = _queue[_current_index]
	var path: String = String(item["path"])
	var is_required: bool = bool(item["required"])
	var total_items := maxi(_queue.size(), 1)

	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(path, progress)
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var item_fraction := 0.0
			if progress.size() > 0:
				item_fraction = clampf(float(progress[0]), 0.0, 1.0)
			var overall_percent := (float(_current_index) + item_fraction) / float(total_items) * 100.0
			_target_progress = maxf(_target_progress, overall_percent)
		ResourceLoader.THREAD_LOAD_LOADED:
			var loaded_res := ResourceLoader.load_threaded_get(path)
			if loaded_res == null:
				if is_required:
					_handle_required_error("Core scene '%s' returned an empty resource." % path)
					return
				push_warning("LoadingScreen: optional asset '%s' loaded as null." % path)
			else:
				_preloaded_cache.append(loaded_res)
				if path == TARGET_SCENE:
					_main_packed = loaded_res as PackedScene
					if _main_packed == null:
						_handle_required_error("Core scene '%s' is not a valid PackedScene." % path)
						return

			_active_requested = false
			_current_index += 1
			var completed_percent := float(_current_index) / float(total_items) * 100.0
			_target_progress = maxf(_target_progress, completed_percent)
			_asset_count_label.text = "%d / %d" % [_current_index, _queue.size()]
			_request_next_item()
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_active_requested = false
			if is_required:
				_handle_required_error("Failed to load core scene '%s' (status %d)." % [path, status])
				return
			push_warning("LoadingScreen: optional asset '%s' failed to load (status %d)." % [path, status])
			_current_index += 1
			var fallback_percent := float(_current_index) / float(total_items) * 100.0
			_target_progress = maxf(_target_progress, fallback_percent)
			_asset_count_label.text = "%d / %d" % [_current_index, _queue.size()]
			_request_next_item()


func _finish_queue() -> void:
	_queue_complete = true
	_active_requested = false
	_target_progress = 100.0
	_status_label.text = "Initializing simulation..."
	_asset_count_label.text = "%d / %d" % [_queue.size(), _queue.size()]
	var stage_total := 1 if _fast_mode else LOAD_STAGES.size()
	var final_label := "CORE ENGINE" if _fast_mode else String(LOAD_STAGES[LOAD_STAGES.size() - 1]["label"])
	_stage_tag_label.text = "STAGE %d/%d  •  %s" % [stage_total, stage_total, final_label]


func _handle_required_error(message: String) -> void:
	if _fast_mode:
		_transitioning = true
		get_tree().change_scene_to_file(TARGET_SCENE)
		return
	_has_error = true
	_active_requested = false
	_spinner_host.visible = false
	_status_label.text = "Loading paused due to an error."
	_error_label.text = message
	_error_box.visible = true


func _begin_scene_transition() -> void:
	if _transitioning:
		return
	_transitioning = true
	if _fast_mode:
		_complete_scene_transition()
		return

	_fade_overlay.visible = true
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_fade_overlay, "modulate:a", 1.0, FADE_OUT_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_fade_tween.finished.connect(_complete_scene_transition)


func _complete_scene_transition() -> void:
	if _main_packed != null:
		var err := get_tree().change_scene_to_packed(_main_packed)
		if err != OK:
			get_tree().change_scene_to_file(TARGET_SCENE)
	else:
		get_tree().change_scene_to_file(TARGET_SCENE)


func _on_retry_pressed() -> void:
	if _transitioning:
		return
	_start_loading_queue()


func _on_fallback_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	get_tree().change_scene_to_file(TARGET_SCENE)


func _update_stage_header(queue_index: int) -> void:
	if _queue.is_empty():
		return
	var clamped_idx := clampi(queue_index, 0, _queue.size() - 1)
	var item: Dictionary = _queue[clamped_idx]
	var stage_index: int = int(item["stage_index"])
	var stage_label: String = String(item["stage_label"])
	var stage_total := 1 if _fast_mode else LOAD_STAGES.size()
	_stage_tag_label.text = "STAGE %d/%d  •  %s" % [stage_index, stage_total, stage_label]


func _rotate_tip() -> void:
	if TIPS.size() <= 1:
		return
	_tip_idx = (_tip_idx + 1) % TIPS.size()
	var next_tip := TIPS[_tip_idx]
	if _fast_mode:
		_tip_label.text = next_tip
		return

	if _tip_tween != null and _tip_tween.is_valid():
		_tip_tween.kill()
	_tip_tween = create_tween()
	_tip_tween.tween_property(_tip_label, "modulate:a", 0.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tip_tween.tween_callback(func() -> void:
		if is_instance_valid(_tip_label):
			_tip_label.text = next_tip
	)
	_tip_tween.tween_property(_tip_label, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _update_responsive_layout() -> void:
	if get_viewport() == null:
		return
	var vp_w := get_viewport().get_visible_rect().size.x
	_card_frame.custom_minimum_size = Vector2(clampf(vp_w - 32.0, 280.0, 580.0), 0.0)

	if vp_w < 460.0:
		_title_label.add_theme_font_size_override("font_size", 17)
		_logo_rect.custom_minimum_size = Vector2(44.0, 44.0)
		_margin.add_theme_constant_override("margin_left", 18)
		_margin.add_theme_constant_override("margin_right", 18)
		_margin.add_theme_constant_override("margin_top", 18)
		_margin.add_theme_constant_override("margin_bottom", 18)
	else:
		_title_label.add_theme_font_size_override("font_size", 21)
		_logo_rect.custom_minimum_size = Vector2(56.0, 56.0)
		_margin.add_theme_constant_override("margin_left", 28)
		_margin.add_theme_constant_override("margin_right", 28)
		_margin.add_theme_constant_override("margin_top", 24)
		_margin.add_theme_constant_override("margin_bottom", 24)


func _format_asset_name(path: String) -> String:
	if path == TARGET_SCENE:
		return "Factory Core Scene"
	var base := path.get_file().get_basename()
	var parts := base.split("_", false)
	var formatted: PackedStringArray = PackedStringArray()
	for part in parts:
		var lower := part.to_lower()
		match lower:
			"npc":
				formatted.append("NPC")
			"qc":
				formatted.append("QC")
			"2d":
				formatted.append("2D")
			"3d":
				formatted.append("3D")
			"plc":
				formatted.append("PLC")
			_:
				formatted.append(part.capitalize())
	return " ".join(formatted)


class _BlueprintBackdrop extends Control:
	const MINOR_STEP := 32.0
	const MAJOR_STEP := 128.0
	var _scroll_offset: float = 0.0
	var _scan_phase: float = 0.0

	func _process(delta: float) -> void:
		_scroll_offset = fposmod(_scroll_offset + delta * 10.0, MAJOR_STEP)
		_scan_phase = fposmod(_scan_phase + delta * 0.14, 1.0)
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w <= 0.0 or h <= 0.0:
			return

		var minor_col := Color(0.16, 0.34, 0.49, 0.10)
		var major_col := Color(0.22, 0.49, 0.69, 0.18)

		var x := -MINOR_STEP + fposmod(_scroll_offset, MINOR_STEP)
		while x < w:
			draw_line(Vector2(x, 0.0), Vector2(x, h), minor_col, 1.0)
			x += MINOR_STEP

		var y := -MINOR_STEP + fposmod(_scroll_offset, MINOR_STEP)
		while y < h:
			draw_line(Vector2(0.0, y), Vector2(w, y), minor_col, 1.0)
			y += MINOR_STEP

		var mx := -MAJOR_STEP + _scroll_offset
		while mx < w:
			draw_line(Vector2(mx, 0.0), Vector2(mx, h), major_col, 1.0)
			mx += MAJOR_STEP

		var my := -MAJOR_STEP + _scroll_offset
		while my < h:
			draw_line(Vector2(0.0, my), Vector2(w, my), major_col, 1.0)
			my += MAJOR_STEP

		var scan_y := _scan_phase * (h + 120.0) - 60.0
		draw_rect(Rect2(0.0, scan_y - 26.0, w, 52.0), Color(0.22, 0.74, 0.97, 0.035), true)
		draw_line(Vector2(0.0, scan_y), Vector2(w, scan_y), Color(0.22, 0.74, 0.97, 0.16), 1.0)

		var inset := 22.0
		var arm := 10.0
		var cross_col := Color(0.22, 0.74, 0.97, 0.28)
		var corners := [
			Vector2(inset, inset),
			Vector2(w - inset, inset),
			Vector2(inset, h - inset),
			Vector2(w - inset, h - inset),
		]
		for pt: Vector2 in corners:
			draw_line(Vector2(pt.x - arm, pt.y), Vector2(pt.x + arm, pt.y), cross_col, 1.0)
			draw_line(Vector2(pt.x, pt.y - arm), Vector2(pt.x, pt.y + arm), cross_col, 1.0)


class _CornerBrackets extends Control:
	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w <= 8.0 or h <= 8.0:
			return

		var cyan := Color("38bdf8")
		var amber := Color("f59e0b")
		var b_len := 18.0
		var thick := 2.0
		var pad := 1.0

		# Top-left
		draw_line(Vector2(pad, pad), Vector2(pad + b_len, pad), cyan, thick)
		draw_line(Vector2(pad, pad), Vector2(pad, pad + b_len), cyan, thick)
		draw_line(Vector2(pad + b_len + 4.0, pad), Vector2(pad + b_len + 9.0, pad), amber, thick)

		# Top-right
		draw_line(Vector2(w - pad, pad), Vector2(w - pad - b_len, pad), cyan, thick)
		draw_line(Vector2(w - pad, pad), Vector2(w - pad, pad + b_len), cyan, thick)
		draw_line(Vector2(w - pad - b_len - 4.0, pad), Vector2(w - pad - b_len - 9.0, pad), amber, thick)

		# Bottom-left
		draw_line(Vector2(pad, h - pad), Vector2(pad + b_len, h - pad), cyan, thick)
		draw_line(Vector2(pad, h - pad), Vector2(pad, h - pad - b_len), cyan, thick)
		draw_line(Vector2(pad + b_len + 4.0, h - pad), Vector2(pad + b_len + 9.0, h - pad), amber, thick)

		# Bottom-right
		draw_line(Vector2(w - pad, h - pad), Vector2(w - pad - b_len, h - pad), cyan, thick)
		draw_line(Vector2(w - pad, h - pad), Vector2(w - pad, h - pad - b_len), cyan, thick)
		draw_line(Vector2(w - pad - b_len - 4.0, h - pad), Vector2(w - pad - b_len - 9.0, h - pad), amber, thick)


class _SpinnerIcon extends Control:
	var _outer_angle: float = 0.0
	var _inner_angle: float = 0.0

	func _process(delta: float) -> void:
		_outer_angle = fposmod(_outer_angle + delta * 3.4, TAU)
		_inner_angle = fposmod(_inner_angle - delta * 4.6, TAU)
		queue_redraw()

	func _draw() -> void:
		var center := size * 0.5
		var outer_r := minf(size.x, size.y) * 0.42
		var inner_r := outer_r * 0.62
		if outer_r <= 2.0:
			return

		draw_arc(center, outer_r, 0.0, TAU, 32, Color(0.18, 0.34, 0.47, 0.35), 2.5, true)
		draw_arc(center, outer_r, _outer_angle, _outer_angle + PI * 1.15, 24, Color("38bdf8"), 2.5, true)
		draw_arc(center, inner_r, _inner_angle, _inner_angle + PI * 0.85, 20, Color("f59e0b"), 2.0, true)


class _ShimmerLayer extends Control:
	var progress_ratio: float = 0.0
	var _phase: float = 0.0

	func _process(delta: float) -> void:
		_phase = fposmod(_phase + delta * 0.95, 1.0)
		queue_redraw()

	func _draw() -> void:
		var fill_w := size.x * clampf(progress_ratio, 0.0, 1.0)
		if fill_w <= 6.0 or size.y <= 0.0:
			return

		var band_w := clampf(size.x * 0.22, 36.0, 96.0)
		var travel := fill_w + band_w * 2.0
		var center_x := -band_w + _phase * travel

		var outer_left := clampf(center_x - band_w * 0.5, 0.0, fill_w)
		var outer_right := clampf(center_x + band_w * 0.5, 0.0, fill_w)
		if outer_right > outer_left:
			draw_rect(Rect2(outer_left, 1.0, outer_right - outer_left, size.y - 2.0), Color(0.78, 0.94, 1.0, 0.14), true)

		var inner_left := clampf(center_x - band_w * 0.2, 0.0, fill_w)
		var inner_right := clampf(center_x + band_w * 0.2, 0.0, fill_w)
		if inner_right > inner_left:
			draw_rect(Rect2(inner_left, 1.0, inner_right - inner_left, size.y - 2.0), Color(0.92, 0.98, 1.0, 0.26), true)
