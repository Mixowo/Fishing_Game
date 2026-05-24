extends CanvasLayer

signal pesca_exitosa
signal pesca_fallida

# ─── PARÁMETROS DEL PEZ ──────────────────────────────────────────────────────
var puntos_objetivo: float = 100.0
var toques_fase2: int = 1
var velocidad: String = "medio"

var _bloqueando_input: bool = false

# ─── CONSTANTES ──────────────────────────────────────────────────────────────
const VELOCIDADES = {
	"lento":   { "indicador": 55.0,  "zona_ancho": 52.0, "aguja": 75.0  },
	"medio":   { "indicador": 95.0,  "zona_ancho": 38.0, "aguja": 115.0 },
	"rapido":  { "indicador": 145.0, "zona_ancho": 27.0, "aguja": 165.0 },
	"extremo": { "indicador": 195.0, "zona_ancho": 18.0, "aguja": 225.0 }
}

# ─── ESTADO ──────────────────────────────────────────────────────────────────
enum Fase { FASE1, FASE2, FASE3, TERMINADO }
var fase_actual: Fase = Fase.FASE1

var vel_zona: float = 0.0
var dir_zona: float = 1.0
var tiempo_cambio_zona: float = 0.0

var puntos_actuales: float = 0.0
var toques_restantes: int = 0

# Fase 1/3
var angulo_indicador: float = 90.0
var angulo_zona: float = 90.0
var presionado: bool = false
var vel_indicador: float = 95.0
var ancho_zona: float = 38.0
var tiempo_zona: float = 0.0

# Fase 2
var angulo_aguja: float = 0.0
var angulo_zona_f2: float = 90.0
var ancho_zona_f2: float = 28.0
var vel_aguja: float = 115.0
var dir_aguja: float = 1.0

var _tiempo_bloqueo: float = 0.0

# ─── NODOS ───────────────────────────────────────────────────────────────────
var dibujo: Control
var label_fase: Label
var label_puntos: Label

# ─── READY ───────────────────────────────────────────────────────────────────
func _ready():
	layer = 15

	var v = VELOCIDADES.get(velocidad, VELOCIDADES["medio"])
	vel_indicador = v["indicador"]
	ancho_zona    = v["zona_ancho"]
	vel_aguja     = v["aguja"]
	ancho_zona_f2 = v["zona_ancho"] * 0.65
	toques_restantes = toques_fase2

	# Nodo de dibujo centrado en pantalla arriba del jugador
	dibujo = Control.new()
	dibujo.set_anchors_preset(Control.PRESET_CENTER)
	dibujo.custom_minimum_size = Vector2(300, 220)
	dibujo.offset_left   = -150
	dibujo.offset_right  =  150
	dibujo.offset_top    = -200
	dibujo.offset_bottom =  200
	dibujo.draw.connect(_dibujar)
	add_child(dibujo)

	# Label fase
	label_fase = Label.new()
	label_fase.set_anchors_preset(Control.PRESET_CENTER)
	label_fase.offset_left   = -150
	label_fase.offset_right  =  150
	label_fase.offset_top    = -90
	label_fase.offset_bottom = -60
	label_fase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_fase.add_theme_color_override("font_color", Color(1, 0.92, 0.4, 1))
	label_fase.add_theme_font_size_override("font_size", 18)
	add_child(label_fase)

	# Label puntos
	label_puntos = Label.new()
	label_puntos.set_anchors_preset(Control.PRESET_CENTER)
	label_puntos.offset_left   = -150
	label_puntos.offset_right  =  150
	label_puntos.offset_top    = -64
	label_puntos.offset_bottom = -36
	label_puntos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_puntos.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	label_puntos.add_theme_font_size_override("font_size", 14)
	add_child(label_puntos)

	_iniciar_fase1()


