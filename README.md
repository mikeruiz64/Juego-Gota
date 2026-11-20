# Juego Gota

Videojuego 2D en **Godot 4.6** (nombre provisional). La protagonista es **Gota**, una pequeña gota de agua seria y misteriosa, con un interior valiente y protector.

> Proyecto personal en desarrollo. Por ahora está lista la protagonista con sus animaciones de reposo; lo siguiente es caminar y el movimiento del personaje.

## Qué hay hecho

- Diseño del personaje: vista de tres cuartos, manos y pies flotantes y expresiones solo con los ojos.
- 8 animaciones aprobadas: reposo normal, entrada al reposo prolongado, reposo prolongado, alerta, determinada, preocupada, recelosa y reacción al movimiento.
- Cadena de reposo en `gota.gd`: tras 8 s quieta, Gota entra en reposo prolongado, y reacciona cuando se pulsa una tecla.
- Arte generado por código: cada fotograma se dibuja en SVG con Python, se revisa en una página local y se monta en Aseprite antes de exportarlo a Godot.

## Cómo probarlo

1. Abre Godot 4.6 → **Importar** → elige `project.godot`.
2. Pulsa **F5**. Gota aparece en reposo; espera 8 s o pulsa cualquier tecla para ver sus reacciones.

## Estructura

| Carpeta | Contenido |
|---|---|
| `Scenes/` | Escena principal y la escena de Gota (`CharacterBody2D` + `AnimatedSprite2D`) |
| `Scripts/Gota/gota.gd` | Estados de reposo de Gota |
| `Assets/Sprites/Gota/` | Hojas de sprites exportadas (PNG + JSON) |
| `Resources/Gota/` | `SpriteFrames` con todas las animaciones |
| `Arte/` | Fuentes del arte: scripts de Python, Lua para Aseprite y página de revisión (Godot no las importa) |
| `Docs/` | Diseño completo del personaje |

## Tecnologías

Godot 4.6 · GDScript · Python (generación del arte) · Aseprite (montaje de animaciones)

## Autor

Michael Ruiz · [LinkedIn](https://www.linkedin.com/in/michael-ruiz-04244b370) · [GitHub](https://github.com/maxy26)
