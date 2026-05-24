## Pescadero.gd
extends "res://Scripts/NPC.gd"

func _ready():
	distancia_camara = 2.3
	nombre_npc = "Don Peces"
	dialogos = [
		"¡Bienvenido pescador!",
		"Pago bien por todo lo que traigas.\nAhora mismo tienes $%d." % GestoMundo.dinero_actual,
	]
	opciones = [
		{ "texto": "Vender",  "accion": Callable(self, "_vender"),  "salir": false },
		{ "texto": "Hablar",  "accion": Callable(self, "_hablar"),  "salir": false },
		{ "texto": "Salir",   "accion": Callable(self, "_salir"),   "salir": true  },
	]
	super._ready()


func _vender():
	var ganancia = 50
	GestoMundo.dinero_actual += ganancia
	if label_dialogo:
		label_dialogo.text = "¡Trato hecho! Te pago [color=#6b3a10]$%d[/color].\nAhora tienes [color=#6b3a10]$%d[/color] en total.\n\n[color=#8c6a3a][ E — Volver ][/color]" % [ganancia, GestoMundo.dinero_actual]


func _hablar():
	var frases = [
		"Dicen que en la alta mar hay peces enormes...\n¡Pero necesitas un buen bote para llegar!",
		"De noche salen las anguilas.\nSon escurridizas pero valen mucho.",
		"Con lluvia aparece el Pez Lluvia en el lago.\n¡Es raro y lo pago bien!",
		"Llevo años en este muelle.\nHe visto cosas en el mar que no te creerías...",
	]
	if label_dialogo:
		label_dialogo.text = frases[randi() % frases.size()] + "\n\n[color=#8c6a3a][ E — Volver ][/color]"


func _salir():
	if label_dialogo:
		label_dialogo.text = "¡Hasta luego! Vuelve cuando quieras."
	await get_tree().create_timer(1.5).timeout
	cerrar_dialogo()
