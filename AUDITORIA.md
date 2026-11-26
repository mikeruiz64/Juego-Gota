# AUDITORÍA

> Registro de revisiones, pruebas y decisiones. Entrada nueva arriba.

## Plantilla

```
## AUD-XXX — AAAA-MM-DD — Título
**Alcance:** · **Hallazgos:** · **Riesgos:** · **Acciones:** · **Estado:**
```

---

## AUD-006 — 2026-11-26 — Commit del trabajo en la cámara cenital
**Alcance:** guardar en git el trabajo pendiente desde el 2026-10-16. · **Hallazgos:** `Assets/Sprites/Gota/Prueba/` (482 archivos, 126 MB) son sprites provisionales que genera `prueba_cenital.py` y se reemplazarán al cerrar la etapa. · **Riesgos:** quien clone el repositorio tiene que ejecutar `prueba_cenital.py` para ver la escena cenital. · **Acciones:** `Prueba/` al `.gitignore` y anotado en INSTRUCCIONES; enlace del repositorio corregido a mikeruiz64 en PENDIENTES; commit de scripts (combate, mundo, Gota), escenas, `gota_hk.py`, `project.godot` y documentos. · **Estado:** cerrado.

## AUD-005 — 2026-11-26 — Cambio de usuario de GitHub y limpieza del historial
**Alcance:** repositorio de GitHub. · **Hallazgos:** el usuario de GitHub pasó de maxy26 a mikeruiz64 y el remoto seguía apuntando al nombre viejo; los dos commits del 19/11 (README y enlaces) tenían líneas de coautoría en el mensaje; el commit «Se añade el caminar sigiloso y el botón de agacharse» no estaba subido. · **Riesgos:** ninguno; el contenido de los archivos no cambió. · **Acciones:** remoto cambiado a github.com/mikeruiz64/Juego-Gota; mensajes de los dos commits del 19/11 limpiados; commit del caminar sigiloso puesto encima y subido con --force-with-lease; README.md y .gitattributes traídos a la copia local sin tocar los cambios sin guardar. · **Estado:** cerrado.

## AUD-001 — 2026-10-15 — Creación del proyecto y animaciones de reposo

**Alcance:** creación del proyecto de Godot, traslado del arte de Gota y primeras animaciones en el juego.

**Decisiones:**
- Estilo dibujado a mano inspirado en *Hollow Knight*, acabado "Limpio", vista de tres cuartos a 45°, sin brazos ni piernas (manos y pies flotantes), cuerpo al 90 % del ancho de la gota clásica.
- Expresiones solo con los ojos y su uso definido por el usuario (tabla en `Docs/CONTEXTO_PERSONAJE.md`, sección 2.3). Descartadas: "de reojo" y la seria sin parpadeo como expresión propia.
- 8 animaciones de reposo aprobadas: `reposo`, `reposo_prolongado_entrada`, `reposo_prolongado`, `reaccion_movimiento`, `reposo_alerta`, `reposo_determinada`, `reposo_preocupada`, `reposo_recelosa`.
- El arte fuente vive en `Arte/` con `.gdignore` para que Godot no importe las hojas de revisión ni los SVG.
- `gota_frames.tres` se genera desde las exportaciones de Aseprite (no se edita a mano).

**Pruebas:**
- Importación del proyecto con Godot 4.6.3 en modo consola: sin errores.
- Prueba automática de la escena principal: las 8 animaciones cargan con su número de fotogramas, ~12 fps y el bucle correcto; la cadena reposo → entrada → reposo prolongado → reacción → reposo funciona.
- Las 8 etiquetas de `gota.aseprite` (271 fotogramas de 512×512) cubren sus fotogramas sin solaparse.

**Riesgos y límites:**
- Escala del sprite (0,4) y colisión aproximadas: revisar cuando haya escenario.
- Las hojas de 512×512 por fotograma pesan (~7 MB en total). Si el juego crece, valorar bajar a 256×256.
- El escenario del juego sigue sin definir (afecta a fondos y a la legibilidad de una protagonista semitransparente).

**Estado:** cerrada.

---

## AUD-002 — 2026-10-16 — Caminar sigilosa, agacharse y propuestas de caminar y correr

**Alcance:** animaciones de desplazamiento de Gota y primer movimiento en Godot.

**Decisiones:**
- Caminar A, B y C descartadas (demasiado parecidas entre sí); D, E y G también.
- La propuesta F (sigilosa) se aprueba como `caminar_sigiloso`: se usa al caminar con el botón de agacharse pulsado.
- Acciones de entrada: `mover_izquierda` (A, ←), `mover_derecha` (D, →), `agacharse` (C, Ctrl).
- `gota_hk.py` gana parámetros de paso: `balanceo`, `aplastar`, `manoAlto`, `bamboleo`, `vuelo` (correr) y `gotitas`.

