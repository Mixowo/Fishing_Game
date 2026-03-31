extends CharacterBody3D

const SPEED = 10
const JUMP_VELOCITY = 10
const SENSITIVITY = 0.003
const SPRINT_SPEED = 18
const ANIM_SPEED_WALK = 1.0
const ANIM_SPEED_RUN = 2
const FOV_WALK = 75.0
const FOV_RUN = 85.0
const FOV_LERP_SPEED = 5.0
const MAX_ENERGIA_LUZ = 0.5

var sensibilidad_tactil = 0.2
var joystick: Node
var color_brazo_dia = Color("ffffff")
var color_brazo_noche = Color("595e7aff")
var oscuridad_actual = 1.0
var reloj_activo = false

var caña = get_node_or_null("MC/CañaPesca")
var pescando = caña and caña.visible and caña.estado != caña.Estado.GUARDADA

@onready var farola_luz = $MC/FarolaMesh/FarolaLuz
@onready var anim = $MC/AnimationPlayer
@onready var pivot = $Camara
@onready var cam_3ra = $Camara/Camera3D_3ra
@onready var cam_1ra = $Camara/Camera3D_1ra
@onready var visual = $CanvasLayer/InterfazReloj/Visual
@onready var label_hora = $CanvasLayer/InterfazReloj/Visual/LabelHora
@onready var label_dinero = $CanvasLayer/InterfazReloj/Visual/LabelDinero


func _ready():
	if get_tree().current_scene.name == "MenuPrincipal":
		self.visible = false
		set_process(false)
		set_physics_process(false)
	else:
		self.visible = true
		set_process(true)
		set_physics_process(true)

	var alto_pantalla = get_viewport().get_visible_rect().size.y
	visual.position.y = alto_pantalla
	cam_3ra.make_current()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	joystick = get_tree().root.find_child("Virtual Joystick", true, false)


func _unhandled_input(event):
	if reloj_activo:
		return

	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		var multiplier = SENSITIVITY
		if event is InputEventScreenDrag:
			multiplier *= 0.5
		rotate_y(-event.relative.x * multiplier)
		pivot.rotation.x = 0

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()
		if event.keycode == KEY_F11:
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _physics_process(delta):
	if reloj_activo:
		velocity = Vector3.ZERO
		if anim.current_animation != "IDLE1":
			anim.play("IDLE1", 0.3)
		move_and_slide()
		return

	var caña = get_node_or_null("MC/CañaPesca")
	var pescando = caña != null and caña.visible and caña.estado != caña.Estado.GUARDADA

	if pescando:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("mover_izquierda", "mover_derecha", "mover_adelante", "mover_atras")

	var joystick_fuerza = 0.0
	if joystick:
		var joy_output = joystick.output
		if joy_output.length() > 0:
			input_dir = joy_output
			joystick_fuerza = joy_output.length()

	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var esta_corriendo = (Input.is_action_pressed("correr") or joystick_fuerza > 0.9) and direction != Vector3.ZERO
	var velocidad_actual = SPRINT_SPEED if esta_corriendo else SPEED

	if direction:
		velocity.x = direction.x * velocidad_actual
		velocity.z = direction.z * velocidad_actual
		if anim.current_animation != "CAMINAR":
			anim.play("CAMINAR", 0.2)
		anim.speed_scale = ANIM_SPEED_RUN if esta_corriendo else ANIM_SPEED_WALK
		set_efectos_correr(esta_corriendo)
	else:
		velocity.x = move_toward(velocity.x, 0, velocidad_actual)
		velocity.z = move_toward(velocity.z, 0, velocidad_actual)
		set_efectos_correr(false)
		anim.speed_scale = ANIM_SPEED_WALK
		if anim.current_animation != "IDLE1":
			anim.play("IDLE1", 0.3)

	var fov_objetivo = FOV_RUN if esta_corriendo else FOV_WALK
	cam_3ra.fov = lerp(cam_3ra.fov, fov_objetivo, delta * FOV_LERP_SPEED)
	move_and_slide()


func _input(event):
	if not reloj_activo:
		if event is InputEventScreenDrag:
			if event.position.x > get_viewport().size.x / 2:
				rotate_y(deg_to_rad(-event.relative.x * sensibilidad_tactil))
				pivot.rotate_x(deg_to_rad(-event.relative.y * sensibilidad_tactil))
				pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(0), deg_to_rad(60))

	if event.is_action_pressed("ver_reloj"):
		alternar_reloj()


func alternar_reloj():
	reloj_activo = !reloj_activo

	var alto_pantalla = get_viewport().get_visible_rect().size.y
	var pos_oculto = alto_pantalla
	var pos_visible = alto_pantalla - 380
	var tween = create_tween()

	if reloj_activo:
		cam_3ra.current = false
		cam_1ra.make_current()
		cam_1ra.rotation_degrees.x = 0

		tween.set_parallel(true)
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(cam_1ra, "rotation_degrees:x", -45.0, 0.5)
		tween.tween_property(visual, "position:y", pos_visible, 0.5)
		tween.tween_property(cam_1ra, "fov", 60.0, 0.5)
	else:
		cam_3ra.global_transform = cam_1ra.global_transform
		cam_3ra.make_current()

		var pos_original_3ra = Vector3(0, 1.848, 2.651)
		var rot_original_3ra = Vector3(-26, 0, 0)

		tween.set_parallel(true)
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(cam_3ra, "rotation_degrees", rot_original_3ra, 0.4)
		tween.tween_property(visual, "position:y", pos_oculto, 0.4)
		tween.tween_property(cam_3ra, "fov", 75.0, 0.4)

		tween.set_parallel(false)
		tween.tween_property(cam_3ra, "position", pos_original_3ra, 0.6)
		tween.finished.connect(func():
			cam_3ra.position = pos_original_3ra
			cam_3ra.rotation_degrees = rot_original_3ra
		)


func _process(_delta):
	actualizar_interfaz()
	if reloj_activo:
		visual.position.y += sin(Time.get_ticks_msec() * 0.002) * 0.1


func actualizar_interfaz():
	var h = GestoMundo.hora_actual
	var m = int((h - int(h)) * 60)

	label_hora.text = "%02d:%02d" % [int(h), m]
	label_dinero.text = "$ " + str(GestoMundo.dinero_actual)

	if h > 6.0 and h < 15.0:
		oscuridad_actual = 1.0
	elif h >= 15.0 and h < 18.0:
		oscuridad_actual = 1.0 - ((h - 18.0) / 2.0)
	elif h >= 5.0 and h < 6.0:
		oscuridad_actual = (h - 5.0) / 1.0
	else:
		oscuridad_actual = 0.0

	var color_final = color_brazo_noche.lerp(color_brazo_dia, oscuridad_actual)
	visual.self_modulate = color_final

	label_hora.modulate = Color("e8ffbe")
	label_dinero.modulate = Color("e8ffbe")

	var transparencia_noche = lerp(0.2, 1.0, oscuridad_actual)
	var nuevo_color = Color(1, 1, 1, transparencia_noche)

	for nodo in get_tree().get_nodes_in_group("efectos_correr"):
		if nodo is GPUParticles3D:
			var material_particula = nodo.draw_pass_1.material
			if material_particula:
				material_particula.albedo_color = nuevo_color

	var energia_deseada = (1.0 - oscuridad_actual) * MAX_ENERGIA_LUZ
	farola_luz.light_energy = energia_deseada
	farola_luz.visible = energia_deseada > 0.05


func set_efectos_correr(activar: bool):
	get_tree().call_group("efectos_correr", "set_emitting", activar)
