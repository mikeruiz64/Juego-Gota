extends CharacterBody2D
## Gota con cámara cenital a ~45° (como Minish Cap o los Pokémon clásicos).
##
## Se mueve y se dibuja en 8 direcciones (abajo, abajo_derecha, derecha,
## arriba_derecha y arriba; la izquierda es el espejo de la derecha) y se inclina
## un poco hacia donde va. Acelera y frena de forma progresiva.
##
## Controles: moverse; "correr"; "agacharse" (sigilo); "saltar"; "saltar_atras"
## (sin dejar de mirar al frente); "golpear" (combo según el nivel de pelea a mano
## limpia) y "escupir" (nivel alto: mantener para cargar el ácido, soltar para
## lanzarlo; cuanto más se carga, más grande sale). Mientras carga camina normal
## sin dejar de apuntar: si va hacia atrás, camina de espaldas.
##
## Salto físico: la altura la lleva el juego (la sombra se queda en el suelo).
## Despega al instante, conserva la velocidad que llevaba (corriendo hace un salto
## largo), se puede dirigir un poco en el aire y golpear mientras salta.
##
## Para que se mueva como en un juego real, sin pausas entre botones:
## - Lo que se pulsa durante una acción se guarda y se hace en cuanto se puede.
## - Mantener "golpear" o "saltar" los repite.
## - Al soltar un botón se corta lo que activó: el salto sube menos, el golpe se
##   corta justo después del impacto y el ácido se lanza.
## - Los frenados y el aterrizaje se cortan con cualquier botón o al moverse.
## - El ritmo de los pies sigue a la velocidad real.
## Al andar deja huellitas mojadas que se secan.
##
## Elementos: el calor (fogata, sol) la evapora y encoge; el frío la enfría y frena
## hasta congelarla (se suelta pulsando botones o esperando); el agua (charcos,
## lluvia) le da vida. Al llegar a 0 de vida se derrota y vuelve al último punto de
## guardado tal como estaba. Las expresiones van solas: alerta si la detectan, si la
## acaban de golpear o en zona de peligro; determinada si pelea con un enemigo igual
## o más fuerte que ella (según su tamaño).
##
## Vida y tamaño: la vida (0-100) se divide en 5 tramos y cada tramo es un tamaño
## (A pequeña … E grande), con más fuerza y más resistencia cuanto más grande.
## Empieza pequeña (A); al recibir daño encoge y al recoger las almas que sueltan
## los enemigos crece. Las almas valen más cuanto más poder y peligrosidad tiene
## el enemigo y cuanto más tiempo lleva sin recibir daño. Al ser golpeada sale
## despedida de un brinco en sentido contrario (más lejos cuanto más pequeña).
## Caída en picado: agacharse en el aire la estira como una gota de lluvia (sin manos
## ni pies) que cae, se hace charco y se levanta de él como una cúpula; con más de media
## vida suelta una onda de gelatina, más grande cuanto más grande es Gota. Se queda
## agachada mientras se mantenga agacharse.
## Sigilo: cuanto más grande, desde más lejos la ven los enemigos; pequeña (A o B)
## se esconde dentro de los arbustos o agachada junto a las rocas.
##
## Quieta: a los 10 s, si está de frente, saluda; a los 20 s entra en reposo
## prolongado (de frente no se gira, de perfil mira a la pantalla, de espaldas se
## estira), se sienta apoyada en las manos y a los 6 s se acurruca y duerme (zzz).
## Al moverse o atacar se levanta en alerta y después hace lo pedido.

const Acido := preload("res://Scripts/Gota/acido.gd")
const Salpicadura := preload("res://Scripts/Gota/salpicadura.gd")
const Huellas := preload("res://Scripts/Gota/huellas.gd")
const Onda := preload("res://Scripts/Combate/onda.gd")
const Vapor := preload("res://Scripts/Combate/vapor.gd")

## Velocidad al caminar normal (píxeles por segundo).
@export var velocidad_caminar := 160.0
## Velocidad al caminar agachada (sigilosa).
@export var velocidad_sigilosa := 58.0
## Velocidad al correr.
@export var velocidad_correr := 280.0
## Velocidad del salto hacia atrás.
@export var velocidad_salto_atras := 230.0
## Aceleración al empezar a moverse (píxeles por segundo al cuadrado).
@export var aceleracion := 1600.0
## Control en el aire: cuánto puede cambiar de dirección durante un salto.
@export var aceleracion_aire := 450.0
## Deceleración al soltar el movimiento caminando (casi en seco).
@export var frenado := 1600.0
## Deceleración al dejar de correr: frena y se desliza un poco.
@export var frenado_correr := 1300.0
## Impulso hacia arriba del salto (normal y corriendo) y gravedad.
@export var impulso_salto := 290.0
@export var impulso_salto_correr := 310.0
@export var gravedad := 1500.0
## Tiempo mínimo en el suelo antes de poder volver a saltar.
@export var segundos_en_suelo_para_saltar := 0.12
## Al soltar "saltar" mientras sube, el impulso se multiplica por esto (salto más bajo).
@export var corte_salto := 0.45
## Grados que se inclina hacia los lados al correr (al caminar, en proporción).
@export var inclinacion_maxima := 7.0
## Segundos quieta antes de saludar (solo de frente).
@export var segundos_hasta_saludo := 10.0
## Segundos quieta antes de empezar el reposo prolongado.
@export var segundos_hasta_prolongado := 20.0
## Segundos sentada antes de acurrucarse.
@export var segundos_hasta_acurrucarse := 6.0
## Segundos de carga del ácido para el tamaño máximo.
@export var segundos_carga_maxima := 1.5
## Nivel de pelea a mano limpia: 0 bajo/nulo, 1 medio/bajo, 2 medio, 3 medio/alto, 4 alto.
@export_range(0, 4) var nivel_pelea := 0
## Vida máxima y con la que empieza (20 = tamaño A).
@export var vida_maxima := 100.0
@export var vida_inicial := 20.0
## Segundos sin recibir daño para que las almas valgan el doble.
@export var segundos_racha := 20.0

## Se emite al cambiar la vida (para el marcador), al guardar y al volver tras una derrota.
signal vida_cambiada
signal partida_guardada
signal reaparecio

