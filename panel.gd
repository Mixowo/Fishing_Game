extends Panel

func _ready():
	# 1. Esperamos 5 segundos antes de empezar a quitarlo
	await get_tree().create_timer(5.0).timeout
	
	# 2. Creamos un "Tween" (una herramienta para animar propiedades)
	var tween = create_tween()
	
	# 3. Animamos la propiedad "modulate:a" (el canal Alpha/transparencia)
	# Queremos que pase de 1.0 (visible) a 0.0 (invisible) en 1.5 segundos
	tween.tween_property(self, "modulate:a", 0.0, 1.5)
	
	# 4. Cuando la animación termine, borramos el nodo para que no consuma recursos
	tween.finished.connect(queue_free)
