extends GutTest

func test_say_hello_returns_expected():
	var cls = ClassDB.instantiate("HelloNode")
	assert_true(cls != null, "Failed to instantiate HelloNode via ClassDB")
	# default greeting is "Hello"
	var result = cls.say_hello("World")
	assert_eq(result, "Hello World!", "Unexpected greeting result")
	# Avoid orphan warnings in GUT by freeing the instance
	cls.free()
