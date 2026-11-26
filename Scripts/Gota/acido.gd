extends Node2D
## Bola pequeña de ácido que lanza Gota con el escupitajo (nivel de pelea alto).
##
## Fases: salida (aparece y se estira como un líquido), vuelo en arco dejando
## gotitas, caída al suelo con salpicadura y charco de ácido que burbujea y
## humea antes de desvanecerse. Se dibuja con código; el nodo está en el suelo y
## la bola se dibuja a su altura. El charco quema: daña poco a poco a los enemigos que lo pisan
## y también a Gota si pasa por encima.

## Dirección del vuelo (normalizada).
var direccion := Vector2.RIGHT
## Velocidad horizontal (píxeles por segundo).
var velocidad := 300.0
## Tamaño según la carga (1 = sin cargar; las grandes van algo más despacio).
var escala := 1.0
## Fuerza de Gota al lanzarla (según su tamaño).
var fuerza := 1.0
const DANO := 12.0
## Daño del charco cada vez que quema (cada QUEMA segundos).
const DANO_CHARCO := 3.0
const QUEMA := 0.25
var _ha_danado := false
var _ultima_quema := 0.0

const SALIDA := 0.12
const VUELO := 0.55
const CHARCO := 1.6
const DESVANECER := 0.5
const ALTURA_INICIAL := 26.0

const VERDE := Color("a6e05a")
const VERDE_CLARO := Color("d6f59a")
const BORDE := Color("4e8a26")
const HUMO := Color(0.8, 0.9, 0.7)

var _tiempo := 0.0
## Gotitas que va dejando en el aire y las de la salpicadura: [posición, velocidad, vida]
var _gotitas: Array = []
var _burbujas: Array = []
var _azar := RandomNumberGenerator.new()
var _ultima_gotita := 0.0


func _ready() -> void:
	_azar.randomize()
	velocidad /= sqrt(escala)


func _process(delta: float) -> void:
	var antes := _tiempo
	_tiempo += delta
	var fin_vuelo := SALIDA + VUELO
	if _tiempo < fin_vuelo:
		if _tiempo > SALIDA:
			position += direccion * velocidad * delta
			# Si toca a un enemigo en el vuelo, cae en ese momento
			if _danar(8.0 * escala):
				_tiempo = fin_vuelo
				_salpicar()
				_ultima_quema = _tiempo
				_quemar()
			# Va dejando gotitas que caen
			if _tiempo - _ultima_gotita > 0.06:
				_ultima_gotita = _tiempo
				_gotitas.append([Vector2(0, -_altura()), -direccion * velocidad * 0.85, 0.35])
	elif antes < fin_vuelo:
		_salpicar()
		_danar(16.0 * escala)
		_ultima_quema = _tiempo
		_quemar()   # quema en cuanto toca el suelo
	elif _tiempo - _ultima_quema > QUEMA:
		# Sigue quemando hasta que el charco desaparece del todo
		_ultima_quema = _tiempo
		_quemar()
	if _tiempo >= fin_vuelo and _tiempo < fin_vuelo + CHARCO and _azar.randf() < delta * 7.0:
		# Burbujas del charco: [posición, vida, tamaño]
		_burbujas.append([Vector2(_azar.randf_range(-12, 12), _azar.randf_range(-4, 4)) * escala, 0.45,
				_azar.randf_range(1.5, 3.2) * sqrt(escala)])
	if _tiempo > fin_vuelo + CHARCO + DESVANECER:
		queue_free()
	for g in _gotitas:
		g[1].y += 260.0 * delta
		g[0] += g[1] * delta
		g[2] -= delta
	_gotitas = _gotitas.filter(func(g): return g[2] > 0.0 and g[0].y < 0.0)
	for b in _burbujas:
		b[1] -= delta
	_burbujas = _burbujas.filter(func(b): return b[1] > 0.0)
	queue_redraw()


## Altura de la bola sobre el suelo durante el vuelo (sube un poco y cae).
func _altura() -> float:
	var u := clampf((_tiempo - SALIDA) / VUELO, 0.0, 1.0)
	return ALTURA_INICIAL + 10.0 * sin(PI * u) - ALTURA_INICIAL * u * u


