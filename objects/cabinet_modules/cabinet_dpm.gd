extends Node3D

@export var label_text: String = "DPM":
	set(value):
		if label_text == value:
			return
		label_text = value
		if is_node_ready():
			_apply_visuals()

@export var led_color: Color = Color("ff3b30"):
	set(value):
		if led_color == value:
			return
		led_color = value
		if is_node_ready():
			_apply_visuals()

@export var unit_text: String = "":
	set(value):
		if unit_text == value:
			return
		unit_text = value
		if is_node_ready():
			_update_readout()

@export_range(0, 2) var decimals: int = 0:
	set(value):
		var clamped := clampi(value, 0, 2)
		if decimals == clamped:
			return
		decimals = clamped
		if is_node_ready():
			_update_readout()

@export var signed_mode: bool = true:
	set(value):
		if signed_mode == value:
			return
		signed_mode = value
		if is_node_ready():
			_update_readout()

@export var raw_value: int = 0:
	set(value):
		var clamped := clampi(value, -32768, 65535)
		if raw_value == clamped:
			return
		raw_value = clamped
		if is_node_ready():
			_update_readout()

@export var io_id: String = ""

@onready var tag_label: Label3D = $Tag
@onready var value_label: Label3D = $ValueLabel
@onready var unit_label: Label3D = $UnitLabel

func _ready() -> void:
	_apply_visuals()
	_update_readout()

func _format_display_text(val: int, dec: int, is_signed: bool) -> String:
	var v := val
	if is_signed and v >= 32768:
		v -= 65536
	if dec <= 0:
		return "%d" % v
	var divisor := pow(10.0, float(dec))
	return ("%." + str(dec) + "f") % (float(v) / divisor)

func _update_readout() -> void:
	if value_label != null:
		value_label.text = _format_display_text(raw_value, decimals, signed_mode)
		value_label.position.y = 0.004 if not unit_text.strip_edges().is_empty() else 0.0
	if unit_label != null:
		var u := unit_text.strip_edges()
		unit_label.text = u
		unit_label.visible = not u.is_empty()

func _apply_visuals() -> void:
	if tag_label != null:
		tag_label.text = label_text
	if value_label != null:
		value_label.modulate = led_color
	if unit_label != null:
		unit_label.modulate = led_color.lightened(0.25)