## Golpes encadenables según el nivel de pelea a mano limpia.
const COMBOS := [["a"], ["b"], ["b", "c"], ["b", "c", "d", "e"], ["b", "c", "d", "e", "g"]]
const NOMBRES_NIVEL := ["0 · bajo/nulo", "1 · medio/bajo", "2 · medio", "3 · medio/alto", "4 · alto"]
## Nivel de pelea a partir del cual puede escupir ácido.
const NIVEL_ESCUPIR := 4
## Fotograma de "soltar_acido" en el que sale la bola.
const FOTOGRAMA_ACIDO := 2
## Parte de un golpe (0..1) en la que ya ha golpeado: a partir de aquí se puede cortar.
const IMPACTO_GOLPE := 0.45
## Botones de acción: lo que se pulsa durante otra acción se guarda y se hace después.
const BOTONES := ["saltar", "saltar_atras", "golpear", "escupir"]
## Botones que se repiten al mantenerlos pulsados (a partir de SEGUNDOS_MANTENER).
const BOTONES_REPETIBLES := ["golpear", "saltar"]
const SEGUNDOS_MANTENER := 0.2
## Caída en picado (elegida: «D3d · charco que se forma de abajo arriba»): animación al
## empezar, en el aire, al chocar y mientras se mantiene agacharse.
const PICADO := ["gota_estirar", "gota_cayendo", "gota_impacto_charco_forma", "reposo_agachada"]
## Direcciones dibujadas, de 45 en 45 grados desde "abajo" (la izquierda, en espejo).
const DIRECCIONES := ["abajo", "abajo_derecha", "derecha", "arriba_derecha", "arriba"]
## Centro del cuerpo respecto a los pies (para la bola de ácido que se forma dentro), a tamaño C.
const CENTRO_CUERPO := Vector2(0, -34)
## Tamaños según el tramo de vida (escala del dibujo) y lo que da cada uno.
const TAMANOS := [0.18, 0.22, 0.25, 0.30, 0.36]
const LETRAS_TAMANO := ["A", "B", "C", "D", "E"]
const FUERZA := [1.0, 1.25, 1.5, 1.75, 2.0]
const DANO_RECIBIDO := [1.0, 0.85, 0.7, 0.6, 0.5]
## Daño de un golpe (por la fuerza del tamaño) y alcance a tamaño C (píxeles).
const DANO_GOLPE := 10.0
const ALCANCE_GOLPE := 46.0
## Segundos sin poder recibir otro golpe después de uno.
const INVULNERABLE := 0.8

## Pruebas: estados de ánimo (1-5) y daños (F2, aún sin decidir).
const ANIMOS := {KEY_1: ["reposo", "normal"], KEY_2: ["reposo_alerta", "alerta"],
		KEY_3: ["reposo_determinada", "determinada"], KEY_4: ["reposo_preocupada", "preocupada"],
		KEY_5: ["reposo_recelosa", "recelosa"]}
const DANOS := [["a", "A · Temblor"], ["b", "B · Retroceso"], ["c", "C · Aplastón"],
		["d", "D · Salpicadura"], ["e", "E · Ondulación"], ["f", "F · Tambaleo"], ["g", "G · Derrame"]]


## Sombra en el suelo durante el salto (en el suelo la lleva el propio dibujo).
class Sombra extends Node2D:
	var altura := 0.0

	func _draw() -> void:
		var k := clampf(1.0 - altura / 90.0, 0.55, 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.3))
		draw_circle(Vector2.ZERO, 22.0 * k, Color(0.06, 0.07, 0.12, 0.22 * k))
		draw_set_transform(Vector2.ZERO)


## Capa de hielo cuando está congelada.
class Hielo extends Node2D:
	func _draw() -> void:
		var puntos := PackedVector2Array([Vector2(0, -78), Vector2(30, -52), Vector2(34, -14), Vector2(18, 4),
				Vector2(-18, 4), Vector2(-34, -14), Vector2(-30, -52)])
		draw_colored_polygon(puntos, Color(0.78, 0.92, 1.0, 0.45))
		puntos.append(puntos[0])
		draw_polyline(puntos, Color(0.95, 0.99, 1.0, 0.95), 2.0)
		draw_line(Vector2(-16, -60), Vector2(-6, -24), Color(1, 1, 1, 0.8), 2.0)
		draw_line(Vector2(12, -44), Vector2(20, -20), Color(1, 1, 1, 0.6), 1.5)


## Bola de ácido que se forma dentro del cuerpo mientras carga.
class AcidoInterno extends Node2D:
	var carga := 0.0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var r := 2.5 + 7.5 * carga + 0.6 * sin(_t * 12.0)
		draw_circle(Vector2.ZERO, r + 1.5, Color(0.31, 0.54, 0.15, 0.35))
		draw_circle(Vector2.ZERO, r, Color(0.65, 0.88, 0.35, 0.6))
		draw_circle(Vector2(-r * 0.3, -r * 0.35), r * 0.35, Color(0.84, 0.96, 0.6, 0.6))


@onready var sprite: AnimatedSprite2D = $Sprite

## Hacia dónde mira (una de DIRECCIONES; flip_h para la izquierda).
var mirando := "abajo"
## Animación de reposo en uso (cambia con el estado de ánimo) y su nombre.
var reposo := "reposo"
var nombre_animo := "normal"
## Daño en uso (índice en DANOS).
var dano := 0

## "suelo" (quieta o moviéndose), "accion" o "reposo_largo"
var _estado := "suelo"
## Acción en curso ("golpear", "cargar", "soltar", "frenar"...) y acción pedida que espera su turno
var _accion := ""
var _pedida := ""
## Fase del reposo prolongado: "entrada", "sentada", "acurrucarse", "prolongado" o "levantarse"
var _fase := ""
var _combo_paso := 0
## Se soltó "golpear": el golpe se corta en cuanto haya golpeado
var _golpe_soltado := false
var _acido_lanzado := false
var _carga := 0.0
## Salto: si está en el aire, altura, velocidad vertical, tipo ("normal", "correr" o "atras")
var _en_aire := false
var _altura := 0.0
var _vel_z := 0.0
var _vel_z_inicial := 1.0
var _tipo_salto := "normal"
var _tiempo_aire := 0.0
var _tiempo_en_suelo := 1.0
var _salto_cortado := false
var _velocidad_salto := 0.0
## Velocidad que busca al moverse (para el ritmo de los pies)
var _velocidad_objetivo := 0.0
var _corria := false
var _caminaba := false
var _tiempo_quieta := 0.0
var _tiempo_sentada := 0.0
var _saludando := false
var _saludo_hecho := false
## Cuánto tiempo lleva pulsado cada botón repetible
var _pulsado := {"golpear": 0.0, "saltar": 0.0}
var _sombra := Sombra.new()
var _huellas := Huellas.new()
var _distancia_paso := 0.0
var _lado_huella := 1.0
var _acido_interno := AcidoInterno.new()
var _hielo := Hielo.new()
## Vida actual, tramo de tamaño (0 = A … 4 = E), escala que se ve y tiempo desde que cambió
var vida := 0.0
var racha := 0.0
var _tamano := 0
var _escala := 0.18
var _desde_cambio_tamano := 9.0
var _invulnerable := 0.0
var _golpe_aplicado := false
## Cae en picado (saltar + agacharse en el aire); con más de media vida, al tocar el suelo, onda
var _caida_fuerte := false
## Tras la caída en picado, no vuelve a saltar hasta soltar y pulsar otra vez el botón
var _esperar_soltar_salto := false
## Si está en el choque de la caída en picado
## Estilo de la onda de gelatina (prueba, F7): "g1" anillo, "g2" cúpula, "g3" ola
var estilo_onda := "g1"
const ESTILOS_ONDA := {"g1": "G1 · Anillo de gelatina", "g2": "G2 · Cúpula de gelatina", "g3": "G3 · Ola de gelatina"}
var _chocando := false
## Destello verde al quemarse con el ácido
var _quemado := 0.0
## Elementos: frío acumulado (0..1, a 1 se congela), tiempo congelada y efectos recientes
var _frio := 0.0
var _enfriando := 0.0
var _congelada := 0.0
var _inmune_frio := 0.0
var _calentando := 0.0
var _mojando := 0.0
var _ultimo_vapor := 0.0
## Derrota: estilo (prueba, F8) y partida guardada en el último punto de guardado
var estilo_derrota := "a"
const ESTILOS_DERROTA := {"a": "A · Se aplana y se desvanece", "b": "B · Se derrite y se evapora",
		"c": "C · Se filtra en el suelo"}
