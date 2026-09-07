extends Control

signal objective_selected(quest_id: String)

@onready var title_label: Label = $PanelContainer/VBoxContainer/TitleLabel
@onready var objective_1_btn: Button = $PanelContainer/VBoxContainer/Objective1Btn
@onready var objective_2_btn: Button = $PanelContainer/VBoxContainer/Objective2Btn
@onready var banner_label: Label = $BannerLabel

var quests: Array = [
	{
		"id": "quest_waterwheel",
		"title": "Lower Millstone Sluice Gate",
		"desc": "Solve water sluice valves in Millstone Fields (Zone 1) to obtain Rusty Machete.",
		"time": "60s"
	},
	{
		"id": "quest_fen_shrine",
		"title": "Explore Whispering Fen",
		"desc": "Cut brambles with Machete, light Waypoint Shrine Alpha, defeat Moss Hulk.",
		"time": "90s"
	}
]

func _ready() -> void:
	if banner_label:
		banner_label.visible = false
	if objective_1_btn:
		objective_1_btn.text = "%s (%s)" % [quests[0].title, quests[0].time]
		objective_1_btn.pressed.connect(_on_objective_selected.bind(quests[0].id))
	if objective_2_btn:
		objective_2_btn.text = "%s (%s)" % [quests[1].title, quests[1].time]
		objective_2_btn.pressed.connect(_on_objective_selected.bind(quests[1].id))

func _on_objective_selected(quest_id: String) -> void:
	QuestManager.active_quest_id = quest_id
	show_banner("Active Objective Updated: " + quest_id)
	objective_selected.emit(quest_id)

func show_banner(msg: String) -> void:
	if banner_label:
		banner_label.text = msg
		banner_label.visible = true
		var tween = create_tween()
		tween.tween_interval(3.0)
		tween.tween_callback(func(): banner_label.visible = false)