## El charco quema a quien esté encima: enemigos y también Gota (si no salta por encima).
func _quemar() -> void:
	var radio := 16.0 * escala
	for enemigo in get_tree().get_nodes_in_group("enemigos"):
		if Vector2(enemigo.position.x - position.x, (enemigo.position.y - position.y) / 0.45).length() < radio + enemigo.radio:
			enemigo.recibir_golpe(DANO_CHARCO * escala * fuerza, Vector2.ZERO, 0.0)
	var gota := get_tree().get_first_node_in_group("gota")
	if gota and gota.altura() < 4.0 \
			and Vector2(gota.position.x - position.x, (gota.position.y - position.y) / 0.45).length() < radio + 6.0:
		gota.recibir_quemadura(DANO_CHARCO * escala)


## Daña a los enemigos cercanos (una sola vez). Devuelve si ha dado a alguno.
func _danar(radio: float) -> bool:
	if _ha_danado:
		return false
	var dio := false
	for enemigo in get_tree().get_nodes_in_group("enemigos"):
		if enemigo.position.distance_to(position) < radio + enemigo.radio:
			enemigo.recibir_golpe(DANO * escala * fuerza, direccion, 200.0)
			dio = true
	_ha_danado = dio
	return dio


func _salpicar() -> void:
	for i in 6:
		var ang := -PI * (0.15 + 0.7 * i / 5.0)
		var v := Vector2(cos(ang), sin(ang)) * _azar.randf_range(60, 110) * sqrt(escala)
		_gotitas.append([Vector2(0, -2), v, 0.5])


func _draw() -> void:
	var fin_vuelo := SALIDA + VUELO
	var apagado := 1.0
	if _tiempo > fin_vuelo + CHARCO:
		apagado = 1.0 - (_tiempo - fin_vuelo - CHARCO) / DESVANECER

	if _tiempo < fin_vuelo:
		var altura := _altura()
		# Sombra en el suelo
		_elipse(Vector2.ZERO, 4.5 * escala, 2.0 * escala, Color(0, 0, 0, 0.22))
		# Salida: crece y se estira en la dirección del vuelo, como un líquido
		var crece := clampf(_tiempo / SALIDA, 0.0, 1.0)
		var estira := 1.0 + 0.6 * sin(PI * crece) + 0.25 * clampf((_tiempo - SALIDA) / 0.1, 0.0, 1.0)
		var r := 5.5 * crece * escala
		var centro := Vector2(0, -altura)
		draw_set_transform(centro, direccion.angle(), Vector2(estira, 1.0 / sqrt(estira)))
		draw_circle(Vector2.ZERO, r + 1.0, BORDE)
		draw_circle(Vector2.ZERO, r, VERDE)
		draw_circle(Vector2(-r * 0.3, -r * 0.35), r * 0.35, VERDE_CLARO)
		draw_set_transform(Vector2.ZERO)
	else:
		# Charco de ácido: se extiende, burbujea y humea
		var k := clampf((_tiempo - fin_vuelo) / 0.15, 0.0, 1.0) * escala
		_elipse(Vector2.ZERO, 7.0 * escala + 11.0 * k, (7.0 * escala + 11.0 * k) * 0.45, Color(BORDE, 0.8 * apagado))
		_elipse(Vector2.ZERO, 6.0 * escala + 10.0 * k, (6.0 * escala + 10.0 * k) * 0.42, Color(VERDE, 0.85 * apagado))
		for b in _burbujas:
			var vida: float = b[1] / 0.45
			var radio: float = b[2] * (1.2 - vida * 0.6)
			if vida > 0.15:
				draw_arc(b[0], radio, 0, TAU, 12, Color(VERDE_CLARO, apagado), 1.0)
			else:
				# Revienta y suelta una voluta de humo que sube
				var sube: float = (0.15 - vida) * 120.0
				draw_circle(b[0] + Vector2(0, -6 - sube), 2.5 + sube * 0.2, Color(HUMO, 0.35 * apagado))
	for g in _gotitas:
		draw_circle(g[0], 1.6 * sqrt(escala), Color(VERDE, clampf(g[2] * 3.0, 0.0, 1.0)))


func _elipse(centro: Vector2, rx: float, ry: float, color: Color) -> void:
	draw_set_transform(centro, 0.0, Vector2(1.0, ry / rx))
	draw_circle(Vector2.ZERO, rx, color)
	draw_set_transform(Vector2.ZERO)
