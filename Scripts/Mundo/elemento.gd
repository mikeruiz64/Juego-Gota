extends Node2D
## Elementos del escenario que afectan a Gota por ser de agua (para probar):
## - "fogata": la evapora rápido (pierde vida y encoge).
## - "sol": zona soleada que la evapora poco a poco.
## - "hielo": zona fría que la enfría y frena hasta congelarla.
## - "charco": agua que absorbe (gana vida y crece); el charco se seca y vuelve a llenarse.
## - "lluvia": zona de lluvia que le da vida poco a poco.
## - "peligro": zona de peligro (Gota se pone en alerta).
## - "manantial": punto de guardado (guarda la partida al tocarlo).
## Se dibujan con código. Las zonas de suelo (sol, hielo, charco, lluvia y peligro) van en
## una capa de suelo del escenario, por debajo de los personajes.

## Tipos que se dibujan en el suelo, por debajo de todo
const DE_SUELO := ["sol", "hielo", "charco", "lluvia", "peligro"]

@export_enum("fogata", "sol", "hielo", "charco", "lluvia", "peligro", "manantial") var tipo := "fogata"
## Radio de la zona (en el suelo; se achata como el resto del escenario).
@export var radio := 70.0

const ACHATADO := 0.5
## Vida por segundo que quita o da cada elemento.
const CALOR := {"fogata": 7.0, "sol": 1.5}
const AGUA := {"charco": 9.0, "lluvia": 2.5}
## Cuánta agua tiene un charco y cuánto tarda en volver a llenarse.
const AGUA_CHARCO := 30.0
const RELLENO_CHARCO := 15.0

var _t := 0.0
var _agua := AGUA_CHARCO
var _vacio := 0.0
var _gotas_lluvia: Array = []
var _guardado := 0.0


func _ready() -> void:
	if tipo == "peligro":
		add_to_group("zonas_peligro")
	if tipo == "lluvia":
		for i in 40:
			_gotas_lluvia.append(Vector2(randf_range(-1, 1), randf()))


## Si Gota está dentro de la zona (en el suelo, sin contar la altura del salto).
func contiene(punto: Vector2, margen := 0.0) -> bool:
	var d := punto - global_position
	return Vector2(d.x, d.y / ACHATADO).length() < radio + margen


func _process(delta: float) -> void:
	_t += delta
	_guardado = maxf(0.0, _guardado - delta)
	var gota := get_tree().get_first_node_in_group("gota") as Node2D
	if gota:
		var dentro := contiene(gota.position)
		match tipo:
			"fogata", "sol":
				if dentro:
					gota.calentar(CALOR[tipo] * delta)
			"hielo":
				if dentro:
					gota.enfriar(delta)
			"charco":
				if _agua > 0.0 and contiene(gota.position, -radio * (1.0 - _agua / AGUA_CHARCO)) \
						and gota.altura() < 2.0:
					var bebe := minf(_agua, AGUA[tipo] * delta)
					_agua -= bebe
					gota.absorber_agua(bebe)
			"lluvia":
				if dentro:
					gota.absorber_agua(AGUA[tipo] * delta)
			"manantial":
				if dentro and _guardado <= 0.0:
					gota.guardar()
					_guardado = 1.0
	# El charco seco vuelve a llenarse con el tiempo
	if tipo == "charco" and _agua <= 0.0:
		_vacio += delta
		if _vacio > RELLENO_CHARCO:
			_vacio = 0.0
			_agua = AGUA_CHARCO
	queue_redraw()


func _elipse(centro: Vector2, r: float, color: Color) -> void:
	draw_set_transform(centro, 0.0, Vector2(1.0, ACHATADO))
	draw_circle(Vector2.ZERO, r, color)
	draw_set_transform(Vector2.ZERO)


