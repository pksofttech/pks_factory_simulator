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

func _ready() -> void:
	set_notify_transform(true)
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

func _process(delta: float) -> void:
	if not active or belt_material == null or is_zero_approx(speed):
		return
	# ใช้ speed แทน constant_linear_velocity.length() เพื่อให้รองรับค่าติดลบ (ถอยหลัง) ได้ด้วย
	scroll_offset = fposmod(scroll_offset + delta * speed / BELT_TEXTURE_REPEAT_METERS, 1.0)
	belt_material.set_shader_parameter("scroll_offset", scroll_offset)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_update_velocity()

func _update_velocity() -> void:
	# คำนวณทิศทางไปข้างหน้าของสายพาน (+X) ให้ตรงกับแกนของโมเดลและ UV ที่เลื่อน
	var forward := global_basis.x.normalized() if is_inside_tree() else basis.x.normalized()
	constant_linear_velocity = forward * (speed if active else 0.0)
