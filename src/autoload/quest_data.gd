extends Node

var available_quest:Dictionary = {
	"Napoleon_1" : "res://assets/quest/misi_napoleon_1.tres",
	"Napoleon_2" : "res://assets/quest/misi_napoleon_2.tres",
	"Napoleon_3" : "res://assets/quest/misi_napoleon_3.tres"
}

var active_quests: Dictionary = {}

var completed_quest_ids: Array[String] = []

func accept_quest(quest: BaseQuest):
	if quest and not active_quests.has(quest.quest_id) and not completed_quest_ids.has(quest.quest_id):
		active_quests[quest.quest_id] = quest
		print("Quest Diterima: ", quest.quest_name)
		emit_signal("quest_list_changed")

func try_complete_quest(quest_id: String) -> bool:
	if active_quests.has(quest_id):
		var quest = active_quests[quest_id]
		if quest.can_complete(Inventory.slots):
			_remove_quest_items(quest)
			completed_quest_ids.append(quest_id)
			active_quests.erase(quest_id)
			print("Quest Selesai: ", quest.quest_name)
			emit_signal("quest_list_changed")
			return true
	return false

func _remove_quest_items(quest: BaseQuest):
	for req in quest.items_needed:
		for n in range(req.quantity):
			Inventory.erase(req.item.id)

func get_quest_status(quest_id: String) -> String:
	if completed_quest_ids.has(quest_id):
		return "completed"
	if active_quests.has(quest_id):
		return "active"
	return "not_started"

signal quest_list_changed