func _draw() -> void:
	match tipo:
		"fogata":
			_elipse(Vector2.ZERO, radio, Color(1.0, 0.55, 0.2, 0.08))
			_elipse(Vector2.ZERO, 16.0, Color("4a3426"))
			for i in 3:
				var bajo := 4.0 * sin(_t * 9.0 + i * 2.1)
				var ancho := 9.0 - i * 2.5
				var alto := 24.0 - i * 6.0 + bajo
				var color: Color = [Color("e2552b"), Color("f39b2b"), Color("ffe08a")][i]
				draw_colored_polygon(PackedVector2Array([Vector2(-ancho, -2), Vector2(0, -alto - 6),
						Vector2(ancho, -2), Vector2(0, 2)]), color)
		"sol":
			_elipse(Vector2.ZERO, radio, Color(1.0, 0.93, 0.55, 0.22 + 0.04 * sin(_t * 2.0)))
			for i in 8:
				var a := TAU * i / 8.0 + _t * 0.3
				draw_line(Vector2(cos(a), sin(a) * ACHATADO) * radio * 0.4,
						Vector2(cos(a), sin(a) * ACHATADO) * radio * 0.9, Color(1, 0.95, 0.6, 0.25), 3.0)
		"hielo":
			_elipse(Vector2.ZERO, radio, Color(0.80, 0.92, 1.0, 0.45))
			_elipse(Vector2.ZERO, radio * 0.7, Color(0.92, 0.97, 1.0, 0.35))
			for i in 10:
				var p := Vector2(cos(i * 2.4), sin(i * 2.4) * ACHATADO) * radio * fmod(i * 0.37, 1.0)
				draw_line(p - Vector2(4, 0), p + Vector2(4, 0), Color(1, 1, 1, 0.6), 1.0)
				draw_line(p - Vector2(0, 3), p + Vector2(0, 3), Color(1, 1, 1, 0.6), 1.0)
		"charco":
			if _agua > 0.0:
				var r := radio * (0.35 + 0.65 * _agua / AGUA_CHARCO)
				_elipse(Vector2.ZERO, r, Color(0.45, 0.65, 0.85, 0.55))
				_elipse(Vector2(-r * 0.25, -r * 0.1), r * 0.35, Color(1, 1, 1, 0.25))
			else:
				_elipse(Vector2.ZERO, radio * 0.4, Color(0.2, 0.3, 0.25, 0.25))
		"lluvia":
			_elipse(Vector2.ZERO, radio, Color(0.4, 0.55, 0.75, 0.18))
			# Nube y gotas cayendo
			for i in 4:
				draw_circle(Vector2((i - 1.5) * radio * 0.35, -110.0 + 6 * sin(i)), radio * 0.32,
						Color(0.82, 0.86, 0.92, 0.85))
			for g in _gotas_lluvia:
				var x: float = g.x * radio * 0.9
				var fase: float = fmod(g.y + _t * 1.6, 1.0)
				var y: float = -100.0 + 100.0 * fase + (g.x * g.x) * 10.0
				draw_line(Vector2(x, y), Vector2(x - 1, y + 7), Color(0.75, 0.85, 1.0, 0.8), 1.5)
		"peligro":
			_elipse(Vector2.ZERO, radio, Color(0.35, 0.1, 0.25, 0.35))
			for i in 12:
				var a := TAU * i / 12.0
				var p := Vector2(cos(a), sin(a) * ACHATADO) * radio * 0.8
				draw_colored_polygon(PackedVector2Array([p + Vector2(-4, 0), p + Vector2(0, -12), p + Vector2(4, 0)]),
						Color("2a1424"))
		"manantial":
			var brillo := 0.5 + 0.5 * sin(_t * 3.0)
			_elipse(Vector2.ZERO, radio, Color(0.7, 0.9, 1.0, 0.18 + 0.12 * brillo))
			_elipse(Vector2.ZERO, radio * 0.55, Color(0.55, 0.78, 0.95, 0.8))
			for i in 3:
				var sube := fmod(_t * 0.8 + i / 3.0, 1.0)
				draw_circle(Vector2((i - 1) * 6.0, -6.0 - 22.0 * sube), 2.2, Color(0.9, 0.97, 1.0, 1.0 - sube))
			if _guardado > 0.0:
				draw_string(ThemeDB.fallback_font, Vector2(-48, -44), "Partida guardada",
						HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, _guardado))
