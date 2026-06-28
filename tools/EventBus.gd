@tool
extends Node

signal settings_button_clicked()
signal play_button_clicked()
signal duel_rooms_button_clicked()
signal tutorial_button_clicked()

func request_settings_menu()-> void:
	self.emit_signal("settings_button_clicked")

func request_play_game()-> void:
	self.emit_signal("play_button_clicked")

func request_duel_rooms()-> void:
	self.emit_signal("duel_rooms_button_clicked")
	
func request_tutorial()-> void:
	self.emit_signal("tutorial_button_clicked")
