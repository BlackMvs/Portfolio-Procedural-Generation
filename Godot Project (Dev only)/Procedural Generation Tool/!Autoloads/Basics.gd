extends Node

#region MOUSE FUNCTIONS
#Use this when we definetly want the mouse arrow to be visible 
func mouseArrowShow():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

#Use this when we definetly want the mouse arrow to be hidden 
func mouseArrowHide():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

#Use this when we just want to switch between the mouse arrow modes from visible to hidden 
func mouseArrowShowHide():
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouseArrowShow()
	else:
		mouseArrowHide()

#...............................................................................
#endregion MOUSE FUNCTIONS
