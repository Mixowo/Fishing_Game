## NPC.gd
## Molde base para todos los NPCs del juego.
##
## Estructura de nodos del NPC:
##   NPC (Node3D)  ← este script
##     ├── Mesh          (MeshInstance3D)
##     ├── AreaDeteccion (Area3D)
##     │     └── CollisionShape3D  (SphereShape3D ~3.0)
##     ├── PuntoMirada   (Marker3D)
##     └── LabelE        (Node3D)
##           ├── Circulo (MeshInstance3D con QuadMesh)
##           └── Letra   (Label3D)

extends Node3D

# ─── EXPORTS ─────────────────────────────────────────────────────────────────
@export var nombre_npc: String = "NPC"
@export var distancia_camara: float = 1.8

# ─── REFERENCIAS ─────────────────────────────────────────────────────────────
@onready var area_deteccion: Area3D = $AreaDeteccion
@onready var punto_mirada: Marker3D = $PuntoMirada
@onready var label_e: Node3D = $LabelE

# ─── ESTADO ──────────────────────────────────────────────────────────────────
var jugador_cerca: bool = false
var dialogando: bool = false
var jugador: CharacterBody3D = null
var camara_1ra: Camera3D = null
var camara_3ra: Camera3D = null
var anim_player: AnimationPlayer = null

# UI
var ui_dialogo: CanvasLayer = null
var label_dialogo: RichTextLabel = null
var panel_opciones: Control = null
var botones_opciones: Array = []
var _en_respuesta: bool = false

# Diálogos y opciones
var dialogos: Array[String] = ["..."]
var dialogo_index: int = 0
var opciones: Array = []

# ─── COLORES ─────────────────────────────────────────────────────────────────
const COLOR_FONDO     = Color(0.05, 0.05, 0.05, 0.75)  # negro semitransparente
const COLOR_PANEL     = Color(0.08, 0.08, 0.08, 0.85)  # negro un poco más opaco para el título
const COLOR_BORDE     = Color(0.0, 0.0, 0.0, 0.0)  # sin borde
const COLOR_TITULO    = Color(1.0, 0.92, 0.70, 1.0)    # amarillo cálido suave para el nombre
const COLOR_TEXTO     = Color(0.95, 0.95, 0.95, 1.0)   # blanco casi puro para el diálogo
const COLOR_HINT      = Color(1.0, 1.0, 1.0, 0.35)     # blanco muy transparente para el hint
const COLOR_BTN       = Color(0.12, 0.12, 0.12, 0.90)  # botón oscuro
const COLOR_BTN_HOVER = Color(0.25, 0.25, 0.25, 0.95)  # hover un poco más claro
const COLOR_BTN_BORDE = Color(1.0, 1.0, 1.0, 0.20)     # borde botón sutil

# ─── READY ───────────────────────────────────────────────────────────────────
func _ready():
	label_e.visible = false
	area_deteccion.body_entered.connect(_jugador_entro)
	area_deteccion.body_exited.connect(_jugador_salio)
	await get_tree().process_frame
	jugador = get_tree().root.find_child("CharacterBody3D", true, false) as CharacterBody3D
	if jugador:
		camara_1ra = jugador.get_node_or_null("Camara/Camera3D_1ra")
		camara_3ra = jugador.get_node_or_null("Camara/Camera3D_3ra")
		anim_player = jugador.get_node_or_null("MC/AnimationPlayer")


# ─── INPUT ───────────────────────────────────────────────────────────────────
func _input(event: InputEvent):
	if event.is_action_pressed("interactuar"):
		if jugador_cerca and not dialogando:
			iniciar_dialogo()
		elif dialogando and panel_opciones == null and not _en_respuesta:
			avanzar_dialogo()
		elif dialogando and _en_respuesta:
			_volver_a_opciones()


# ─── DETECCIÓN ───────────────────────────────────────────────────────────────
func _jugador_entro(cuerpo: Node3D):
	if not cuerpo is CharacterBody3D:
		return
	jugador_cerca = true
	label_e.visible = true

