"""Build a realistic Overhead Box Emitter / Spawner Gantry for objects/emitter.tscn.

Usage:
    /home/pksofttech/blender-4.1.1-linux-x64/blender -b --python tools/build_emitter_asset.py
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


def build_emitter() -> None:
    reset()
    frame_steel = make_material("Powder Coated Frame", (0.24, 0.33, 0.39), roughness=0.45, metallic=0.35)
    aluminum = make_material("Anodized Aluminum", (0.64, 0.69, 0.73), roughness=0.32, metallic=0.78)
    dark_steel = make_material("Dark Cast Steel", (0.14, 0.16, 0.18), roughness=0.48, metallic=0.60)
    amber = make_material("Safety Amber", (0.92, 0.62, 0.12), roughness=0.40, metallic=0.10)

    # Side gantry columns outside conveyor width (z = +-0.86, clear of belt z in [-0.75, 0.75])
    for sz in (-1, 1):
        z = sz * 0.86
        add_cube(f"BasePlate_{sz}", (0.0, 0.02, z), (0.34, 0.04, 0.24), dark_steel, bevel=0.006)
        add_cube(f"GantryLeg_{sz}", (0.0, 1.15, z), (0.12, 2.22, 0.12), frame_steel, bevel=0.008)
        for bx in (-0.12, 0.12):
            add_cylinder(f"Bolt_{sz}_{bx}", (bx, 0.045, z), 0.012, 0.016, aluminum, axis="y", vertices=6)

    # Control enclosure on -Z side leg
    add_cube("ControlEnclosure", (0.0, 1.35, -0.96), (0.24, 0.30, 0.14), dark_steel, bevel=0.008)

    # Overhead gantry cross-beam & drop chute (bottom at y = 2.02, safely above 0.65m boxes!)
    add_cube("TopBeam", (0.0, 2.28, 0.0), (0.16, 0.12, 1.84), frame_steel, bevel=0.008)
    add_cube("ChuteHousing", (0.0, 2.18, 0.0), (0.78, 0.28, 0.78), dark_steel, bevel=0.012)
    add_cube("ChuteRim", (0.0, 2.02, 0.0), (0.82, 0.04, 0.82), amber, bevel=0.006)
    add_cube("ChuteTopHopper", (0.0, 2.40, 0.0), (0.90, 0.16, 0.90), aluminum, bevel=0.010)

    SOURCE.mkdir(parents=True, exist_ok=True)
    target = ASSETS / "emitter"
    target.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / "emitter_blender.blend"))
    bpy.ops.export_scene.gltf(
        filepath=str(target / "emitter_visual.glb"),
        export_format="GLB",
        export_yup=True,
        export_texcoords=True,
        export_normals=True,
    )
    print("WROTE emitter/emitter_visual.glb")


if __name__ == "__main__":
    build_emitter()
