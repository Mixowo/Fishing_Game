## CañaPesca.gd
## Adjunta este script al nodo raíz de la caña (Node3D o MeshInstance3D).
## La caña debe ser hija del jugador (o del hueso de la mano en el Skeleton3D).
##
## Estructura de nodos sugerida dentro de la caña:
##   CañaPesca (Node3D)  ← este script
##     ├── MeshCaña      (MeshInstance3D)
##     ├── PuntaCaña     (Marker3D) ← desde aquí sale la línea y el bobber
##     └── LineaRenderer (Node3D + MeshInstance3D con ImmediateMesh) ← opcional visual

extends Node3D

# ─── SEÑALES ────────────────────────────────────────────────────────────────
signal pesca_completada(nombre_pez: String)

# ─── EXPORTS (asigna en el Inspector) ────────────────────────────────────────
@export var bobber_scene: PackedScene        ## Escena del flotador (Bobber.tscn)
@export var pez_scene: PackedScene           ## Escena del pez 3D (Pez.tscn)
@export var distancia_lanzamiento: float = 12.0
@export var capa_agua: int = 2              ## Layer de física del agua (ajusta al tuyo)

# ─── REFERENCIAS ─────────────────────────────────────────────────────────────
@onready var punta_caña : Marker3D = $"../Armature/Skeleton3D/mano_izq_001/PuntaCaña" # usa la posición de la propia caña
var linea: MeshInstance3D
@onready var linea_mesh: MeshInstance3D = null   # puede ser null si no tienes visual
@onready var anim_player: AnimationPlayer = $"../AnimationPlayer" 
var _revisando_caida: bool = false

# ─── ESTADO ──────────────────────────────────────────────────────────────────
enum Estado { GUARDADA, LANZANDO, ESPERANDO, PIQUE, MINIJUEGO, RECOGIENDO }
var estado: Estado = Estado.GUARDADA

var tipo_agua_actual: GestoMundo.TipoAgua = GestoMundo.TipoAgua.MAR

var bobber_instance: Node3D = null
var jugador: CharacterBody3D

# Agrega esta variable arriba con las demás
var bobber_en_agua: bool = false

# UI del minijuego (se crea en tiempo de ejecución)
var ui_minijuego: CanvasLayer = null

# ─── READY ───────────────────────────────────────────────────────────────────
func _ready():
	jugador = get_parent().get_parent() as CharacterBody3D
	visible = true
	# Crear la cuerda
	linea = MeshInstance3D.new()
	linea.mesh = ImmediateMesh.new()
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color("4a2800")  # color café de cuerda
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	linea.material_override = mat
	add_child(linea)
	
func _process(delta):
	_dibujar_cuerda()
	if not _revisando_caida or not bobber_instance:
		return

	var aguas = get_tree().get_nodes_in_group("agua")
	for agua in aguas:
		if agua is Area3D:
			var vel = bobber_instance.linear_velocity if bobber_instance is RigidBody3D else Vector3.ZERO
			if vel.y < 0 and _punto_dentro_de_area(bobber_instance.global_position, agua):
				_revisando_caida = false
				bobber_en_agua = true

				if agua.is_in_group("agua_lago"):
					tipo_agua_actual = GestoMundo.TipoAgua.LAGO
				elif agua.is_in_group("agua_alta_mar"):
					tipo_agua_actual = GestoMundo.TipoAgua.ALTA_MAR
				else:
					tipo_agua_actual = GestoMundo.TipoAgua.MAR

				# Detener el tween y anclar el bobber en la superficie
				bobber_instance.global_position.y = agua.global_position.y + 0.1
				_al_caer_al_agua("")
				return

func _dibujar_cuerda():
	var mesh = linea.mesh as ImmediateMesh
	mesh.clear_surfaces()
	
	if not is_instance_valid(bobber_instance):
		return
	
	var punto_inicio = punta_caña.global_position
	var punto_fin = bobber_instance.global_position
	var segmentos = 20  # más segmentos = más suave
	var caida = 1.5     # cuánto cuelga en el medio
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	for i in range(segmentos + 1):
		var t = float(i) / float(segmentos)
		# Interpolación lineal entre inicio y fin
		var punto = punto_inicio.lerp(punto_fin, t)
		# Curva catenaria: baja en el medio y sube en los extremos
		var cuelgue = caida * sin(t * PI)
		punto.y -= cuelgue
		mesh.surface_add_vertex(to_local(punto))
	
	mesh.surface_end()
	
# ─── INPUT ───────────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent):
	if not visible:
		return
	
	if jugador and jugador.get("reloj_activo") == true:
		return

	if event.is_action_pressed("pescar"):
		match estado:
			Estado.GUARDADA:
				if not is_instance_valid(bobber_instance):
					lanzar_caña()
			Estado.ESPERANDO, Estado.PIQUE:
				recoger_sin_pez()
			_:
				pass

