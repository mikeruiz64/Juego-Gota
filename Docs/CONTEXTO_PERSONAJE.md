# CONTEXTO_PERSONAJE: Gota

> Documento de referencia del personaje. Las decisiones escritas aquí son las que definen el diseño. Las imágenes de referencia previas son aproximadas y **no** representan el personaje final.

---

## 1. Resumen

**Gota** es el personaje principal de un videojuego 2D de estilo caricaturesco: una pequeña gota de agua de apariencia frágil, pero seria, misteriosa, solitaria e inquietante.

---

## 2. Diseño visual

### 2.1 Forma y silueta
- Gota de agua clásica, rechoncha y compacta.
- Punta superior definida, que se estrecha gradualmente y termina ligeramente redondeada.
- Base redonda y ancha.
- Vista de **tres cuartos** a **45°**, mirando hacia la derecha. Para mirar a la izquierda se refleja en espejo. La silueta del cuerpo sigue siendo simétrica; el giro se nota en los ojos (desplazados hacia donde mira, el lejano más estrecho) y en las extremidades (la mano y el pie cercanos más adelante y abajo; la mano lejana asoma por detrás del borde).
- El reflejo lateral se mantiene en el lado izquierdo: la luz no gira con el personaje.
- Proporciones pequeñas y cuerpo de apariencia suave.
- Algo más delgada que la gota clásica (90 % del ancho).

### 2.2 Color y material
- Gris casi blanco, semitransparente.
- Más transparente en la parte superior que en la base.
- Matiz gris plateado muy tenue.
- Acabado cristalino, ligeramente brillante.
- Superficie lisa, sin texturas internas ni manchas.
- Doble contorno gris muy claro, uniforme y casi imperceptible.
- Un reflejo pequeño en uno de los laterales.

### 2.3 Rostro y personalidad
- Dos ojos diminutos, negros sólidos, ovalados verticalmente.
- Ojos juntos y situados a media altura.
- Sin pupilas ni reflejos en los ojos.
- **Sin boca durante el juego.**
- Boca fina **únicamente** durante las cinemáticas.
- Expresión seria y misteriosa.
- Personalidad: solitaria e inquietante (por fuera). Ver 2.6 para su personalidad interior.

#### Expresiones (solo con los ojos; negros, sólidos, sin pupilas)
| Expresión | Cuándo se usa |
|---|---|
| Seria con parpadeo | Idle normal. |
| (De perfil: mira a la pantalla →) párpados a media altura → ojos cerrados | Reposo prolongado: párpados a media altura sentada; ojos cerrados al acurrucarse. |
| Alerta → seria con parpadeo | Cuando detecta movimiento. |
| Alerta | Según la zona en la que se encuentra y su peligrosidad; también al levantarse del reposo prolongado. |
| Determinada | Según el enemigo y la zona, y su peligrosidad. |
| Preocupada | Según el contexto de la historia. |
| Recelosa | Según el contexto de la historia. |
| Ojos cerrados | Final del reposo prolongado; cierre breve al recibir daño; derrota. |

Descartadas: "de reojo" y la seria sin parpadeo como expresión propia.

### 2.4 Extremidades
- **Sin brazos**: solo manos, que flotan junto a los lados del cuerpo.
- **Sin piernas**: solo pies, que flotan bajo el cuerpo.
- Manos y pies pequeños pero visibles, redondos, sin dedos definidos.
- Pies del mismo color gris claro semitransparente que el cuerpo. **Manos en gris azulado algo más oscuro y con contorno marcado** para que se distingan sobre el cuerpo (cambiado por el usuario el 2026-10-16).
- Manos y pies separados del cuerpo, como si flotaran ligeramente.

### 2.5 Sombra
- Sombra ovalada, muy tenue y suave, debajo del personaje.

### 2.6 Personalidad interior (rasgos tomados de Finn el humano)
Gota toma **solo algunos rasgos** de Finn el humano (*Hora de Aventura*). Por fuera sigue siendo seria, misteriosa, solitaria e inquietante; estos rasgos viven por dentro y **se expresan en cómo se mueve y en lo que hace, nunca en la cara**.

| Rasgo | Cómo es en Gota |
|---|---|
| Valiente | Pequeña y frágil, pero no huye: se planta ante el peligro y ante enemigos grandes. |
| Justiciera | Fuerte sentido del bien y del mal; ayuda a quien lo necesita aunque no se lo pidan. |
| Leal y protectora | Defiende por encima de todo a los pocos que le importan (encaja con ser solitaria). |
| Aventurera e impulsiva | Se lanza a explorar y a actuar sin pensarlo demasiado. |
| Sensible | Siente mucho por dentro (tristeza, culpa, empatía) aunque por fuera no lo muestre. |
| Entusiasta | Se emociona, pero de forma **contenida**; nunca cómica ni exagerada. |

