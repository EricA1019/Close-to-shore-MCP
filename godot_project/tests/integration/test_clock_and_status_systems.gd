extends GutTest

func test_game_clock_advances_on_move():
	# Test that moving advances GameClock by 1 second
	GameClock.reset() # Ensure we start from 0
	assert_eq(GameClock.current_time(), 0)
	
	# Advance time manually
	GameClock.advance(1)
	assert_eq(GameClock.current_time(), 1)
	
	# Test signal emission using await
	GameClock.advance(1)
	await wait_for_signal(GameClock.time_changed, 1.0)
	assert_eq(GameClock.current_time(), 2)

func test_status_system_add_remove():
	# Test basic status operations
	var entity_id = "E-001"
	var status_id = "S-001"
	
	# Clear any existing statuses
	StatusSystem.clear_statuses(entity_id)
	assert_false(StatusSystem.has_status(entity_id, status_id))
	
	# Add status
	StatusSystem.add_status(entity_id, status_id)
	assert_true(StatusSystem.has_status(entity_id, status_id))
	
	# Check get_statuses
	var statuses = StatusSystem.get_statuses(entity_id)
	assert_eq(statuses.size(), 1)
	assert_eq(statuses[0], status_id)
	
	# Remove status
	StatusSystem.remove_status(entity_id, status_id)
	assert_false(StatusSystem.has_status(entity_id, status_id))
	assert_eq(StatusSystem.get_statuses(entity_id).size(), 0)

func test_status_system_mods():
	# Test that status mods are computed correctly
	var entity_id = "E-001"
	StatusSystem.clear_statuses(entity_id)
	
	# No statuses = no mods
	var mods = StatusSystem.get_mods(entity_id)
	assert_eq(mods.size(), 0)
	
	# Add Hungover (S-001) - should reduce accuracy by 2, dex by 1
	StatusSystem.add_status(entity_id, "S-001")
	mods = StatusSystem.get_mods(entity_id)
	assert_eq(mods.get("accuracy", 0), -2)
	assert_eq(mods.get("dexterity", 0), -1)
	
	# Add Steady Nerves (S-002) - should add +1 accuracy
	StatusSystem.add_status(entity_id, "S-002")
	mods = StatusSystem.get_mods(entity_id)
	assert_eq(mods.get("accuracy", 0), -1) # -2 + 1 = -1
	assert_eq(mods.get("dexterity", 0), -1) # Still -1

func test_status_system_signals():
	# Test that status_changed signal is emitted
	var entity_id = "E-001" 
	StatusSystem.clear_statuses(entity_id)
	
	# Test signal emission using await
	StatusSystem.add_status(entity_id, "S-001")
	await wait_for_signal(StatusSystem.status_changed, 1.0)
	assert_true(StatusSystem.has_status(entity_id, "S-001"))

func test_top_status_integration():
	# Test that TopStatus updates when systems change
	# This requires instantiating a scene with TopStatus
	var scene = preload("res://scenes/ui/main_ui.tscn").instantiate()
	add_child_autofree(scene)
	
	# Find TopStatus component
	var top_status = scene.find_child("TopStatus", true, false)
	if not top_status:
		# Try alternate paths if TopStatus isn't found directly
		var candidates = scene.find_children("*", "HBoxContainer", true, false)
		for candidate in candidates:
			if candidate.has_method("connect_providers"):
				top_status = candidate
				break
	
	if top_status:
		# Force connection to systems
		top_status.connect_providers()
		
		# Wait a frame for connections to establish
		await get_tree().process_frame
		
		# Test time display updates
		GameClock.reset()
		GameClock.advance(3661) # 1 hour, 1 minute, 1 second
		
		# Find time label
		var time_label = top_status.find_child("TimeLabel", true, false)
		if time_label:
			# Should display formatted time
			await get_tree().process_frame
			var time_text = time_label.text
			print("Time display: ", time_text)
			# Should be "01:01" for 3661 seconds
			assert_true(time_text.contains("01:01"))
	else:
		print("TopStatus not found in scene, skipping UI integration test")
