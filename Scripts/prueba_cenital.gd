extends Node2D
## Escenario de prueba para la cámara cenital (como Minish Cap o los Pokémon
## clásicos): suelo de hierba con un camino, rocas, arbustos y árboles con
## orden por profundidad (Gota pasa por delante o por detrás según su altura).
## Todo se dibuja con código; es solo para probar la cámara.

const EnemigoPrueba := preload("res://Scripts/Combate/enemigo_prueba.gd")
const Elemento := preload("res://Scripts/Mundo/elemento.gd")
## Elementos de prueba: tipo, posición y radio
const ELEMENTOS := [
	["manantial", Vector2(760, 610), 22.0], ["manantial", Vector2(260, 830), 22.0],
	["fogata", Vector2(1060, 400), 70.0], ["sol", Vector2(1260, 730), 150.0],
	["hielo", Vector2(300, 380), 130.0], ["charco", Vector2(620, 330), 28.0],
	["charco", Vector2(980, 830), 28.0], ["lluvia", Vector2(530, 780), 110.0],
	["peligro", Vector2(1320, 330), 120.0],
]

const BALDOSA := 48
## Enemigos de práctica que hay a la vez.
const ENEMIGOS := 4
const COLUMNAS := 32
const FILAS := 20

## Hojas delanteras de un arbusto: se dibujan delante de quien esté dentro.
class HojasDelante extends Node2D:
	func _draw() -> void:
		for p in [Vector2(-12, -30), Vector2(12, -30), Vector2(0, -26)]:
			draw_circle(p, 13.0, Color("2f6b3a", 0.92))
		draw_circle(Vector2(6, -34), 6.0, Color("3f8a4b", 0.9))


## Decorado: rocas y árboles colisionan en la base, como en los juegos cenitales;
## los arbustos se pueden atravesar. Rocas y arbustos sirven de escondite a una
## Gota pequeña (dentro del arbusto, o agachada junto a la roca).
class Decorado extends StaticBody2D:
	var tipo := "roca"
	## Distancia al centro para estar escondida (0 = no es escondite)
	var radio_escondite := 0.0

	func _ready() -> void:
		radio_escondite = {"roca": 42.0, "arbusto": 22.0, "arbol": 0.0}[tipo]
		if radio_escondite > 0.0:
			add_to_group("escondites")
		if tipo == "arbusto":
			# Se puede entrar en él; una capa de hojas delante tapa a quien esté dentro
			y_sort_enabled = true
			var hojas := HojasDelante.new()
			hojas.position.y = 16.0
			add_child(hojas)
			return
		var forma := CollisionShape2D.new()
		var circulo := CircleShape2D.new()
		circulo.radius = {"roca": 18.0, "arbol": 16.0}[tipo]
		forma.shape = circulo
		forma.position.y = -4.0
		add_child(forma)

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2(0, 0), 26.0, Color(0, 0, 0, 0.18))
		draw_set_transform(Vector2.ZERO)
		match tipo:
			"roca":
				draw_circle(Vector2(0, -12), 20.0, Color("6f7480"))
				draw_circle(Vector2(-5, -17), 12.0, Color("878c97"))
				draw_circle(Vector2(-8, -21), 4.0, Color("a3a8b2"))
			"arbusto":
				for p in [Vector2(-12, -14), Vector2(12, -14), Vector2(0, -24), Vector2(0, -10)]:
					draw_circle(p, 15.0, Color("2f6b3a"))
				draw_circle(Vector2(-4, -26), 7.0, Color("3f8a4b"))
			"arbol":
				draw_rect(Rect2(-8, -40, 16, 40), Color("5a3d2b"))
				for p in [Vector2(-22, -66), Vector2(22, -66), Vector2(0, -88), Vector2(0, -56)]:
					draw_circle(p, 30.0, Color("245a31"))
				draw_circle(Vector2(-10, -90), 13.0, Color("347a42"))


