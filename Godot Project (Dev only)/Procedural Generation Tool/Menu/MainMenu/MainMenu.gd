extends Control

@onready var currentSeedLineEdit : LineEdit = %CurrentLineEdit
@onready var customSeedLineEdit : LineEdit = %CustomLineEdit
@onready var selectSeedTextArray : Array[LineEdit] = [
	$PanelContainer/VBoxContainer/SelectSeedsContainer/SelectSeed1/SeedSelectLineEdit,
	$PanelContainer/VBoxContainer/SelectSeedsContainer/SelectSeed2/SeedSelectLineEdit,
	$PanelContainer/VBoxContainer/SelectSeedsContainer/SelectSeed3/SeedSelectLineEdit,
	$PanelContainer/VBoxContainer/SelectSeedsContainer/SelectSeed4/SeedSelectLineEdit,
	$PanelContainer/VBoxContainer/SelectSeedsContainer/SelectSeed5/SeedSelectLineEdit]


func _ready() -> void:
	# Make sure that the game is not paused and show mouse always 
	get_tree().paused = false 
	Basics.mouseArrowShow()
	
	#Add current seed to the LineEdit text 
	currentSeedLineEdit.text = str(Stats.currentSeed)
	
	#Fill in select seeds texts 
	fillSelectSeedsText()

func fillSelectSeedsText() -> void:
	for i in selectSeedTextArray.size():
		selectSeedTextArray[i].text = str(Stats.defaultSeeds[i])

func _on_random_seed_btn_pressed() -> void:
	var randomSeed = randi_range(0, 999999)
	customSeedLineEdit.text = str(randomSeed)

#When pressing the select button, set the current seed to the default numbers 
#If a mistake was done in code and number is bigger or smaller than array, default it to 0
func selectSeed(index : int) -> void:
	if (index < 0 || index > Stats.defaultSeeds.size()):
		index = 0
	Stats.currentSeed = Stats.defaultSeeds[index]
	#Add current seed to the LineEdit text 
	currentSeedLineEdit.text = str(Stats.currentSeed)


func _on_start_game_btn_pressed() -> void:
	#If the custom field is empty, run the current one, if not, run the custom one 
	if (customSeedLineEdit.text.is_empty()):
		Stats.fastNoiseLiteGenerator.set_seed(Stats.currentSeed)
	else:
		var randomSeed : int 
		#If the custom field has only numbers, use that as the seed, if there are string or anything else, hash it and then run the custom one 
		if (customSeedLineEdit.text.is_valid_int()): 
			randomSeed = int(customSeedLineEdit.text)
		else:
			randomSeed = hash(customSeedLineEdit.text)
		Stats.randomNumGen.set_seed(randomSeed)
	get_tree().change_scene_to_file("res://Menu/LoadingScreen/LoadingScreen.tscn")


func _on_select_seed_pressed(index : int) -> void:
	selectSeed(index)
