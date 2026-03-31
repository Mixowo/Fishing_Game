extends SubViewport

# --- REFERENCIAS A NODOS (Ajusta las rutas si es necesario) ---
@onready var eje_astral = $EjeAstral
@onready var lluvia_particulas = $LluviaParticulas
@onready var sol_luz = $MUNDO_DATA/SOL
@onready var env = $MUNDO_DATA/WorldEnvironment

var color_objetivo_top: Color = Color("41aaff")
var color_objetivo_horizon: Color = Color("85d1ff")

func _process(delta):
	# 1. ROTACIÓN VISUAL (Lee la hora de GestoMundo)
	var h = GestoMundo.hora_actual
	var angulo_visual = -(h / 24.0) * 360.0 + 90.0
	eje_astral.rotation_degrees.x = angulo_visual

	# 2. ROTACIÓN DE LA LUZ
	var angulo_luz = 0.0
	if h > 6.0 and h < 18.0:
		angulo_luz = -((h - 6.0) / 12.0) * 180.0
	else:
		var hora_noche = h
		if hora_noche >= 18.0: hora_noche -= 18.0
		else: hora_noche += 6.0
		angulo_luz = -(hora_noche / 12.0) * 180.0
	
	sol_luz.rotation_degrees.x = angulo_luz

	# 3. ACTUALIZACIONES VISUALES
	actualizar_iluminacion_astral(h)
	actualizar_logica_colores(h)
	aplicar_colores_suaves(delta, h)
	actualizar_luciernagas(h)
	
	# Sincronizar clima visual con el estado de GestoMundo
	lluvia_particulas.emitting = (GestoMundo.clima_actual == GestoMundo.Clima.LLUVIOSO)

func actualizar_iluminacion_astral(h):
	if h > 6.0 and h < 18.0:
		sol_luz.light_color = Color("bababaff") 
		sol_luz.light_energy = 0.4
	else:
		sol_luz.light_color = Color("5b6e9e")
		sol_luz.light_energy = 0.3

func actualizar_logica_colores(h):
	# AMANECER: 5:00 a 7:30 (Más corto para que el día entre claro)
	if h >= 5.0 and h < 8: 
		color_objetivo_top = Color("70408d")
		color_objetivo_horizon = Color("ff8274")
		
	# DÍA: 7:30 a 17:30
	elif h >= 8 and h < 17: 
		color_objetivo_top = Color("41aaff")
		color_objetivo_horizon = Color("85d1ff")
		
	# ATARDECER: 17:30 a 19:00 (Rápido, para que la luna entre en azul)
	elif h >= 17 and h < 18: 
		color_objetivo_top = Color("ff7d45")
		color_objetivo_horizon = Color("5e2c5d")
		
	# NOCHE: 19:00 en adelante
	else: 
		color_objetivo_top = Color("020208")
		color_objetivo_horizon = Color("101025")

func aplicar_colores_suaves(delta, h):
	var sky_mat = env.environment.sky.sky_material
	if not sky_mat: return
	var current_top = sky_mat.get_shader_parameter("sky_top_color")
	var current_hor = sky_mat.get_shader_parameter("sky_horizon_color")
	
	var new_top = current_top.lerp(color_objetivo_top, 0.5 * delta)
	var new_hor = current_hor.lerp(color_objetivo_horizon, 0.5 * delta)

	sky_mat.set_shader_parameter("sky_top_color", new_top)
	sky_mat.set_shader_parameter("sky_horizon_color", new_hor)
	sky_mat.set_shader_parameter("ground_horizon_color", new_hor)

	var color_nubes_dest = Color("ffffff")
	if h < 6.0 or h > 19.0: color_nubes_dest = Color("1e0100ff")
	elif h >= 17.0 and h <= 19.0: color_nubes_dest = Color("5e3a5e")

	var cloud_mod = sky_mat.get_shader_parameter("sky_cover_modulate")
	sky_mat.set_shader_parameter("sky_cover_modulate", cloud_mod.lerp(color_nubes_dest, 0.5 * delta))
	
	var energia_dest = 1.0 if (h > 6.0 and h < 18.0) else 0.1
	var current_energy = sky_mat.get_shader_parameter("sky_energy")
	sky_mat.set_shader_parameter("sky_energy", lerp(current_energy, energia_dest, 0.5 * delta))

func actualizar_luciernagas(h):
	var debe_emitir = h > 18.0 or h < 5.0
	get_tree().call_group("grupo_luciernagas", "set_emitting", debe_emitir)

func _input(event):
	if event.is_action_pressed("ui_accept"):
		if GestoMundo.clima_actual == GestoMundo.Clima.SOLEADO:
			GestoMundo.cambiar_clima(GestoMundo.Clima.LLUVIOSO)
		else:
			GestoMundo.cambiar_clima(GestoMundo.Clima.SOLEADO)
