extends Node2D

const PickUp = preload("res://item/pick_up.tscn")

@onready var player = $player
@onready var inventory_interface = $UI/InventoryInterface
@onready var player_2 = $player_2
@onready var player_3 = $player_3
@onready var player_4 = $player_4
@onready var player_5 = $player_5

@onready var dungeon_camera = $DungeonCamera
@onready var town_camera = $TownCamera

func _ready():
	player.toggle_inventory.connect(toggle_inventory_interface)
	
	inventory_interface.set_player_inventory_data(player.inventory_data, 1)
	player.inventory_data.set_player(1)
	player.equip_inventory_data.set_player(1)
	inventory_interface.set_equip_inventory_data(player.equip_inventory_data, 1)
	
	inventory_interface.set_player_inventory_data(player_2.inventory_data, 2)
	player_2.inventory_data.set_player(2)
	player_2.equip_inventory_data.set_player(2)
	inventory_interface.set_equip_inventory_data(player_2.equip_inventory_data, 2)
	
	inventory_interface.set_player_inventory_data(player_3.inventory_data, 3)
	player_3.inventory_data.set_player(3)
	player_3.equip_inventory_data.set_player(3)
	inventory_interface.set_equip_inventory_data(player_3.equip_inventory_data, 3)
	
	inventory_interface.set_player_inventory_data(player_4.inventory_data, 4)
	player_4.inventory_data.set_player(4)
	player_4.equip_inventory_data.set_player(4)
	inventory_interface.set_equip_inventory_data(player_4.equip_inventory_data, 4)
	
	inventory_interface.set_player_inventory_data(player_5.inventory_data, 5)
	player_5.inventory_data.set_player(5)
	player_5.equip_inventory_data.set_player(5)
	inventory_interface.set_equip_inventory_data(player_5.equip_inventory_data, 5)
		
	for node in get_tree().get_nodes_in_group("external_inventory"):
		node.toggle_inventory.connect(toggle_inventory_interface)
		
	if global.game_first_loadin == true:
		$player.position.x = global.player_start_posx
		$player.position.y = global.player_start_posy
	else:
		$player.position.x = global.player_exit_cliffside_posx
		$player.position.y = global.player_exit_cliffside_posy
		

func toggle_inventory_interface(external_inventory_owner = null) -> void:
	inventory_interface.visible = not inventory_interface.visible
	
#	if inventory_interface.visible:
#		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
#	else:
#		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if external_inventory_owner and inventory_interface.visible:
		inventory_interface.set_external_inventory(external_inventory_owner)
	else:
		inventory_interface.clear_external_inventory()
	
func _process(delta):
	change_scene()

func _on_cliffside_transition_point_body_entered(body):
	if body.has_method("player"):
		global.transition_scene = true

func _on_cliffside_transition_point_body_exited(body):
	if body.has_method("player"):
		global.transition_scene = false

func change_scene():
	if global.transition_scene == true:
		if global.current_scene == "world":
			get_tree().change_scene_to_file("res://scenes/cliff_side.tscn")
			global.game_first_loadin = false
			global.finish_changescenes()


func _on_inventory_interface_drop_slot_data(slot_data):
	var pick_up = PickUp.instantiate()
	pick_up.slot_data = slot_data
	pick_up.global_position = player.get_drop_position()
	add_child(pick_up)
	

func _on_button_pressed():
	var character_scene = preload("res://player/player.tscn")
	var characters = $Characters
	var character = character_scene.instantiate()
  # give it a random position on screen
	character.position = Vector2(randf_range(0, get_viewport().get_visible_rect().size.x), randf_range(0, get_viewport().get_visible_rect().size.y))  
	characters.add_child(character)
	print("Number of children in 'Characters' node: ", characters.get_child_count())

func _on_teleport_to_dungeon_pressed():
	player.global_position = Vector2(4500, 30)
	player_2.global_position = Vector2(4500, 50)
	player_3.global_position = Vector2(4500, 70)
	player_4.global_position = Vector2(4500, 90)
	player_5.global_position = Vector2(4500, 110)
	dungeon_camera.make_current()

func _on_teleport_to_town_pressed():
	player.global_position = Vector2(520, 290)
	player_2.global_position = Vector2(520, 310)
	player_3.global_position = Vector2(500, 270)
	player_4.global_position = Vector2(500, 290)
	player_5.global_position = Vector2(500, 310)
	town_camera.make_current()
