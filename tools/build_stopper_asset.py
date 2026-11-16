"""Build a realistic Side-Swing Gate Stopper for objects/stopper.tscn.

Usage:
    /home/pksofttech/blender-4.1.1-linux-x64/blender -b --python tools/build_stopper_asset.py
"""
from pathlib import Path
import math
import bpy

PROJECT = Path(__file__).resolve().parents[1]
SOURCE = PROJECT.parent / "godot-object-sources"
ASSETS = PROJECT / "assets"


def reset() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for mat in list(bpy.data.materials):
        bpy.data.materials.remove(mat)


def make_material(name: str, color: tuple[float, float, float], roughness: float = 0.75, metallic: float = 0.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    return mat


def xyz(point: tuple[float, float, float]) -> tuple[float, float, float]:
    x, y, z = point
    return (x, -z, y)


def add_cube(name: str, center: tuple[float, float, float], size: tuple[float, float, float], mat, bevel: float = 0.0):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=xyz(center))
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = (size[0], size[2], size[1])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0.0:
        mod = obj.modifiers.new("Bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
    obj.data.materials.append(mat)
    return obj


def add_cylinder(
    name: str,
    center: tuple[float, float, float],
    radius: float,
    depth: float,
    mat,
    axis: str = "y",
    vertices: int = 24,
):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=xyz(center))
    obj = bpy.context.object
    obj.name = name
    if axis == "z":
        obj.rotation_euler[0] = math.pi / 2.0
    elif axis == "x":
        obj.rotation_euler[1] = math.pi / 2.0
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    obj.data.materials.append(mat)
    return obj


def join_objects(objects: list, name: str):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    objects[0].name = name
    return objects[0]


def build_stopper() -> None:
    reset()
    frame_steel = make_material("Powder Coated Frame", (0.24, 0.33, 0.39), roughness=0.45, metallic=0.35)
    aluminum = make_material("Anodized Aluminum", (0.64, 0.69, 0.73), roughness=0.32, metallic=0.78)
    dark_steel = make_material("Dark Cast Steel", (0.14, 0.16, 0.18), roughness=0.48, metallic=0.60)
    amber = make_material("Safety Amber", (0.92, 0.62, 0.12), roughness=0.40, metallic=0.10)
    brass = make_material("Pneumatic Brass", (0.78, 0.61, 0.24), roughness=0.32, metallic=0.82)
    rubber_pad = make_material("Rubber Bumper", (0.07, 0.08, 0.09), roughness=0.85, metallic=0.0)

    pivot_z = -0.92
    # Side pedestal outside conveyor width (z = -0.92, clear of belt z in [-0.75, 0.75])
    add_cube("SideBasePlate", (0.0, 0.02, pivot_z), (0.38, 0.04, 0.34), dark_steel, bevel=0.006)
    for bx in (-0.14, 0.14):
        for bz in (-0.12, 0.12):
            add_cylinder(f"AnchorBolt_{bx}_{bz}", (bx, 0.045, pivot_z + bz), 0.014, 0.018, aluminum, axis="y", vertices=6)
    add_cube("PedestalColumn", (0.0, 0.58, pivot_z), (0.16, 1.08, 0.16), frame_steel, bevel=0.010)
    add_cube("RotaryActuator", (0.0, 1.22, pivot_z), (0.22, 0.20, 0.22), dark_steel, bevel=0.010)
    add_cube("SolenoidManifold", (-0.13, 1.06, pivot_z), (0.08, 0.14, 0.14), dark_steel, bevel=0.005)
    for dy in (-0.03, 0.03):
        add_cylinder(f"AirPort_{dy}", (-0.18, 1.06 + dy, pivot_z), 0.013, 0.035, brass, axis="x", vertices=12)
    add_cylinder("RotaryHub", (0.0, 1.26, pivot_z), 0.065, 0.14, aluminum, axis="y", vertices=24)

    # Swinging Gate Arm (origin set at pivot (0, 1.24, -0.92) so rotating Y swings cleanly!)
    arm_parts = []
    arm_parts.append(add_cylinder("ArmHubCollar", (0.0, 1.24, pivot_z), 0.072, 0.09, dark_steel, axis="y", vertices=24))
    arm_parts.append(add_cube("GateArmBeam", (0.0, 1.24, pivot_z + 0.74), (0.06, 0.15, 1.44), amber, bevel=0.008))
    arm_parts.append(add_cube("GateRubberBumper", (-0.036, 1.24, pivot_z + 0.78), (0.018, 0.12, 1.32), rubber_pad, bevel=0.004))
    arm_parts.append(add_cube("ArmTipCap", (0.0, 1.24, pivot_z + 1.47), (0.068, 0.16, 0.04), dark_steel, bevel=0.005))
    swing_arm = join_objects(arm_parts, "SwingArm")

    # Set SwingArm origin to pivot (0, 1.24, pivot_z) in Blender coordinates
    bpy.context.scene.cursor.location = xyz((0.0, 1.24, pivot_z))
    bpy.ops.object.select_all(action="DESELECT")
    swing_arm.select_set(True)
    bpy.context.view_layer.objects.active = swing_arm
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")

    SOURCE.mkdir(parents=True, exist_ok=True)
    target = ASSETS / "stopper"
    target.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / "stopper_blender.blend"))
    bpy.ops.export_scene.gltf(
        filepath=str(target / "stopper_visual.glb"),
        export_format="GLB",
        export_yup=True,
        export_texcoords=True,
        export_normals=True,
    )
    print("WROTE stopper/stopper_visual.glb (Side-Swing Gate)")


if __name__ == "__main__":
    build_stopper()