func _jugador_salio(cuerpo: Node3D):
	if not cuerpo is CharacterBody3D:
		return
	jugador_cerca = false
	label_e.visible = false
	if dialogando:
		cerrar_dialogo()


# ─── INICIAR DIÁLOGO ─────────────────────────────────────────────────────────
func iniciar_dialogo():
	label_e.visible = false
	dialogando = true
	dialogo_index = 0

	var dir = (jugador.global_position - global_position)
	dir.y = 0
	var angulo = atan2(dir.x, dir.z)
	var tween = create_tween()
	tween.tween_property(self, "rotation:y", angulo, 0.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if jugador.has_method("set"):
		jugador.set("reloj_activo", true)
		jugador.set_process_unhandled_input(false)
		jugador.set_process_input(false)

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_efecto_parpadeo(_activar_camara_dialogo)
	_crear_ui_dialogo()
	_mostrar_dialogo_actual()


# ─── CÁMARA ──────────────────────────────────────────────────────────────────
func _efecto_parpadeo(callback: Callable):
	var canvas = CanvasLayer.new()
	canvas.layer = 20
	var rect = ColorRect.new()
	rect.color = Color(0, 0, 0, 0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(rect)
	get_tree().current_scene.add_child(canvas)
	var tween = create_tween()
	tween.tween_property(rect, "color:a", 1.0, 0.08)
	tween.tween_callback(callback)
	tween.tween_property(rect, "color:a", 0.0, 0.12)
	tween.tween_callback(canvas.queue_free)

func _activar_camara_dialogo():
	if not camara_1ra or not jugador:
		return
	var armature = jugador.get_node_or_null("MC/Armature")
	if armature:
		armature.visible = false
	var dir_a_npc = (punto_mirada.global_position - jugador.global_position).normalized()
	var altura_ojos = jugador.global_position.y + 1.0
	var pos_camara = punto_mirada.global_position - dir_a_npc * distancia_camara
	pos_camara.y = altura_ojos
	camara_3ra.current = false
	camara_1ra.global_position = pos_camara
	camara_1ra.look_at(punto_mirada.global_position)
	
	# Desplazar cámara a la derecha para que el NPC quede a la izquierda
	camara_1ra.global_position += camara_1ra.global_transform.basis.x * 1.5

	# Hacer que el NPC mire hacia la cámara
	var dir_npc_a_cam = (camara_1ra.global_position - global_position)
	dir_npc_a_cam.y = 0
	var angulo_npc = atan2(dir_npc_a_cam.x, dir_npc_a_cam.z)
	var tween_npc = create_tween()
	tween_npc.tween_property(self, "rotation:y", angulo_npc, 0.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	camara_1ra.make_current()

func _desactivar_camara_dialogo():
	if not camara_3ra:
		return
	_efecto_parpadeo(func():
		camara_1ra.current = false
		camara_1ra.position = Vector3(-0.158, 0.59, 0.0)
		camara_1ra.rotation_degrees = Vector3(0, 0, 0)
		camara_3ra.position = Vector3(0, 1.848, 2.651)
		camara_3ra.rotation_degrees = Vector3(-26, 0, 0)
		camara_3ra.fov = 75.0
		camara_3ra.make_current()
		var pivot = jugador.get_node_or_null("Camara")
		if pivot:
			pivot.rotation_degrees = Vector3(0, 0, 0)
	)


# ─── HELPER ──────────────────────────────────────────────────────────────────
func _hacer_style(bg: Color, borde: Color, radio: int = 8, grosor: int = 1) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = radio
	s.corner_radius_top_right = radio
	s.corner_radius_bottom_left = radio
	s.corner_radius_bottom_right = radio
	s.border_width_top = grosor
	s.border_width_bottom = grosor
	s.border_width_left = grosor
	s.border_width_right = grosor
	s.border_color = borde
	return s


# ─── UI ──────────────────────────────────────────────────────────────────────
func _crear_ui_dialogo():
	ui_dialogo = CanvasLayer.new()
	ui_dialogo.layer = 10

	var panel_d = Panel.new()
	panel_d.anchor_left   = 1.0
	panel_d.anchor_top    = 0.5
	panel_d.anchor_right  = 1.0
	panel_d.anchor_bottom = 0.5
	panel_d.offset_left   = -300
	panel_d.offset_right  = -20
	panel_d.offset_top    = -140
	panel_d.offset_bottom = 140
	panel_d.add_theme_stylebox_override("panel", _hacer_style(COLOR_FONDO, COLOR_BORDE, 8, 0))

	# Franja título — redondeada arriba, cuadrada abajo
	var franja = Panel.new()
	franja.set_anchors_preset(Control.PRESET_TOP_WIDE)
	franja.offset_bottom = 28
	var style_franja = StyleBoxFlat.new()
	style_franja.bg_color = COLOR_PANEL
	style_franja.corner_radius_top_left = 8
	style_franja.corner_radius_top_right = 8
	style_franja.corner_radius_bottom_left = 0  # cuadrado abajo
	style_franja.corner_radius_bottom_right = 0
	franja.add_theme_stylebox_override("panel", style_franja)

	var lbl_nombre = Label.new()
	lbl_nombre.text = nombre_npc
	lbl_nombre.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_nombre.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_nombre.add_theme_color_override("font_color", COLOR_TITULO)
	lbl_nombre.add_theme_font_size_override("font_size", 20)
	franja.add_child(lbl_nombre)

	# Texto diálogo
	label_dialogo = RichTextLabel.new()
	label_dialogo.bbcode_enabled = true
	label_dialogo.set_anchors_preset(Control.PRESET_FULL_RECT)
	label_dialogo.offset_top    = 42
	label_dialogo.offset_left   = 18
	label_dialogo.offset_right  = -18
	label_dialogo.offset_bottom = -55  # espacio para botones abajo
	label_dialogo.scroll_active = false
	label_dialogo.add_theme_color_override("default_color", COLOR_TEXTO)
	label_dialogo.add_theme_font_size_override("normal_font_size", 16)

	# Zona inferior — aquí irán los botones o el hint
# Zona inferior pegada al borde
	var zona_inferior = HBoxContainer.new()
	zona_inferior.name = "ZonaInferior"
	zona_inferior.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	zona_inferior.offset_top    = -38
	zona_inferior.offset_bottom = 0
	zona_inferior.offset_left   = 0
	zona_inferior.offset_right  = 0
	zona_inferior.add_theme_constant_override("separation", 0)  # sin hueco entre botones

	# Hint por defecto cuando no hay opciones
	var lbl_hint = Label.new()
	lbl_hint.name = "HintLabel"
	lbl_hint.text = "[ E — Continuar ]"
	lbl_hint.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_hint.add_theme_color_override("font_color", COLOR_HINT)
	lbl_hint.add_theme_font_size_override("font_size", 13)
	zona_inferior.add_child(lbl_hint)

	panel_d.add_child(franja)
	panel_d.add_child(label_dialogo)
	panel_d.add_child(zona_inferior)
	ui_dialogo.add_child(panel_d)

	panel_opciones = null
	get_tree().current_scene.add_child(ui_dialogo)

	panel_d.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(panel_d, "modulate:a", 1.0, 0.22)


func _mostrar_dialogo_actual():
	if not label_dialogo:
		return
	if dialogo_index < dialogos.size():
		label_dialogo.text = dialogos[dialogo_index]


func avanzar_dialogo():
	dialogo_index += 1
	if dialogo_index >= dialogos.size():
		if opciones.size() > 0:
			_mostrar_opciones()
		else:
			cerrar_dialogo()
	else:
		_mostrar_dialogo_actual()


# ─── MENÚ DE OPCIONES ────────────────────────────────────────────────────────
func _mostrar_opciones():
	if not ui_dialogo:
		return
	if label_dialogo and dialogos.size() > 0:
		label_dialogo.text = dialogos[dialogos.size() - 1]
	var panel_principal = ui_dialogo.get_child(0)
	var zona = panel_principal.get_node_or_null("ZonaInferior")
	if not zona:
		return
	var hint = zona.get_node_or_null("HintLabel")
	if hint:
		hint.queue_free()
	panel_opciones = zona
	botones_opciones.clear()
	for i in opciones.size():
		var opcion = opciones[i]
		var btn = Button.new()
		btn.text = opcion["texto"]
		btn.custom_minimum_size = Vector2(0, 36)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 15)
		btn.add_theme_color_override("font_color", COLOR_TITULO)
		btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))

		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = COLOR_BTN
		btn_style.corner_radius_top_left = 0
		btn_style.corner_radius_top_right = 0
		# Solo redondear las esquinas exteriores
		btn_style.corner_radius_bottom_left = 8 if i == 0 else 0
		btn_style.corner_radius_bottom_right = 8 if i == opciones.size() - 1 else 0
		btn.add_theme_stylebox_override("normal", btn_style)

		var btn_hover = StyleBoxFlat.new()
		btn_hover.bg_color = COLOR_BTN_HOVER
		btn_hover.corner_radius_top_left = 0
		btn_hover.corner_radius_top_right = 0
		btn_hover.corner_radius_bottom_left = 8 if i == 0 else 0
		btn_hover.corner_radius_bottom_right = 8 if i == opciones.size() - 1 else 0
		btn.add_theme_stylebox_override("hover", btn_hover)
		btn.add_theme_stylebox_override("pressed", btn_hover)

		var idx = i
		btn.pressed.connect(func(): _opcion_seleccionada(idx))
		zona.add_child(btn)
		botones_opciones.append(btn)
	zona.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(zona, "modulate:a", 1.0, 0.18)