**Pruebas:**
- Importación con Godot 4.6.3 en modo consola: sin errores.
- Prueba automática: con derecha pulsada avanza a 160 px/s; agachada, a 70 px/s con `caminar_sigiloso`; a la izquierda se refleja; al soltar vuelve a `reposo`.

**Riesgos y límites:**
- Sin caminar normal aprobado, el juego usa la sigilosa para caminar también.
- Agachada y quieta no tiene animación propia.
- Movimiento solo horizontal y sin gravedad hasta que se defina el escenario.

**Estado:** abierta (falta elegir caminar normal y correr).

---

## AUD-003 — 2026-10-16 — Prueba de cámara cenital

**Alcance:** el usuario cambia la cámara a cenital (como *The Minish Cap* o los Pokémon clásicos).

**Hecho:**
- `gota_hk.py` genera a Gota de frente (0°), de perfil (90°) y de espaldas (180°); la inclinación y el bamboleo del paso solo se aplican de perfil.
- Hojas de prueba `cenital_*` (reposo, caminar provisional H y caminar sigilosa) en las 3 direcciones.
- `prueba_cenital.py` las lleva a Godot sin Aseprite; escena `prueba_cenital.tscn` con hierba, camino, rocas, arbustos y árboles con orden por profundidad, colisión en los pies y cámara que sigue a Gota.

**Pruebas:** importación sin errores; prueba automática de las 4 direcciones, el espejo a la izquierda, el caminar sigiloso y la vuelta al reposo; captura revisada.

**Riesgos:** las animaciones aprobadas siguen a 45°; si se aprueba la cámara cenital hay que rehacerlas en 4 direcciones. No se ha subido nada a GitHub por indicación del usuario.

**Estado:** abierta (pendiente de la opinión del usuario).

---

## AUD-004 — 2026-10-16 — Gota en cámara cenital: animaciones, acciones y control

**Alcance:** todo el trabajo sobre Gota en la prueba cenital después de AUD-003.

**Decisiones del usuario:**
- Cámara cenital a ~45° y 8 direcciones (la izquierda en espejo); se inclina hacia donde se mueve.
- Manos en gris azulado con contorno marcado; de perfil, cada mano en la vertical de su pie.
- Reposo prolongado a los 20 s según la dirección (de frente no se gira, de perfil mira a la pantalla, de espaldas se estira), sentada apoyada en las manos, a los 6 s acurrucada con zzz; al moverse o atacar se levanta en alerta. Saludo a los 10 s solo de frente.
- Sigilo agachada y más lento; correr con manos atrás (estilo Naruto) en todas las direcciones.
- Salto «C · Gota»; frenado al correr líquido; frenado al caminar con paso de ajuste; gelatina a medio camino en caminar, sigilo y carrera.
- Golpes por nivel de pelea a mano limpia: 0 → A; 1 → B; 2 → B-C; 3 → B-C-D-E; 4 → B-C-D-E-G y escupitajo de ácido (bola que sale, vuela, cae, salpica y deja un charco que burbujea).
- Control de juego real: aceleración, pulsaciones guardadas, mantener para repetir, cortar golpes con salto o movimiento, salto con impulso y salto atrás.
- El daño se decidirá según zonas y enemigos. No se sube nada a GitHub hasta que el usuario lo indique.

**Herramientas:** `gota_hk.py` ganó direcciones, cámara cenital, acciones (`accion_t`), sesgo líquido, salpicaduras, zzz, ácido, agachada, sentarse/acurrucarse/estirarse y fotogramas por animación (`ms`). `prueba_cenital.py` lleva a Godot las hojas por dirección sin Aseprite.

**Pruebas:** importación sin errores; pruebas automáticas de las 8 direcciones, reposo prolongado, combos por nivel, escupitajo (solo nivel 4), frenados, salto con impulso, salto atrás, pulsaciones guardadas y repetición al mantener; capturas revisadas.

**Pendiente:** elegir el caminar (S1-S3), confirmar el salto atrás, decidir el daño y migrar lo aprobado a Aseprite y a la escena definitiva.

**Estado:** abierta.

**Ampliación (2026-10-16):** salto físico (altura en el juego, sombra en el suelo, posturas sin sombra `saltar_aire`, `saltar_aire_correr`, `saltar_atras_aire` y `aterrizar`), salto más bajo al soltar, golpes con versión aérea (`golpear_*_aire`) para saltar y golpear a la vez, golpe cortado al soltar tras el impacto y ácido cargado (bola interna que crece; `cargar_acido` y `soltar_acido`). Pruebas: salto corriendo a 280 px/s (26 px de alto, ~135 px de recorrido), toque corto 8 px frente a 26 px manteniendo, golpe aéreo que pasa a la versión de suelo al aterrizar, golpe de un toque cortado a ~330 ms y ácido de escala 1 sin cargar frente a 2,6 cargado.
