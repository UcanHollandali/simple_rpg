# Layer: UI
extends RefCounted
class_name StageTransitionPresenter


func build_title_text() -> String:
	return "The Next Road"


func build_summary_text(stage_index: int) -> String:
	return "Stage %d waits beyond the trees.\nStep forward when ready.\nOpen Settings if you need save or load." % stage_index
