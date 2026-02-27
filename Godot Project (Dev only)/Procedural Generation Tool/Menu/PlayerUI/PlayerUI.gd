class_name PlayerUI
extends CanvasLayer

#region REFERENCES
@onready var menuContainer : PanelContainer = %MenuContainer
@onready var flyToggleLbl : Label = %FlyToggleLbl
#Console 
@onready var consoleLabelContainer : PanelContainer = $ConsoleContainer
@onready var consoleLabel : RichTextLabel = %ConsoleRichLabel
#Performance monitor 
@onready var monitorLabelContainer : PanelContainer = $PerformanceMonitorContainer
@onready var monitorLabel : RichTextLabel = %MonitorRichLabel

#...............................................................................
#endregion REFERENCES


#region INSTANCE VARIABLES 
#Console sizes 
var consoleCollapsedHeight : float = 100.0
var consoleExpandedHeight : float = 400.0
var consoleCollapsedWidth : float = 350.0
var consoleExpandedWidth : float = 500.0
#Performance monitor console size 
var monitorCollapsedHeight : float = 50.0
var monitorExpandedHeight : float = 400.0
var monitorCollapsedWidth : float = 350.0
var monitorExpandedWidth : float = 500.0
var isExpanded : bool = false

#...............................................................................
#endregion INSTANCE VARIABLES 

#---------------------CONTRUCTOR AND PROCESSES----------------------------------
func _ready() -> void:
	#Hide the menu, since we do not want to see it as it shows up 
	hideMenu()
	
	#Clear console 
	consoleLabel.text = ""
	#Connect the console to the RichTextLabel 
	ConsoleManager.set_console(consoleLabel)
	#Set the initial minimum size of the console 
	if is_instance_valid(consoleLabelContainer):
		consoleLabelContainer.custom_minimum_size.y = consoleCollapsedHeight
		consoleLabelContainer.custom_minimum_size.x = consoleCollapsedWidth
	#Set the initial minimum size of the performance monitor  
	if is_instance_valid(monitorLabelContainer):
		monitorLabelContainer.custom_minimum_size.y = monitorCollapsedHeight
		monitorLabelContainer.custom_minimum_size.x = monitorCollapsedWidth

func _input(event):
	if event.is_action_pressed("enter_key"):  # Enter key
		#Change expansion 
		isExpanded = !isExpanded
		#Console 
		toggleConsoles(consoleLabelContainer, consoleLabel, 100, 500, 350, 500)
		#Performance monitor 
		toggleConsoles(monitorLabelContainer, monitorLabel, 50, 500, 350, 500)
		if !isExpanded:
			monitorLabel.scroll_following = false #Remove auto scroll
			monitorLabel.scroll_to_line(0) #Scroll to the first line
		
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	#Show hide the menu
	if event.is_action_pressed("options-menu"):
		toggleMenu()

func flyToggleText(isFlying : bool) -> void:
	var startingText : String = "Flying: "
	if isFlying:
		flyToggleLbl.text = startingText + "on"
		ConsoleManager.log("Flying was turned ON")
	else:
		flyToggleLbl.text = startingText + "off"
		ConsoleManager.log("Flying was turned OFF")
	

## Make the console bigger or smaller 
func toggleConsoles(container : PanelContainer, richTextLabel : RichTextLabel,
collapsedHeight : float, expandedHeight : float, collapsedWidth : float, expandedWidth : float):
	if isExpanded:
		#Show mouse 
		Basics.mouseArrowShow()
		#Expand and pause
		container.custom_minimum_size.y = expandedHeight
		container.custom_minimum_size.x = expandedWidth
		get_tree().paused = true
		richTextLabel.scroll_following = false  #Allow manual scrolling
	else:
		#Hide mouse
		Basics.mouseArrowHide()
		#Collapse and unpause
		container.custom_minimum_size.y = collapsedHeight
		container.custom_minimum_size.x = collapsedWidth
		get_tree().paused = false
		richTextLabel.scroll_following = true  #Auto-scroll to latest
		#Scroll to bottom when collapsing
		richTextLabel.scroll_to_line(richTextLabel.get_line_count())


#===MENU FUNCTIONS===
func showMenu():
	menuContainer.show()
	Basics.mouseArrowShow()
	get_tree().paused = true


func hideMenu():
	menuContainer.hide()
	Basics.mouseArrowHide()
	get_tree().paused = false


func toggleMenu():
	#Check if menu is visible or not 
	if menuContainer.visible:
		hideMenu()
	else:
		showMenu()

#...............................................................................


#---------------------------------SIGNALS---------------------------------------
func _on_menu_btn_pressed() -> void:
	toggleMenu()

func _on_resume_btn_pressed() -> void:
	hideMenu()

func _on_exit_btn_pressed() -> void:
	# Reset UI state (collapse consoles, hide menu)
	isExpanded = false
	hideMenu()
	
	# Make sure game is unpaused
	get_tree().paused = false
	
	# Show mouse cursor BEFORE transitioning
	Basics.mouseArrowShow()
	
	# Return to main menu
	get_tree().change_scene_to_file("res://Menu/MainMenu/MainMenu.tscn")

#...............................................................................
