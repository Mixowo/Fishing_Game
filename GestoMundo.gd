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
	hora_actual = 12  # Amanece al empezar

func cargar_partida(hora_guardada: float):
	hora_actual = hora_guardada
	
# ─── TIPOS DE AGUA ───────────────────────────────────────────────
enum TipoAgua { MAR, LAGO, ALTA_MAR }

# ─── CATÁLOGO DE PECES ───────────────────────────────────────────
# Cada pez tiene: nombre, tipo_agua, solo_noche, solo_lluvia, valor
const PECES = [
	{ "nombre": "Sardina",    "agua": 0, "noche": false, "lluvia": false, "valor": 10,
	  "puntos_fase1": 500,  "toques_fase2": 5, "velocidad": "medio"  },
	{ "nombre": "Trucha",     "agua": 1, "noche": false, "lluvia": false, "valor": 15,
	  "puntos_fase1": 100, "toques_fase2": 1, "velocidad": "lento"  },
	{ "nombre": "Carpa",      "agua": 1, "noche": true,  "lluvia": false, "valor": 20,
	  "puntos_fase1": 120, "toques_fase2": 2, "velocidad": "medio"  },
	{ "nombre": "Anguila",    "agua": 0, "noche": true,  "lluvia": false, "valor": 35,
	  "puntos_fase1": 180, "toques_fase2": 2, "velocidad": "medio"  },
	{ "nombre": "Pez Lluvia", "agua": 1, "noche": false, "lluvia": true,  "valor": 60,
	  "puntos_fase1": 220, "toques_fase2": 3, "velocidad": "medio"  },
	{ "nombre": "Atún",       "agua": 2, "noche": false, "lluvia": false, "valor": 50,
	  "puntos_fase1": 300, "toques_fase2": 3, "velocidad": "rapido" },
	{ "nombre": "Pez Espada", "agua": 2, "noche": true,  "lluvia": false, "valor": 80,
	  "puntos_fase1": 500, "toques_fase2": 5, "velocidad": "extremo"},
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