# ─── PROCESS ─────────────────────────────────────────────────────────────────
func _process(delta):
	if fase_actual == Fase.TERMINADO:
		return
	if _tiempo_bloqueo > 0.0:
		_tiempo_bloqueo -= delta
		_bloqueando_input = _tiempo_bloqueo > 0.0

	dibujo.queue_redraw()
	tiempo_zona += delta

	match fase_actual:
		Fase.FASE1, Fase.FASE3:
			_procesar_fase1(delta)
		Fase.FASE2:
			_procesar_fase2(delta)


# ─── INPUT ───────────────────────────────────────────────────────────────────
func _input(event):
	if fase_actual == Fase.TERMINADO:
		return
	if _bloqueando_input:
		return

	if event is InputEventMouseButton:
		if fase_actual == Fase.FASE1 or fase_actual == Fase.FASE3:
			if event.button_index == MOUSE_BUTTON_LEFT:
				presionado = event.pressed
		elif fase_actual == Fase.FASE2:
			if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				_intentar_acierto_fase2()

	elif event is InputEventScreenTouch:
		if fase_actual == Fase.FASE1 or fase_actual == Fase.FASE3:
			presionado = event.pressed
		elif fase_actual == Fase.FASE2:
			if event.pressed:
				_intentar_acierto_fase2()

# ─── FASE 1 / 3 ──────────────────────────────────────────────────────────────
var _primer_inicio: bool = true

func _iniciar_fase1():
	fase_actual = Fase.FASE1
	presionado = false
	_nueva_zona()
	angulo_indicador = angulo_zona
	if _primer_inicio:
		puntos_actuales = puntos_objetivo * 0.5  # 2/4 al comenzar
		_primer_inicio = false
	label_fase.text = "¡Mantén el ritmo!"

func _iniciar_fase3():
	fase_actual = Fase.FASE3
	presionado = false
	_nueva_zona()
	angulo_indicador = angulo_zona
	puntos_actuales = puntos_objetivo * 0.25  # 1/4
	label_fase.text = "¡Último esfuerzo!"

func _procesar_fase1(delta):
	# Mover indicador según presionado
	if presionado:
		angulo_indicador += vel_indicador * delta
	else:
		angulo_indicador -= vel_indicador * delta
	angulo_indicador = clamp(angulo_indicador, 0.0, 180.0)

	# Zona verde se mueve suavemente
	tiempo_cambio_zona -= delta
	if tiempo_cambio_zona <= 0.0:
		dir_zona = 1.0 if randf() > 0.5 else -1.0
		vel_zona = randf_range(20.0, 60.0)
		tiempo_cambio_zona = randf_range(0.5, 1.8)

	angulo_zona += vel_zona * dir_zona * delta
	angulo_zona = clamp(angulo_zona, 15.0, 165.0)
	if angulo_zona <= 15.0 or angulo_zona >= 165.0:
		dir_zona *= -1.0

	# Puntos
	var dentro = abs(angulo_indicador - angulo_zona) <= ancho_zona / 2.0
	if dentro:
		puntos_actuales += 100.0 * delta   # +10 por segundo (x10 delta)
	else:
		puntos_actuales -= 100.0 * delta   # -10 por segundo

	puntos_actuales = clamp(puntos_actuales, 0.0, puntos_objetivo * 1.5)
	label_puntos.text = "%d / %d pts" % [int(puntos_actuales), int(puntos_objetivo)]

	# Condiciones de salida
	if puntos_actuales <= 0.0:
		if fase_actual == Fase.FASE1:
			_pez_escapo()
		else:
			# Fase 3 perdida → volver a Fase 2
			_iniciar_fase2()
	elif puntos_actuales >= puntos_objetivo:
		puntos_actuales = 0.0
		if fase_actual == Fase.FASE1:
			_iniciar_fase2()
		else:
			# Fase 3 completada → pescado!
			_pescado()


# ─── FASE 2 ──────────────────────────────────────────────────────────────────
func _iniciar_fase2():
	fase_actual = Fase.FASE2
	toques_restantes = toques_fase2
	angulo_aguja = 0.0
	dir_aguja = 1.0
	_nueva_zona_f2()
	label_fase.text = "¡Atrápalo!"
	label_puntos.text = "Toques: %d" % toques_restantes
	_bloqueando_input = true
	_tiempo_bloqueo = 0.5

