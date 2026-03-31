## Pescadero.gd
## Extiende NPC.gd — compra los peces del jugador.
## Asigna este script al nodo del pescadero en la escena.

extends "res://Scripts/NPC.gd"  # ← ajusta la ruta a donde tengas NPC.gd

func _ready():
	nombre_npc = "zama haz algo"
	dialogos = [
		"¡Bienvenido! ¿Traes algo fresco hoy?",
		"Pago bien por todo lo que pesques.\nTienes $%d en tu bolsillo." % GestoMundo.dinero_actual,
		"¡Vuelve cuando quieras!",
	]
	super._ready()  # llama el _ready del molde base