var _guardado := {}
## Expresión automática (si no se elige a mano con 1-5) y tiempo desde el último golpe
var animo_auto := true
var _desde_golpe := 99.0


func _ready() -> void:
	add_to_group("gota")
	vida = vida_inicial
	_tamano = _tramo_de_vida()
	_escala = TAMANOS[_tamano]
	sprite.animation_finished.connect(_al_terminar_animacion)
	add_child(_sombra)
	move_child(_sombra, 0)   # debajo del dibujo
	_sombra.visible = false
	add_child(_acido_interno)
	_acido_interno.visible = false
	add_child(_hielo)
	_hielo.visible = false
	guardar(false)   # la partida empieza guardada donde aparece
	# Las huellas van en el escenario, a la altura del suelo (debajo de todo)
	get_parent().add_child.call_deferred(_huellas)
	_reproducir(reposo)


func _physics_process(delta: float) -> void:
	var direccion := Input.get_vector(&"mover_izquierda", &"mover_derecha", &"mover_arriba", &"mover_abajo")
	_tiempo_en_suelo = 0.0 if _en_aire else _tiempo_en_suelo + delta
	_leer_botones(delta)
	_al_soltar_botones()
	if _en_aire:
		_volar(delta)
	match _estado:
		"reposo_largo":
			_en_reposo_largo(direccion, delta)
		"accion":
			_en_accion(direccion, delta)
		_:
			if _en_aire:
				_en_el_aire(direccion, delta)
			else:
				_en_suelo(direccion, delta)
	_inclinar(delta)
	_ajustar_ritmo()
	_marcar_huellas(delta)
	_actualizar_elementos(delta)
	_actualizar_animo(delta)
	_sombra.altura = _altura
	_sombra.queue_redraw()
	_actualizar_tamano(delta)
	_acido_interno.position = CENTRO_CUERPO * factor_tamano() + sprite.position


# --- Entrada ---------------------------------------------------------------

## Guarda la última acción pulsada; mantener un botón repetible la vuelve a pedir.
func _leer_botones(delta: float) -> void:
	for boton: String in BOTONES:
		if Input.is_action_just_pressed(boton):
			_pedida = boton
	for boton: String in BOTONES_REPETIBLES:
		_pulsado[boton] = _pulsado[boton] + delta if Input.is_action_pressed(boton) else 0.0
		if _pedida == "" and _pulsado[boton] >= SEGUNDOS_MANTENER:
			_pedida = boton
	# Un salto pedido en el aire no se guarda: hay que tocar el suelo antes de volver a saltar.
	# En la caída en picado se ignora el salto, y después hay que soltarlo y volver a pulsarlo
	if _esperar_soltar_salto:
		if Input.is_action_pressed(&"saltar") or Input.is_action_pressed(&"saltar_atras"):
			_pulsado["saltar"] = 0.0
		elif not _caida_fuerte and _accion != "charco":
			_esperar_soltar_salto = false
	if (_en_aire or _esperar_soltar_salto) and _pedida in ["saltar", "saltar_atras"]:
		_pedida = ""


## Al soltar un botón se corta lo que activó.
func _al_soltar_botones() -> void:
	# Salto: si aún sube, sube menos
	if _en_aire and not _salto_cortado and not _caida_fuerte and _vel_z > 0.0 and (Input.is_action_just_released(&"saltar")
			or Input.is_action_just_released(&"saltar_atras")):
		_vel_z *= corte_salto
		_salto_cortado = true
	# Golpe: se corta en cuanto haya golpeado
	if Input.is_action_just_released(&"golpear"):
		_golpe_soltado = true
	# Ácido: al soltar se lanza
	if _accion == "cargar" and not Input.is_action_pressed(&"escupir"):
		if _en_aire:
			_lanzar_acido()
			_terminar_accion()
			return
		_accion = "soltar"
		_acido_lanzado = false
		sprite.play(StringName("soltar_acido_" + mirando))


func _puede(accion: String) -> bool:
	return accion != "escupir" or nivel_pelea >= NIVEL_ESCUPIR


# --- En el suelo: quieta, caminando, corriendo o agachada --------------------

func _en_suelo(direccion: Vector2, delta: float) -> void:
	var salto_pronto := _pedida in ["saltar", "saltar_atras"] and _tiempo_en_suelo < segundos_en_suelo_para_saltar
	if _pedida != "" and not salto_pronto:
		if _puede(_pedida):
			_empezar(_pedida, direccion)
			return
		_pedida = ""

	# Agachada manda sobre correr
	var agachada := Input.is_action_pressed(&"agacharse")
	var corriendo := not agachada and Input.is_action_pressed(&"correr")
	_velocidad_objetivo = velocidad_caminar
	if agachada:
		_velocidad_objetivo = velocidad_sigilosa
	elif corriendo:
		_velocidad_objetivo = velocidad_correr
	_velocidad_objetivo *= 1.0 - 0.7 * _frio   # con frío va más despacio
	var venia_corriendo := _corria
	var venia_caminando := _caminaba
	_corria = corriendo and direccion != Vector2.ZERO
	_caminaba = not corriendo and not agachada and direccion != Vector2.ZERO
	_acercar_velocidad(direccion * _velocidad_objetivo, delta, frenado)
	move_and_slide()

	if direccion != Vector2.ZERO:
		_tiempo_quieta = 0.0
		_saludando = false
		_saludo_hecho = false
		_mirar_hacia(direccion)
		if agachada:
			_reproducir("caminar_sigiloso")
		elif corriendo:
			_reproducir("correr")
		else:
			_reproducir("caminar")
		return

	# Al soltar: frena (deslizándose si corría, con un paso de ajuste si caminaba)
	if venia_corriendo:
		_empezar("frenar", Vector2.ZERO)
		return
	if venia_caminando:
		_empezar("frenar_caminar", Vector2.ZERO)
		return
	if agachada:
		_tiempo_quieta = 0.0
		_saludando = false
		_reproducir("reposo_agachada")
		return
	_tiempo_quieta += delta
	if _saludando:
		return
	_reproducir(reposo)
	if reposo == "reposo" and mirando == "abajo" and not _saludo_hecho \
			and _tiempo_quieta >= segundos_hasta_saludo:
		_saludando = true
		_saludo_hecho = true
		sprite.play(&"saludar_abajo")
	elif reposo == "reposo" and _tiempo_quieta >= segundos_hasta_prolongado:
		_estado = "reposo_largo"
		_fase = "entrada"
		velocity = Vector2.ZERO
		sprite.play(StringName("reposo_prolongado_entrada_" + mirando))


