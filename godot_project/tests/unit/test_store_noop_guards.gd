extends "res://addons/gut/test.gd"

func test_location_state_noop_guard():
    var ls := preload("res://scripts/autoload/location_state.gd").new()
    add_child_autofree(ls)
    var count := {"v": 0}
    ls.location_changed.connect(func(_n): count["v"] += 1)
    ls.set_location("Apartment")
    ls.set_location("Apartment")
    ls.set_location("Street")
    assert_eq(count["v"], 2, "Only two emits for two distinct changes")

func test_player_state_noop_guard():
    var ps := preload("res://scripts/autoload/player_state.gd").new()
    add_child_autofree(ps)
    var hc := {"v": 0}
    var sc := {"v": 0}
    ps.health_changed.connect(func(_c,_m): hc["v"] += 1)
    ps.status_changed.connect(func(_t): sc["v"] += 1)
    ps.set_health(9, 9) # initial change
    ps.set_health(10, 10) # no-op
    ps.set_health(10, 10)  # change
    ps.set_status("Idle")    # initial
    ps.set_status("Idle")    # no-op
    ps.set_status("Exploring")
    assert_eq(hc["v"], 2, "Health emits only when changed")
    assert_eq(sc["v"], 2, "Status emits only when changed")

func test_game_clock_noop_guard():
    var gc := preload("res://scripts/autoload/game_clock.gd").new()
    add_child_autofree(gc)
    var count := {"v": 0}
    gc.time_changed.connect(func(_s): count["v"] += 1)
    gc.set_time_str("Day 1 - 08:00")
    gc.set_time_str("Day 1 - 08:00")
    gc.set_time_str("Day 1 - 09:00")
    assert_eq(count["v"], 2, "Only emits for distinct time strings")
