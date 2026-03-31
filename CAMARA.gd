extends Camera3D

@export var objetivo_ruta : NodePath # Para seleccionarlo en el Inspector
var jugador : CharacterBody3D
var offset = Vector3(0, 6, 8) # Ajusta esto para la distancia tipo Animal Crossing

func _ready():
	# Si no asignaste nada en el inspector, intenta buscarlo por nombre
	if objetivo_ruta:
		jugador = get_node(objetivo_ruta)
	else:
		jugador = get_tree().root.find_child("CharacterBody3D", true, false)

func _physics_process(_delta):
	if jugador:
		# La cámara copia la posición del jugador + el espacio (offset)
		global_position = jugador.global_position + offset
		# Mantiene la mirada fija hacia donde está el jugador
		look_at(jugador.global_position)
