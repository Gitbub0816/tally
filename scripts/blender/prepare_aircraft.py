"""Headless Blender processor for Tally aircraft source models.

Run through scripts/process_aircraft_assets.sh; do not launch this with the
system Python because Blender provides the bpy module and bundled interpreter.
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--report", required=True, type=Path)
    parser.add_argument("--target-faces", type=int, default=80_000)
    return parser.parse_args(sys.argv[sys.argv.index("--") + 1 :])


def reset_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in (bpy.data.meshes, bpy.data.curves, bpy.data.materials):
        for block in list(collection):
            if block.users == 0:
                collection.remove(block)


def import_model(path: Path) -> None:
    suffix = path.suffix.lower()
    if suffix == ".fbx":
        bpy.ops.import_scene.fbx(filepath=str(path), use_anim=False)
    elif suffix in {".glb", ".gltf"}:
        bpy.ops.import_scene.gltf(filepath=str(path))
    elif suffix == ".obj":
        bpy.ops.wm.obj_import(filepath=str(path))
    else:
        raise ValueError(f"Unsupported model type: {suffix}")


def mesh_objects() -> list[bpy.types.Object]:
    return [item for item in bpy.context.scene.objects if item.type == "MESH"]


def remove_non_mesh_objects() -> None:
    for item in list(bpy.context.scene.objects):
        if item.type != "MESH":
            bpy.data.objects.remove(item, do_unlink=True)


def world_bounds(objects: list[bpy.types.Object]) -> tuple[Vector, Vector]:
    points = [item.matrix_world @ Vector(corner) for item in objects for corner in item.bound_box]
    minimum = Vector(min(point[index] for point in points) for index in range(3))
    maximum = Vector(max(point[index] for point in points) for index in range(3))
    return minimum, maximum


def normalize(objects: list[bpy.types.Object]) -> None:
    minimum, maximum = world_bounds(objects)
    center = (minimum + maximum) * 0.5
    longest = max(maximum[index] - minimum[index] for index in range(3))
    scale = 10.0 / longest if longest > 0 else 1.0

    roots = [item for item in objects if item.parent is None or item.parent not in objects]
    for item in roots:
        item.location = (item.location - center) * scale
        item.scale *= scale

    bpy.context.view_layer.update()
    bpy.ops.object.select_all(action="DESELECT")
    for item in objects:
        item.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)


def optimize(objects: list[bpy.types.Object], target_faces: int) -> None:
    total_faces = sum(len(item.data.polygons) for item in objects)
    ratio = min(1.0, target_faces / total_faces) if total_faces else 1.0

    for item in objects:
        mesh = item.data
        for polygon in mesh.polygons:
            polygon.use_smooth = True
        if ratio < 0.995 and len(mesh.polygons) > 300:
            modifier = item.modifiers.new(name="TallyMobileLOD", type="DECIMATE")
            modifier.decimate_type = "COLLAPSE"
            modifier.ratio = max(0.05, ratio)
            modifier.use_collapse_triangulate = True
            bpy.context.view_layer.objects.active = item
            try:
                bpy.ops.object.modifier_apply(modifier=modifier.name)
            except RuntimeError:
                item.modifiers.remove(modifier)


def report_for(source: Path, objects: list[bpy.types.Object]) -> dict[str, object]:
    minimum, maximum = world_bounds(objects)
    materials = sorted(
        {
            slot.material.name
            for item in objects
            for slot in item.material_slots
            if slot.material is not None
        }
    )
    return {
        "source": source.name,
        "objects": len(objects),
        "vertices": sum(len(item.data.vertices) for item in objects),
        "faces": sum(len(item.data.polygons) for item in objects),
        "uv_layers": sum(len(item.data.uv_layers) for item in objects),
        "materials": materials,
        "bounds": {
            "minimum": list(minimum),
            "maximum": list(maximum),
            "size": list(maximum - minimum),
        },
    }


def supported_export_options(**requested: object) -> dict[str, object]:
    properties = bpy.ops.wm.usd_export.get_rna_type().properties.keys()
    return {key: value for key, value in requested.items() if key in properties}


def export_usdz(path: Path, objects: list[bpy.types.Object]) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    for item in objects:
        item.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    path.parent.mkdir(parents=True, exist_ok=True)
    options = supported_export_options(
        filepath=str(path),
        selected_objects_only=True,
        visible_objects_only=True,
        export_animation=False,
        export_uvmaps=True,
        export_normals=True,
        export_materials=True,
        triangulate_meshes=True,
        rename_uvmaps=True,
    )
    options["filepath"] = str(path)
    bpy.ops.wm.usd_export(**options)


def main() -> None:
    args = arguments()
    reset_scene()
    import_model(args.input)
    remove_non_mesh_objects()
    objects = mesh_objects()
    if not objects:
        raise RuntimeError(f"No mesh objects were imported from {args.input}")
    normalize(objects)
    optimize(objects, args.target_faces)
    export_usdz(args.output, objects)
    payload = report_for(args.input, objects)
    payload["output"] = args.output.name
    payload["target_faces"] = args.target_faces
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(f"TALLY_EXPORT_COMPLETE {args.output}")


if __name__ == "__main__":
    main()