- **No** toma de Finn: la alegría expresiva, la inocencia/ingenuidad ni la competitividad.
- La expresión facial sigue siendo seria (ojos sin cambios, sin boca en el juego).
- Los rasgos se notan en:
  - **Las animaciones existentes**: postura firme y decidida en lugar de tímida.
  - **Animaciones nuevas** propias de estos rasgos (ver sección 3.1).

---

## 3. Animaciones

| Situación | Comportamiento definido |
|---|---|
| Reposo | Idle normal: respiración tranquila (dos respiraciones cada 3,2 s), postura firme, seria con un parpadeo por ciclo. Variantes de historia: preocupada y recelosa. |
| Reposo en alerta | Al recuperarse de un golpe o al entrar en una zona peligrosa: respiración corta, manos más altas y pies más abiertos, lista para actuar. Ojos de alerta o determinados según la peligrosidad. |
| Saludo | A los **10 s** quieta y **solo si está de frente** (una vez): sube una mano junto a la cabeza, la mueve tres veces y la baja. Expresión seria. Añadido por el usuario el 2026-10-16. |
| Sigilo | Con el botón de agacharse: va **agachada** (más baja y aplastada, manos bajas), andando despacio o quieta. |
| Reposo prolongado | Tras **20 s** quieta (cambiado por el usuario el 2026-10-16). Entrada (una vez, ~4 s) según hacia dónde mira: de frente no se gira; de perfil mira a la pantalla; de espaldas se estira con pereza. En los tres casos **se sienta apoyándose en las manos por detrás**, con los párpados a media altura. A los **6 s se acurruca de rodillas** y cierra los ojos. Bucle: acurrucada, ojos cerrados, **zetas (zzz) que suben** y ligero pulso de transparencia (75 % de opacidad, ciclo de 2 s). Al moverse **se levanta de un respingo con los ojos de alerta** (0,7 s) y después anda en la dirección pulsada. |
| Reacción al movimiento | Ya no se usa al salir del reposo prolongado (se levanta al momento). Queda para cuando detecte movimiento de otros (una vez, 1,8 s): abre los ojos en alerta con un pequeño sobresalto, se relaja y parpadea hasta la expresión seria. |
| Caminar | «S1 · Serio y firme» (elegido el 2026-10-16): erguida, paso medido y pisada firme, pies y manos bien marcados, algo gelatinoso. De perfil, cada mano en la vertical de su pie. Deja **huellitas mojadas** que se secan. |
| Golpear (mano limpia) | Golpes suaves y realistas (preparación, golpe rápido, recuperación lenta, el cuerpo acompaña). Mantener el botón sigue golpeando en combo; al soltarlo, el golpe se corta justo después del impacto. Depende del **nivel de pelea a mano limpia** (decidido por el usuario el 2026-10-16), encadenando golpes en combo: 0 bajo/nulo → A (directo); 1 medio/bajo → B (uno-dos); 2 medio → B, C (embestida); 3 medio/alto → B, C, D (gancho), E (ráfaga); 4 alto → B, C, D, E, G (giratorio) y además **escupitajo de ácido** (sin boca: lo expulsa contrayendo el cuerpo). Se carga manteniendo el botón: la bola se forma y crece **dentro del cuerpo**, y al soltar sale. Mientras carga camina normal sin dejar de apuntar (hacia atrás camina de espaldas) y puede saltar en cualquier dirección; cuanto más se carga, más grande. Es una bola de ácido verde: sale estirándose como un líquido, vuela en arco dejando gotitas, cae salpicando y deja un charco que burbujea y humea antes de desvanecerse. |
| Frenar | Solo al dejar de correr: frena como un líquido (la punta sigue por inercia y se bambolea, se aplasta y salpica unas gotitas) y se desliza un poco. Al dejar de caminar: da un **paso de ajuste** para juntar los pies y se asienta temblando como gelatina (elegido «C»). |
| Saltar | Salto físico (2026-10-16): despega al instante, no se puede volver a saltar sin haber tocado el suelo, la altura la lleva el juego y la sombra se queda en el suelo. Postura «Gota»: se estira al subir y se recoge al caer; al aterrizar se aplasta y tiembla. Corriendo hace un salto largo conservando la velocidad (inclinada, piernas abiertas y manos atrás). Si se suelta el botón pronto, salta más bajo. Se puede golpear en el aire. |
| Saltar hacia atrás | Salta hacia atrás sin dejar de mirar al frente, echándose hacia atrás con las manos por delante (aprobado). |
| Recibir daño | Pequeño temblor y cierre breve de los ojos. Siempre **salpica agua**: gotitas que saltan del cuerpo, caen al suelo y se secan. Pendiente: dependerá de la zona y de los enemigos (propuestas A-G en prueba). |
| Derrota | Se aplana suavemente y después se desvanece. |
| Aparición | Cae desde arriba y aterriza con un rebote mínimo. |
| Ganar una ronda | Breve brillo plateado, sin cambiar su expresión seria. |
| Movimiento rápido | Al correr se desprenden gotas diminutas que desaparecen rápidamente (aprobado el 2026-10-16). |

