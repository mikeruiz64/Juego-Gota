# PENDIENTES

> Última actualización: 2026-10-16
> `[ ]` pendiente · `[~]` en progreso · `[x]` hecho · 🔴 alta · 🟡 media · 🟢 baja

## v0.1: base (hecho)

- [x] Diseño de Gota: estilo, vista de tres cuartos, manos y pies flotantes, expresiones — 2026-10-15
- [x] 8 animaciones de reposo aprobadas y montadas en `gota.aseprite` — 2026-10-15
- [x] Proyecto de Godot con Gota en escena y la cadena de reposo funcionando — 2026-10-15
- [x] Documentos de seguimiento (CONTEXTO, INSTRUCCIONES, AUDITORIA, PENDIENTES) — 2026-10-15
- [x] Repositorio en GitHub: https://github.com/mikeruiz64/Juego-Gota — 2026-10-15

## Próximo

- [~] 🔴 **Vida y tamaño**: sistema en prueba (5 tramos A-E, empieza en A, fuerza y resistencia por tamaño, almas de los enemigos para crecer, racha sin daño). Falta ajustar valores y decidir la derrota al llegar a 0
- [ ] 🟡 **Enemigos de verdad** (los de la prueba son manchas de práctica: débil, normal y peligroso) y cómo se ven las almas en el juego final
- [ ] 🟡 **Idea para más adelante (no hacer aún)**: el enemigo pierde frente a Gota si ella tiene más tamaño de vida
- [ ] 🔴 **Cerrar la etapa** (cuando el usuario lo indique): montar en Aseprite todo lo aprobado, exportar al juego, retirar las animaciones a 45° y la escena lateral (`principal.tscn`, `gota.gd`), dejar la escena cenital como principal y subir a GitHub
- [ ] 🟡 **Nivel de pelea a mano limpia**: decidir cómo se sube de nivel (historia, experiencia, entrenamiento, objetos…). Los 5 niveles y sus combos ya están hechos
- [ ] 🟡 **Controles definitivos** y si habrá mando (gamepad); ahora: WASD/flechas, Shift, C/Ctrl, Espacio, Q, J y L
- [ ] 🟡 **Recibir daño** según zonas y enemigos (propuestas A-G; siempre salpica agua)
- [ ] 🔴 **Tipo de escenario y ambiente** (la cámara ya es cenital; falta el mundo)
- [~] 🔴 **Derrota**: elegir A (se aplana y se desvanece), B (se derrite y se evapora) o C (se filtra en el suelo); F8 en la prueba. Vuelve al último punto guardado ya funciona
- [ ] 🟡 **Aparición y victoria**: para la historia
- [ ] 🟡 **Elementos**: ajustar valores (calor, frío, agua) y decidir cómo se ven en el juego final
- [ ] 🟡 **Animaciones de personalidad** (en guardia, proteger, ayudar, impulso, explorar y determinación): solo en ocasiones especiales y específicas de la historia
- [ ] 🟡 **Sonido para prácticamente todo** (el usuario quiere un juego muy vivo): pasos, golpes, ácido, onda, daño, elementos, aterrizajes (húmedo y sutil)…
- [ ] 🟡 **Escala y colisión** de Gota cuando exista un escenario de verdad
- [ ] 🟢 **Boca fina** solo para cinemáticas

- [ ] 🟡 **Onda de la caída en picado**: elegir G1 (anillo), G2 (cúpula) o G3 (ola) de gelatina; F7 en la prueba (ahora G1)

## Hecho en esta etapa

- [x] Cámara cenital (como Minish Cap / Pokémon clásicos), con escena de prueba `Scenes/prueba_cenital.tscn` — 2026-10-16
- [x] Caminar sigilosa (antes «F · Sigilosa») aprobada y montada; botón de agacharse (C o Ctrl) — 2026-10-16
- [x] Movimiento horizontal de Gota en Godot (A/D o flechas) — 2026-10-16
- [x] Caminar (M2 · Saltitos firmes), correr (A · Carrera decidida, Shift) y caminar sigilosa en 3 direcciones, con manos atrás de perfil (estilo Naruto) — 2026-10-16

- [x] Cámara a ~45°, 8 direcciones, inclinación al moverse, manos de color más notable, zzz al dormir, agachada en sigilo, saludo a los 10 s, reposo prolongado sentada → acurrucada (6 s) → levantarse en alerta — 2026-10-16

- [x] Salto «C · Gota», frenado al correr (líquido) y al caminar (paso de ajuste), golpes por nivel de pelea (A; B; B-C; B-C-D-E; B-C-D-E-G + escupitajo de ácido), gelatina a medio camino y control de juego real (sin pausas, pulsaciones guardadas, mantener para repetir, salto con impulso y salto atrás) — 2026-10-16

- [x] Aprobados (2026-10-16): caminar «S1 · Serio y firme», salto corriendo, salto atrás, reposos por dirección (descanso solo con ánimo normal); gotitas al correr, huellitas mojadas, salto sin flotar (no se vuelve a saltar sin tocar el suelo), saltar cargando el ácido en cualquier dirección — 2026-10-16

- [x] Caída en picado «D3d · charco que se forma de abajo arriba» (sin manos ni pies), aterrizajes más aguados con salpicadura, charco de ácido que quema hasta desaparecer — 2026-10-16

## Historial

| Fecha | Hecho |
|---|---|
| 2026-10-15 | Proyecto creado; arte de Gota trasladado; reposo funcionando en Godot |
| 2026-10-15 | Aseprite compilado movido a `C:\Herramientas\Aseprite`; rutas actualizadas |
| 2026-10-16 | Cámara cenital a ~45°, 8 direcciones, acciones (saltar, golpear por nivel, escupir, frenar) y control de juego real |
| 2026-10-16 | Cámara cenital: escena de prueba con Gota en 4 direcciones |
| 2026-10-16 | Caminar sigilosa con botón de agacharse; movimiento horizontal; nuevas propuestas de caminar y correr |
