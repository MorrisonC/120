extends Area2D
class_name NPCDialogueTrigger

signal dialogue_opened(dialogue_text: String)
signal dialogue_closed()

@export var npc_name: String = "Village Elder"
@export var first_meeting_text: String = "Greetings traveler. The road ahead is blocked by ancient overgrown vines. Find the Shears in the village to clear your path."
@export var repeat_text: String = "The shears should be nearby in the village."

var has_met: bool = false
var is_dialogue_open: bool = false

func interact() -> String:
    var text = ""
    if not has_met:
        has_met = true
        text = first_meeting_text
    else:
        text = repeat_text

    is_dialogue_open = true
    emit_signal("dialogue_opened", text)
    return text

func close_dialogue():
    is_dialogue_open = false
    emit_signal("dialogue_closed")