Todas las animaciones deben transmitir la personalidad interior de 2.6 (decisión, firmeza, valentía contenida) sin romper la expresión seria.

### 3.1 Animaciones nuevas por personalidad
Expresión facial siempre seria; el rasgo se transmite con el cuerpo.

| Animación | Rasgo | Comportamiento definido |
|---|---|---|
| En guardia | Valiente | Ante un enemigo, baja un poco el cuerpo, adelanta las manos y se queda firme, sin retroceder. |
| Proteger | Leal y protectora | Se interpone con los brazos abiertos, cubriendo a alguien detrás de ella. |
| Ayudar | Justiciera | Tiende la mano hacia abajo/adelante para levantar o ayudar a alguien. |
| Impulso | Aventurera e impulsiva | Se agacha un instante y sale disparada hacia delante sin dudar. |
| Explorar | Aventurera | Se inclina para mirar a un lado y al otro, curiosa, antes de avanzar. |
| Determinación | Valiente / sensible | Tras recibir daño o caer, se recompone y se endereza con firmeza. Puede encadenarse con "Recibir daño". |

Descartadas por el usuario: tristeza contenida y emoción contenida.

---

## 3.2 Vida y tamaño (decidido por el usuario el 2026-10-16)

- La **vida** (por ejemplo, 100) se divide en **5 tramos**, y cada tramo es un **tamaño** de Gota: A (pequeña, 0-20 %), B, C, D y E (grande, 80-100 %).
- Gota **empieza pequeña (A)**. Cuanto más grande, **más fuerza y más resistencia** (en la prueba: fuerza ×1 … ×2 y daño recibido ×1 … ×0,5).
- Al **recibir daño** pierde vida y **encoge**; al derrotar enemigos, estos sueltan **almas/energía** que recupera y la hacen **crecer**.
- Las almas valen más cuanto más tiempo lleva **sin recibir daño** (racha; en la prueba, hasta el doble a los 20 s).
- Cada cambio de tamaño se hace poco a poco y con un temblor de gelatina. Tras un golpe parpadea un instante sin poder recibir otro.
- **Al ser golpeada** sale despedida de un **brinco** en sentido contrario al golpe; el daño depende de su tamaño y del **poder y la peligrosidad** del enemigo, y cuanto más pequeña, más lejos sale.
- **Más grande, más daño**: golpes, ácido y onda escalan con el tamaño (y el alcance del golpe crece con ella).
- **Caída en picado** (saltar y agacharse en el aire, con cualquier vida), elegida por el usuario (2026-10-16): «**D3d · charco que se forma de abajo arriba**». Se estira como una gota de lluvia y cae **sin manos ni pies**, ignorando el botón de saltar; al chocar se aplasta en un **charco** tembloroso, se levanta como una **cúpula** y la **punta se forma la última** (manos y pies reaparecen al final); se queda agachada mientras se mantiene agacharse. Con **más de media vida** suelta una **onda de gelatina** que nace del borde del charco (estilo en elección: G1 anillo, G2 cúpula, G3 ola), con más alcance cuanto más grande es Gota y más daño cuanto más cerca del centro; con menos, ni onda ni daño.
- **Charco de ácido**: quema a los enemigos que lo pisan y también a Gota, sin brinco, desde que cae hasta que desaparece del todo (cada 0,25 s) y menos cuanto más grande es.
- **Sigilo según el tamaño**: cuanto más grande, desde más lejos la ven los enemigos (agachada, menos). Pequeña (A o B) se **esconde** dentro de los arbustos o agachada junto a las rocas, y no la ven.
- Las **huellas** son del tamaño de Gota.
- **Crecimiento según el enemigo**: sus almas valen más cuanto más poder y peligrosidad tiene (crece más rápido derrotando enemigos fuertes).
- **A tener en cuenta (no hecho)**: al final, el enemigo perderá frente a Gota si ella tiene más tamaño de vida.
- Pendiente: los valores exactos, cómo se ven las almas en el juego final y qué pasa al llegar a 0 (animación de derrota).

