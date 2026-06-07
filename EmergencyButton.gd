extends Area3D

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.has_method("is_local_player") and body.is_local_player():
		body.set("in_meeting_zone", self)

func _on_body_exited(body):
	if body.has_method("is_local_player") and body.is_local_player():
		if body.get("in_meeting_zone") == self:
			body.set("in_meeting_zone", null)
