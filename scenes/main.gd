extends Node


const SERVER_IP = "YOUR_SERVER_IP_HERE"  # Change this to your servers public IP address

func _ready() -> void:
	if "--server" in OS.get_cmdline_args():
		_launch_server()
	else:
		_launch_client()


func _launch_server() -> void:
	print("Launching as dedicated server...")
	print("Args: ", OS.get_cmdline_args())
	get_tree().change_scene_to_file.call_deferred("res://server/server.tscn")


func _launch_client() -> void:
	# Auto-connect to the server before showing any UI
	Network.connection_succeeded.connect(_on_connected, CONNECT_ONE_SHOT)
	Network.connection_failed.connect(_on_connection_failed, CONNECT_ONE_SHOT)
	Network.join_server(SERVER_IP)


func _on_connected() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/main_menu.tscn")


func _on_connection_failed() -> void:
	# Show main menu anyway so the player sees an error state
	get_tree().change_scene_to_file.call_deferred("res://scenes/main_menu.tscn")
