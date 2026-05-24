extends Area3D

@export var destino = Vector3(689.9, -0.5, 211.2)
@export var es_regreso: bool = false

@onready var label_e: Node3D = $LabelE

var jugador_cerca: bool = false
var jugador: CharacterBody3D = null
var barco: Node3D = null

func _ready():
	label_e.visible = false
	body_entered.connect(_jugador_entro)
	body_exited.connect(_jugador_salio)
	await get_tree().process_frame
	jugador = get_tree().root.find_child("CharacterBody3D", true, false)
	barco = get_tree().root.find_child("barco_mar", true, false)
	# El barco empieza oculto
	if barco:
		barco.visible = false

func _jugador_entro(cuerpo):
	if not cuerpo is CharacterBody3D:
		return
	jugador_cerca = true
	label_e.visible = true

func _jugador_salio(cuerpo):
	if not cuerpo is CharacterBody3D:
		return
	jugador_cerca = false
	label_e.visible = false

func _input(event):
	if event.is_action_pressed("interactuar") and jugador_cerca:
		_viajar()

func _viajar():
	label_e.visible = false
	jugador_cerca = false

	var canvas = CanvasLayer.new()
	canvas.layer = 20
	var rect = ColorRect.new()
	rect.color = Color(0, 0, 0, 0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(rect)
	get_tree().current_scene.add_child(canvas)

	var tween = create_tween()
	tween.tween_property(rect, "color:a", 1.0, 0.5)
	tween.tween_callback(func():
		jugador.global_position = destino
		# Si vas a alta mar muestra el barco, si regresas ocúltalo
		if barco:
			barco.visible = not es_regreso
	)
	tween.tween_interval(0.3)
	tween.tween_property(rect, "color:a", 0.0, 0.5)
	tween.tween_callback(canvas.queue_free)
