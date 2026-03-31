## NPC.gd
## Molde base para todos los NPCs del juego.
## Extiende este script en cada NPC específico.
##
## Estructura de nodos del NPC:
##   NPC (Node3D)  ← este script
##     ├── Mesh          (MeshInstance3D) — modelo del NPC
##     ├── AreaDeteccion (Area3D)         — detecta al jugador cerca
##     │     └── CollisionShape3D        — radio de detección (SphereShape3D ~3.0)
##     └── PuntoMirada   (Marker3D)      — punto donde mirará la cámara (altura de los ojos)

extends Node3D

# ─── EXPORTS ─────────────────────────────────────────────────────────────────
@export var nombre_npc: String = "NPC"
@export var distancia_camara: float = 1.8   ## Qué tan cerca queda la cámara del NPC

# ─── REFERENCIAS ─────────────────────────────────────────────────────────────
@onready var area_deteccion: Area3D = $AreaDeteccion
@onready var punto_mirada: Marker3D = $PuntoMirada

# ─── ESTADO ──────────────────────────────────────────────────────────────────
var jugador_cerca: bool = false
var dialogando: bool = false
var jugador: CharacterBody3D = null
var camara_1ra: Camera3D = null
var camara_3ra: Camera3D = null
var anim_player: AnimationPlayer = null

# UI generada en runtime
var ui_boton: CanvasLayer = null
var ui_dialogo: CanvasLayer = null
var label_dialogo: RichTextLabel = null

# Diálogos — sobreescribir en cada NPC
var dialogos: Array[String] = ["..."]
var dialogo_index: int = 0

# ─── READY ───────────────────────────────────────────────────────────────────
func _ready():
	area_deteccion.body_entered.connect(_jugador_entro)
	area_deteccion.body_exited.connect(_jugador_salio)
	await get_tree().process_frame
	jugador = get_tree().root.find_child("CharacterBody3D", true, false) as CharacterBody3D
	if jugador:
		camara_1ra = jugador.get_node_or_null("Camara/Camera3D_1ra")
		camara_3ra = jugador.get_node_or_null("Camara/Camera3D_3ra")
		anim_player = jugador.get_node_or_null("MC/AnimationPlayer")


# ─── INPUT ───────────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("interactuar"):
		if jugador_cerca and not dialogando:
			iniciar_dialogo()
		elif dialogando:
			avanzar_dialogo()


# ─── DETECCIÓN DE JUGADOR ────────────────────────────────────────────────────
func _jugador_entro(cuerpo: Node3D):
	if not cuerpo is CharacterBody3D:
		return
	jugador_cerca = true
	_mostrar_boton_interaccion()


func _jugador_salio(cuerpo: Node3D):
	if not cuerpo is CharacterBody3D:
		return
	jugador_cerca = false
	_ocultar_boton_interaccion()
	if dialogando:
		cerrar_dialogo()


# ─── BOTÓN DE INTERACCIÓN ────────────────────────────────────────────────────
func _mostrar_boton_interaccion():
	if ui_boton:
		return
	ui_boton = CanvasLayer.new()
	ui_boton.layer = 5

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.custom_minimum_size = Vector2(200, 50)
	panel.position = Vector2(-100, -120)
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.7)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)

	var label = Label.new()
	label.text = "E — Hablar con " + nombre_npc
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_color_override("font_color", Color("ffe066"))
	label.add_theme_font_size_override("font_size", 16)

	panel.add_child(label)
	ui_boton.add_child(panel)
	get_tree().current_scene.add_child(ui_boton)

	# Animación de entrada
	panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)


func _ocultar_boton_interaccion():
	if ui_boton:
		ui_boton.queue_free()
		ui_boton = null


# ─── INICIAR DIÁLOGO ─────────────────────────────────────────────────────────
func iniciar_dialogo():
	dialogando = true
	dialogo_index = 0
	_ocultar_boton_interaccion()

	# Bloquear movimiento del jugador
	var script_jugador = jugador.get_script()
	if jugador.has_method("set") :
		jugador.set("reloj_activo", true)
		jugador.set_process_unhandled_input(false)
		jugador.set_process_input(false)

	# Activar mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Efecto parpadeo → cambio de cámara
	_efecto_parpadeo(_activar_camara_dialogo)

	# Crear UI de diálogo
	_crear_ui_dialogo()
	_mostrar_dialogo_actual()