## Marcador de vida: 5 tramos (A-E), con la fuerza, el daño recibido y la racha.
class Marcador extends Control:
	var gota: Node
	var aviso := ""

	func _draw() -> void:
		if gota == null:
			return
		var ancho := 300.0
		var tramo := ancho / 5.0
		var origen := Vector2(16, size.y - 44)
		draw_rect(Rect2(origen - Vector2(6, 26), Vector2(560, 46)), Color(0, 0, 0, 0.35))
		var lleno: float = ancho * gota.vida / gota.vida_maxima
		draw_rect(Rect2(origen, Vector2(ancho, 12)), Color(1, 1, 1, 0.15))
		draw_rect(Rect2(origen, Vector2(lleno, 12)), Color("8fd0f0"))
		for i in 5:
			var x := origen.x + tramo * i
			if i > 0:
				draw_line(Vector2(x, origen.y - 2), Vector2(x, origen.y + 14), Color(1, 1, 1, 0.7), 2.0)
			var actual: bool = gota.letra_tamano() == gota.LETRAS_TAMANO[i]
			draw_string(ThemeDB.fallback_font, Vector2(x + tramo / 2 - 4, origen.y + 26),
					gota.LETRAS_TAMANO[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
					Color("ffffff") if actual else Color(1, 1, 1, 0.45))
		var vista := "ESCONDIDA" if gota.esta_escondida() else "te ven a ~%d px" % roundi(gota.distancia_deteccion(1.5))
		var texto := "Vida %d/%d · Tamaño %s · Fuerza ×%.2f · Daño ×%.2f · Racha %d s · %s" % [
				roundi(gota.vida), roundi(gota.vida_maxima), gota.letra_tamano(), gota.fuerza(),
				gota.dano_recibido(), roundi(gota.racha), vista]
		draw_string(ThemeDB.fallback_font, origen + Vector2(0, -8), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
		if aviso != "":
			draw_string(ThemeDB.fallback_font, Vector2(size.x / 2 - 150, size.y / 2 - 120), aviso,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 18)


var _marcador := Marcador.new()
var _aviso := ""
var _tiempo_aviso := 0.0
var _azar := RandomNumberGenerator.new()
var _tiempo_enemigos := 0.0


func _ready() -> void:
	y_sort_enabled = true
	_azar.randomize()
	_marcador.gota = $Gota
	_marcador.set_anchors_preset(Control.PRESET_FULL_RECT)
	_marcador.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Interfaz.add_child(_marcador)
	for i in ENEMIGOS:
		_poner_enemigo.call_deferred()
	# Elementos: las zonas de suelo van en una capa por debajo de los personajes
	# (en y = 0, como las huellas, para que se dibuje antes que todo lo que está en pie)
	var suelo := Node2D.new()
	add_child(suelo)
	move_child(suelo, 0)
	for datos in ELEMENTOS:
		var elemento := Elemento.new()
		elemento.tipo = datos[0]
		elemento.radio = datos[2]
		if datos[0] in Elemento.DE_SUELO:
			elemento.position = datos[1]
			suelo.add_child(elemento)
		else:
			elemento.position = datos[1]
			add_child(elemento)
	$Gota.reaparecio.connect(func(): _avisar("Has vuelto al último punto guardado"))
	var azar := RandomNumberGenerator.new()
	azar.seed = 7
	# Árboles en el borde de arriba y a los lados, el resto repartido
	for c in range(0, COLUMNAS, 2):
		_poner("arbol", Vector2(c * BALDOSA + 24, 125))
	for f in range(4, FILAS, 3):
		_poner("arbol", Vector2(30, f * BALDOSA))
		_poner("arbol", Vector2(COLUMNAS * BALDOSA - 30, f * BALDOSA))
	for i in 22:
		var pos := Vector2(azar.randf_range(120, COLUMNAS * BALDOSA - 120), azar.randf_range(180, FILAS * BALDOSA - 60))
		if absf(pos.y - _camino_y(pos.x)) < 70 or pos.distance_to(Vector2(760, 520)) < 120:
			continue
		_poner(["roca", "arbusto", "arbusto"][azar.randi() % 3], pos)
	# Paredes invisibles en los bordes
	var limites := StaticBody2D.new()
	add_child(limites)
	var ancho := COLUMNAS * BALDOSA
	var alto := FILAS * BALDOSA
	for r in [Rect2(-50, 0, 50, alto), Rect2(ancho, 0, 50, alto), Rect2(0, 80, ancho, 50), Rect2(0, alto, ancho, 50)]:
		var forma := CollisionShape2D.new()
		var caja := RectangleShape2D.new()
		caja.size = r.size
		forma.shape = caja
		forma.position = r.get_center()
		limites.add_child(forma)
	# La cámara sigue a Gota sin salirse del escenario
	var camara := Camera2D.new()
	camara.limit_left = 0
	camara.limit_top = 0
	camara.limit_right = ancho
	camara.limit_bottom = alto
	camara.position_smoothing_enabled = true
	$Gota.add_child(camara)


func _process(delta: float) -> void:
	var gota := $Gota
	$Interfaz/Ayuda.text = ("WASD/flechas: mover · Shift: correr · C/Ctrl: agachada · Espacio: saltar · "
			+ "Q: salto atrás · J: golpear · L: escupir (nivel 4)\n"
			+ "Enemigos de práctica: golpéalos o lánzales ácido; al morir sueltan almas que te hacen crecer\n"
			+ "Salta y agáchate en el aire: cae en picado y se hace charco (con más de media vida, con onda) · F7 onda: "
			+ gota.ESTILOS_ONDA[gota.estilo_onda] + "\n"
			+ "Pequeña (A o B) te escondes en los arbustos o agachada junto a las rocas; grande te ven de más lejos\n"
			+ "Fogata y sol te evaporan · el hielo te congela (pulsa botones para soltarte) · charcos y lluvia te dan vida"
			+ " · los manantiales guardan la partida\n"
			+ "Pruebas → ánimo: " + gota.nombre_animo + " (1-5 a mano, 0 automático) · K: recibir un golpe · F8 derrota: "
			+ gota.ESTILOS_DERROTA[gota.estilo_derrota]
			+ " · Z: descansar ya · F4 nivel de pelea: " + gota.NOMBRES_NIVEL[gota.nivel_pelea]
			+ " → combo " + " → ".join(gota.combo()).to_upper())
	_tiempo_aviso = maxf(0.0, _tiempo_aviso - delta)
	_marcador.aviso = _aviso if _tiempo_aviso > 0.0 else ""
	_marcador.queue_redraw()
	# Siempre hay unos cuantos enemigos de práctica
	_tiempo_enemigos += delta
	if _tiempo_enemigos > 2.0 and get_tree().get_nodes_in_group("enemigos").size() < ENEMIGOS:
		_tiempo_enemigos = 0.0
		_poner_enemigo()


func _avisar(texto: String) -> void:
	_aviso = texto
	_tiempo_aviso = 2.5


func _poner_enemigo() -> void:
	var gota := $Gota as Node2D
	for intento in 20:
		var pos := Vector2(_azar.randf_range(120, COLUMNAS * BALDOSA - 120),
				_azar.randf_range(220, FILAS * BALDOSA - 80))
		if pos.distance_to(gota.position) > 260.0:
			var enemigo := EnemigoPrueba.new()
			enemigo.tipo = ["debil", "normal", "normal", "peligroso"][_azar.randi() % 4]
			enemigo.position = pos
			add_child(enemigo)
			return


func _poner(tipo: String, pos: Vector2) -> void:
	var d := Decorado.new()
	d.tipo = tipo
	d.position = pos
	add_child(d)


func _camino_y(x: float) -> float:
	return 520.0 + 90.0 * sin(x / 260.0)


func _draw() -> void:
	# Hierba en damero suave
	for c in COLUMNAS:
		for f in FILAS:
			var tono := Color("4f8f4a") if (c + f) % 2 == 0 else Color("4a8946")
			draw_rect(Rect2(c * BALDOSA, f * BALDOSA, BALDOSA, BALDOSA), tono)
	# Camino de tierra
	var x := 0.0
	while x < COLUMNAS * BALDOSA:
		draw_circle(Vector2(x, _camino_y(x)), 34.0, Color("b49a6a"))
		x += 8.0
	# Flores y briznas
	var azar := RandomNumberGenerator.new()
	azar.seed = 3
	for i in 260:
		var p := Vector2(azar.randf_range(0, COLUMNAS * BALDOSA), azar.randf_range(0, FILAS * BALDOSA))
		if absf(p.y - _camino_y(p.x)) < 40:
			continue
		if i % 6 == 0:
			draw_circle(p, 3.0, [Color("e8d36a"), Color("e9eef2"), Color("d77a8c")][i % 3])
		else:
			draw_line(p, p + Vector2(2, -6), Color("3b7337"), 2.0)
