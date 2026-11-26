extends Node2D
## Alma (energía) que suelta un enemigo al morir. Flota en el sitio y, cuando
## Gota se acerca, vuela hacia ella y le da energía (vida), que la hace crecer.
## Vale más cuanto más tiempo lleva Gota sin recibir daño. Se dibuja con código.

## Energía que da al recogerla.
var valor := 5.0
## Segundos que dura en el suelo antes de desvanecerse.
const DURACION := 15.0
const ATRAER := 80.0

var _t := 0.0
var _velocidad := Vector2.ZERO
var _salida := Vector2.ZERO


func _ready() -> void:
	# Sale despedida un poco al aparecer
	_salida = Vector2.from_angle(randf() * TAU) * 60.0


func _process(delta: float) -> void:
	_t += delta
	position += _salida * delta
	_salida = _salida.move_toward(Vector2.ZERO, 150.0 * delta)
	var gota := get_tree().get_first_node_in_group("gota") as Node2D
	if gota and _t > 0.35:
		var hacia := gota.position - position
		if hacia.length() < 12.0:
			gota.ganar_energia(valor)
			queue_free()
			return
		if hacia.length() < ATRAER:
			_velocidad = _velocidad.move_toward(hacia.normalized() * 320.0, 900.0 * delta)
			position += _velocidad * delta
	if _t > DURACION:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var apaga := clampf((DURACION - _t) / 2.0, 0.0, 1.0)
	var flota := Vector2(0, -16 - 3 * sin(_t * 4.0))
	var r := 3.5 + 0.4 * valor / 5.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 4.0, Color(0, 0, 0, 0.15 * apaga))
	draw_set_transform(Vector2.ZERO)
	draw_circle(flota, r * 2.2, Color(0.55, 0.85, 1.0, 0.18 * apaga))
	draw_circle(flota, r, Color(0.78, 0.94, 1.0, 0.9 * apaga))
	draw_circle(flota + Vector2(-r * 0.3, -r * 0.3), r * 0.4, Color(1, 1, 1, 0.9 * apaga))
