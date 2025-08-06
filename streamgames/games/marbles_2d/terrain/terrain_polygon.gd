class_name TerrainPolygon
extends Polygon2D

@export_category('Nodes')
@export var collision_polygon: CollisionPolygon2D

func _ready() -> void:
	collision_polygon.polygon = polygon
