"""Build a realistic Pneumatic Pusher / Diverter without floating rods at full stroke.

Usage:
    /home/pksofttech/blender-4.1.1-linux-x64/blender -b --python tools/build_pusher_asset.py
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


def build_pusher() -> None:
    reset()
    frame_steel = make_material("Powder Coated Frame", (0.24, 0.33, 0.39), roughness=0.45, metallic=0.35)
    aluminum = make_material("Anodized Aluminum", (0.64, 0.69, 0.73), roughness=0.32, metallic=0.78)
    chrome = make_material("Chrome Piston Rod", (0.82, 0.85, 0.88), roughness=0.14, metallic=0.95)
    dark_steel = make_material("Dark Cast Steel", (0.14, 0.16, 0.18), roughness=0.48, metallic=0.60)
    amber = make_material("Safety Amber", (0.92, 0.62, 0.12), roughness=0.40, metallic=0.10)
    brass = make_material("Pneumatic Brass", (0.78, 0.61, 0.24), roughness=0.32, metallic=0.82)
    rubber_pad = make_material("Rubber Foot Pad", (0.07, 0.08, 0.09), roughness=0.85, metallic=0.0)

    # Stand & Pedestal (bottom at y = 0.0, actuator centerline at y = 1.26)
    add_cube("BasePlate", (0.0, 0.02, -0.18), (0.64, 0.04, 0.76), dark_steel, bevel=0.008)
    for sx in (-0.25, 0.25):
        for sz in (-0.48, 0.12):
            add_cylinder(f"Foot_{sx}_{sz}", (sx, 0.01, sz), 0.042, 0.02, rubber_pad, axis="y", vertices=16)
    add_cube("PedestalColumn", (0.0, 0.58, -0.18), (0.20, 1.08, 0.22), frame_steel, bevel=0.010)
    add_cube("ColumnGusset", (0.0, 0.14, -0.18), (0.14, 0.20, 0.42), dark_steel, bevel=0.006)

    # Long twin-guide pneumatic actuator body (z from -0.68 to +0.26 = 0.94m long)
    add_cube("ActuatorMount", (0.0, 1.15, -0.21), (0.48, 0.08, 0.92), dark_steel, bevel=0.008)
    add_cube("CylinderBarrel", (0.0, 1.26, -0.21), (0.14, 0.14, 0.90), aluminum, bevel=0.012)
    for sz in (-0.66, 0.24):
        add_cube(f"CylinderCap_{sz}", (0.0, 1.26, sz), (0.44, 0.16, 0.045), dark_steel, bevel=0.006)
        add_cylinder(f"AirFitting_{sz}", (0.09, 1.26, sz), 0.014, 0.035, brass, axis="x", vertices=12)
    # Side guide rod housings (full length so rods slide inside them cleanly)
    for sx in (-0.16, 0.16):
        add_cylinder(f"GuideHousing_{sx}", (sx, 1.26, -0.21), 0.030, 0.90, frame_steel, axis="z", vertices=18)
        add_cylinder(f"GuideBushingFront_{sx}", (sx, 1.26, 0.26), 0.032, 0.06, dark_steel, axis="z", vertices=18)

    # Moving PusherPaddle assembly: rods span z = -0.58 to +0.46 (1.04m long!)
    # Even at stroke_length = 0.72, rear of rods is at +0.14 — still 0.12m inside the front cap/bushings!
    paddle_parts = []
    paddle_parts.append(add_cylinder("MainPistonRod", (0.0, 1.26, -0.06), 0.022, 1.04, chrome, axis="z", vertices=18))
    for sx in (-0.16, 0.16):
        paddle_parts.append(add_cylinder(f"GuideRod_{sx}", (sx, 1.26, -0.06), 0.016, 1.04, chrome, axis="z", vertices=14))
    paddle_parts.append(add_cube("PaddleBackplate", (0.0, 1.26, 0.45), (0.54, 0.22, 0.036), dark_steel, bevel=0.005))
    paddle_parts.append(add_cube("PaddleFace", (0.0, 1.26, 0.48), (0.52, 0.20, 0.028), amber, bevel=0.006))
    paddle_parts.append(add_cube("PaddleBumper", (0.0, 1.26, 0.498), (0.50, 0.16, 0.012), rubber_pad, bevel=0.003))
    join_objects(paddle_parts, "PusherPaddle")

    SOURCE.mkdir(parents=True, exist_ok=True)
    target = ASSETS / "pusher"
    target.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / "pusher_blender.blend"))
    bpy.ops.export_scene.gltf(
        filepath=str(target / "pusher_visual.glb"),
        export_format="GLB",
        export_yup=True,
        export_texcoords=True,
        export_normals=True,
    )
    print("WROTE pusher/pusher_visual.glb (long-stroke non-floating)")


if __name__ == "__main__":
    build_pusher()
