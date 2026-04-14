# Layer: Tests
extends SceneTree
class_name TestBossPhases

const RunStateScript = preload("res://Game/RuntimeState/run_state.gd")
const CombatPresenterScript = preload("res://Game/UI/combat_presenter.gd")

var _domain_events: Array[Dictionary] = []


func _init() -> void:
	test_gate_warden_starts_in_first_phase()
	test_gate_warden_threshold_change_waits_until_turn_end()
	test_briar_sovereign_can_reach_deepest_phase_from_threshold_check()
	test_authored_bosses_define_phase_blocks()
	print("test_boss_phases: all assertions passed")
	quit()


func test_gate_warden_starts_in_first_phase() -> void:
	var flow: CombatFlow = _build_boss_flow("gate_warden")
	assert(flow.combat_state.has_boss_phases(), "Expected gate_warden boss combat to expose boss phase truth.")
	assert(String(flow.combat_state.boss_phase_id) == "iron_watch", "Expected gate_warden combat to start in the authored first phase.")
	assert(String(flow.combat_state.boss_phase_display_name) == "Iron Watch", "Expected first boss phase display name to stay authored.")
	assert(String(flow.combat_state.current_intent.get("intent_id", "")) == "pressing_bash", "Expected setup to reveal the first intent from the first phase pool.")
	var presenter: RefCounted = CombatPresenterScript.new()
	assert(
		presenter.call("build_enemy_token_texture_path", flow.combat_state) == "res://Assets/Enemies/enemy_gate_warden_token.png",
		"Expected live gate_warden boss combat to expose the dedicated boss token path."
	)

	var combat_started_event: Dictionary = _find_domain_event("CombatStarted")
	assert(not combat_started_event.is_empty(), "Expected CombatStarted signal payload to be emitted during boss setup.")
	assert(String(combat_started_event.get("boss_phase_id", "")) == "iron_watch", "Expected CombatStarted payload to expose the initial boss phase id.")
	assert(String(combat_started_event.get("boss_phase_display_name", "")) == "Iron Watch", "Expected CombatStarted payload to expose the initial boss phase display name.")


func test_gate_warden_threshold_change_waits_until_turn_end() -> void:
	var flow: CombatFlow = _build_boss_flow("gate_warden")
	_domain_events.clear()
	flow.combat_state.enemy_hp = 18
	flow.combat_state.enemy_state["hp"] = 18

	assert(String(flow.combat_state.current_intent.get("intent_id", "")) == "pressing_bash", "Expected threshold crossing alone not to replace the already revealed current intent.")

	var turn_end_result: Dictionary = flow.process_turn_end()
	assert(int(turn_end_result.get("current_turn", -1)) == 2, "Expected turn end to advance the combat turn before revealing the new phase intent.")
	assert(String(flow.combat_state.boss_phase_id) == "chain_unbound", "Expected gate_warden to enter the second authored phase once HP is at or below 60 percent.")
	assert(String(flow.combat_state.current_intent.get("intent_id", "")) == "warden_cleave", "Expected phase change to reset the phase-local intent pool to its first intent.")

	var phase_event: Dictionary = _find_domain_event("BossPhaseChanged")
	assert(not phase_event.is_empty(), "Expected BossPhaseChanged signal when the boss phase threshold is crossed.")
	assert(String(phase_event.get("phase_id", "")) == "chain_unbound", "Expected BossPhaseChanged payload to expose the authored phase id.")
	assert(int(phase_event.get("threshold_percent", -1)) == 60, "Expected BossPhaseChanged payload to expose the authored threshold percent.")

	var presenter: RefCounted = CombatPresenterScript.new()
	assert(
		presenter.format_domain_event_line("BossPhaseChanged", phase_event) == "Boss phase: Chain Unbound.",
		"Expected combat presenter to expose a player-facing boss phase line."
	)


func test_briar_sovereign_can_reach_deepest_phase_from_threshold_check() -> void:
	var flow: CombatFlow = _build_boss_flow("briar_sovereign")
	_domain_events.clear()
	flow.combat_state.enemy_hp = 10
	flow.combat_state.enemy_state["hp"] = 10

	flow.process_turn_end()
	assert(String(flow.combat_state.boss_phase_id) == "ruin_harvest", "Expected low HP to resolve directly into the deepest authored briar_sovereign phase.")
	assert(int(flow.combat_state.boss_phase_index) == 3, "Expected briar_sovereign deepest phase to use the fourth authored slot.")
	assert(String(flow.combat_state.current_intent.get("intent_id", "")) == "sovereign_harvest", "Expected deepest phase to reveal its first intent after the threshold swap.")


func test_authored_bosses_define_phase_blocks() -> void:
	var loader: ContentLoader = ContentLoader.new()
	for definition_id in ["gate_warden", "chain_herald", "briar_sovereign"]:
		var enemy_definition: Dictionary = loader.load_definition("Enemies", definition_id)
		var rules: Dictionary = enemy_definition.get("rules", {})
		var boss_phases: Array = rules.get("boss_phases", [])
		assert(boss_phases.size() >= 2, "Expected boss definition '%s' to author at least two phases." % definition_id)
		assert(String((boss_phases[0] as Dictionary).get("phase_id", "")) != "", "Expected boss phase entries to carry phase ids.")
	var presenter: RefCounted = CombatPresenterScript.new()
	var unresolved_token_path: String = presenter.call("build_enemy_token_texture_path", _build_boss_flow("chain_herald").combat_state)
	assert(
		unresolved_token_path == "res://Assets/Enemies/enemy_chain_herald_token.png",
		"Expected stage-2 live boss combat to expose the dedicated chain_herald boss token path."
	)


func _build_boss_flow(definition_id: String) -> CombatFlow:
	_domain_events.clear()
	var loader: ContentLoader = ContentLoader.new()
	var run_state: RunState = RunStateScript.new()
	run_state.reset_for_new_run()
	run_state.player_hp = RunState.DEFAULT_PLAYER_HP
	run_state.hunger = RunState.DEFAULT_HUNGER

	var weapon_definition: Dictionary = loader.load_definition("Weapons", "iron_sword")
	var enemy_definition: Dictionary = loader.load_definition("Enemies", definition_id)
	var flow: CombatFlow = CombatFlow.new()
	flow.connect("domain_event_emitted", Callable(self, "_on_domain_event_emitted"))
	flow.setup_combat(run_state, enemy_definition, weapon_definition, {
		"encounter_node_family": "boss",
		"is_boss_combat": true,
	})
	return flow


func _on_domain_event_emitted(event_name: String, payload: Dictionary) -> void:
	_domain_events.append({
		"event_name": event_name,
		"payload": payload.duplicate(true),
	})


func _find_domain_event(event_name: String) -> Dictionary:
	for event_entry in _domain_events:
		if String(event_entry.get("event_name", "")) != event_name:
			continue
		return (event_entry.get("payload", {}) as Dictionary).duplicate(true)
	return {}
