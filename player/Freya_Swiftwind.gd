extends CharacterBody2D

signal toggle_inventory

@export var inventory_data: InventoryData
@export var equip_inventory_data: InventoryDataEquip
@onready var health_bar = $HealthBar

var enemy
var enemy_attack_cooldown = true
var walking_towards = "none"

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
@onready var play_anim = $play_anim
@onready var player_status = $player_status
@onready var battle_status = $battle_status
@onready var ai_requests = $"ai-requests"

func _ready():
	PlayerManager.players.push_back(self)
	health_bar.max_value = player_status.max_health
	$AnimatedSprite2D.play("front_idle")

	battle_status.walk_towards("Building5")		

	ai_requests.send_request("Test")
	
	# set up http req object for on-chain syncs
	chain_http_req.request_completed.connect(_on_req_completed)
	self.add_child(chain_http_req) 	
	
	# do on-chain init of attributes
	update_attribute_on_chain("health", player_status.health)
	update_attribute_on_chain("attack", player_status.attack_damage)
	update_attribute_on_chain("defense", player_status.defense)
	update_attribute_on_chain("stamina", player_status.stamina)
	update_attribute_on_chain("strength", player_status.strength)
	update_attribute_on_chain("constitution", player_status.constitution)
	update_attribute_on_chain("dexterity", player_status.dexterity)
	update_attribute_on_chain("intelligence", player_status.intelligence)


func _physics_process(delta):
	update_healthbar()
	play_anim.play_anim(current_direction, 0, attack_ip)
	battle_status.enemy_attack(1) #TODO: Change to be called from Enemy
	current_camera()
	
	if walking_towards != "none" and global.current_location == global.Location.TOWN:
		battle_status.walk_towards(walking_towards)
	
	if global.current_location == global.Location.DUNGEON:
		battle_status.go_and_attack(enemy)

	if player_status.health <= 0:
		player_alive = false
		player_status.health = 0
		print("player has died")
		self.queue_free()
	


func _on_player_hitbox_body_entered(body):
	if body.has_method("enemy"):
		battle_status.enemy_in_attackrange = true


func _on_player_hitbox_body_exited(body):
	if body.has_method("enemy"):
		battle_status.enemy_in_attackrange = false

	
func player():
	pass
	
func _on_attack_cooldown_timeout():
	enemy_attack_cooldown = true

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

func _unhandled_input(event):
	if Input.is_action_just_pressed("inventory"):
		toggle_inventory.emit()
		
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
	health_bar.value = player_status.health

func _on_req_completed(result, response_code, headers, body):
	pass

func update_attribute_on_chain(attribute, value):
	var headers = ["Content-Type: application/json"]
	var body = {
		"player": self.name,
		"attribute": attribute,
		"value": value
	}
	var body_text = JSON.stringify(body)  

	var error = chain_http_req.request("http://127.0.0.1:3000/attribute", headers, HTTPClient.METHOD_POST, body_text)
	if error != OK:
		print("An error occurred in the HTTP request")	
	else:
		print("===== On-chain update result: " + attribute + " updated for " + self.name)

