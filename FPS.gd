extends Label

func _process(_delta):
	# Obtenemos los FPS
	var fps = Engine.get_frames_per_second()
	
	# Actualizamos el texto
	text = "FPS: " + str(fps)
	
	# EXTRA: Cambia de color según el rendimiento
	if fps > 50:
		add_theme_color_override("font_color", Color.GREEN)
	elif fps > 30:
		add_theme_color_override("font_color", Color.YELLOW)
	else:
		add_theme_color_override("font_color", Color.RED)
