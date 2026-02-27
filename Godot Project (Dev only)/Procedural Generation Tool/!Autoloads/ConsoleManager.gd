extends Node

var console_display : RichTextLabel

## Set the node that will display the messages 
## INFO run this in the class that contains the node for the console 
func set_console(console : RichTextLabel):
	console_display = console

## Log simple message 
func log(message : String):
	if console_display:
		console_display.append_text(message + "\n")
		console_display.scroll_to_line(console_display.get_line_count())

## Log important message 
func log_important(message : String):
	if console_display:
		console_display.append_text("[color=blue]IMPORTANT: " + message + "[/color]\n")
		console_display.scroll_to_line(console_display.get_line_count())

## Log error message 
func log_error(message : String):
	if console_display:
		console_display.append_text("[color=red]ERROR: " + message + "[/color]\n")
		console_display.scroll_to_line(console_display.get_line_count())

## Log warning 
func log_warning(message : String):
	if console_display:
		console_display.append_text("[color=yellow]WARNING: " + message + "[/color]\n")
		console_display.scroll_to_line(console_display.get_line_count())
