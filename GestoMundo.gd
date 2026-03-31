extends Node

# --- VARIABLES DE DATOS ---
@export var velocidad_tiempo: float = 1.0
var hora_actual = 17
var dinero_actual = 67

# --- ESTADOS DE CLIMA ---
enum Clima {SOLEADO, LLUVIOSO, TORMENTA}
var clima_actual = Clima.SOLEADO

func _process(delta):
	# Solo el avance del tiempo vive aquí
	hora_actual += delta * (velocidad_tiempo / 60.0)
	if hora_actual >= 24.0: 
		hora_actual = 0.0

func cambiar_clima(nuevo_clima):
	clima_actual = nuevo_clima
	# La respuesta visual al clima se manejará en la Isla
	
func iniciar_nueva_partida():
	hora_actual = 14  # Amanece al empezar

func cargar_partida(hora_guardada: float):
	hora_actual = hora_guardada
	
# ─── TIPOS DE AGUA ───────────────────────────────────────────────
enum TipoAgua { MAR, LAGO, ALTA_MAR }

# ─── CATÁLOGO DE PECES ───────────────────────────────────────────
# Cada pez tiene: nombre, tipo_agua, solo_noche, solo_lluvia, valor
const PECES = [
	{ "nombre": "Sardina",     "agua": TipoAgua.MAR,      "noche": false, "lluvia": false, "valor": 10 },
	{ "nombre": "Trucha",      "agua": TipoAgua.LAGO,     "noche": false, "lluvia": false, "valor": 15 },
	{ "nombre": "Carpa",       "agua": TipoAgua.LAGO,     "noche": true,  "lluvia": false, "valor": 20 },
	{ "nombre": "Atún",        "agua": TipoAgua.ALTA_MAR, "noche": false, "lluvia": false, "valor": 50 },
	{ "nombre": "Pez Espada",  "agua": TipoAgua.ALTA_MAR, "noche": true,  "lluvia": false, "valor": 80 },
	{ "nombre": "Anguila",     "agua": TipoAgua.MAR,      "noche": true,  "lluvia": false, "valor": 35 },
	{ "nombre": "Pez Lluvia",  "agua": TipoAgua.LAGO,     "noche": false, "lluvia": true,  "valor": 60 },
]

func get_pez_disponible(tipo_agua: TipoAgua) -> Dictionary:
	var es_noche = hora_actual < 6.0 or hora_actual > 19.0
	var es_lluvia = clima_actual == Clima.LLUVIOSO
	
	# Filtrar peces disponibles según condiciones
	var disponibles = []
	for pez in PECES:
		if pez.agua != tipo_agua:
			continue
		if pez.noche and not es_noche:
			continue
		if pez.lluvia and not es_lluvia:
			continue
		disponibles.append(pez)
	
	# Si no hay ninguno disponible, usar cualquiera de ese tipo
	if disponibles.is_empty():
		for pez in PECES:
			if pez.agua == tipo_agua:
				disponibles.append(pez)
	
	return disponibles[randi() % disponibles.size()]
