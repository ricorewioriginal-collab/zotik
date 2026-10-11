class_name NgPlusMenu
extends MenuPanel
## New Game+: restart the story with everything the player owns; enemies get tougher.


func refresh() -> void:
	super()
	var next: int = GameState.ng_plus + 1
	title_label.text = "Neues Spiel+ (Stufe %d)" % next
	info_label.text = "Du behältst Gegenstände, Ausrüstung, Lun, Andenken, Bestiarium und Arena-Rekorde. Die Geschichte beginnt von vorn – Gegner haben +%d%% Leben, +%d%% Angriff und +%d%% Verteidigung, Bosse bekommen eine Raserei-Phase. Der Weltenriss bleibt offen." % [50 * next, 35 * next, 25 * next]
	add_row("Neues Spiel+ beginnen", [["Beginnen", start]])
	add_row("Lieber nicht", [["Zurück", close_menu]])


func start() -> void:
	close_menu()
	GameState.begin_new_game_plus()
	App.pending_load = false
	App.goto_scene.call_deferred(App.SCENE_GAME_ROOT)
