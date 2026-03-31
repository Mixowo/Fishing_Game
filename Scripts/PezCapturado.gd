## PezCapturado.gd
## Adjunta este script al nodo raíz de cualquier pez 3D.
## CañaPesca.gd lo instancia y llama a volar_hacia() para iniciar la animación.
## El pez sale del agua, vuela hacia el jugador haciéndose cada vez más pequeño
## y desaparece al llegar, dando la sensación de que lo recogemos.

extends Node3D

# ─── PARÁMETROS ──────────────────────────────────────────────────────────────
@export var duracion_vuelo: float = 1.1       ## Segundos que tarda en llegar
@export var altura_arco: float = 3.5         ## Altura máxima del arco de vuelo
@export var escala_final: float = 0.03       ## Tamaño al llegar (casi invisible)
@export var rotar_durante_vuelo: bool = true ## Girar mientras vuela (efecto bonito)

# ─── LLAMADO POR CañaPesca ───────────────────────────────────────────────────
func volar_hacia(destino: Vector3, callback: Callable = Callable()):
	## destino   → posición global del jugador
	## callback  → función a llamar cuando el pez llega (CañaPesca._al_terminar_pesca)

	var pos_inicio = global_position
	scale = Vector3.ONE   # Aseguramos escala normal al inicio

	# ── Tween principal: posición X/Z y escala ──────────────────────────────
	var tween = create_tween()
	tween.set_parallel(true)

	# Posición X y Z: directo al jugador
	tween.tween_property(self, "global_position:x", destino.x, duracion_vuelo)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position:z", destino.z, duracion_vuelo)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Escala: de 1 a casi 0, acelerando al final
	tween.tween_property(self, "scale", Vector3(escala_final, escala_final, escala_final), duracion_vuelo)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Rotación libre si está activada
	if rotar_durante_vuelo:
		tween.tween_property(self, "rotation_degrees:y", 720.0, duracion_vuelo)\
			.set_trans(Tween.TRANS_LINEAR)

	# ── Arco vertical en dos pasos ──────────────────────────────────────────
	var tween_y = create_tween()
	var y_pico = pos_inicio.y + altura_arco
	var y_destino = destino.y + 0.8    ## Llega a la altura de la cintura del jugador

	tween_y.tween_property(self, "global_position:y", y_pico, duracion_vuelo * 0.35)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_y.tween_property(self, "global_position:y", y_destino, duracion_vuelo * 0.65)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# ── Al llegar: destruir y llamar callback ───────────────────────────────
	tween.set_parallel(false)
	tween.tween_callback(func():
		queue_free()
		if callback.is_valid():
			callback.call("Pez")   # Pasa el nombre del pez; cámbialo por variable si tienes varios
	)


# ─── NOMBRE DEL PEZ (para múltiples especies) ────────────────────────────────
## Si quieres usar el mismo script para distintos peces, declara esta variable
## y asígnala desde el Inspector o al instanciar el pez:
##
##   var nombre_pez: String = "Atún"
##
## Luego en el callback de volar_hacia:
##   callback.call(nombre_pez)
##
## En CañaPesca._pescar_pez(), cambia:
##   pez.volar_hacia(jugador.global_position, _al_terminar_pesca)
## a:
##   pez.nombre_pez = "Atún"
##   pez.volar_hacia(jugador.global_position, _al_terminar_pesca)