# ─── LANZAR ──────────────────────────────────────────────────────────────────
func lanzar_caña():
	estado = Estado.LANZANDO

	if anim_player and anim_player.has_animation("PESCAR"):
		anim_player.play("PESCAR", 0.3)

	var origen: Vector3 = punta_caña.global_position
	var destino: Vector3 = jugador.global_position + (-jugador.transform.basis.z * distancia_lanzamiento)

	if bobber_scene:
		bobber_instance = bobber_scene.instantiate()
		get_tree().current_scene.add_child(bobber_instance)
		bobber_instance.global_position = origen
		bobber_instance.visible = true

		if bobber_instance.has_method("lanzar"):
			bobber_instance.lanzar(origen, destino)

		# Escuchar señal de cuando toca agua
		bobber_instance.cayo_en_agua.connect(_al_caer_al_agua)
		bobber_instance.cayo_en_tierra.connect(recoger_sin_pez)
		_revisando_caida = false  # ya no usamos _process para esto
	else:
		_al_caer_al_agua("")

# ─── AL CAER AL AGUA ─────────────────────────────────────────────────────────
func _al_caer_al_agua(tipo: String):
	estado = Estado.ESPERANDO

	match tipo:
		"lago":
			tipo_agua_actual = GestoMundo.TipoAgua.LAGO
		"alta_mar":
			tipo_agua_actual = GestoMundo.TipoAgua.ALTA_MAR
		_:
			tipo_agua_actual = GestoMundo.TipoAgua.MAR

	if bobber_instance and bobber_instance.has_method("animar_pique"):
		bobber_instance.pique.connect(_al_picar)

	var espera = randf_range(3.0, 10.0)
	get_tree().create_timer(espera).timeout.connect(_provocar_pique)


# ─── PIQUE ───────────────────────────────────────────────────────────────────
func _provocar_pique():
	if estado != Estado.ESPERANDO:
		return
	estado = Estado.PIQUE

	if bobber_instance and bobber_instance.has_method("animar_pique"):
		bobber_instance.animar_pique()

	# Pequeño delay para que el jugador vea hundirse el bobber antes del minijuego
	await get_tree().create_timer(0.5).timeout
	_iniciar_minijuego()


func _al_picar():  # Señal directa del bobber si lo necesitas
	_provocar_pique()


# ─── MINIJUEGO ───────────────────────────────────────────────────────────────
func _iniciar_minijuego():
	if estado != Estado.PIQUE:
		return
	estado = Estado.MINIJUEGO
	
	# Liberar el mouse para poder clickear el botón
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	ui_minijuego = _crear_ui_minijuego()
	get_tree().current_scene.add_child(ui_minijuego)


func _crear_ui_minijuego() -> CanvasLayer:
	## Panel centrado con un botón "¡JALAR!" pulsable
	var canvas = CanvasLayer.new()
	canvas.layer = 10

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(260, 140)
	panel.position = Vector2(-130, -70)

	# Fondo semitransparente
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.1, 0.2, 0.85)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	panel.add_theme_stylebox_override("panel", style)

	var label = Label.new()
	label.text = "¡Pique!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label.position = Vector2(0, 18)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color("ffe066"))

	var boton = Button.new()
	boton.text = "¡JALAR!"
	boton.set_anchors_preset(Control.PRESET_CENTER)
	boton.custom_minimum_size = Vector2(160, 55)
	boton.position = Vector2(-80, 10)
	boton.add_theme_font_size_override("font_size", 20)

	# Estilo del botón
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color("e84040")
	btn_style.corner_radius_top_left = 10
	btn_style.corner_radius_top_right = 10
	btn_style.corner_radius_bottom_left = 10
	btn_style.corner_radius_bottom_right = 10
	boton.add_theme_stylebox_override("normal", btn_style)

	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = Color("ff6060")
	btn_hover.corner_radius_top_left = 10
	btn_hover.corner_radius_top_right = 10
	btn_hover.corner_radius_bottom_left = 10
	btn_hover.corner_radius_bottom_right = 10
	boton.add_theme_stylebox_override("hover", btn_hover)

	boton.pressed.connect(_minijuego_exitoso)

	panel.add_child(label)
	panel.add_child(boton)
	canvas.add_child(panel)

	# Auto-destruir si el jugador no pulsa en 3 segundos
	get_tree().create_timer(3.0).timeout.connect(_minijuego_fallido)

	return canvas


func _minijuego_exitoso():
	if estado != Estado.MINIJUEGO:
		return
	_cerrar_ui_minijuego()
	_pescar_pez()


func _minijuego_fallido():
	if estado != Estado.MINIJUEGO:
		return
	_cerrar_ui_minijuego()
	recoger_sin_pez()


