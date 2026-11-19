extends Control

const TARGET_SCENE := "res://main.tscn"
const TIPS := [
	"Tip: In Edit Mode, right-click anywhere to open Add Factory Object, or right-click again to return to Select.",
	"Tip: Press Q / E while placing or selecting equipment to rotate it in 90° steps.",
	"Tip: Switch between Internal Ladder PLC and Modbus TCP inside the Control & PLC settings.",
	"Tip: Operator, Supervisor, Safety, Maintenance, and QC NPCs patrol matching machines automatically.",
	"Tip: Right-drag to orbit the camera, middle-drag to pan, and scroll wheel to zoom.",
	"Tip: Press R at any time to reset the camera back to the factory overview.",
]

var _progress_bar: ProgressBar
var _percent_label: Label
var _status_label: Label
var _tip_label: Label
var _spinner: Control
var _display_progress: float = 0.0
var _target_progress: float = 0.0
var _tip_idx: int = 0
var _tip_timer: float = 0.0
var _transitioning: bool = false
var _elapsed: float = 0.0
var _min_show_time: float = 0.65


func _ready() -> void:
	if DisplayServer.get_name() == "headless" or "--smoke-test" in OS.get_cmdline_user_args():
		_min_show_time = 0.0
	_build_ui()
	_tip_idx = randi() % TIPS.size()
	_tip_label.text = TIPS[_tip_idx]
	var err := ResourceLoader.load_threaded_request(TARGET_SCENE)
	if err != OK:
		get_tree().change_scene_to_file(TARGET_SCENE)


func _process(delta: float) -> void:
	_elapsed += delta
	if is_instance_valid(_spinner):
		_spinner.rotation += delta * 3.8

	_tip_timer += delta
	if _tip_timer >= 3.2:
		_tip_timer = 0.0
		_tip_idx = (_tip_idx + 1) % TIPS.size()
		if is_instance_valid(_tip_label):
			_tip_label.text = TIPS[_tip_idx]

	if _transitioning:
		return

	var progress := []
	var status := ResourceLoader.load_threaded_get_status(TARGET_SCENE, progress)
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if progress.size() > 0:
				_target_progress = maxf(_target_progress, float(progress[0]) * 100.0)
			if is_instance_valid(_status_label):
				_status_label.text = "Loading factory assets & 3D equipment..."
		ResourceLoader.THREAD_LOAD_LOADED:
			_target_progress = 100.0
			if is_instance_valid(_status_label):
				_status_label.text = "Initializing simulation..."
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_transitioning = true
			get_tree().change_scene_to_file(TARGET_SCENE)
			return

	_display_progress = move_toward(_display_progress, _target_progress, delta * 140.0)
	if is_instance_valid(_progress_bar):
		_progress_bar.value = _display_progress
	if is_instance_valid(_percent_label):
		_percent_label.text = "%d%%" % int(round(_display_progress))

	if status == ResourceLoader.THREAD_LOAD_LOADED and _display_progress >= 99.5 and _elapsed >= _min_show_time:
		_transitioning = true
		var packed := ResourceLoader.load_threaded_get(TARGET_SCENE) as PackedScene
		if packed != null:
			get_tree().change_scene_to_packed(packed)
		else:
			get_tree().change_scene_to_file(TARGET_SCENE)


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("0d1620")
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(540, 260)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.13, 0.18, 0.96)
	style.border_color = Color("2f5470")
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	card.add_theme_stylebox_override("panel", style)
	center.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	card.add_child(vbox)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 14)
	vbox.add_child(top_row)

	var logo_tex := _load_svg_texture("res://assets/branding/app_logo.svg", 2.0)
	if logo_tex != null:
		var logo_rect := TextureRect.new()
		logo_rect.texture = logo_tex
		logo_rect.custom_minimum_size = Vector2(56, 56)
		logo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		top_row.add_child(logo_rect)

	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_col.add_theme_constant_override("separation", 2)
	top_row.add_child(title_col)

	var title := Label.new()
	title.text = "PKS FACTORY SIMULATOR"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("eef7fa"))
	title_col.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "3D Industrial Automation & PLC Sandbox"
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color("7ea7c2"))
	title_col.add_child(subtitle)

	var spinner_box := Control.new()
	spinner_box.custom_minimum_size = Vector2(32, 32)
	spinner_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top_row.add_child(spinner_box)

	_spinner = _SpinnerIcon.new()
	_spinner.size = Vector2(32, 32)
	_spinner.pivot_offset = Vector2(16, 16)
	spinner_box.add_child(_spinner)

	var bar_row := HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", 10)
	vbox.add_child(bar_row)

	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 100.0
	_progress_bar.value = 0.0
	_progress_bar.show_percentage = false
	_progress_bar.custom_minimum_size = Vector2(0, 14)
	_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_progress_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color("132230")
	bar_bg.set_corner_radius_all(6)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color("2da8d8")
	bar_fill.set_corner_radius_all(6)
	_progress_bar.add_theme_stylebox_override("background", bar_bg)
	_progress_bar.add_theme_stylebox_override("fill", bar_fill)
	bar_row.add_child(_progress_bar)

	_percent_label = Label.new()
	_percent_label.text = "0%"
	_percent_label.custom_minimum_size = Vector2(44, 0)
	_percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_percent_label.add_theme_font_size_override("font_size", 13)
	_percent_label.add_theme_color_override("font_color", Color("bfe3f7"))
	bar_row.add_child(_percent_label)

	_status_label = Label.new()
	_status_label.text = "Preparing factory environment..."
	_status_label.add_theme_font_size_override("font_size", 12)
	_status_label.add_theme_color_override("font_color", Color("9cb3c4"))
	vbox.add_child(_status_label)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	_tip_label = Label.new()
	_tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip_label.custom_minimum_size = Vector2(0, 40)
	_tip_label.add_theme_font_size_override("font_size", 12)
	_tip_label.add_theme_color_override("font_color", Color("d2e4ef"))
	vbox.add_child(_tip_label)


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


class _SpinnerIcon extends Control:
	func _draw() -> void:
		var center := size * 0.5
		var r := minf(size.x, size.y) * 0.38
		draw_arc(center, r, 0.0, TAU, 28, Color(0.18, 0.32, 0.44, 0.45), 4.0, true)
		draw_arc(center, r, -PI * 0.5, PI * 0.65, 24, Color("38bdf8"), 4.0, true)
