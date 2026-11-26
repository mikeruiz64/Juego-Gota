extends Node2D
## Salpicadura de agua al recibir daño: gotitas que saltan del cuerpo de Gota,
## vuelan en arco, caen al suelo y dejan pequeñas manchas que se secan.
## Se dibuja con código; el nodo está en el suelo, a los pies de Gota.

## Altura desde la que saltan las gotas (el centro del cuerpo).
var altura_inicial := 34.0
## Cuántas gotas salen y con qué fuerza (1 = la de recibir daño).
var cantidad := 14
var fuerza := 1.0

const AGUA := Color(0.91, 0.94, 0.97, 0.9)
const BORDE := Color(0.62, 0.70, 0.79, 0.9)
const GRAVEDAD := 700.0
const SECADO := 0.7

## Cada gota: [posición en el suelo, velocidad en el suelo, altura, velocidad vertical, radio, tiempo en el suelo]
var _gotas: Array = []
var _azar := RandomNumberGenerator.new()


func _ready() -> void:
	_azar.randomize()
	for i in cantidad:
		var ang := _azar.randf_range(0.0, TAU)
		var empuje := _azar.randf_range(50.0, 130.0) * fuerza
		_gotas.append([Vector2.ZERO, Vector2(cos(ang), sin(ang) * 0.5) * empuje,
				maxf(0.0, altura_inicial + _azar.randf_range(-6.0, 6.0)), _azar.randf_range(90.0, 220.0) * fuerza,
				_azar.randf_range(1.6, 3.4) * clampf(fuerza, 0.6, 1.0), -1.0])


func _process(delta: float) -> void:
	var quedan := false
	for g in _gotas:
		if g[5] < 0.0:
			# En el aire: avanza, sube y cae
			g[0] += g[1] * delta
			g[3] -= GRAVEDAD * delta
			g[2] += g[3] * delta
			if g[2] <= 0.0:
				g[2] = 0.0
				g[5] = 0.0
			quedan = true
		elif g[5] < SECADO:
			g[5] += delta
			quedan = true
	if not quedan:
		queue_free()
	queue_redraw()


func _draw() -> void:
	for g in _gotas:
		var radio: float = g[4]
		if g[5] < 0.0:
			# Sombra en el suelo y la gota en el aire, algo estirada al caer
			_elipse(g[0], radio, radio * 0.4, Color(0, 0, 0, 0.15))
			var estira := clampf(1.0 - g[3] / 400.0, 1.0, 1.6)
			draw_set_transform(g[0] + Vector2(0, -g[2]), 0.0, Vector2(1.0 / sqrt(estira), estira))
			draw_circle(Vector2.ZERO, radio + 0.7, BORDE)
			draw_circle(Vector2.ZERO, radio, AGUA)
			draw_set_transform(Vector2.ZERO)
		else:
			# En el suelo: una manchita que se extiende un poco y se seca
			var k: float = g[5] / SECADO
			var r := radio * (1.4 + 0.8 * k)
			_elipse(g[0], r, r * 0.45, Color(AGUA, 0.75 * (1.0 - k)))


func _elipse(centro: Vector2, rx: float, ry: float, color: Color) -> void:
	draw_set_transform(centro, 0.0, Vector2(1.0, ry / rx))
	draw_circle(Vector2.ZERO, rx, color)
	draw_set_transform(Vector2.ZERO)
