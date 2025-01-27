extends CharacterBody2D



@export var inventory_data: InventoryData
@export var equip_inventory_data: InventoryDataEquip
@export var head: InventoryDataEquip
@onready var health_bar = $HealthBar
@onready var notifications = $Notifications
@onready var crafting = $Crafting

var sword_recipe = preload("res://item/recipes/sword_recipe.tres")
var characterNum = 1
var enemy
var enemy_attack_cooldown = true
var walking_towards = "none"
# var monster_chase = false

var player_alive = true

var attack_ip = false

var current_dir = "none"

enum Direction { UP, DOWN, LEFT, RIGHT, NONE }

var current_direction = Direction.NONE
var step_size = 1
var current_action = null
@onready var buildings_list = $"../Buildings"
@onready var monsters_list = $"../DungeonMonsters"
@onready var http_request = $HTTPRequest
@onready var chain_http_req = HTTPRequest.new()
@onready var player_animation = $PlayerAnimation
@onready var character_inventory = $InventoryInterface/CharacterInventory/Inventory
@onready var equip_inventory = $InventoryInterface/EquipInventory/Inventory

@onready var play_anim = $play_anim
@onready var player_status = $player_status
@onready var battle_status = $battle_status
@onready var ai_requests = $ai_requests

# MARKET
var external_store = null
var external_currency_manager = null
@onready var currency_manager = $CurrencyManager
@onready var store = $Store
@onready var transaction_manager = $TransactionManager
@onready var buy_button = $BuyButton
# END MARKET	

@onready var action_functions = $ActionFunctions
@onready var action_manager = $ActionManager	
@onready var player_label = $Label

func _ready():
	PlayerManager.set_player(self)
	health_bar.max_value = PlayerStatus.characters[characterNum].max_health
	$AnimatedSprite2D.play("front_idle")
	#battle_status.walk_towards("Building5")
	
	# Initialize MARKET
	# store and tx manager have to be initialized
	store.initialize(inventory_data)
	transaction_manager.initialize(inventory_data, currency_manager)
	
	# set prices for items I want to sell
	store.set_item_price("Health Potion", 300)
	
	# give myself some money to start with
	currency_manager.increase_balance(1000)
	# END MARKET
	
	#craft Iron Sword
	crafting.craft(sword_recipe)
	#drink health potion
#	inventory_data.use_slot_data(5)
	
	#equip wooden shield
	inventory_data.equip_slot_data(1)
	
	#equip iron sword
	inventory_data.equip_slot_data(0)
	
	#equip iron helmet
	inventory_data.equip_slot_data(3)
	
	#equip steel helmet
	#This should not work because a helmet is already equipped
	inventory_data.equip_slot_data(4)
	
	#unequip iron sword
#	equip_inventory_data.unequip_item(1)
	
#	# Testing some actions that are queued and interrupted
#	action_manager.add_action(action_functions, "wrapped_train", ["Building1"], true)
#	action_manager.add_action(action_functions, "wrapped_walk_towards", ["FreyaSwiftwind"], true)
##	await get_tree().create_timer(21).timeout
#	action_manager.add_action(action_functions, "wrapped_talk_to", ["FreyaSwiftwind", "Garrick Stormwind: Hey there Freya, what have you got for me today?\nFreyaSwiftwind: Nothing but an old beat up Iron Sword.\n"], true)
##	action_manager.add_action(action_functions, "wrapped_walk_towards", ["Building3"], true)

func _physics_process(delta):
	update_healthbar()
	play_anim.play_anim(current_direction, 0, attack_ip)
	current_camera()
	battle_status.enemy_attack(1) #TODO: Change to be called from Enemy	
	pickup()
#	if walking_towards != "none" and global.current_location == global.Location.TOWN:
#		battle_status.walk_towards(walking_towards)
	
	if global.current_location == global.Location.DUNGEON:
		battle_status.go_and_attack(enemy)

	if PlayerStatus.characters[characterNum].health <= 0:
		player_alive = false
		PlayerStatus.characters[characterNum].health = 0
		print("player has died")
		self.queue_free()
		
	# ActionManager testing
	player_label.text = "Garrick Stormwind\n"
#	player_label.text += "Action Finished?: " + str(action_manager.action_finished) + "\n"
#	player_label.text += "Queue size: " + str(action_manager.action_queue.size()) + "\n"
	if action_manager.current_action:
		player_label.text += action_manager.current_action["func_name"] + "(" +  str(action_manager.current_action["args"]) + ")\n"
	for action in action_manager.action_queue:
		player_label.text += action["func_name"] + "(" +  str(action["args"]) + ")\n"
	
func _on_player_hitbox_body_entered(body):
	if body.has_method("enemy"):
		battle_status.enemy_in_attackrange = true

func _on_player_hitbox_body_exited(body):
	if body.has_method("enemy"):
		battle_status.enemy_in_attackrange = false

#TODO: Move attack cooldown to Attack Node
func _on_attack_cooldown_timeout():
	enemy_attack_cooldown = true

func pickup():
	if Input.is_action_just_pressed("interact"):
		print("interact button pressed")

#TODO: Move on deal attack timer to Attack Node
func _on_deal_attack_timer_timeout():
	$deal_attack_timer.stop()
	global.player_current_attack = false
	attack_ip = false

func current_camera():
	if global.current_scene == "world":
		$world_camera.enabled = true
		$cliffside_camera.enabled = false
	elif global.current_scene == "cliff_side":
		$world_camera.enabled = false
		$cliffside_camera.enabled = true

func get_drop_position():
	var dir = current_dir
	
	if dir == "none":
		return position + Vector2(0, 35)
	if dir == "right":
		return position + Vector2(35, 0)
	if dir == "left":
		return position + Vector2(-35, 0)
	if dir == "up":
		return position + Vector2(0, -35)
	if dir == "down":
		return position + Vector2(0, 35)
		
func update_healthbar():
	health_bar.value = PlayerStatus.characters[characterNum].health


func is_player():
	true
