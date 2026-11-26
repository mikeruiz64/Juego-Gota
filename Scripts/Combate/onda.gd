extends Node2D
## Onda de la caída en picado, de gelatina (el mismo material que Gota: translúcida,
## con doble contorno y brillo). Daña y empuja a los enemigos que alcanza el frente:
## más cuanto más cerca del centro. Se dibuja con código; el nodo está en el suelo.
##
## Estilos (en prueba):
## - "g1" Anillo de gelatina: anillo grueso con algo de altura que se expande temblando.
## - "g2" Cúpula de gelatina: una cúpula que sale del impacto, se expande, se aplana y se disuelve.
## - "g3" Ola de gelatina: un muro de gelatina que avanza con el borde ondulando y se desploma.

## Radio final (píxeles), daño en el centro, empuje y estilo.
var radio_maximo := 80.0
var dano := 15.0
var empuje := 320.0
var estilo := "g1"
## Radio desde el que empieza (0 = desde el centro)
var radio_inicial := 0.0

const DURACION := 0.6
const DESVANECER := 0.45
## La onda es una elipse en el suelo (cámara a ~45°)
const ACHATADO := 0.5
const SEGMENTOS := 48
const RELLENO := Color(0.90, 0.94, 0.98, 0.42)
const LADO := Color(0.80, 0.86, 0.92, 0.55)
const CONTORNO := Color(0.76, 0.81, 0.86, 0.95)
const CONTORNO_INTERIOR := Color(0.89, 0.91, 0.93, 0.8)
const BRILLO := Color(1, 1, 1, 0.85)

var _t := 0.0
var _alcanzados: Array = []


func _process(delta: float) -> void:
	_t += delta
	var radio := _radio()
	# Daña una sola vez a cada enemigo que alcanza el frente; más cuanto más cerca del centro
	for enemigo in get_tree().get_nodes_in_group("enemigos"):
		if enemigo in _alcanzados:
			continue
		var hacia: Vector2 = enemigo.position - position
		var distancia := Vector2(hacia.x, hacia.y / ACHATADO).length()
		if distancia <= radio + enemigo.radio:
			_alcanzados.append(enemigo)
			var cercania := 1.0 - clampf(distancia / maxf(1.0, radio_maximo), 0.0, 1.0)
			enemigo.recibir_golpe(dano * (0.3 + 0.7 * cercania), hacia if hacia.length() > 1.0 else Vector2.RIGHT,
					empuje * (0.5 + 0.5 * cercania))
	if _t > DURACION + DESVANECER:
		queue_free()
	queue_redraw()


## Radio del frente: sale rápido y frena, con un pequeño rebote de gelatina al final.
func _radio() -> float:
	var u := clampf(_t / DURACION, 0.0, 1.0)
	var rebote := 0.06 * sin(u * PI * 3.0) * (1.0 - u)
	return radio_inicial + (radio_maximo - radio_inicial) * (1.0 - pow(1.0 - u, 2.4) + rebote)


## Temblor que se va calmando (0 al final).
func _temblor() -> float:
	return exp(-3.0 * _t)


func _apagado() -> float:
	return 1.0 - clampf((_t - DURACION) / DESVANECER, 0.0, 1.0)


func _draw() -> void:
	match estilo:
		"g2":
			_dibujar_cupula()
		"g3":
			_dibujar_anillo(true)
		_:
			_dibujar_anillo(false)


## Cuadrilátero de un color (dos triángulos, sin triangulación que pueda fallar).
func _cuadro(a: Vector2, b: Vector2, c: Vector2, d: Vector2, color: Color) -> void:
	draw_primitive(PackedVector2Array([a, b, c, d]), PackedColorArray([color, color, color, color]),
			PackedVector2Array())


## Punto del anillo en el ángulo a, con radio r y altura h (en el suelo, achatado).
func _punto(a: float, r: float, h: float) -> Vector2:
	return Vector2(cos(a) * r, sin(a) * r * ACHATADO - h)


