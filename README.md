# Juego Gota

Videojuego 2D en **Godot 4.6** (nombre provisional) con cámara cenital, como *The Minish Cap* o los Pokémon clásicos. La protagonista es **Gota**, una pequeña gota de agua seria y misteriosa, con un interior valiente y protector.

> Proyecto personal en desarrollo. Gota ya se mueve en 8 direcciones, salta, golpea y pelea en una escena de prueba; falta el escenario de verdad, los enemigos definitivos y el sonido.

## Qué hay hecho

- **Diseño del personaje:** vista de tres cuartos, manos y pies flotantes y expresiones solo con los ojos.
- **Cámara cenital en 8 direcciones** (la izquierda en espejo), con movimiento de juego real: aceleración y frenado progresivos, y pulsaciones que se guardan durante las acciones.
- **Acciones:** caminar, correr, caminar sigilosa agachada, saltar (más bajo si se suelta antes), salto hacia atrás, golpes con combos por nivel de pelea y escupir ácido.
- **Reposo:** 8 animaciones (normal, prolongado, alerta, determinada, preocupada, recelosa…); tras un rato quieta, Gota entra en reposo prolongado.
- **Combate en prueba:** enemigos de práctica, almas que hacen crecer a Gota, vida por tamaños, elementos (calor, frío y agua), huellas y salpicaduras.
- **Arte generado por código:** cada fotograma se dibuja en SVG con Python, se revisa en una página local y se monta en Aseprite antes de exportarlo a Godot.

## Controles

| Tecla | Acción |
|---|---|
| WASD o flechas | Moverse |
| Shift | Correr |
| C o Ctrl | Agacharse (caminar sigilosa) |
| Espacio | Saltar |
| Q | Salto hacia atrás |
| J | Golpear |
| L | Escupir ácido (nivel de pelea 4) |

## Cómo probarlo

1. Genera los sprites de prueba de la cámara cenital (no están en el repositorio; hace falta Python 3 y Brave en Windows):
   ```
   python -I Arte/Gota/scripts/gota_hk.py Arte/Gota
   python -I Arte/Gota/scripts/prueba_cenital.py
   ```
2. Abre Godot 4.6 → **Importar** → elige `project.godot`.
3. Pulsa **F5** para abrir la escena de prueba cenital.

## Estructura

| Carpeta | Contenido |
|---|---|
| `Scenes/` | Escena de prueba cenital (la principal por ahora), la escena lateral anterior y la escena de Gota |
| `Scripts/Gota/` | Movimiento y acciones de Gota (`gota_cenital.gd`), ácido, huellas y salpicaduras |
| `Scripts/Combate/` | Enemigos de práctica, almas, onda de la caída y vapor |
| `Scripts/Mundo/` | Elementos del escenario (calor, frío y agua) |
| `Assets/Sprites/Gota/` | Hojas de sprites exportadas (PNG + JSON) |
| `Resources/Gota/` | `SpriteFrames` con las animaciones |
| `Arte/` | Fuentes del arte: scripts de Python, Lua para Aseprite y página de revisión (Godot no las importa) |
| `Docs/` | Diseño completo del personaje |

## Tecnologías

Godot 4.6 · GDScript · Python (generación del arte) · Aseprite (montaje de animaciones)

## Autor

Michael Ruiz · [LinkedIn](https://www.linkedin.com/in/michael-ruiz-04244b370) · [GitHub](https://github.com/mikeruiz64)