# --- Salto -----------------------------------------------------------------

func _saltar(tipo: String, direccion: Vector2, impulso := -1.0) -> void:
	_en_aire = true
	_salto_cortado = false
	_caida_fuerte = false
	_tiempo_aire = 0.0
	_tipo_salto = tipo
	_vel_z = impulso_salto_correr if tipo == "correr" else impulso_salto
	if impulso > 0.0:
		_vel_z = impulso
	_vel_z_inicial = _vel_z
	_sombra.visible = true
	_saludando = false
	_tiempo_quieta = 0.0
	_corria = false
	_caminaba = false
	match tipo:
		"atras":
			velocity = -_vector_mirada() * velocidad_salto_atras
		_:
			if direccion != Vector2.ZERO and _accion != "cargar":
				_mirar_hacia(direccion)
			# Conserva la velocidad que llevaba (corriendo, la de correr)
			_velocidad_salto = maxf(velocity.length(), velocidad_caminar)
	# Si estaba golpeando, sigue el golpe en el aire
	if _estado == "accion" and _accion == "golpear":
		_cambiar_golpe_de_version()


## Sube y baja; al tocar el suelo aterriza.
func _volar(delta: float) -> void:
	_tiempo_aire += delta
	_vel_z -= gravedad * delta
	_altura += _vel_z * delta
	if _altura <= 0.0:
		_aterrizar()
	sprite.position.y = -_altura


func _en_el_aire(direccion: Vector2, delta: float) -> void:
	# Saltar y agacharse, con más de media vida: cae en picado y al tocar el suelo suelta una onda
	# (espera a haber subido un poco, también si ya saltó agachada)
	if not _caida_fuerte and _tiempo_aire > 0.12 and Input.is_action_pressed(&"agacharse"):
		_caida_fuerte = true
		_esperar_soltar_salto = true
		_vel_z = minf(_vel_z, -520.0)
		sprite.play(_anim_picado(0))
	if _caida_fuerte:
		# Cae sin control; al terminar de estirarse, sigue con la postura de caída
		if not sprite.is_playing() or sprite.animation != _anim_picado(0):
			if sprite.animation != _anim_picado(1):
				sprite.play(_anim_picado(1))
		move_and_slide()
		return
	# Golpear en el aire
	if _pedida == "golpear":
		_empezar("golpear", direccion)
		return
	match _tipo_salto:
		"atras":
			velocity = velocity.move_toward(Vector2.ZERO, 200.0 * delta)
		_:
			# Conserva el impulso y se puede dirigir un poco
			if direccion != Vector2.ZERO:
				velocity = velocity.move_toward(direccion * _velocidad_salto, aceleracion_aire * delta)
	move_and_slide()
	_postura_aire()


## Postura en el aire según el momento del vuelo.
func _postura_aire() -> void:
	var nombre: String = {"normal": "saltar_aire", "correr": "saltar_aire_correr",
			"atras": "saltar_atras_aire"}[_tipo_salto]
	var animacion := StringName("%s_%s" % [nombre, mirando])
	if sprite.animation != animacion:
		sprite.play(animacion)
	sprite.pause()
	# Fotograma según el momento del vuelo: de 0 (despega) a 1 (toca el suelo)
	var total := sprite.sprite_frames.get_frame_count(animacion)
	var fase := clampf(0.5 - 0.5 * _vel_z / _vel_z_inicial, 0.0, 1.0)
	sprite.frame = clampi(roundi(fase * (total - 1)), 0, total - 1)


func _aterrizar() -> void:
	# Al caer salpica agua alrededor de los pies (más si cae en picado)
	var salpicadura := Salpicadura.new()
	salpicadura.position = position
	salpicadura.altura_inicial = 2.0
	salpicadura.cantidad = 14 if _caida_fuerte else 7
	salpicadura.fuerza = (0.75 if _caida_fuerte else 0.4) * factor_tamano()
	get_parent().add_child(salpicadura)
	# Al caer marca los dos pies a la vez
	var f := factor_tamano()
	_huellas.poner(position + Vector2(-4, 0) * f, _vector_mirada().angle(), 1.0, f)
	_huellas.poner(position + Vector2(4, 0) * f, _vector_mirada().angle(), 1.0, f)
	_en_aire = false
	_altura = 0.0
	_vel_z = 0.0
	sprite.position.y = 0.0
	_sombra.visible = false
	if _caida_fuerte:
		_caida_fuerte = false
		# Con más de media vida suelta la onda (si no, solo cae)
		if vida > vida_maxima * 0.5:
			_soltar_onda()
		# Choca y sigue así mientras mantenga agacharse
		_estado = "accion"
		_accion = "charco"
		_pedida = ""
		_chocando = true
		sprite.play(_anim_picado(2))
		return
	# Tras el brinco de un golpe recibido, amortigua la caída
	if _estado == "accion" and _accion == "golpeada":
		_terminar_accion()
		_empezar("aterrizar", Vector2.ZERO)
		return
	if _estado == "accion" and _accion == "golpear":
		_cambiar_golpe_de_version()
		return
	if _estado == "accion" and _accion == "cargar":
		sprite.play(StringName("cargar_acido_" + mirando))
		return
	if _estado != "suelo":
		return
	# Si sigue moviéndose o pide otra cosa, sigue sin pararse; si no, amortigua la caída
	var direccion := Input.get_vector(&"mover_izquierda", &"mover_derecha", &"mover_arriba", &"mover_abajo")
	_corria = _tipo_salto == "correr" and Input.is_action_pressed(&"correr")
	if direccion == Vector2.ZERO and _pedida == "":
		_empezar("aterrizar", Vector2.ZERO)