## 3.3 Elementos, derrota y expresiones (decidido por el usuario el 2026-10-16)

- **Elementos** (Gota es agua): el **calor** la evapora (fogata rápido, sol poco a poco: suelta vapor, pierde vida y encoge); el **frío** la enfría (se pone azul y va más lenta) hasta **congelarla** dentro de un cristal de hielo, del que se suelta pulsando botones o esperando; el **agua** le da vida (al pisar un **charco** lo absorbe y el charco se seca; bajo la **lluvia** recupera poco a poco). Valores en prueba.
- **Derrota** (vida a 0): animación en elección (A se aplana y se desvanece, B se derrite y se evapora, C se filtra en el suelo); después **vuelve al último punto de guardado tal como se guardó** (posición, vida, tamaño y nivel de pelea). En la prueba, los puntos de guardado son manantiales.
- **Expresiones automáticas**: **alerta** cuando un enemigo la detecta, cuando la acaban de golpear o en una zona de peligro; **determinada** mientras pelea con un enemigo igual o más fuerte que ella (según su tamaño actual); **preocupada** y **recelosa** solo en la historia.
- **Aparición** y **victoria**: se dejan para la historia. Las **animaciones de personalidad** (en guardia, proteger, ayudar, impulso, explorar, determinación) siguen, pero solo en ocasiones especiales y específicas.

## 4. Sonido

- Al aterrizar tras caer desde arriba (animación de aparición): sonido húmedo y sutil, casi imperceptible.

---

## 5. Dirección artística y ambiente

- **Estilo:** caricaturesco 2D, pensado para un videojuego.
- **Acabado:** limpio, delicado, cristalino y ligeramente brillante.
- **Expresión:** seria, misteriosa y solitaria.
- **Sensación:** un personaje pequeño que parece frágil, pero resulta inquietante.
- **Evitar:** exageraciones, expresiones cómicas y deformaciones fuertes.

---

## 6. Pendiente

- **Cámara (decidida por el usuario el 2026-10-16):** cenital a ~45°, como *The Minish Cap* o los Pokémon clásicos; no es un 2D de plataformas. Gota se mueve y se dibuja en **8 direcciones** (de frente, diagonal abajo, de perfil, diagonal arriba y de espaldas; la izquierda en espejo) y se inclina un poco hacia donde se mueve. La vista a 45° queda para la página de revisión hasta que se apruebe la versión en 4 direcciones (en prueba).

- **Tipo de escenario del juego:** aún no confirmado. La última pregunta sobre el ambiente quedó sin responder. No asumir un escenario; preguntar al usuario antes de tomar decisiones que dependan de él.

---

## 7. Decisiones cerradas (NO volver a preguntar)

- Forma y proporciones de la gota.
- Color, transparencia y matiz.
- Textura, brillo y contorno.
- Reflejo lateral.
- Ojos, boca y expresión.
- Brazos, piernas, manos y pies.
- Vista de tres cuartos a 45° (cambiada por el usuario: antes era vista frontal simétrica).
- Sin brazos ni piernas: solo manos y pies flotantes; cuerpo al 90 % del ancho.
- Expresiones y su uso (tabla de 2.3).
- Sombra.
- Animaciones de reposo, movimiento, salto, daño, derrota, aparición y victoria.
- Animaciones de personalidad (3.1): en guardia, proteger, ayudar, impulso, explorar y determinación.
- Efecto de transparencia durante el reposo prolongado.
- Sonido al aterrizar.
- Personalidad solitaria e inquietante.
- Personalidad interior con rasgos de Finn el humano: valiente, justiciera, leal y protectora, aventurera e impulsiva, sensible y entusiasta contenida (2.6). Se expresa en animaciones, no en la cara.
- **Estilo gráfico:** dibujo 2D suave inspirado en Hollow Knight (no pixel art), acabado **"A · Limpio"**: curvas suaves y degradado cristalino, sin halo ni sombreado extra. Contorno gris claro del documento (no el contorno negro de Hollow Knight).
- **Formato:** fotogramas de 256×256 renderizados a 512×512; animaciones fluidas (~16 fotogramas por ciclo).

---

## 8. Instrucciones de trabajo

- Tratar este documento como fuente de verdad del personaje.
- No modificar ni reinterpretar las decisiones de la sección 7.
- Mantener la consistencia visual y de animación en cualquier asset, sprite o código que se genere.
- Ante cualquier duda sobre el escenario (sección 6), consultar al usuario.
