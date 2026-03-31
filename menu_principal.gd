extends Control

func _on_boton_jugar_pressed():
	GestoMundo.iniciar_nueva_partida()  # <-- esto
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().change_scene_to_file("res://node_3d.tscn")

func _on_boton_opciones_pressed():
	# Aquí abriremos el panel de opciones después
	print("Abriendo opciones...")

func _on_boton_salir_pressed():
	# Cierra el juego (en Android esto suele minimizar la app)
	get_tree().quit()
	
func _ready():
	var controles = get_node_or_null("MUNDO/SUBFILTRO/FILTRO/MUNDO_DATA/ANDROID_FILTRO") 
	if controles:
		controles.hide()
	# Asegura que el ratón sea visible y se pueda mover libremente
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Buscamos la isla que instanciamos y su cámara especial
	# Ajusta la ruta "$Isla" al nombre que tenga el nodo de tu isla en el menú
	var cam_menu = $MUNDO/SUBFILTRO/FILTRO/ISLA/CamaraMenu
	
	if cam_menu:
		cam_menu.make_current() # Esto activa la cámara fija