# --- Acciones --------------------------------------------------------------

func _empezar(accion: String, direccion: Vector2) -> void:
	_pedida = ""
	_saludando = false
	_tiempo_quieta = 0.0
	match accion:
		"saltar", "saltar_atras":
			if _en_aire:
				return
			var corriendo := _corria or (Input.is_action_pressed(&"correr") and direccion != Vector2.ZERO)
			_saltar("atras" if accion == "saltar_atras" else ("correr" if corriendo else "normal"), direccion)
			if _estado == "accion" and _accion != "golpear":
				_terminar_accion()
			return
	_corria = false
	_caminaba = false
	# Al atacar se gira hacia donde se esté pulsando
	if direccion != Vector2.ZERO:
		_mirar_hacia(direccion)
	_estado = "accion"
	_accion = accion
	match accion:
		"golpear":
			_combo_paso = 0
			_golpe_aplicado = false
			_golpe_soltado = not Input.is_action_pressed(&"golpear")
			sprite.play(_animacion_golpe())
		"escupir":
			_accion = "cargar"
			_carga = 0.0
			_acido_interno.carga = 0.0
			_acido_interno.visible = true
			sprite.play(StringName("cargar_acido_" + mirando))
		"dano":
			sprite.play(StringName("dano_%s_%s" % [DANOS[dano][0], mirando]))
		_:
			sprite.play(StringName("%s_%s" % [accion, mirando]))


func _en_accion(direccion: Vector2, delta: float) -> void:
	var total := sprite.sprite_frames.get_frame_count(sprite.animation)
	var progreso := float(sprite.frame) / maxf(1.0, total - 1)
	match _accion:
		"golpear":
			if not _golpe_aplicado and progreso >= IMPACTO_GOLPE - 0.1:
				_golpe_aplicado = true
				_aplicar_golpe()
			if _en_aire:
				pass   # en el aire conserva el impulso del salto
			else:
				# Golpeando no pierde velocidad: si sigue pulsando una dirección, sigue a su paso
				# (caminando o corriendo); si no, frena. Puede saltar sin dejar de golpear
				var paso := velocidad_correr if Input.is_action_pressed(&"correr") else velocidad_caminar
				_acercar_velocidad(direccion * maxf(paso, velocity.length() if direccion != Vector2.ZERO else 0.0),
						delta, frenado)
				if _pedida in ["saltar", "saltar_atras"]:
					_empezar(_pedida, direccion)
			if progreso >= IMPACTO_GOLPE:
				# Soltó el botón: se corta tras el impacto (o sigue el combo si volvió a pulsar)
				if _golpe_soltado and _pedida != "golpear":
					_terminar_accion()
					return
				# Moverse corta la recuperación
				if direccion != Vector2.ZERO and _pedida == "" and not _en_aire:
					_terminar_accion()
					_en_suelo(direccion, delta)
					return
		"cargar":
			_carga = minf(1.0, _carga + delta / segundos_carga_maxima)
			_acido_interno.carga = _carga
			# Cargando se puede saltar; en el aire sigue cargando con la postura del salto
			if _en_aire:
				# En el aire se dirige hacia donde se pulse, sin dejar de apuntar; sin pulsar, conserva el impulso
				if direccion != Vector2.ZERO:
					velocity = velocity.move_toward(direccion * velocidad_caminar, aceleracion * delta)
				elif _tipo_salto == "atras":
					velocity = velocity.move_toward(Vector2.ZERO, 260.0 * delta)
				move_and_slide()
				_postura_aire()
				return
			if _pedida in ["saltar", "saltar_atras"] and _tiempo_en_suelo >= segundos_en_suelo_para_saltar:
				var atras := _pedida == "saltar_atras"
				_pedida = ""
				_saltar("atras" if atras else "normal", direccion)
				if not atras:
					velocity = direccion * velocidad_caminar
				return
			# Cargando camina normal sin dejar de apuntar; hacia atrás camina de espaldas
			_acercar_velocidad(direccion * velocidad_caminar, delta, frenado)
			if direccion == Vector2.ZERO:
				var quieta := StringName("cargar_acido_" + mirando)
				if sprite.animation != quieta or sprite.get_playing_speed() <= 0.0:
					sprite.play(quieta)
			else:
				var andando := StringName("caminar_" + mirando)
				var atras := direccion.dot(_vector_mirada()) < -0.35
				if sprite.animation != andando or (sprite.get_playing_speed() < 0.0) != atras:
					if atras:
						sprite.play_backwards(andando)
					else:
						sprite.play(andando)
		"soltar":
			_acercar_velocidad(Vector2.ZERO, delta, frenado)
			if not _acido_lanzado and sprite.frame >= FOTOGRAMA_ACIDO:
				_lanzar_acido()
		"charco":
			velocity = velocity.move_toward(Vector2.ZERO, frenado * delta)
			move_and_slide()
			# Al soltar agacharse (pasado el choque) vuelve a su forma
			if not _chocando and not Input.is_action_pressed(&"agacharse"):
				_terminar_accion()
				_reproducir(reposo)
			return
		"congelada":
			# Congelada no se mueve; cada botón pulsado ayuda a romper el hielo
			velocity = Vector2.ZERO
			if _pedida != "":
				_pedida = ""
				_congelada -= 0.35
			_congelada -= delta
			if _congelada <= 0.0:
				_descongelar()
			return
		"derrota":
			velocity = Vector2.ZERO
			# Al derretirse se evapora
			if estilo_derrota == "b" and _ultimo_vapor > 0.1 and sprite.frame > 6:
				_ultimo_vapor = 0.0
				_soltar_vapor(3)
			return
		"golpeada":
			velocity = velocity.move_toward(Vector2.ZERO, 250.0 * delta)
			move_and_slide()
			if _en_aire:
				_postura_aire()
			return
		"frenar", "frenar_caminar", "aterrizar":
			# Se cortan con cualquier botón o al volver a moverse
			if direccion != Vector2.ZERO or _pedida != "":
				_terminar_accion()
				_en_suelo(direccion, delta)
				return
			_acercar_velocidad(Vector2.ZERO, delta, frenado_correr if _accion == "frenar" else frenado)
		_:
			_acercar_velocidad(Vector2.ZERO, delta, frenado)
	move_and_slide()


func _terminar_accion() -> void:
	_estado = "suelo"
	_accion = ""
	_acido_interno.visible = false
	sprite.play()   # por si estaba en pausa


## Golpes del combo según el nivel de pelea.
func combo() -> Array:
	return COMBOS[nivel_pelea]


## Animación del golpe actual del combo (versión aérea si está en el aire).
func _animacion_golpe() -> StringName:
	return StringName("golpear_%s%s_%s" % [combo()[_combo_paso], "_aire" if _en_aire else "", mirando])


