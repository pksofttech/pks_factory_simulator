"""Build a front-facing Industrial MDB/Rittal Control Cabinet matching the reference photo.

Usage:
    /home/pksofttech/blender-4.1.1-linux-x64/blender -b --python tools/build_cabinet_asset.py
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


def build_cabinet() -> None:
    reset()
    cabinet_grey = make_material("Cabinet Light Grey", (0.74, 0.76, 0.78), roughness=0.45, metallic=0.22)
    door_seam = make_material("Door Gap Dark", (0.16, 0.18, 0.20), roughness=0.65, metallic=0.30)
    chrome = make_material("Chrome Trim", (0.84, 0.86, 0.89), roughness=0.18, metallic=0.92)
    legend_white = make_material("Legend Plate White", (0.95, 0.96, 0.97), roughness=0.55)
    estop_yellow = make_material("EStop Yellow", (0.96, 0.80, 0.08), roughness=0.38)
    black_plastic = make_material("Switch Black", (0.08, 0.09, 0.10), roughness=0.50)

    # Outer cabinet enclosure (0.62 x 0.90 x 0.24, centered at y = 0.45)
    add_cube("CabinetFrame", (0.0, 0.45, 0.0), (0.62, 0.90, 0.24), cabinet_grey, bevel=0.010)
    add_cube("DoorRecess", (0.0, 0.45, 0.114), (0.55, 0.83, 0.016), door_seam)
    add_cube("CabinetDoor", (0.0, 0.45, 0.125), (0.53, 0.81, 0.020), cabinet_grey, bevel=0.006)

    # Left-side recessed chrome key lock handle (x = -0.21, y = 0.46)
    add_cube("LockFrame", (-0.21, 0.46, 0.137), (0.048, 0.14, 0.008), chrome, bevel=0.002)
    add_cube("LockLatch", (-0.21, 0.46, 0.141), (0.032, 0.10, 0.006), legend_white, bevel=0.001)
    add_cylinder("KeyCylinder", (-0.21, 0.465, 0.144), 0.008, 0.006, chrome, axis="z", vertices=16)

    # Legend plates (white rectangular tags behind every lamp/button/switch)
    plate_positions = [
        # Row 1: R, S, T
        (-0.13, 0.72), (0.0, 0.72), (0.13, 0.72),
        # Row 2: FORWARD, REVERSE pilot lamps
        (-0.12, 0.54), (0.12, 0.54),
        # Row 3: FORWARD, STOP, REVERSE buttons
        (-0.14, 0.30), (0.0, 0.30), (0.14, 0.30),
        # Row 4: OFF / ON selector (left) & E-STOP (right)
        (-0.10, 0.13),
    ]
    for idx, (px, py) in enumerate(plate_positions):
        add_cube(f"LegendPlate_{idx}", (px, py + 0.016, 0.137), (0.082, 0.098, 0.004), legend_white, bevel=0.002)
    add_cube("LegendPlate_EStop", (0.10, 0.146, 0.137), (0.090, 0.104, 0.004), estop_yellow, bevel=0.002)

    # Chrome collars for pushbuttons, selector, and E-STOP collar
    for idx, bx in enumerate((-0.14, 0.0, 0.14)):
        add_cylinder(f"BtnCollar_{idx}", (bx, 0.30, 0.142), 0.034, 0.010, chrome, axis="z", vertices=24)
    add_cylinder("SelectorBase", (-0.10, 0.13, 0.142), 0.032, 0.010, black_plastic, axis="z", vertices=24)
    add_cylinder("EStopCollar", (0.10, 0.13, 0.142), 0.038, 0.010, estop_yellow, axis="z", vertices=32)

    SOURCE.mkdir(parents=True, exist_ok=True)
    target = ASSETS / "cabinet"
    target.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / "cabinet_blender.blend"))
    bpy.ops.export_scene.gltf(
        filepath=str(target / "cabinet_visual.glb"),
        export_format="GLB",
        export_yup=True,
        export_texcoords=True,
        export_normals=True,
    )
    print("WROTE cabinet/cabinet_visual.glb (Front-Facing MDB Style)")


if __name__ == "__main__":
    build_cabinet()
