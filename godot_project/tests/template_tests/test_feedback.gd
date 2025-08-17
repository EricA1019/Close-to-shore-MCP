# Test: Feedback Logging
extends "res://addons/gut/test.gd"

func test_feedback_logging():
    var logger = FeedbackLogger.new()
    var feedback = {"user": "test", "comments": "Great hop!"}
    logger.log_feedback(feedback)
    assert_true(logger.last_feedback == feedback)
