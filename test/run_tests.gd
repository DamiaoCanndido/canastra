extends SceneTree

const TestCardData = preload("res://test/test_card_data.gd")
const TestDeckManager = preload("res://test/test_deck_manager.gd")
const TestMeldValidator = preload("res://test/test_meld_validator.gd")
const TestScoreCalculator = preload("res://test/test_score_calculator.gd")
const TestRoundFlow = preload("res://test/test_round_flow.gd")
const TestMortoAndBatida = preload("res://test/test_morto_and_batida.gd")
const TestUIComponents = preload("res://test/test_ui_components.gd")

var total_assertions: int = 0
var passed_assertions: int = 0
var failed_assertions: int = 0
var current_suite: String = ""

func _init() -> void:
	print("\n==========================================")
	print("       CANASTA TEST SUITE (GODOT 4)       ")
	print("==========================================\n")
	
	TestCardData.run(self)
	TestDeckManager.run(self)
	TestMeldValidator.run(self)
	TestScoreCalculator.run(self)
	TestRoundFlow.run(self)
	TestMortoAndBatida.run(self)
	TestUIComponents.run(self)
	
	print("\n------------------------------------------")
	print("RESULTS: %d total assertions" % total_assertions)
	print("PASSED:  %d" % passed_assertions)
	print("FAILED:  %d" % failed_assertions)
	print("------------------------------------------\n")
	
	if failed_assertions == 0:
		print("✅ ALL TESTS PASSED SUCCESSFULLY!\n")
		quit(0)
	else:
		print("❌ TEST SUITE FAILED WITH %d ERRORS!\n" % failed_assertions)
		quit(1)

func describe(suite_name: String) -> void:
	current_suite = suite_name
	print("\n[%s]" % suite_name)

func assert_true(condition: bool, message: String) -> void:
	total_assertions += 1
	if condition:
		passed_assertions += 1
		print("  ✔ %s" % message)
	else:
		failed_assertions += 1
		print("  ✖ FAILED: %s" % message)

func assert_false(condition: bool, message: String) -> void:
	assert_true(not condition, message)

func assert_equal(val1: Variant, val2: Variant, message: String) -> void:
	total_assertions += 1
	if val1 == val2:
		passed_assertions += 1
		print("  ✔ %s" % message)
	else:
		failed_assertions += 1
		print("  ✖ FAILED: %s (Expected %s, got %s)" % [message, str(val2), str(val1)])
