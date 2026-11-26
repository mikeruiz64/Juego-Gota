extends Node2D
## Volutas de vapor que suben y se deshacen (Gota evaporándose con el calor o al ser
## derrotada). Se dibuja con código; el nodo está en el suelo, a los pies de Gota.

## Altura desde la que salen, cuántas volutas y su tamaño.
var altura := 30.0
var cantidad := 3
var tamano := 1.0

const DURACION := 0.9

## Cada voluta: [posición, velocidad, radio inicial, edad]
var _volutas: Array = []


func _ready() -> void:
	for i in cantidad:
		_volutas.append([Vector2(randf_range(-10, 10) * tamano, -altura + randf_range(-8, 8) * tamano),
				Vector2(randf_range(-8, 8), randf_range(-45, -30)), randf_range(3.0, 5.0) * tamano,
				randf_range(-0.15, 0.0)])


func _process(delta: float) -> void:
	var quedan := false
	for v in _volutas:
		v[3] += delta
		if v[3] > 0.0:
			v[0] += v[1] * delta
		quedan = quedan or v[3] < DURACION
	if not quedan:
		queue_free()
	queue_redraw()


func _draw() -> void:
	for v in _volutas:
		if v[3] <= 0.0 or v[3] >= DURACION:
			continue
		var k: float = v[3] / DURACION
		draw_circle(v[0], v[2] * (1.0 + 1.6 * k), Color(0.93, 0.96, 1.0, 0.45 * (1.0 - k)))
