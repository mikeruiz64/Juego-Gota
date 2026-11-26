extends Node2D
## Huellitas mojadas que deja Gota en el suelo y que se van secando.
##
## Va en el escenario (a la altura del suelo) para quedar debajo de todo. Gota
## añade cada huella con poner(); se dibujan con código.

## Segundos que tarda en secarse una huella.
const SECADO := 2.5
const COLOR := Color(0.16, 0.30, 0.20, 0.4)

## Cada huella: [posición, ángulo, intensidad, edad, tamaño]
var _huellas: Array = []


func poner(posicion: Vector2, angulo: float, intensidad := 1.0, tamano := 1.0) -> void:
	_huellas.append([posicion, angulo, intensidad, 0.0, tamano])


func _process(delta: float) -> void:
	if _huellas.is_empty():
		return
	for h in _huellas:
		h[3] += delta
	_huellas = _huellas.filter(func(h): return h[3] < SECADO)
	queue_redraw()


func _draw() -> void:
	for h in _huellas:
		var k: float = 1.0 - h[3] / SECADO
		# Pie redondo, sin dedos: una manchita ovalada en la dirección del paso
		draw_set_transform(h[0], h[1], Vector2(1.0, 0.62))
		draw_circle(Vector2.ZERO, 3.6 * h[4], Color(COLOR, COLOR.a * k * h[2]))
		draw_set_transform(Vector2.ZERO)
