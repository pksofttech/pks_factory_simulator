extends StaticBody3D

const BELT_TEXTURE_REPEAT_METERS := 1.5
const BELT_SHADER := preload("res://objects/belt_surface.gdshader")

# เพิ่มตัวแปรปรับความเร็วใน Inspector และเรียกแก้ผ่านโค้ดได้ง่ายๆ
@export var active: bool = false:
	set(value):
		active = value
		_update_velocity()

@export var speed: float = 1.8:
	set(value):
		speed = value
		_update_velocity()

var belt_material: ShaderMaterial
var scroll_offset := 0.0
var indicator_mat: StandardMaterial3D
var _last_working := false
var _loop_audio: AudioStreamPlayer3D

@onready var indicator: MeshInstance3D = get_node_or_null("Indicator")
@onready var beacon_light: OmniLight3D = get_node_or_null("BeaconLight")

func _ready() -> void:
	set_notify_transform(true)
	if indicator != null:
		indicator_mat = indicator.material_override as StandardMaterial3D
	var fa := get_node_or_null("/root/FactoryAudio")
	if fa != null:
		_loop_audio = fa.call("attach_loop", self, "conveyor_loop", -18.0, 14.0) as AudioStreamPlayer3D
	_update_velocity() # ตั้งค่าความเร็วเริ่มต้น
	
	var belt := find_child("BeltSurface", true, false) as MeshInstance3D
	if belt == null:
		push_error("ConveyorVisual is missing BeltSurface")
		return
	var imported := belt.get_active_material(0) as StandardMaterial3D
	if imported == null or imported.albedo_texture == null:
		push_error("BeltSurface is missing its color texture")
		return
	belt_material = ShaderMaterial.new()
	belt_material.shader = BELT_SHADER
	belt_material.set_shader_parameter("belt_albedo", imported.albedo_texture)
	belt_material.set_shader_parameter("belt_roughness", imported.roughness)
	if imported.normal_texture != null:
		belt_material.set_shader_parameter("belt_normal", imported.normal_texture)
		belt_material.set_shader_parameter("normal_strength", imported.normal_scale)
		belt_material.set_shader_parameter("has_normal", true)
	belt.material_override = belt_material

func _is_system_running() -> bool:
	var scene := get_parent()
	if scene == null or scene.get("running") == null:
		return true
	return bool(scene.get("running"))

func _process(delta: float) -> void:
	var working := active and _is_system_running()
	var blink_on := (Time.get_ticks_msec() / 350) % 2 == 0
	if working != _last_working or (working and blink_on != bool(get_meta("_last_blink", false))):
		_update_indicator()
	if not working or belt_material == null or is_zero_approx(speed):
		return
	# ใช้ speed แทน constant_linear_velocity.length() เพื่อให้รองรับค่าติดลบ (ถอยหลัง) ได้ด้วย
	scroll_offset = fposmod(scroll_offset + delta * speed / BELT_TEXTURE_REPEAT_METERS, 1.0)
	belt_material.set_shader_parameter("scroll_offset", scroll_offset)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_update_velocity()

func _update_indicator() -> void:
	var working := active and _is_system_running()
	var blink_on := (Time.get_ticks_msec() / 350) % 2 == 0
	_last_working = working
	set_meta("_last_blink", blink_on)
	if beacon_light != null:
		beacon_light.visible = working and blink_on
	var fa := get_node_or_null("/root/FactoryAudio")
	if fa != null and _loop_audio != null:
		fa.call("set_loop_active", _loop_audio, working)
	if indicator_mat != null:
		indicator_mat.albedo_color = Color("f22929") if working else Color("4a5a66")
		indicator_mat.emission = Color("f22929")
		indicator_mat.emission_energy_multiplier = (3.2 if blink_on else 0.15) if working else 0.0

func _update_velocity() -> void:
	# คำนวณทิศทางไปข้างหน้าของสายพาน (+X) ให้ตรงกับแกนของโมเดลและ UV ที่เลื่อน
	var forward := global_basis.x.normalized() if is_inside_tree() else basis.x.normalized()
	constant_linear_velocity = forward * (speed if (active and _is_system_running()) else 0.0)
	_update_indicator()
