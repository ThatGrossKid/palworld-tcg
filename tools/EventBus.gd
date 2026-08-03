@tool
extends Node

signal settings_button_clicked()
signal play_button_clicked()
signal duel_rooms_button_clicked()
signal tutorial_button_clicked()
signal hovering_over_card()
signal stop_hovering_over_card()
signal close_settings_menu()
signal draw_card(card_id: String)
signal deck_is_empty()
signal view_card()
signal change_phase()
signal draw_soul_cards(cards:int)


func request_close_settings_menu()-> void:
	self.emit_signal("close_settings_menu")

func request_settings_menu()-> void:
	self.emit_signal("settings_button_clicked")

func request_play_game()-> void:
	self.emit_signal("play_button_clicked")

func request_duel_rooms()-> void:
	self.emit_signal("duel_rooms_button_clicked")
	
func request_tutorial()-> void:
	self.emit_signal("tutorial_button_clicked")
	
func request_hover_over_card(card)-> void:
	self.emit_signal("hovering_over_card", card)
	
func request_stop_hovering_over_card(card) -> void:
	self.emit_signal("stop_hovering_over_card", card)

func request_draw_card(card_id:String):
	self.emit_signal("draw_card", card_id)

func request_deck_is_empty():
	self.emit_signal("deck_is_empty")

func request_view_card(card_name:String):
	self.emit_signal("view_card",card_name)

func request_change_phase(phase:PlayersField.Phase)-> void:
	self.emit_signal("change_phase",phase)
	
func request_draw_soul_cards(cards:int)-> void:
	self.emit_signal("draw_soul_cards", cards)