func _procesar_fase2(delta):
	angulo_aguja += vel_aguja * delta * dir_aguja
	if angulo_aguja >= 180.0:
		angulo_aguja = 180.0
		dir_aguja = -1.0
	elif angulo_aguja <= 0.0:
		angulo_aguja = 0.0
		dir_aguja = 1.0
	label_puntos.text = "Toques: %d" % toques_restantes

func _intentar_acierto_fase2():
	var dentro = abs(angulo_aguja - angulo_zona_f2) <= ancho_zona_f2 / 2.0
	if dentro:
		toques_restantes -= 1
		label_puntos.text = "Toques: %d" % toques_restantes
		if toques_restantes <= 0:
			_iniciar_fase3()
		else:
			_nueva_zona_f2()
	else:
		puntos_actuales = puntos_objetivo * 0.75  # 3/4 al perder fase 2
		_iniciar_fase1()

# ─── HELPERS ─────────────────────────────────────────────────────────────────
func _nueva_zona():
	tiempo_zona = randf_range(0.0, TAU)  # fase aleatoria del seno
	var vel_zona: float = 0.0
	var dir_zona: float = 1.0
	var tiempo_cambio_zona: float = 0.0

func _nueva_zona_f2():
	angulo_zona_f2 = randf_range(25.0, 155.0)


# ─── FIN ─────────────────────────────────────────────────────────────────────
func _pez_escapo():
	fase_actual = Fase.TERMINADO
	label_fase.text = "¡Se escapó!"
	label_puntos.text = ""
	await get_tree().create_timer(1.2).timeout
	emit_signal("pesca_fallida")
	queue_free()

func _pescado():
	fase_actual = Fase.TERMINADO
	label_fase.text = "¡Pescado!"
	label_puntos.text = ""
	await get_tree().create_timer(0.8).timeout
	emit_signal("pesca_exitosa")
	queue_free()


# ─── DIBUJO ──────────────────────────────────────────────────────────────────
func _dibujar():
	var centro = Vector2(150, 160)
	var radio  = 100.0
	var grosor = 18.0

	# Fondo media luna
	_arco(centro, radio, grosor, Color(0.12, 0.12, 0.12, 0.88), 0.0, 180.0)

	match fase_actual:
		Fase.FASE1, Fase.FASE3:
			# Zona verde
			var zi = angulo_zona - ancho_zona / 2.0
			var zf = angulo_zona + ancho_zona / 2.0
			_arco(centro, radio, grosor, Color(0.25, 0.85, 0.35, 0.8), zi, zf)

			# Indicador blanco
			var rad = deg_to_rad(180.0 - angulo_indicador)
			var p = centro + Vector2(cos(rad), -sin(rad)) * radio
			dibujo.draw_circle(p, 11.0, Color(1, 1, 1, 1))

		Fase.FASE2:
			# Zona roja
			var zi = angulo_zona_f2 - ancho_zona_f2 / 2.0
			var zf = angulo_zona_f2 + ancho_zona_f2 / 2.0
			_arco(centro, radio, grosor, Color(0.9, 0.2, 0.15, 0.85), zi, zf)

			# Aguja amarilla
			var rad = deg_to_rad(180.0 - angulo_aguja)
			var p = centro + Vector2(cos(rad), -sin(rad)) * radio
			dibujo.draw_circle(p, 11.0, Color(1, 0.9, 0.05, 1))


func _arco(centro: Vector2, radio: float, grosor: float, color: Color, a_ini: float, a_fin: float):
	var segs = 48
	var prev: Vector2
	for i in range(segs + 1):
		var t   = float(i) / float(segs)
		var ang = deg_to_rad(180.0 - lerp(a_ini, a_fin, t))
		var p   = centro + Vector2(cos(ang), -sin(ang)) * radio
		if i > 0:
			dibujo.draw_line(prev, p, color, grosor, true)
		prev = p
