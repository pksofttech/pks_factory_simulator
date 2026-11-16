"""Build a realistic Pop-up Belt / Roller Transfer Table for objects/turn.tscn.

Usage:
    /home/pksofttech/blender-4.1.1-linux-x64/blender -b --python tools/build_turn_asset.py
"""
from pathlib import Path
import math
import bpy

PROJECT = Path(__file__).resolve().parents[1]
SOURCE = PROJECT.parent / "godot-object-sources"
ASSETS = PROJECT / "assets"
CONVEYOR_ASSETS = ASSETS / "conveyor"


def reset() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for mat in list(bpy.data.materials):
        bpy.data.materials.remove(mat)
    for img in list(bpy.data.images):
        bpy.data.images.remove(img)


def make_material(name: str, color: tuple[float, float, float], roughness: float = 0.75, metallic: float = 0.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    return mat


def make_belt_material():
    mat = make_material("Transfer Rubber Belt", (0.11, 0.13, 0.14), roughness=0.88, metallic=0.0)
    albedo_path = CONVEYOR_ASSETS / "rubber_belt_con01.jpeg"
    normal_path = CONVEYOR_ASSETS / "rubber_belt_normal.png"
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf = nodes.get("Principled BSDF")

    if albedo_path.exists():
        tex = nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(str(albedo_path), check_existing=True)
        tex.image.colorspace_settings.name = "sRGB"
        tex.extension = "REPEAT"
        links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])

    if normal_path.exists():
        ntex = nodes.new("ShaderNodeTexImage")
        ntex.image = bpy.data.images.load(str(normal_path), check_existing=True)
        ntex.image.colorspace_settings.name = "Non-Color"
        ntex.extension = "REPEAT"
        nmap = nodes.new("ShaderNodeNormalMap")
        nmap.inputs["Strength"].default_value = 0.25
        links.new(ntex.outputs["Color"], nmap.inputs["Color"])
        links.new(nmap.inputs["Normal"].links[0].from_socket if False else nmap.outputs["Normal"], bsdf.inputs["Normal"])

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


def apply_belt_uvs(obj, length_z: float = 1.32, width_x: float = 0.11) -> None:
    mesh = obj.data
    if not mesh.uv_layers:
        mesh.uv_layers.new(name="UVMap")
    uv_layer = mesh.uv_layers.active.data
    for poly in mesh.polygons:
        for loop_idx in poly.loop_indices:
            v = mesh.vertices[mesh.loops[loop_idx].vertex_index].co
            # In Blender coords: X is x, Y is -z
            u = (v.y + length_z * 0.5) / 0.55
            w = (v.x + width_x * 0.5) / width_x
            uv_layer[loop_idx].uv = (u, w)


