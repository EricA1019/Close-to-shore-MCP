class_name DebugHTTPServer
extends Node

## HTTP server for exposing debugging tools to external agents
## Provides REST API endpoints for scene inspection, state monitoring, etc.

var tcp_server: TCPServer
var clients: Array[StreamPeerTCP] = []
var is_running: bool = false
var port: int = 8080

signal server_started(port: int)
signal server_stopped()

func _ready() -> void:
	tcp_server = TCPServer.new()

func start_server(listen_port: int = 8080) -> bool:
	"""Start the debug HTTP server"""
	if is_running:
		print("[DebugHTTPServer] Server already running on port ", port)
		return false
	
	port = listen_port
	
	# Start listening
	var error = tcp_server.listen(port)
	if error != OK:
		print("[DebugHTTPServer] Failed to start server on port ", port, ": ", error)
		return false
	
	is_running = true
	print("[DebugHTTPServer] Server started on port ", port)
	server_started.emit(port)
	return true

func stop_server() -> void:
	"""Stop the debug HTTP server"""
	if not is_running:
		return
	
	tcp_server.stop()
	for client in clients:
		client.disconnect_from_host()
	clients.clear()
	
	is_running = false
	print("[DebugHTTPServer] Server stopped")
	server_stopped.emit()

func _process(_delta: float) -> void:
	if not is_running:
		return
	
	# Accept new connections
	if tcp_server.is_connection_available():
		var client = tcp_server.take_connection()
		clients.append(client)
		print("[DebugHTTPServer] New client connected")
	
	# Handle existing clients
	for i in range(clients.size() - 1, -1, -1):
		var client = clients[i]
		if client.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			clients.remove_at(i)
			continue
		
		if client.get_available_bytes() > 0:
			_handle_client_request(client)

func _handle_client_request(client: StreamPeerTCP) -> void:
	"""Handle HTTP request from client"""
	var request_string = client.get_string(client.get_available_bytes())
	var lines = request_string.split("\r\n")
	
	if lines.size() == 0:
		return
	
	var request_line = lines[0]
	var parts = request_line.split(" ")
	
	if parts.size() < 2:
		return
	
	var method = parts[0]
	var path = parts[1]
	
	print("[DebugHTTPServer] ", method, " ", path)
	
	var response_data = {}
	var status_code = 200
	
	match path:
		"/scene":
			response_data = _handle_scene_export()
		"/global-state":
			response_data = _handle_global_state_export()
		"/nodes/find":
			# Parse query parameters from path
			var query_start = path.find("?")
			if query_start > -1:
				var query_string = path.substr(query_start + 1)
				response_data = _handle_node_search(query_string)
			else:
				response_data = {"success": false, "error": "Must specify query parameters"}
		"/health":
			response_data = {"status": "ok", "timestamp": Time.get_unix_time_from_system()}
		_:
			response_data = {"error": "Endpoint not found"}
			status_code = 404
	
	_send_json_response(client, response_data, status_code)

func _handle_scene_export() -> Dictionary:
	"""Handle /scene endpoint - export scene tree"""
	var scene_inspector = load("res://scripts/tools/scene_inspector.gd")
	var scene_data = scene_inspector.export_scene_tree()
	if scene_data:
		return {"success": true, "data": scene_data}
	else:
		return {"success": false, "error": "Failed to export scene tree"}

func _handle_global_state_export() -> Dictionary:
	"""Handle /global-state endpoint - export global state"""
	var scene_inspector = load("res://scripts/tools/scene_inspector.gd")
	var global_data = scene_inspector.export_global_state()
	if global_data:
		return {"success": true, "data": global_data}
	else:
		return {"success": false, "error": "Failed to export global state"}

func _handle_node_search(query_string: String) -> Dictionary:
	"""Handle /nodes/find endpoint - search for nodes"""
	var query_params = _parse_query_string(query_string)
	
	if not query_params.has("name") and not query_params.has("type"):
		return {"success": false, "error": "Must specify 'name' or 'type' parameter"}
	
	var scene_inspector = load("res://scripts/tools/scene_inspector.gd")
	var results = []
	
	if query_params.has("name"):
		var name_pattern = query_params["name"]
		var case_sensitive = query_params.get("case_sensitive", "false") == "true"
		var nodes = scene_inspector.find_nodes_by_name(name_pattern, null, case_sensitive)
		for node in nodes:
			results.append({
				"name": node.name,
				"type": node.get_class(),
				"path": str(node.get_path())
			})
	
	if query_params.has("type"):
		var type_name = query_params["type"]
		var nodes = scene_inspector.find_nodes_by_type(type_name)
		for node in nodes:
			results.append({
				"name": node.name,
				"type": node.get_class(),
				"path": str(node.get_path())
			})
	
	return {"success": true, "data": {"nodes": results, "count": results.size()}}

func _parse_query_string(query_string: String) -> Dictionary:
	"""Parse URL query string into dictionary"""
	var params = {}
	var pairs = query_string.split("&")
	
	for pair in pairs:
		var key_value = pair.split("=")
		if key_value.size() == 2:
			params[key_value[0]] = key_value[1]
	
	return params

func _send_json_response(client: StreamPeerTCP, data: Dictionary, status_code: int = 200) -> void:
	"""Send JSON response to client"""
	var json_string = JSON.stringify(data)
	var content_length = json_string.length()
	
	var response = "HTTP/1.1 %d OK\r\n" % status_code
	response += "Content-Type: application/json\r\n"
	response += "Content-Length: %d\r\n" % content_length
	response += "Access-Control-Allow-Origin: *\r\n"
	response += "Connection: close\r\n"
	response += "\r\n"
	response += json_string
	
	client.put_string(response)
	client.disconnect_from_host()