func _opcion_seleccionada(idx: int):
	if idx < 0 or idx >= opciones.size():
		return
	var opcion = opciones[idx]
	var es_salir = opcion.get("salir", false)

	if not es_salir:
		for i in botones_opciones.size():
			if not opciones[i].get("salir", false) and i != idx:
				botones_opciones[i].disabled = true
				botones_opciones[i].modulate.a = 0.35
		_en_respuesta = true

	if opcion.has("accion") and opcion["accion"].is_valid():
		opcion["accion"].call()


func _volver_a_opciones():
	_en_respuesta = false
	for i in botones_opciones.size():
		botones_opciones[i].disabled = false
		botones_opciones[i].modulate.a = 1.0
	if label_dialogo and dialogos.size() > 0:
		label_dialogo.text = dialogos[dialogos.size() - 1]


# ─── CERRAR DIÁLOGO ──────────────────────────────────────────────────────────
func cerrar_dialogo():
	dialogando = false
	panel_opciones = null
	_en_respuesta = false

	if ui_dialogo:
		ui_dialogo.queue_free()
		ui_dialogo = null
	label_dialogo = null

	if jugador:
		jugador.set("reloj_activo", false)
		jugador.set_process_unhandled_input(true)
		jugador.set_process_input(true)
		var armature = jugador.get_node_or_null("MC/Armature")
		if armature:
			armature.visible = true
	# Regresar NPC a mirar al jugador
	if jugador:
		var dir = (jugador.global_position - global_position)
		dir.y = 0
		var angulo = atan2(dir.x, dir.z)
		var tween_regreso = create_tween()
		tween_regreso.tween_property(self, "rotation:y", angulo, 0.2)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_desactivar_camara_dialogo()
	_al_cerrar_dialogo()


# ─── SOBREESCRIBIR ───────────────────────────────────────────────────────────
func _al_cerrar_dialogo():
	pass