## Al despegar o aterrizar a mitad de un golpe, cambia de versión sin cortar el golpe.
func _cambiar_golpe_de_version() -> void:
	var fotograma := sprite.frame
	sprite.play(_animacion_golpe())
	sprite.frame = fotograma


## Recibe un golpe desde «origen»: pierde vida (menos cuanto más grande, más cuanto más
## peligroso el enemigo) y sale despedida de un brinco en sentido contrario.
func recibir_dano(cantidad := 10.0, origen := Vector2.INF, peligrosidad := 1.0) -> void:
	if _invulnerable > 0.0 or _accion == "derrota":
		return
	if _accion == "congelada":
		_descongelar()
	_invulnerable = INVULNERABLE
	racha = 0.0
	_desde_golpe = 0.0
	_cambiar_vida(vida - cantidad * DANO_RECIBIDO[_tamano] * (0.75 + 0.25 * peligrosidad))
	if vida <= 0.0:
		_derrotar()
		return
	if origen == Vector2.INF:
		origen = position + _vector_mirada() * 20.0   # (prueba) golpe de frente
	var hacia := position - origen
	var direccion := hacia.normalized() if hacia.length() > 0.5 else -_vector_mirada()
	# Mira hacia quien la golpeó y sale despedida hacia atrás
	_fase = ""
	_acido_interno.visible = false
	_estado = "accion"
	_accion = "golpeada"
	_pedida = ""
	_mirar_hacia(-direccion)
	_en_aire = false
	_saltar("atras", Vector2.ZERO, 140.0 + 30.0 * peligrosidad)
	velocity = direccion * (120.0 + 60.0 * peligrosidad) / factor_tamano()
	# Le salta agua del cuerpo, que cae al suelo
	var salpicadura := Salpicadura.new()
	salpicadura.position = position
	get_parent().add_child(salpicadura)


## Quemadura del charco de ácido: quita vida (menos cuanto más grande), sin brinco.
func recibir_quemadura(cantidad: float) -> void:
	if _accion == "derrota":
		return
	racha = 0.0
	_quemado = 0.12
	_cambiar_vida(vida - cantidad * DANO_RECIBIDO[_tamano])
	if vida <= 0.0:
		_derrotar()


# --- Elementos, derrota y guardado ---------------------------------------------

## El calor la evapora: pierde vida (menos cuanto más grande) y suelta vapor.
func calentar(cantidad: float) -> void:
	if _accion == "derrota":
		return
	_calentando = 0.2
	_cambiar_vida(vida - cantidad * DANO_RECIBIDO[_tamano])
	if _ultimo_vapor > 0.18:
		_ultimo_vapor = 0.0
		_soltar_vapor(2)
	if vida <= 0.0:
		_derrotar()


## El frío la enfría poco a poco: va más despacio y, al llegar al máximo, se congela.
func enfriar(delta: float) -> void:
	if _accion in ["derrota", "congelada"] or _inmune_frio > 0.0:
		return
	_enfriando = 0.2
	_frio = minf(1.0, _frio + delta / 3.0)
	if _frio >= 1.0:
		_congelar()


## El agua (charcos, lluvia) le da vida y la hace crecer.
func absorber_agua(cantidad: float) -> void:
	if _accion == "derrota":
		return
	_mojando = 0.2
	_cambiar_vida(vida + cantidad)


func _congelar() -> void:
	_estado = "accion"
	_accion = "congelada"
	_pedida = ""
	_congelada = 2.5
	velocity = Vector2.ZERO
	if _en_aire:
		_en_aire = false
		_altura = 0.0
		sprite.position.y = 0.0
		_sombra.visible = false
	sprite.pause()
	_hielo.visible = true


## Rompe el hielo: salen trocitos y durante un momento no se vuelve a congelar.
func _descongelar() -> void:
	_frio = 0.0
	_inmune_frio = 2.0
	_hielo.visible = false
	var trozos := Salpicadura.new()
	trozos.position = position
	trozos.altura_inicial = 30.0 * factor_tamano()
	trozos.cantidad = 10
	trozos.fuerza = 0.8
	get_parent().add_child(trozos)
	_terminar_accion()
	_reproducir(reposo)


func _soltar_vapor(cantidad: int) -> void:
	var vapor := Vapor.new()
	vapor.position = position
	vapor.altura = 40.0 * factor_tamano()
	vapor.cantidad = cantidad
	vapor.tamano = factor_tamano()
	get_parent().add_child(vapor)


## Efectos de los elementos que se van pasando cuando deja de estar en ellos.
func _actualizar_elementos(delta: float) -> void:
	_ultimo_vapor += delta
	_enfriando = maxf(0.0, _enfriando - delta)
	_calentando = maxf(0.0, _calentando - delta)
	_mojando = maxf(0.0, _mojando - delta)
	_inmune_frio = maxf(0.0, _inmune_frio - delta)
	_desde_golpe += delta
	if _enfriando <= 0.0 and _accion != "congelada":
		_frio = maxf(0.0, _frio - delta / 2.0)
	var f := factor_tamano()
	_hielo.scale = Vector2(f, f)
	_hielo.position = sprite.position


## Vida a 0: se derrota (animación según el estilo) y después vuelve al último punto guardado.
func _derrotar() -> void:
	_cambiar_vida(0.0)
	_estado = "accion"
	_accion = "derrota"
	_pedida = ""
	_fase = ""
	velocity = Vector2.ZERO
	_hielo.visible = false
	_acido_interno.visible = false
	if _en_aire:
		_en_aire = false
		_altura = 0.0
		sprite.position.y = 0.0
		_sombra.visible = false
	_invulnerable = 0.0
	sprite.play(StringName("derrota_%s_%s" % [estilo_derrota, mirando]))


## Guarda la partida tal como está ahora (posición, vida, tamaño y nivel de pelea).
func guardar(avisar := true) -> void:
	_guardado = {"posicion": position, "vida": vida, "nivel_pelea": nivel_pelea, "mirando": mirando,
			"flip": sprite.flip_h}
	if avisar:
		partida_guardada.emit()


## Vuelve al último punto de guardado, tal como se guardó.
func _reaparecer() -> void:
	position = _guardado["posicion"]
	nivel_pelea = _guardado["nivel_pelea"]
	mirando = _guardado["mirando"]
	sprite.flip_h = _guardado["flip"]
	_cambiar_vida(_guardado["vida"])
	_escala = TAMANOS[_tamano]
	_frio = 0.0
	racha = 0.0
	velocity = Vector2.ZERO
	_terminar_accion()
	_invulnerable = 1.5
	_reproducir(reposo)
	reaparecio.emit()


## Animación de la caída en picado: 0 al empezar, 1 en el aire, 2 al chocar, 3 agachada.
func _anim_picado(parte: int) -> StringName:
	return StringName("%s_%s" % [PICADO[parte], mirando])


