class_name Modal
extends PanelContainer

signal close_clicked

@export var title: String = "Title" : set = _set_title
@export_category('Nodes')
@export var content_container: MarginContainer
@export var title_label: Label

func _set_title(_title: String):
	title = _title
	
	if !is_node_ready():
		await ready
		
	title_label.text = title


func _on_close_button_pressed() -> void:
	close_clicked.emit()

func _on_child_entered_tree(node: Node):
	if node.owner != self:
		await ready
		node.reparent(content_container)
		
