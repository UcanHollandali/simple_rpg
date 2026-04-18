# Layer: UI helper
extends RefCounted
class_name RunSummaryCleanupHelper

const MAP_RUN_SUMMARY_CARD_NAME := "RunSummaryCard"


func cleanup_orphaned_map_run_summary_cards(tree_root: Node, active_scene_root: Node) -> int:
	if tree_root == null or not is_instance_valid(tree_root):
		return 0

	var cleaned_count: int = 0
	for child in tree_root.get_children():
		if child == null or not is_instance_valid(child):
			continue
		if child == active_scene_root:
			continue
		if not (child is CanvasItem):
			continue
		cleaned_count += _cleanup_map_run_summary_cards_under_root(child)
	return cleaned_count


func _cleanup_map_run_summary_cards_under_root(scene_root: Node) -> int:
	var cleaned_count: int = 0
	var stale_cards: Array[Node] = scene_root.find_children(MAP_RUN_SUMMARY_CARD_NAME, "Node", true, false)
	for stale_card in stale_cards:
		if not _is_orphaned_map_run_summary_card(stale_card):
			continue
		stale_card.queue_free()
		cleaned_count += 1
	return cleaned_count


func _is_orphaned_map_run_summary_card(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if String(node.name) != MAP_RUN_SUMMARY_CARD_NAME:
		return false
	return (
		node.get_node_or_null("StatsStack/StatusRows/HpRow/HpStatusLabel") != null
		and node.get_node_or_null("StatsStack/StatusRows/HungerRow/HungerStatusLabel") != null
		and (
			node.get_node_or_null("StatsStack/StatusRows/HungerRow/DurabilityStatusLabel") != null
			or node.get_node_or_null("StatsStack/StatusRows/DurabilityRow/DurabilityStatusLabel") != null
		)
	)