## Onda de agua al caer en picado: más alcance cuanto más grande es Gota; hace más
## daño cuanto más cerca del centro está el enemigo.
func _soltar_onda() -> void:
	var onda := Onda.new()
	onda.radio_maximo = 160.0 * (vida / vida_maxima) * factor_tamano() / 1.44
	onda.dano = 22.0 * FUERZA[_tamano]
	onda.empuje = 340.0 * factor_tamano()
	onda.estilo = estilo_onda
	# Se hace charco: la onda nace del borde del charco
	onda.radio_inicial = 26.0 * factor_tamano()
	onda.position = position
	get_parent().add_child(onda)


## Lanza la bola de ácido; cuanto más se cargó, más grande.
func _lanzar_acido() -> void:
	_acido_lanzado = true
	_acido_interno.visible = false
	var acido := Acido.new()
	acido.direccion = _vector_mirada()
	acido.escala = 1.0 + 1.6 * _carga
	acido.fuerza = FUERZA[_tamano]
	acido.position = position + acido.direccion * 22.0
	get_parent().add_child(acido)


# --- Reposo prolongado -------------------------------------------------------

func _en_reposo_largo(direccion: Vector2, delta: float) -> void:
	if _fase == "levantarse":
		return
	# Moverse o pulsar una acción: primero se levanta en alerta
	if direccion != Vector2.ZERO or _pedida != "":
		var acurrucada := _fase in ["acurrucarse", "prolongado"]
		_fase = "levantarse"
		sprite.play(StringName(("levantarse_" if acurrucada else "levantarse_sentada_") + mirando))
		return
	if _fase == "sentada":
		_tiempo_sentada += delta
		if _tiempo_sentada >= segundos_hasta_acurrucarse:
			_fase = "acurrucarse"
			sprite.play(StringName("acurrucarse_" + mirando))


func _al_terminar_animacion() -> void:
	match _estado:
		"accion":
			if _accion == "cargar":
				return   # la carga sigue hasta soltar
			if _accion == "derrota":
				_reaparecer()
				return
			if _accion == "congelada":
				return
			if _accion == "charco" and _chocando:
				# Tras el choque, sigue agachada o vuelve a su forma
				_chocando = false
				sprite.play(_anim_picado(3))
				return
			# Combo: si se pidió otro golpe (o se mantiene el botón), sigue con el siguiente
			if _accion == "golpear" and _pedida == "golpear" and _combo_paso + 1 < combo().size():
				_pedida = ""
				_combo_paso += 1
				_golpe_aplicado = false
				_golpe_soltado = not Input.is_action_pressed(&"golpear")
				sprite.play(_animacion_golpe())
				return
			_terminar_accion()
			if not _en_aire:
				_reproducir(reposo)
		"reposo_largo":
			match _fase:
				"entrada":
					_fase = "sentada"
					_tiempo_sentada = 0.0
					sprite.play(StringName("reposo_sentada_" + mirando))
				"acurrucarse":
					_fase = "prolongado"
					sprite.play(StringName("reposo_prolongado_" + mirando))
				"levantarse":
					_fase = ""
					_estado = "suelo"
					_tiempo_quieta = 0.0
					_reproducir(reposo)
		_:
			if _saludando:
				_saludando = false
				_reproducir(reposo)


# --- Utilidades ----------------------------------------------------------------

## Acelera hacia la velocidad objetivo o frena hasta pararse.
func _acercar_velocidad(objetivo: Vector2, delta: float, ritmo_frenado: float,
		ritmo_acelerar := aceleracion) -> void:
	var ritmo := ritmo_acelerar if objetivo != Vector2.ZERO else ritmo_frenado
	velocity = velocity.move_toward(objetivo, ritmo * delta)


## Elige la dirección dibujada más cercana (de 45 en 45 grados).
func _mirar_hacia(direccion: Vector2) -> void:
	var grados := rad_to_deg(atan2(absf(direccion.x), direccion.y))   # 0 = abajo, 180 = arriba
	mirando = DIRECCIONES[roundi(grados / 45.0)]
	if mirando != "abajo" and mirando != "arriba":
		sprite.flip_h = direccion.x < 0.0
	else:
		sprite.flip_h = false


## Vector unitario hacia donde mira.
func _vector_mirada() -> Vector2:
	var grados := DIRECCIONES.find(mirando) * 45.0
	var dir := Vector2(sin(deg_to_rad(grados)), cos(deg_to_rad(grados)))
	if sprite.flip_h:
		dir.x = -dir.x
	return dir


# --- Vida y tamaño --------------------------------------------------------------

## Tramo de tamaño según la vida: 0-20 → A, 20-40 → B … 80-100 → E.
func _tramo_de_vida() -> int:
	return clampi(ceili(vida / (vida_maxima / 5.0)) - 1, 0, 4)


func _cambiar_vida(nueva: float) -> void:
	vida = clampf(nueva, 0.0, vida_maxima)
	var tramo := _tramo_de_vida()
	if tramo != _tamano:
		_tamano = tramo
		_desde_cambio_tamano = 0.0
	vida_cambiada.emit()


## Recoge energía (de las almas): gana vida y crece.
func ganar_energia(cantidad: float) -> void:
	_cambiar_vida(vida + cantidad)


## Las almas valen más cuanto más tiempo lleva sin recibir daño (hasta el doble).
func multiplicador_racha() -> float:
	return 1.0 + clampf(racha / segundos_racha, 0.0, 1.0)


## Escala respecto al tamaño C (para alcance, sombra, huellas…).
func factor_tamano() -> float:
	return _escala / 0.25


func letra_tamano() -> String:
	return LETRAS_TAMANO[_tamano]


func fuerza() -> float:
	return FUERZA[_tamano]


func dano_recibido() -> float:
	return DANO_RECIBIDO[_tamano]


## Expresión automática: determinada si pelea con un enemigo igual o más fuerte que
## ella (según su tamaño); alerta si la detectan, si la acaban de golpear o en zona de peligro.
func _actualizar_animo(_delta: float) -> void:
	if not animo_auto:
		return
	var nuevo := "reposo"
	var en_peligro := _desde_golpe < 3.0
	for zona in get_tree().get_nodes_in_group("zonas_peligro"):
		if zona.contiene(position):
			en_peligro = true
	for enemigo in get_tree().get_nodes_in_group("enemigos"):
		if not enemigo.detecta:
			continue
		en_peligro = true
		if enemigo.nivel >= _tamano and position.distance_to(enemigo.position) < 170.0:
			nuevo = "reposo_determinada"
	if nuevo == "reposo" and en_peligro:
		nuevo = "reposo_alerta"
	if nuevo != reposo:
		reposo = nuevo
		nombre_animo = {"reposo": "normal (auto)", "reposo_alerta": "alerta (auto)",
				"reposo_determinada": "determinada (auto)"}[nuevo]