func _efecto_parpadeo(callback: Callable):
	## Parpadeo rápido negro → cambia cámara en el medio → desaparece
	var canvas = CanvasLayer.new()
	canvas.layer = 20
	var rect = ColorRect.new()
	rect.color = Color(0, 0, 0, 0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(rect)
	get_tree().current_scene.add_child(canvas)

	var tween = create_tween()
	tween.tween_property(rect, "color:a", 1.0, 0.08)  # oscurece rápido
	tween.tween_callback(callback)                      # cambia cámara en negro
	tween.tween_property(rect, "color:a", 0.0, 0.12)  # aclara
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

# ─── UI DE DIÁLOGO ───────────────────────────────────────────────────────────
func _crear_ui_dialogo():
	ui_dialogo = CanvasLayer.new()
	ui_dialogo.layer = 10

	# Panel fondo
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.custom_minimum_size = Vector2(0, 150)
	panel.offset_top = -160
	panel.offset_bottom = -10
	panel.offset_left = 20
	panel.offset_right = -20

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.05, 0.1, 0.92)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color("ffe066aa")
	panel.add_theme_stylebox_override("panel", style)

	# Nombre del NPC
	var label_nombre = Label.new()
	label_nombre.text = nombre_npc
	label_nombre.position = Vector2(20, 12)
	label_nombre.add_theme_color_override("font_color", Color("ffe066"))
	label_nombre.add_theme_font_size_override("font_size", 18)

	# Texto del diálogo
	label_dialogo = RichTextLabel.new()
	label_dialogo.bbcode_enabled = true
	label_dialogo.set_anchors_preset(Control.PRESET_FULL_RECT)
	label_dialogo.offset_top = 40
	label_dialogo.offset_left = 20
	label_dialogo.offset_right = -20
	label_dialogo.offset_bottom = -35
	label_dialogo.add_theme_color_override("default_color", Color("e8f4ff"))
	label_dialogo.add_theme_font_size_override("normal_font_size", 16)
	label_dialogo.scroll_active = false

	# Indicador "continuar"
	var label_continuar = Label.new()
	label_continuar.text = "[ E — Continuar ]"
	label_continuar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	label_continuar.offset_left = -180
	label_continuar.offset_top = -28
	label_continuar.add_theme_color_override("font_color", Color("ffffff66"))
	label_continuar.add_theme_font_size_override("font_size", 13)

	panel.add_child(label_nombre)
	panel.add_child(label_dialogo)
	panel.add_child(label_continuar)
	ui_dialogo.add_child(panel)
	get_tree().current_scene.add_child(ui_dialogo)

	# Animación entrada
	panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.25)

func _mostrar_dialogo_actual():
	if not label_dialogo:
		return
	if dialogo_index < dialogos.size():
		label_dialogo.text = dialogos[dialogo_index]
	
func avanzar_dialogo():
	dialogo_index += 1
	if dialogo_index >= dialogos.size():
		cerrar_dialogo()
	else:
		_mostrar_dialogo_actual()

# ─── CERRAR DIÁLOGO ──────────────────────────────────────────────────────────
func cerrar_dialogo():
	dialogando = false
	if ui_dialogo:
		ui_dialogo.queue_free()
		ui_dialogo = null
	if jugador:
		jugador.set("reloj_activo", false)
		jugador.set_process_unhandled_input(true)
		jugador.set_process_input(true)
		var armature = jugador.get_node_or_null("MC/Armature")
		if armature:
			armature.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_desactivar_camara_dialogo()
	_al_cerrar_dialogo()

# ─── MÉTODOS A SOBREESCRIBIR EN CADA NPC ─────────────────────────────────────
func _al_cerrar_dialogo():
	pass  ## Sobreescribir en cada NPC para lógica específica
