extends RigidBody3D

signal pique
signal cayo_en_agua(tipo_agua: String)
signal cayo_en_tierra

var flotando: bool = false
var picando: bool = false
var y_base: float = 0.0
var tiempo_bob: float = 0.0

@export var amplitud_bob: float = 0.08
@export var velocidad_bob: float = 2.0
@export var profundidad_pique: float = 0.35

func _ready():
	gravity_scale = 2.0
	freeze = false
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_al_tocar_algo)
	await get_tree().process_frame
	var aguas = get_tree().get_nodes_in_group("agua")
	for agua in aguas:
		if agua is Area3D:
			if not agua.body_entered.is_connected(_al_entrar_agua):
				agua.body_entered.connect(_al_entrar_agua.bind(agua))
				
func _al_entrar_agua(cuerpo: Node3D, area: Area3D):
	if cuerpo != self:
		return
	if flotando:
		return

	var tipo = "mar"
	if area.is_in_group("agua_lago"):
		tipo = "lago"
	elif area.is_in_group("agua_alta_mar"):
		tipo = "alta_mar"

	# Anclar en la superficie
	freeze = true
	linear_velocity = Vector3.ZERO
	global_position.y = area.global_position.y + 0.5
	iniciar_flotacion()
	cayo_en_agua.emit(tipo)

func _physics_process(delta):
	if not flotando:
		return
	tiempo_bob += delta
	if picando:
		global_position.y = y_base - profundidad_pique + sin(tiempo_bob * 6.0) * 0.02
	else:
		global_position.y = y_base + sin(tiempo_bob * velocidad_bob) * amplitud_bob

func lanzar(origen: Vector3, destino: Vector3):
	global_position = origen
	freeze = false
	gravity_scale = 2.0
	var diff = destino - origen
	var tiempo = 0.7
	var gravedad = ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_scale
	linear_velocity = Vector3(
		diff.x / tiempo,
		(diff.y - 0.5 * (-gravedad) * tiempo * tiempo) / tiempo + 4.0,
		diff.z / tiempo
	)

func iniciar_flotacion():
	flotando = true
	freeze = true
	y_base = global_position.y
	linear_velocity = Vector3.ZERO
	tiempo_bob = 0.0

func animar_pique():
	picando = true
	emit_signal("pique")
	
func _al_tocar_algo(cuerpo: Node):
	if flotando:
		return
	# Si toca algo que no es agua, avisar a la caña
	emit_signal("cayo_en_tierra")
