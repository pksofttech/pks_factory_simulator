"""Run with Blender: blender -b --python tools/build_blender_assets.py"""
from pathlib import Path
import bpy
import math

PROJECT = Path(__file__).resolve().parents[1]
SOURCE = PROJECT.parent / "godot-object-sources"
ASSETS = PROJECT / "assets"


def reset():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for material in list(bpy.data.materials):
        bpy.data.materials.remove(material)


def material(name, color, roughness=0.75, metallic=0.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    node = mat.node_tree.nodes.get("Principled BSDF")
    node.inputs["Base Color"].default_value = (*color, 1)
    node.inputs["Roughness"].default_value = roughness
    node.inputs["Metallic"].default_value = metallic
    return mat


def xyz(point):
    # Blender Z-up to glTF/Godot Y-up.
    x, y, z = point
    return (x, -z, y)


def cube(name, center, size, mat, bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=xyz(center))
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = (size[0], size[2], size[1])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = obj.modifiers.new("Soft edges", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
    obj.data.materials.append(mat)
    return obj


def cylinder(name, center, radius, depth, mat, axis="y", vertices=24):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=xyz(center))
    obj = bpy.context.object
    obj.name = name
    if axis == "z":
        obj.rotation_euler[0] = math.pi / 2
    elif axis == "x":
        obj.rotation_euler[1] = math.pi / 2
    obj.data.materials.append(mat)
    return obj


def save(kind):
    SOURCE.mkdir(parents=True, exist_ok=True)
    target = ASSETS / kind
    target.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / f"{kind}_blender.blend"))
    bpy.ops.export_scene.gltf(filepath=str(target / f"{kind}_visual.glb"), export_format="GLB", export_yup=True)
    print(f"WROTE {kind}")


def box():
    reset()
    cardboard = material("Cardboard brown - color changed by Godot", (0.64, 0.43, 0.24))
    tape = material("Packing tape", (0.89, 0.76, 0.53), 0.65)
    edge = material("Cut cardboard edges", (0.47, 0.30, 0.15))
    cube("CardboardBody", (0, 0, 0), (0.65, 0.65, 0.65), cardboard, 0.012)
    cube("TopSeam", (0, 0.328, 0), (0.12, 0.003, 0.65), tape)
    for z in (-0.328, 0.328):
        cube("TapeEnd", (0, 0.235, z), (0.12, 0.18, 0.004), tape)
    for x in (-0.32, 0.32):
        cube("CartonFold", (x, 0.326, 0), (0.003, 0.003, 0.62), edge)
    save("box")


def turn():
    reset()
    steel = material("Powder coated frame", (0.31, 0.42, 0.48), 0.48, 0.35)
    belt = material("Rubber transfer surface", (0.10, 0.15, 0.17), 0.9)
    trim = material("Edge trim", (0.53, 0.60, 0.64), 0.42, 0.55)
    hazard = material("Amber markers", (0.92, 0.61, 0.13))
    cube("TransferFrame", (0, 0, 0), (1.5, 0.25, 1.5), steel, 0.04)
    cube("TransferBelt", (0, 0.144, 0), (1.37, 0.03, 1.37), belt, 0.035)
    for side in (-1, 1):
        cube("SideRim", (0, 0.17, side * 0.72), (1.46, 0.08, 0.05), trim, 0.014)
        cube("SideRim", (side * 0.72, 0.17, 0), (0.05, 0.08, 1.46), trim, 0.014)
    for x in (-0.57, 0.57):
        for z in (-0.57, 0.57):
            cube("SupportLeg", (x, -0.51, z), (0.13, 0.8, 0.13), steel, 0.012)
            cube("Foot", (x, -0.91, z), (0.23, 0.04, 0.23), trim, 0.012)
    for x in (-0.48, -0.28, -0.08, 0.12, 0.32, 0.52):
        cube("BeltGrip", (x, 0.164, 0), (0.018, 0.004, 1.27), trim, 0.003)
    for x, z in ((-0.62, -0.62), (0.62, 0.62)):
        cube("SafetyMarker", (x, 0.19, z), (0.1, 0.005, 0.05), hazard)
    save("turn")


def sensor():
    reset()
    metal = material("Sensor brackets", (0.54, 0.64, 0.69), 0.45, 0.45)
    yellow = material("Sensor housing", (0.91, 0.68, 0.19), 0.55)
    white = material("Reflector", (0.9, 0.93, 0.93), 0.28, 0.15)
    black = material("Optical surround", (0.08, 0.11, 0.12), 0.55)
    for z in (-0.95, 0.95):
        cube("MountingPost", (0, -0.28, z), (0.07, 0.48, 0.07), metal, 0.009)
        cube("FootPlate", (0, -0.53, z), (0.18, 0.035, 0.19), metal, 0.01)
    cube("SensorHead", (0, -0.03, -0.95), (0.20, 0.17, 0.12), yellow, 0.02)
    cube("OpticalRim", (0, -0.03, -0.89), (0.125, 0.125, 0.012), black, 0.01)
    cube("ReflectorPlate", (0, -0.03, 0.95), (0.16, 0.16, 0.06), white, 0.013)
    for x in (-0.06, 0.06):
        cube("ReflectorBracket", (x, -0.03, 0.92), (0.018, 0.19, 0.05), metal, 0.004)
    save("sensor")


box()
turn()
sensor()
