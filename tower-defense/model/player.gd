extends Node2D


export(int) var health = 100

var money = 100

var selected_turret = null

signal turret_selected
signal place_turret(turret)

onready var lifebar = get_node("LifeBar")
onready var money_label = get_node("Money")
onready var turret_buttons = get_node("TurretButtons")
onready var controller = get_node("Controller")
onready var death_controller = get_node("DeathController")
onready var board = get_node("../BoardNav/BoardMap")

func _ready():
  lifebar.set_value(health)
  money_label.set_text("$ %d" % money)
  controller.enable()
  death_controller.disable()

func receive_damage(damage):
  health -= damage
  printt("damage taken", damage, " health=", health)

  if health <= 0:
    controller.disable()
    death_controller.enable()
    get_node("DeathAlert").show()

  lifebar.set_value(health)

func reset_buttons(selected_button):
  for button in turret_buttons.get_children():
    if button != selected_button:
      button.set_pressed(false)

func get_selected_turret():
  return selected_turret

func _on_normal_turret_button_released():
  var button = null
  if get_node("TurretButtons/NormalTurret").is_pressed():
    button = get_node("TurretButtons/NormalTurret")

  printt("button=", button)
  reset_buttons(button)

  if button == null:
    selected_turret = null
    return

  selected_turret = get_node("TurretsType/" + button.get_name()).duplicate(true)
  add_child(selected_turret)
  emit_signal("turret_selected")

func get_board():
  return board

static func center_tile_point(board, point):
  point = board.world_to_map(point)
  point = board.map_to_world(point) + Vector2(board.get_cell_size().x / 2,  board.get_cell_size().y / 2)
  return point

func get_selected_button():
  for button in turret_buttons.get_children():
    if button.is_pressed():
      return button

func place_turret():
  var tile_pos = board.world_to_map(selected_turret.get_pos())
  var aux_cell = board.get_cell(tile_pos.x, tile_pos.y)
  board.set_cell(tile_pos.x, tile_pos.y, -1)

  var init = center_tile_point(board, board.get_node("init").get_pos())
  var finish = center_tile_point(board, board.get_node("finish").get_pos())
  yield(get_tree(), "fixed_frame")
  var points = board.get_parent().get_simple_path(init, finish, false)
  printt("path=", points)
  if points.size() <= 1:
    board.set_cell(tile_pos.x, tile_pos.y, aux_cell)
    yield(get_tree(), "fixed_frame")
    return
  remove_child(selected_turret)
  get_selected_button().set_pressed(false)
  emit_signal("place_turret", selected_turret)


func unselect_turret():
  remove_child(selected_turret)
  selected_turret = null
