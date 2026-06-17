extends Resource
class_name BaseQuest

@export var quest_id: String
@export var quest_name: String
@export var dialogue: DialogueResource
@export var items_needed: Array[quest_requirements]

func can_complete(inventory_slots: Array) -> bool:
	if items_needed.size() == 0:
		return true
	for req in items_needed:
		var count = 0
		for slot in inventory_slots:
			if slot != null and slot.id == req.item.id:
				count += 1
		if count < req.quantity:
			return false
			
	return true