## Anillo (g1) u ola (g3) de gelatina: borde exterior que tiembla, grosor que late y
## altura; se dibuja la cara lateral delantera y después la parte de arriba con contornos.
func _dibujar_anillo(ola: bool) -> void:
	var radio := _radio()
	if radio < 2.0:
		return
	var u := clampf(_t / DURACION, 0.0, 1.0)
	var tiembla := _temblor()
	var apaga := _apagado()
	var grosor := lerpf(16.0, 7.0, u) * (radio_maximo / 90.0 * 0.6 + 0.4)
	var alto_base := (16.0 if ola else 5.0) * (1.0 - 0.7 * u) * (radio_maximo / 90.0 * 0.5 + 0.5)
	var fase := _t * 14.0
	var exterior: PackedVector2Array = []
	var interior: PackedVector2Array = []
	var base: PackedVector2Array = []
	for i in SEGMENTOS + 1:
		var a := TAU * i / SEGMENTOS
		var bulto := 1.0 + 0.07 * tiembla * sin(6.0 * a + fase)
		var g := grosor * (1.0 + 0.35 * tiembla * sin(8.0 * a - fase * 1.3))
		var h := alto_base * (1.0 + (0.6 if ola else 0.3) * tiembla * sin(5.0 * a + fase * 0.8))
		if ola:
			h *= 1.0 - 0.8 * clampf((_t - DURACION * 0.8) / (DURACION * 0.5), 0.0, 1.0)   # se desploma
		exterior.append(_punto(a, radio * bulto, h))
		interior.append(_punto(a, maxf(0.0, radio * bulto - g), h))
		base.append(_punto(a, radio * bulto, 0.0))
	# Cara lateral delantera (la que da a la cámara)
	for i in SEGMENTOS:
		if sin(TAU * (i + 0.5) / SEGMENTOS) <= 0.0:
			continue
		_cuadro(base[i], base[i + 1], exterior[i + 1], exterior[i], Color(LADO, LADO.a * apaga))
	# Parte de arriba del anillo
	for i in SEGMENTOS:
		_cuadro(exterior[i], exterior[i + 1], interior[i + 1], interior[i], Color(RELLENO, RELLENO.a * apaga))
	# Doble contorno gris claro y brillo, como el cuerpo de Gota
	draw_polyline(exterior, Color(CONTORNO, CONTORNO.a * apaga), 2.0)
	draw_polyline(interior, Color(CONTORNO_INTERIOR, CONTORNO_INTERIOR.a * apaga), 1.2)
	var frente: PackedVector2Array = []
	for i in SEGMENTOS + 1:
		if sin(TAU * i / SEGMENTOS) >= 0.0:
			frente.append(base[i])
	if frente.size() > 1:
		draw_polyline(frente, Color(CONTORNO, 0.6 * apaga), 1.5)
	var brillo: PackedVector2Array = []
	for i in range(int(SEGMENTOS * 0.55), int(SEGMENTOS * 0.72)):
		brillo.append(exterior[i].lerp(interior[i], 0.35))
	if brillo.size() > 1:
		draw_polyline(brillo, Color(BRILLO, BRILLO.a * apaga), 2.0)


## Cúpula de gelatina (g2): sale del impacto, se expande, se aplana bamboleándose y se disuelve.
func _dibujar_cupula() -> void:
	var radio := _radio()
	if radio < 2.0:
		return
	var u := clampf(_t / DURACION, 0.0, 1.0)
	var tiembla := _temblor()
	var apaga := _apagado()
	var alto := radio_maximo * 0.45 * (1.0 - u) * (1.0 + 0.25 * tiembla * sin(_t * 22.0)) + 3.0
	var silueta: PackedVector2Array = []
	var suelo: PackedVector2Array = []
	for i in SEGMENTOS + 1:
		var a := TAU * i / SEGMENTOS
		var bulto := 1.0 + 0.06 * tiembla * sin(5.0 * a + _t * 16.0)
		var p := _punto(a, radio * bulto, 0.0)
		suelo.append(p)
		# La parte de arriba de la silueta sube con la altura de la cúpula
		silueta.append(p + Vector2(0, -alto * maxf(0.0, -sin(a)) * 1.6 - alto * 0.25))
	# Relleno en abanico desde el centro (sin triangular polígonos que puedan cruzarse)
	var centro := Vector2(0, -alto * 0.5)
	for i in SEGMENTOS:
		_cuadro(centro, silueta[i], silueta[i + 1], centro, Color(RELLENO, RELLENO.a * apaga))
	draw_polyline(silueta, Color(CONTORNO, CONTORNO.a * apaga), 2.0)
	draw_polyline(suelo, Color(CONTORNO_INTERIOR, 0.5 * apaga), 1.2)
	# Contorno interior y brillo en el lado izquierdo (la luz no gira)
	var interior: PackedVector2Array = []
	for p in silueta:
		interior.append(p * 0.9 + Vector2(0, -alto * 0.05))
	draw_polyline(interior, Color(CONTORNO_INTERIOR, CONTORNO_INTERIOR.a * apaga), 1.2)
	var brillo: PackedVector2Array = []
	for i in range(int(SEGMENTOS * 0.56), int(SEGMENTOS * 0.68)):
		brillo.append(silueta[i] * 0.8)
	if brillo.size() > 1:
		draw_polyline(brillo, Color(BRILLO, BRILLO.a * apaga), 2.5)