def build_turn() -> None:
    reset()

    frame_steel = make_material("Powder Coated Frame", (0.24, 0.33, 0.39), roughness=0.45, metallic=0.35)
    brushed_steel = make_material("Brushed Stainless Steel", (0.64, 0.69, 0.73), roughness=0.30, metallic=0.80)
    dark_steel = make_material("Dark Cast Steel", (0.14, 0.16, 0.18), roughness=0.50, metallic=0.60)
    motor_blue = make_material("Gearmotor Body", (0.16, 0.25, 0.33), roughness=0.42, metallic=0.45)
    amber = make_material("Safety Amber", (0.92, 0.62, 0.12), roughness=0.42, metallic=0.10)
    rubber_pad = make_material("Rubber Foot Pad", (0.07, 0.08, 0.09), roughness=0.85, metallic=0.0)
    belt_mat = make_belt_material()

    # 1. Perimeter chassis rails (1.5m x 1.5m footprint, top flush below roller surface y=0.157)
    for side in (-1, 1):
        # X-parallel side rails (along Z = +-0.715)
        add_cube(f"SideChannelZ_{side}", (0.0, 0.03, side * 0.715), (1.48, 0.20, 0.065), frame_steel, bevel=0.008)
        # Z-parallel end rails (along X = +-0.715)
        add_cube(f"SideChannelX_{side}", (side * 0.715, 0.03, 0.0), (0.065, 0.20, 1.38), frame_steel, bevel=0.008)
        # Stainless top trim strips along outer edges
        add_cube(f"TopTrimZ_{side}", (0.0, 0.138, side * 0.72), (1.46, 0.016, 0.048), brushed_steel, bevel=0.003)
        add_cube(f"TopTrimX_{side}", (side * 0.72, 0.138, 0.0), (0.048, 0.016, 1.38), brushed_steel, bevel=0.003)

    # Recessed bottom pan & internal cross-members
    add_cube("ChassisPan", (0.0, -0.055, 0.0), (1.38, 0.03, 1.38), dark_steel, bevel=0.005)
    for x in (-0.42, 0.0, 0.42):
        add_cube(f"CrossBeam_{x:.2f}", (x, 0.01, 0.0), (0.05, 0.08, 1.36), frame_steel, bevel=0.004)

    # 2. Corner safety amber caps
    for sx in (-1, 1):
        for sz in (-1, 1):
            add_cube(f"CornerCap_{sx}_{sz}", (sx * 0.715, 0.138, sz * 0.715), (0.075, 0.020, 0.075), amber, bevel=0.004)

    # 3. Driven steel rollers (oriented along Z for +X transport, top at y = 0.157)
    roller_xs = [-0.62, -0.49, -0.22, -0.11, 0.11, 0.22, 0.49, 0.62]
    for idx, rx in enumerate(roller_xs):
        add_cylinder(f"Roller_{idx}", (rx, 0.125, 0.0), 0.031, 1.33, brushed_steel, axis="z", vertices=28, bevel=0.004)
        # Axle stubs & bearing blocks on both Z ends
        add_cylinder(f"RollerAxle_{idx}", (rx, 0.125, 0.0), 0.011, 1.40, dark_steel, axis="z", vertices=12)
        for sz in (-1, 1):
            add_cube(f"BearingBlock_{idx}_{sz}", (rx, 0.125, sz * 0.675), (0.042, 0.042, 0.024), dark_steel, bevel=0.003)

    # 4. Pop-up narrow transfer belts (3 belts oriented along Z for 90-deg transfer, top at y = 0.159)
    belt_xs = [-0.355, 0.0, 0.355]
    for idx, bx in enumerate(belt_xs):
        # Aluminum slider bed / guide channel beneath each belt
        add_cube(f"BeltGuide_{idx}", (bx, 0.105, 0.0), (0.125, 0.045, 1.30), frame_steel, bevel=0.004)
        # Belt top loop (flat upper run)
        belt_obj = add_cube(f"PopUpBelt_{idx}", (bx, 0.145, 0.0), (0.108, 0.026, 1.31), belt_mat, bevel=0.005)
        apply_belt_uvs(belt_obj, length_z=1.31, width_x=0.108)
        # End drive/idler pulleys at z = +-0.655
        for sz in (-1, 1):
            add_cylinder(f"BeltPulley_{idx}_{sz}", (bx, 0.142, sz * 0.655), 0.017, 0.116, brushed_steel, axis="x", vertices=20, bevel=0.002)

    # 5. Under-bed gearmotor & lift drive assembly (kept cleanly inside 1.5m footprint)
    add_cube("LiftActuatorBase", (0.0, -0.02, 0.0), (0.86, 0.045, 0.24), dark_steel, bevel=0.005)
    add_cylinder("DriveMotor", (0.34, -0.15, -0.20), 0.075, 0.28, motor_blue, axis="x", vertices=24, bevel=0.006)
    add_cube("Gearbox", (0.16, -0.14, -0.20), (0.12, 0.15, 0.15), dark_steel, bevel=0.008)
    add_cube("MotorJunctionBox", (0.36, -0.07, -0.20), (0.09, 0.055, 0.09), dark_steel, bevel=0.004)
    add_cylinder("DriveShaft", (0.0, -0.14, 0.0), 0.020, 0.90, brushed_steel, axis="x", vertices=16)

    # 6. Support legs, cross-bracing & adjustable leveling feet (bottom at y = -0.93)
    leg_positions = [(-0.60, -0.60), (-0.60, 0.60), (0.60, -0.60), (0.60, 0.60)]
    for i, (lx, lz) in enumerate(leg_positions):
        # Top mounting plate
        add_cube(f"LegMount_{i}", (lx, -0.085, lz), (0.15, 0.025, 0.15), dark_steel, bevel=0.003)
        # Square tubular leg
        add_cube(f"SupportLeg_{i}", (lx, -0.48, lz), (0.095, 0.77, 0.095), frame_steel, bevel=0.008)
        # Threaded leveling spindle
        add_cylinder(f"LevelingSpindle_{i}", (lx, -0.885, lz), 0.018, 0.055, brushed_steel, axis="y", vertices=14)
        # Round rubberized leveling foot (bottom at -0.91 - 0.02 = -0.93)
        add_cylinder(f"LevelingFoot_{i}", (lx, -0.912, lz), 0.085, 0.036, rubber_pad, axis="y", vertices=24, bevel=0.004)

    # Horizontal cross-braces between legs
    for sx in (-1, 1):
        add_cube(f"LegBraceX_{sx}", (sx * 0.60, -0.64, 0.0), (0.045, 0.055, 1.12), frame_steel, bevel=0.004)
    for sz in (-1, 1):
        add_cube(f"LegBraceZ_{sz}", (0.0, -0.64, sz * 0.60), (1.12, 0.055, 0.045), frame_steel, bevel=0.004)

    SOURCE.mkdir(parents=True, exist_ok=True)
    target = ASSETS / "turn"
    target.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / "turn_blender.blend"))
    bpy.ops.export_scene.gltf(
        filepath=str(target / "turn_visual.glb"),
        export_format="GLB",
        export_yup=True,
        export_texcoords=True,
        export_normals=True,
    )
    print("WROTE turn_visual.glb")


if __name__ == "__main__":
    build_turn()
