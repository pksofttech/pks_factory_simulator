"""Run with Blender after opening conveyor_blender.blend.

Usage: blender -b ../godot-object-sources/conveyor_blender.blend \
       --python tools/finish_conveyor_surface.py
"""
from pathlib import Path
import bpy

project = Path(__file__).resolve().parents[1]
asset_dir = project / "assets" / "conveyor"
if bpy.context.mode != "OBJECT":
    bpy.ops.object.mode_set(mode="OBJECT")
belt = bpy.data.objects["BeltSurface"]
material = belt.active_material
material.name = "Rubber Belt - Tread"
material.use_nodes = True
nodes = material.node_tree.nodes
links = material.node_tree.links

color = nodes.get("Image Texture")
if color is None:
    color = nodes.new("ShaderNodeTexImage")
    color.name = "Image Texture"
color.image = bpy.data.images.load(str(asset_dir / "rubber_belt_con01.jpeg"), check_existing=True)
color.image.filepath = "//../godot-factory-demo/assets/conveyor/rubber_belt_con01.jpeg"
color.image.colorspace_settings.name = "sRGB"
color.image.pack()
color.extension = "REPEAT"

mapping = nodes.get("Mapping")
if mapping:
    mapping.inputs["Scale"].default_value = (1, 1, 1)

principled = nodes.get("Principled BSDF")
principled.inputs["Base Color"].default_value = (1, 1, 1, 1)
principled.inputs["Roughness"].default_value = 0.88
principled.inputs["Metallic"].default_value = 0.0
links.new(color.outputs["Color"], principled.inputs["Base Color"])

normal_tex = nodes.get("Belt Normal Texture")
if normal_tex is None:
    normal_tex = nodes.new("ShaderNodeTexImage")
    normal_tex.name = "Belt Normal Texture"
normal_tex.image = bpy.data.images.load(str(asset_dir / "rubber_belt_normal.png"), check_existing=True)
normal_tex.image.filepath = "//../godot-factory-demo/assets/conveyor/rubber_belt_normal.png"
normal_tex.image.colorspace_settings.name = "Non-Color"
normal_tex.image.pack()
normal_tex.extension = "REPEAT"
normal_map = nodes.get("Belt Normal Map")
if normal_map is None:
    normal_map = nodes.new("ShaderNodeNormalMap")
    normal_map.name = "Belt Normal Map"
normal_map.inputs["Strength"].default_value = 0.25
links.new(normal_tex.outputs["Color"], normal_map.inputs["Color"])
links.new(normal_map.outputs["Normal"], principled.inputs["Normal"])
if mapping:
    links.new(mapping.outputs["Vector"], normal_tex.inputs["Vector"])

# A 1.5 m repeat gives six copies along the 9 m long top surface.
uv = belt.data.uv_layers.active.data
for polygon in belt.data.polygons:
    if polygon.normal.z > 0.9:
        for loop_index in polygon.loop_indices:
            vertex = belt.data.vertices[belt.data.loops[loop_index].vertex_index].co
            uv[loop_index].uv = ((vertex.x + 4.5) / 1.5, (vertex.y + 0.71) / 1.42)

# The photo already contains moving tread ribs. Static mesh seams would stay
# fixed above the animated surface and break the movement illusion.
for obj in list(bpy.data.objects):
    if obj.name.startswith("BeltSeam"):
        bpy.data.objects.remove(obj, do_unlink=True)

bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
bpy.ops.export_scene.gltf(
    filepath=str(asset_dir / "conveyor_visual.glb"),
    export_format="GLB",
    export_yup=True,
    export_texcoords=True,
    export_normals=True,
)
print("CONVEYOR_SURFACE_UPDATED")