## Pequeña (A o B) se esconde dentro de un arbusto o agachada junto a una roca.
func esta_escondida() -> bool:
	if _tamano > 1 or _en_aire:
		return false
	var agachada := Input.is_action_pressed(&"agacharse")
	for escondite in get_tree().get_nodes_in_group("escondites"):
		if position.distance_to(escondite.position) < escondite.radio_escondite \
				and (escondite.tipo == "arbusto" or agachada):
			return true
	return false


## Distancia desde la que la ve un enemigo: más cuanto más grande es Gota y más
## peligroso el enemigo; agachada, menos; escondida, nada.
func distancia_deteccion(peligrosidad := 1.0) -> float:
	if esta_escondida():
		return 0.0
	var distancia := (110.0 + 40.0 * peligrosidad) * pow(factor_tamano(), 1.5)
	if Input.is_action_pressed(&"agacharse") and not _en_aire:
		distancia *= 0.6
	return distancia


## Altura sobre el suelo (para que los enemigos no la toquen al saltar por encima).
func altura() -> float:
	return _altura


## Crece o encoge poco a poco y, al cambiar de tamaño, tiembla como gelatina.
func _actualizar_tamano(delta: float) -> void:
	racha += delta
	_invulnerable = maxf(0.0, _invulnerable - delta)
	_desde_cambio_tamano += delta
	_escala = lerpf(_escala, TAMANOS[_tamano], 1.0 - exp(-6.0 * delta))
	var t := _desde_cambio_tamano
	var tiembla := 0.09 * exp(-4.0 * t) * sin(t * 18.0)
	sprite.scale = Vector2(_escala * (1.0 + tiembla), _escala * (1.0 - tiembla))
	var f := factor_tamano()
	_sombra.scale = Vector2(f, f)
	_acido_interno.scale = Vector2(f, f)
	var colision := $Colision as CollisionShape2D
	(colision.shape as CircleShape2D).radius = 12.0 * f
	colision.position.y = -6.0 * f
	# Tras un golpe parpadea mientras no se le puede volver a dañar; escondida se ve tenue;
	# al quemarse con el ácido destella en verde
	_quemado = maxf(0.0, _quemado - delta)
	var tinte := Color.WHITE
	if _frio > 0.0:
		tinte = tinte.lerp(Color(0.7, 0.86, 1.0), _frio)   # se va poniendo azul de frío
	if _calentando > 0.0:
		tinte = tinte * Color(1.0, 0.93, 0.88)
	if _mojando > 0.0:
		tinte = tinte * Color(0.92, 0.98, 1.0) + Color(0.0, 0.03, 0.08, 0.0)
	if _quemado > 0.0:
		tinte = Color(0.7, 1.0, 0.6)
	sprite.modulate = tinte
	if _invulnerable > 0.0 and fmod(_invulnerable, 0.16) < 0.08:
		sprite.modulate.a = 0.45
	elif esta_escondida():
		sprite.modulate.a = 0.55


## Daña a los enemigos que tenga delante, al alcance del golpe.
func _aplicar_golpe() -> void:
	var frente := _vector_mirada()
	var alcance := ALCANCE_GOLPE * factor_tamano()
	for enemigo in get_tree().get_nodes_in_group("enemigos"):
		var hacia: Vector2 = enemigo.position - position
		if hacia.length() > alcance + enemigo.radio:
			continue
		if hacia.length() > 8.0 and hacia.normalized().dot(frente) < 0.2:
			continue
		enemigo.recibir_golpe(DANO_GOLPE * FUERZA[_tamano], frente, 260.0 * factor_tamano())


## Deja una huellita cada cierto trecho, alternando pie izquierdo y derecho.
func _marcar_huellas(delta: float) -> void:
	var rapidez := velocity.length()
	if _en_aire or rapidez < 20.0:
		return
	_distancia_paso += rapidez * delta
	var paso := (22.0 if rapidez > 200.0 else (10.0 if rapidez < 70.0 else 15.0)) * factor_tamano()
	if _distancia_paso < paso:
		return
	_distancia_paso = 0.0
	_lado_huella = -_lado_huella
	var direccion := velocity.normalized()
	var intensidad := 0.5 if rapidez < 70.0 else 1.0   # agachada pisa más suave
	_huellas.poner(position + direccion.orthogonal() * 4.0 * factor_tamano() * _lado_huella, direccion.angle(),
			intensidad, factor_tamano())


## Se inclina un poco hacia el lado al que se mueve (más cuanto más rápido).
func _inclinar(delta: float) -> void:
	var objetivo := deg_to_rad(inclinacion_maxima) * velocity.x / velocidad_correr
	sprite.rotation = lerpf(sprite.rotation, objetivo, minf(1.0, delta * 10.0))


## Los pies van al ritmo de la velocidad real (más despacio al arrancar).
func _ajustar_ritmo() -> void:
	var anim := String(sprite.animation)
	if _estado == "suelo" and not _en_aire and (anim.begins_with("caminar") or anim.begins_with("correr")):
		sprite.speed_scale = clampf(velocity.length() / maxf(1.0, _velocidad_objetivo), 0.5, 1.0)
	else:
		sprite.speed_scale = 1.0


func _reproducir(accion: String) -> void:
	var animacion := StringName("%s_%s" % [accion, mirando])
	if sprite.animation != animacion or not sprite.is_playing():
		sprite.play(animacion)


# --- Pruebas -------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode in ANIMOS:
		animo_auto = false
		reposo = ANIMOS[event.keycode][0]
		nombre_animo = ANIMOS[event.keycode][1]
		_tiempo_quieta = 0.0
	elif event.keycode == KEY_0:
		animo_auto = true
	elif event.keycode == KEY_F8:
		var estilos := ESTILOS_DERROTA.keys()
		estilo_derrota = estilos[(estilos.find(estilo_derrota) + 1) % estilos.size()]
	elif event.keycode == KEY_F4:
		nivel_pelea = (nivel_pelea + 1) % COMBOS.size()
	elif event.keycode == KEY_F7:
		var ondas := ESTILOS_ONDA.keys()
		estilo_onda = ondas[(ondas.find(estilo_onda) + 1) % ondas.size()]
	elif event.keycode == KEY_K:
		recibir_dano()
	elif event.keycode == KEY_Z and _estado == "suelo" and not _en_aire:
		# Descansar al momento (para probar el reposo prolongado sin esperar)
		_estado = "reposo_largo"
		_fase = "entrada"
		velocity = Vector2.ZERO
		sprite.play(StringName("reposo_prolongado_entrada_" + mirando))
