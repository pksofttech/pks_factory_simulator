"""Upgrade existing Blender models (sensor, box, box_plastic) for higher realism.

Usage:
    /home/pksofttech/blender-4.1.1-linux-x64/blender -b --python tools/upgrade_existing_models.py
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


def make_material(
    name: str,
    color: tuple[float, float, float],
    roughness: float = 0.75,
    metallic: float = 0.0,
    emission: tuple[float, float, float] | None = None,
    emission_strength: float = 0.0,
    alpha: float = 1.0,
):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, alpha)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    if alpha < 1.0:
        bsdf.inputs["Alpha"].default_value = alpha
        mat.blend_method = "BLEND"
    if emission is not None and emission_strength > 0.0:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission_strength
    return mat


def xyz(point: tuple[float, float, float]) -> tuple[float, float, float]:
    """Convert Godot local (x, y_up, z) to Blender (x, -z, y_up)."""
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
    bevel: float = 0.0,
):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=xyz(center))
    obj = bpy.context.object
    obj.name = name
    if axis == "z":
        obj.rotation_euler[0] = math.pi / 2.0
    elif axis == "x":
        obj.rotation_euler[1] = math.pi / 2.0
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    if bevel > 0.0:
        mod = obj.modifiers.new("Bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
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


def export_asset(folder: str, filename: str, blend_name: str) -> None:
    SOURCE.mkdir(parents=True, exist_ok=True)
    target = ASSETS / folder
    target.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / blend_name))
    bpy.ops.export_scene.gltf(
        filepath=str(target / filename),
        export_format="GLB",
        export_yup=True,
        export_texcoords=True,
        export_normals=True,
    )
    print(f"WROTE {folder}/{filename}")


def build_sensor() -> None:
    reset()
    aluminum = make_material("Brushed Aluminum", (0.64, 0.69, 0.73), roughness=0.34, metallic=0.78)
    dark_metal = make_material("Anodized Bracket", (0.15, 0.17, 0.20), roughness=0.45, metallic=0.65)
    yellow_housing = make_material("Sensor Housing Yellow", (0.93, 0.67, 0.14), roughness=0.38, metallic=0.05)
    black_plastic = make_material("Optical Surround", (0.06, 0.07, 0.08), roughness=0.52, metallic=0.0)
    cable_rubber = make_material("Sensor Cable", (0.08, 0.09, 0.10), roughness=0.72, metallic=0.0)
    reflector_face = make_material("Prism Reflector", (0.92, 0.94, 0.96), roughness=0.18, metallic=0.25)
    laser_beam = make_material("Laser Beam", (0.95, 0.15, 0.10), roughness=0.2, emission=(1.0, 0.15, 0.10), emission_strength=1.4, alpha=0.45)

    for sz in (-1, 1):
        z = sz * 0.95
        # Tubular mounting post (bottom at y=-0.5475, top at y=0.08)
        add_cylinder(f"MountingPost_{sz}", (0.0, -0.225, z), 0.028, 0.62, aluminum, axis="y", vertices=24, bevel=0.002)
        add_cylinder(f"PostCap_{sz}", (0.0, 0.09, z), 0.030, 0.015, black_plastic, axis="y", vertices=24)
        # Base mounting plate + 4 anchor bolts
        add_cube(f"FootPlate_{sz}", (0.0, -0.532, z), (0.18, 0.028, 0.18), dark_metal, bevel=0.006)
        add_cylinder(f"PostCollar_{sz}", (0.0, -0.505, z), 0.044, 0.032, dark_metal, axis="y", vertices=20, bevel=0.003)
        for bx in (-0.065, 0.065):
            for bz in (-0.065, 0.065):
                add_cylinder(f"AnchorBolt_{sz}_{bx}_{bz}", (bx, -0.512, z + bz), 0.010, 0.014, aluminum, axis="y", vertices=6)
        # Adjustable clamp block + tightening knob
        add_cube(f"ClampBlock_{sz}", (0.0, -0.03, z), (0.085, 0.085, 0.085), dark_metal, bevel=0.006)
        add_cylinder(f"ClampKnob_{sz}", (0.065, -0.03, z), 0.022, 0.030, black_plastic, axis="x", vertices=16, bevel=0.003)

    # Sensor head (emitter/receiver at z = -0.95, front optical rim at z = -0.89 so Indicator at -0.88 is unobstructed)
    add_cube("SensorHead", (0.0, -0.03, -0.95), (0.19, 0.16, 0.11), yellow_housing, bevel=0.015)
    add_cube("OpticalRim", (0.0, -0.03, -0.892), (0.125, 0.115, 0.016), black_plastic, bevel=0.005)
    add_cylinder("SensorLensBarrel", (0.0, -0.03, -0.886), 0.032, 0.014, dark_metal, axis="z", vertices=24)
    # M12 connector + cable running down the post
    add_cylinder("M12Gland", (0.0, -0.125, -0.95), 0.018, 0.036, aluminum, axis="y", vertices=16)
    add_cylinder("SensorCable", (0.02, -0.32, -0.985), 0.009, 0.40, cable_rubber, axis="y", vertices=12)

    # Retro-reflector assembly at z = +0.95
    add_cube("ReflectorFrame", (0.0, -0.03, 0.942), (0.17, 0.17, 0.045), dark_metal, bevel=0.008)
    add_cube("ReflectorPlate", (0.0, -0.03, 0.916), (0.142, 0.142, 0.014), reflector_face, bevel=0.003)
    for x in (-0.072, 0.072):
        add_cube(f"ReflectorBracket_{x}", (x, -0.03, 0.935), (0.016, 0.18, 0.055), aluminum, bevel=0.003)

    # Subtle optical beam between lens and reflector
    add_cylinder("OpticalBeam", (0.0, -0.03, 0.02), 0.0035, 1.78, laser_beam, axis="z", vertices=10)

    export_asset("sensor", "sensor_visual.glb", "sensor_blender.blend")


def build_box() -> None:
    reset()
    cardboard = make_material("Cardboard brown - color changed by Godot", (0.64, 0.43, 0.24), roughness=0.84)
    tape = make_material("Packing tape", (0.87, 0.74, 0.50), roughness=0.35)
    edge = make_material("Cut cardboard edges", (0.45, 0.28, 0.14), roughness=0.88)
    label_paper = make_material("Shipping Label", (0.94, 0.94, 0.92), roughness=0.65)
    ink_dark = make_material("Label Ink", (0.10, 0.11, 0.12), roughness=0.55)
    ink_accent = make_material("Label Accent", (0.85, 0.34, 0.14), roughness=0.50)

    # Keep main body named "CardboardBody" for main.gd material_override
    add_cube("CardboardBody", (0.0, 0.0, 0.0), (0.65, 0.65, 0.65), cardboard, bevel=0.012)
    # Packing tape on top and wrapping down front/back
    add_cube("TopSeam", (0.0, 0.326, 0.0), (0.11, 0.003, 0.648), tape)
    for z in (-0.326, 0.326):
        add_cube(f"TapeEnd_{z}", (0.0, 0.235, z), (0.11, 0.18, 0.004), tape)
    # Top flap center & side crease lines
    add_cube("FlapCenterLine", (0.0, 0.327, 0.0), (0.004, 0.003, 0.63), edge)
    for x in (-0.318, 0.318):
        add_cube(f"CartonFold_{x}", (x, 0.326, 0.0), (0.004, 0.003, 0.62), edge)
    # Shipping label & barcode on +X and -X faces
    for sx in (-1, 1):
        lx = sx * 0.326
        add_cube(f"ShippingLabel_{sx}", (lx, 0.08, 0.12), (0.003, 0.18, 0.24), label_paper, bevel=0.001)
        add_cube(f"LabelAccent_{sx}", (sx * 0.3275, 0.145, 0.12), (0.002, 0.025, 0.22), ink_accent)
        for i, bz in enumerate((0.05, 0.075, 0.095, 0.12, 0.14, 0.165, 0.185)):
            w = 0.008 if i % 2 == 0 else 0.014
            add_cube(f"Barcode_{sx}_{i}", (sx * 0.3275, 0.05, bz), (0.002, 0.075, w), ink_dark)

    export_asset("box", "box_visual.glb", "box_blender.blend")


def build_box_plastic() -> None:
    reset()
    crate_blue = make_material("Plastic Crate Blue", (0.18, 0.45, 0.78), roughness=0.45, metallic=0.0)
    label_white = make_material("Crate ID Tag", (0.93, 0.94, 0.95), roughness=0.55)
    ink_dark = make_material("Crate Barcode", (0.10, 0.12, 0.14), roughness=0.55)

    # Outer dimensions match PlasticCollision: Vector3(0.657, 0.314, 0.899), bottom at y = 0.0
    parts = []
    # Main recessed crate tub
    parts.append(add_cube("CrateBase", (0.0, 0.145, 0.0), (0.625, 0.285, 0.865), crate_blue, bevel=0.010))
    # Top reinforced lip rim (y = 0.292)
    parts.append(add_cube("CrateTopRim", (0.0, 0.294, 0.0), (0.657, 0.036, 0.899), crate_blue, bevel=0.006))
    # Bottom stacking runner rim
    parts.append(add_cube("CrateBottomRim", (0.0, 0.016, 0.0), (0.640, 0.030, 0.880), crate_blue, bevel=0.005))
    # Vertical reinforcing ribs on long sides (X = +-0.320)
    for sx in (-1, 1):
        for rz in (-0.32, -0.16, 0.0, 0.16, 0.32):
            parts.append(add_cube(f"SideRib_{sx}_{rz}", (sx * 0.318, 0.148, rz), (0.020, 0.25, 0.028), crate_blue, bevel=0.003))
    # Vertical ribs + handgrip recess frame on short ends (Z = +-0.440)
    for sz in (-1, 1):
        for rx in (-0.22, -0.11, 0.11, 0.22):
            parts.append(add_cube(f"EndRib_{sz}_{rx}", (rx, 0.148, sz * 0.438), (0.026, 0.25, 0.020), crate_blue, bevel=0.003))
        parts.append(add_cube(f"HandleBar_{sz}", (0.0, 0.235, sz * 0.444), (0.18, 0.024, 0.022), crate_blue, bevel=0.004))

    # Join all crate body parts into "Box" so objects/box_plastic.tscn index="0" & main.gd material_override work seamlessly
    join_objects(parts, "Box")

    # Separate white ID/barcode label on one side
    add_cube("CrateLabel", (0.328, 0.17, 0.08), (0.004, 0.09, 0.16), label_white, bevel=0.001)
    for i, bz in enumerate((0.025, 0.045, 0.065, 0.09, 0.115, 0.135)):
        add_cube(f"CrateBar_{i}", (0.330, 0.165, bz), (0.002, 0.055, 0.009), ink_dark)

    export_asset("box", "box_plastic.glb", "box_plastic_blender.blend")


if __name__ == "__main__":
    build_sensor()
    build_box()
    build_box_plastic()