func _cerrar_ui_minijuego():
	if ui_minijuego:
		ui_minijuego.queue_free()
		ui_minijuego = null
	
	# Volver a capturar el mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# ─── PESCAR PEZ ──────────────────────────────────────────────────────────────
func _pescar_pez():
	estado = Estado.RECOGIENDO

	# Quitar bobber
	if bobber_instance:
		var pos_pez = bobber_instance.global_position
		bobber_instance.queue_free()
		bobber_instance = null

		# Instanciar pez y animarlo volando hacia el jugador
		if pez_scene:
			var pez = pez_scene.instantiate()
			get_tree().current_scene.add_child(pez)
			pez.global_position = pos_pez

			if pez.has_method("volar_hacia"):
				pez.volar_hacia(jugador.global_position, _al_terminar_pesca)
			else:
				_animar_pez_manual(pez, pos_pez)
		else:
			push_warning("CañaPesca: Asigna pez_scene en el Inspector.")
			_al_terminar_pesca("Pez desconocido")
	else:
		_al_terminar_pesca("Pez desconocido")


func _animar_pez_manual(pez: Node3D, desde: Vector3):
	## Animación manual si el pez no tiene el método volar_hacia:
	## vuela hacia el jugador y se hace pequeño hasta desaparecer
	var destino = jugador.global_position + Vector3.UP * 1.0
	var duracion = 1.2

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(pez, "global_position", destino, duracion)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(pez, "scale", Vector3(0.05, 0.05, 0.05), duracion)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tween.set_parallel(false)
	tween.tween_callback(pez.queue_free)
	tween.tween_callback(_al_terminar_pesca.bind("Pez"))


func _al_terminar_pesca(_nombre: String = ""):
	var pez_data = GestoMundo.get_pez_disponible(tipo_agua_actual)
	estado = Estado.GUARDADA
	GestoMundo.dinero_actual += pez_data.valor
	pesca_completada.emit(pez_data.nombre)
	print("¡Pescaste: ", pez_data.nombre, " — $", pez_data.valor, "!")

	if anim_player and anim_player.has_animation("IDLE1"):
		anim_player.stop()
		anim_player.play("IDLE1", 0.3)


# ─── RECOGER SIN PEZ ─────────────────────────────────────────────────────────
func recoger_sin_pez():
	estado = Estado.GUARDADA
	_cerrar_ui_minijuego()

	if bobber_instance:
		# Animar bobber volviendo hacia la caña
		var tween = create_tween()
		tween.tween_property(bobber_instance, "global_position", punta_caña.global_position, 0.4)\
			.set_trans(Tween.TRANS_SINE)
		tween.tween_callback(func():
			if bobber_instance:
				bobber_instance.queue_free()
				bobber_instance = null
		)
	if anim_player and anim_player.has_animation("IDLE1"):
		anim_player.stop()
		anim_player.play("IDLE1", 0.3)
		
func _verificar_si_cayo_en_agua():
	if not bobber_instance:
		return

	# Revisar si el bobber está dentro de algún Area3D del grupo "agua"
	var aguas = get_tree().get_nodes_in_group("agua")
	bobber_en_agua = false

	for agua in aguas:
		if agua is Area3D:
			var cuerpos = agua.get_overlapping_bodies()
			var areas = agua.get_overlapping_areas()
			# El bobber es Node3D puro, usamos distancia a la caja
			var bounds = _punto_dentro_de_area(bobber_instance.global_position, agua)
			if bounds:
				bobber_en_agua = true
				# Detectar tipo
				if agua.is_in_group("agua_lago"):
					tipo_agua_actual = GestoMundo.TipoAgua.LAGO
				elif agua.is_in_group("agua_alta_mar"):
					tipo_agua_actual = GestoMundo.TipoAgua.ALTA_MAR
				else:
					tipo_agua_actual = GestoMundo.TipoAgua.MAR
				# Ajustar Y del bobber a la superficie del agua
				bobber_instance.global_position.y = agua.global_position.y + 0.1
				_al_caer_al_agua("")
				return

	# Cayó en tierra — recoger sin pescar
	print("El anzuelo cayó en tierra.")
	recoger_sin_pez()


func _punto_dentro_de_area(punto: Vector3, area: Area3D) -> bool:
	for hijo in area.get_children():
		if hijo is CollisionShape3D:
			if hijo.shape is BoxShape3D:
				var shape: BoxShape3D = hijo.shape
				var local_pos = area.to_local(punto)
				var mitad = shape.size / 2.0
				if (abs(local_pos.x) <= mitad.x and
					abs(local_pos.z) <= mitad.z and
					local_pos.y <= mitad.y + 15.0 and
					local_pos.y >= -mitad.y - 15.0):
					return true
			elif hijo.shape is WorldBoundaryShape3D:
				# Plano infinito — solo checar Y
				var y_area = area.global_position.y
				if punto.y <= y_area + 1.0 and punto.y >= y_area - 2.0:
					return true
	return false
