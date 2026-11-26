extends Node2D
## Enemigo de práctica (solo para probar el combate y el sistema de vida/tamaño).
##
## Una mancha que vaga y, si ve a Gota, se le acerca; al tocarla le hace daño y la
## despide de un brinco. Tres tipos: "debil", "normal" y "peligroso"; cuanto más
## poder y peligrosidad, más daño hace, más lejos la despide y más valen sus almas
## (Gota crece más rápido derrotándolo). Se dibuja con código.

const Alma := preload("res://Scripts/Combate/alma.gd")

## Tipos: vida, velocidad, poder (daño al tocar), peligrosidad (1-3), radio, color y nivel
## (comparable con el tamaño de Gota, 0 = A … 4 = E: si es igual o mayor, Gota se pone determinada).
const TIPOS := {
	"debil": [18.0, 35.0, 6.0, 1.0, 11.0, Color("4a3a5a"), 0],
	"normal": [30.0, 45.0, 10.0, 1.5, 14.0, Color("3b2a4a"), 2],
	"peligroso": [55.0, 60.0, 18.0, 2.5, 18.0, Color("5a1f2c"), 4],
}

@export_enum("debil", "normal", "peligroso") var tipo := "normal"

var vida_maxima := 30.0
var velocidad := 45.0
var poder := 10.0
var peligrosidad := 1.5
## Radio del cuerpo (para golpes y contacto).
var radio := 14.0
var color := Color("3b2a4a")
var nivel := 2
## Si ahora mismo ve a Gota
var detecta := false

var vida := 0.0
var _empuje := Vector2.ZERO
var _rumbo := Vector2.ZERO
var _tiempo_rumbo := 0.0
var _destello := 0.0
var _muriendo := -1.0
var _t := 0.0
var _azar := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("enemigos")
	_azar.randomize()
	var datos: Array = TIPOS[tipo]
	vida_maxima = datos[0]
	velocidad = datos[1]
	poder = datos[2]
	peligrosidad = datos[3]
	radio = datos[4]
	color = datos[5]
	nivel = datos[6]
	vida = vida_maxima


func _process(delta: float) -> void:
	_t += delta
	_destello = maxf(0.0, _destello - delta)
	if _muriendo >= 0.0:
		_muriendo += delta
		detecta = false
		if _muriendo > 0.3:
			queue_free()
		queue_redraw()
		return
	var gota := get_tree().get_first_node_in_group("gota") as Node2D
	var movimiento := Vector2.ZERO
	# La ve desde más lejos cuanto más grande es; escondida no la ve
	detecta = gota != null and position.distance_to(gota.position) < gota.distancia_deteccion(peligrosidad)
	if detecta:
		movimiento = (gota.position - position).normalized() * velocidad
		# Al tocarla le hace daño y la despide (si no está saltando por encima)
		var alcance: float = radio + 12.0 * gota.factor_tamano()
		if position.distance_to(gota.position) < alcance and gota.altura() < 12.0:
			gota.recibir_dano(poder, position, peligrosidad)
	else:
		_tiempo_rumbo -= delta
		if _tiempo_rumbo <= 0.0:
			_tiempo_rumbo = _azar.randf_range(1.0, 2.5)
			_rumbo = Vector2.from_angle(_azar.randf_range(0, TAU)) * velocidad * 0.5 * _azar.randi_range(0, 1)
		movimiento = _rumbo
	position += (movimiento + _empuje) * delta
	_empuje = _empuje.move_toward(Vector2.ZERO, 600.0 * delta)
	queue_redraw()


## Recibe un golpe: pierde vida, se ilumina y sale empujado (los más peligrosos, menos).
func recibir_golpe(cantidad: float, direccion: Vector2, empuje := 260.0) -> void:
	if _muriendo >= 0.0:
		return
	vida -= cantidad
	_destello = 0.15
	if direccion != Vector2.ZERO:
		_empuje = direccion.normalized() * empuje / peligrosidad
	if vida <= 0.0:
		_morir()


## Energía que dan sus almas: más cuanto más poder y peligrosidad.
func valor_almas() -> float:
	return 2.5 * peligrosidad * poder / 10.0 + 2.0


func _morir() -> void:
	_muriendo = 0.0
	remove_from_group("enemigos")
	var gota := get_tree().get_first_node_in_group("gota")
	var racha: float = gota.multiplicador_racha() if gota else 1.0
	for i in _azar.randi_range(2, 3):
		var alma := Alma.new()
		alma.valor = valor_almas() * racha
		alma.position = position + Vector2(_azar.randf_range(-10, 10), _azar.randf_range(-6, 6))
		get_parent().add_child.call_deferred(alma)


func _draw() -> void:
	var k := 1.0 if _muriendo < 0.0 else maxf(0.0, 1.0 - _muriendo / 0.3)
	var late := 1.0 + 0.05 * sin(_t * 5.0)
	# Sombra y cuerpo (una mancha oscura que late)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, radio * k, Color(0, 0, 0, 0.22))
	draw_set_transform(Vector2(0, -radio * 0.8 * k), 0.0, Vector2(late, 1.0 / late) * k)
	var cuerpo := color if _destello <= 0.0 else Color("f2eef6")
	draw_circle(Vector2.ZERO, radio, cuerpo)
	draw_circle(Vector2(-4, -4), radio * 0.45, Color(cuerpo.lightened(0.15), 0.6))
	# Ojos (los peligrosos, rojos)
	var ojos := Color("ff8a7a") if tipo == "peligroso" else Color("f4e9a8")
	draw_circle(Vector2(-radio * 0.3, -2), 2.2, ojos)
	draw_circle(Vector2(radio * 0.3, -2), 2.2, ojos)
	draw_set_transform(Vector2.ZERO)
	# Barra de vida si ya le han dado
	if vida < vida_maxima and _muriendo < 0.0:
		var ancho := radio * 2.0
		draw_rect(Rect2(-ancho / 2, -radio * 2 - 10, ancho, 3), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(-ancho / 2, -radio * 2 - 10, ancho * vida / vida_maxima, 3), Color("e2675b"))
