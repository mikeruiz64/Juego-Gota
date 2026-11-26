"""Prueba de cámara cenital: lleva a Godot las hojas de Gota en 4 direcciones.

Copia las hojas por dirección (`*_abajo`, `*_derecha`, `*_arriba`) de revision/sprites a Assets/Sprites/Gota/Prueba/ y
genera Resources/Gota/gota_frames_cenital.tres sin pasar por Aseprite (son
pruebas: incluye también las propuestas sin aprobar). Antes hay que generarlas con:
    python -I Arte/Gota/scripts/gota_hk.py Arte/Gota

Uso: python -I Arte/Gota/scripts/prueba_cenital.py
"""
import json
import os
import shutil

ARTE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROYECTO = os.path.dirname(os.path.dirname(ARTE))
SPRITES = os.path.join(PROYECTO, "Assets", "Sprites", "Gota", "Prueba")
RECURSO = os.path.join(PROYECTO, "Resources", "Gota", "gota_frames_cenital.tres")


def main():
    with open(os.path.join(ARTE, "revision", "manifest.json"), encoding="utf-8") as f:
        manifiesto = json.load(f)
    lado = manifiesto["tam"] * manifiesto["escalaFuente"]
    variantes = [v for a in manifiesto["animaciones"] for v in a["variantes"]
                 if v["id"].endswith(("_abajo", "_derecha", "_arriba"))]
    os.makedirs(SPRITES, exist_ok=True)

    externos, atlas, lista = [], [], []
    for i, v in enumerate(variantes, 1):
        nombre = v["id"]
        png = os.path.join(SPRITES, f"gota_{nombre}.png")
        shutil.copyfile(os.path.join(ARTE, "revision", v["hoja"]), png)
        externos.append(f'[ext_resource type="Texture2D" path="res://Assets/Sprites/Gota/Prueba/'
                        f'gota_{nombre}.png" id="{i}_hoja"]')
        entradas = []
        for k in range(v["n"]):
            sub = f"Atlas_{nombre}_{k}"
            atlas.append(f'[sub_resource type="AtlasTexture" id="{sub}"]\n'
                         f'atlas = ExtResource("{i}_hoja")\n'
                         f'region = Rect2({(k % v["cols"]) * lado}, {(k // v["cols"]) * lado}, {lado}, {lado})\n')
            entradas.append(f'{{\n"duration": 1.0,\n"texture": SubResource("{sub}")\n}}')
        lista.append(f'{{\n"frames": [{", ".join(entradas)}],\n'
                     f'"loop": {"true" if v.get("bucle", True) else "false"},\n'
                     f'"name": &"{nombre}",\n"speed": {1000 / v["duraciones"][0]:.3f}\n}}')
        print(nombre, v["n"], "fotogramas")

    total = len(externos) + len(atlas) + 1
    with open(RECURSO, "w", encoding="utf-8", newline="\n") as f:
        f.write(f'[gd_resource type="SpriteFrames" load_steps={total} format=3]\n\n')
        f.write("\n".join(externos) + "\n\n")
        f.write("\n".join(atlas) + "\n")
        f.write("[resource]\nanimations = [" + ", ".join(lista) + "]\n")


if __name__ == "__main__":
    main()
