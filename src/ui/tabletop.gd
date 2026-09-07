class_name Tabletop
extends Control

## Main Game Tabletop scene coordinating the game state, UI views, player interaction, and bot turns.

const CardData = preload("res://src/core/card_data.gd")
const MeldData = preload("res://src/core/meld_data.gd")
const MeldValidator = preload("res://src/core/meld_validator.gd")
const MatchManager = preload("res://src/core/match_manager.gd")
const RoundState = preload("res://src/core/round_state.gd")
const ScoreCalculator = preload("res://src/core/score_calculator.gd")
const PlayerState = preload("res://src/core/player_state.gd")

const CardView = preload("res://src/ui/card_view.gd")
const HandView = preload("res://src/ui/hand_view.gd")
const PileView = preload("res://src/ui/pile_view.gd")
const HudView = preload("res://src/ui/hud_view.gd")
const MeldGroupView = preload("res://src/ui/meld_group_view.gd")
const MeldGroupViewScene = preload("res://src/ui/meld_group_view.tscn")

var match_mgr: MatchManager = null
var current_round: RoundState = null

@onready var hud: HudView = $HUD
@onready var stock_pile: PileView = $CenterTable/PilesContainer/StockPile
@onready var discard_pile: PileView = $CenterTable/PilesContainer/DiscardPile
@onready var morto_pile: PileView = $CenterTable/PilesContainer/MortoPile

@onready var player_hand: HandView = $PlayerArea/PlayerHand
@onready var opponent_hand: HandView = $OpponentArea/OpponentHand

@onready var player_melds_container: HBoxContainer = $PlayerMeldsScroll/PlayerMelds
@onready var opponent_melds_container: HBoxContainer = $OpponentMeldsScroll/OpponentMelds

@onready var meld_button: Button = $ActionBar/HBox/MeldButton
@onready var discard_button: Button = $ActionBar/HBox/DiscardButton
@onready var sort_suit_button: Button = $ActionBar/HBox/SortSuitButton
@onready var sort_rank_button: Button = $ActionBar/HBox/SortRankButton

func _init() -> void:
	match_mgr = MatchManager.new(2000, 2)

func _ready() -> void:
	Engine.max_fps = 30
	_resolve_nodes()
	
	# Connect Button signals
	if meld_button != null and not meld_button.pressed.is_connected(_on_meld_button_pressed):
		meld_button.pressed.connect(_on_meld_button_pressed)
	if discard_button != null and not discard_button.pressed.is_connected(_on_discard_button_pressed):
		discard_button.pressed.connect(_on_discard_button_pressed)
	if sort_suit_button != null and not sort_suit_button.pressed.is_connected(sort_player_suit):
		sort_suit_button.pressed.connect(sort_player_suit)
	if sort_rank_button != null and not sort_rank_button.pressed.is_connected(sort_player_rank):
		sort_rank_button.pressed.connect(sort_player_rank)
	
	# Connect Pile signals
	if stock_pile != null and not stock_pile.pile_clicked.is_connected(_on_stock_clicked):
		stock_pile.pile_clicked.connect(_on_stock_clicked)
	if discard_pile != null and not discard_pile.pile_clicked.is_connected(_on_discard_pile_clicked):
		discard_pile.pile_clicked.connect(_on_discard_pile_clicked)
	if discard_pile != null and not discard_pile.card_dropped.is_connected(_on_card_dropped_on_discard):
		discard_pile.card_dropped.connect(_on_card_dropped_on_discard)
	
	if player_hand != null:
		if not player_hand.card_selection_changed.is_connected(_on_card_selection_changed):
			player_hand.card_selection_changed.connect(_on_card_selection_changed)
		if not player_hand.card_clicked_event.is_connected(_on_hand_card_clicked):
			player_hand.card_clicked_event.connect(_on_hand_card_clicked)
	
	start_new_round()

func _resolve_nodes() -> void:
	if hud == null and has_node("HUD"): hud = get_node("HUD") as HudView
	if stock_pile == null and has_node("CenterTable/PilesContainer/StockPile"): stock_pile = get_node("CenterTable/PilesContainer/StockPile") as PileView
	if discard_pile == null and has_node("CenterTable/PilesContainer/DiscardPile"): discard_pile = get_node("CenterTable/PilesContainer/DiscardPile") as PileView
	if morto_pile == null and has_node("CenterTable/PilesContainer/MortoPile"): morto_pile = get_node("CenterTable/PilesContainer/MortoPile") as PileView
	if player_hand == null and has_node("PlayerArea/PlayerHand"): player_hand = get_node("PlayerArea/PlayerHand") as HandView
	if opponent_hand == null and has_node("OpponentArea/OpponentHand"): opponent_hand = get_node("OpponentArea/OpponentHand") as HandView
	if player_melds_container == null and has_node("PlayerMeldsScroll/PlayerMelds"): player_melds_container = get_node("PlayerMeldsScroll/PlayerMelds") as HBoxContainer
	if opponent_melds_container == null and has_node("OpponentMeldsScroll/OpponentMelds"): opponent_melds_container = get_node("OpponentMeldsScroll/OpponentMelds") as HBoxContainer
	if meld_button == null and has_node("ActionBar/HBox/MeldButton"): meld_button = get_node("ActionBar/HBox/MeldButton") as Button
	if discard_button == null and has_node("ActionBar/HBox/DiscardButton"): discard_button = get_node("ActionBar/HBox/DiscardButton") as Button
	if sort_suit_button == null and has_node("ActionBar/HBox/SortSuitButton"): sort_suit_button = get_node("ActionBar/HBox/SortSuitButton") as Button
	if sort_rank_button == null and has_node("ActionBar/HBox/SortRankButton"): sort_rank_button = get_node("ActionBar/HBox/SortRankButton") as Button

func sort_player_suit() -> void:
	if player_hand != null: player_hand.sort_by_suit()

func sort_player_rank() -> void:
	if player_hand != null: player_hand.sort_by_rank()

func start_new_round() -> void:
	if match_mgr == null:
		match_mgr = MatchManager.new(2000, 2)
	current_round = match_mgr.start_new_round()
	_update_all_ui()
	if hud != null:
		hud.show_announcement("Nova Rodada! Clique no MONTE ou no LIXO para comprar.", 4.0)

func _update_all_ui() -> void:
	if current_round == null:
		return
		
	_resolve_nodes()
	var p0: PlayerState = current_round.players[0]
	var p1: PlayerState = current_round.players[1]
	
	# Update Hands
	if player_hand != null:
		player_hand.set_cards(p0.hand)
	if opponent_hand != null:
		opponent_hand.set_cards(p1.hand) # Renders face down
	
	# Update Piles
	if stock_pile != null:
		stock_pile.set_pile_state(current_round.stock_pile.size())
	if discard_pile != null:
		var top_disc: CardData = current_round.discard_pile.back() if not current_round.discard_pile.is_empty() else null
		discard_pile.set_pile_state(current_round.discard_pile.size(), top_disc)
	if morto_pile != null:
		morto_pile.set_pile_state(current_round.mortos.size())
	
	# Update Melds
	if player_melds_container != null:
		_refresh_melds(player_melds_container, p0.melds)
	if opponent_melds_container != null:
		_refresh_melds(opponent_melds_container, p1.melds)
	
	_update_action_buttons()

func _update_action_buttons() -> void:
	if current_round == null:
		return
		
	_resolve_nodes()
	var is_player_turn: bool = (current_round.current_player_index == 0)
	var can_meld: bool = is_player_turn and (current_round.current_phase == RoundState.TurnPhase.ACTION)
	var sel_count: int = player_hand.get_selected_cards().size() if player_hand != null else 0
	
	if meld_button != null:
		meld_button.disabled = not (can_meld and sel_count >= 3)
		if can_meld and sel_count >= 3:
			meld_button.text = "Baixar Jogo (%d)" % sel_count
		else:
			meld_button.text = "Baixar Jogo"
			
	if discard_button != null:
		discard_button.disabled = not (can_meld and sel_count == 1)
		if can_meld and sel_count == 1:
			discard_button.text = "Descartar (1)"
		else:
			discard_button.text = "Descartar"
	
	# Update HUD
	if hud != null:
		var turn_str: String = "Vez do Jogador (Você)" if is_player_turn else "Vez do Bot (Adversário)..."
		var score_str: String = "Placar: Você %d  x  %d Bot" % [
			match_mgr.cumulative_scores[0],
			match_mgr.cumulative_scores[1]
		]
		
		var prompt_str: String = ""
		if current_round.is_round_over:
			prompt_str = "Fim da Rodada! Vencedor: %s" % ("Você" if current_round.winner_player_id == 0 else "Bot")
		elif is_player_turn:
			if current_round.current_phase == RoundState.TurnPhase.DRAW:
				prompt_str = "👉 Clique no MONTE ou no LIXO para comprar uma carta."
			else:
				if sel_count == 0:
					prompt_str = "Selecione cartas na mão para Baixar (mín. 3) ou 1 carta para Descartar."
				elif sel_count == 1:
					prompt_str = "1 carta selecionada: clique em 'Descartar' para encerrar o turno."
				elif sel_count == 2:
					prompt_str = "2 cartas selecionadas: selecione mais uma para formar um jogo (mín. 3)."
				else:
					prompt_str = "%d cartas selecionadas: clique em 'Baixar Jogo' para colocar na mesa." % sel_count
		else:
			prompt_str = "Aguarde a jogada do Bot..."
			
		hud.update_status(turn_str, score_str, prompt_str)

func _refresh_melds(container: HBoxContainer, melds: Array[MeldData]) -> void:
	for child in container.get_children():
		child.queue_free()
		
	for meld in melds:
		var mgv: MeldGroupView = MeldGroupViewScene.instantiate() as MeldGroupView
		container.add_child(mgv)
		mgv.setup(meld)
		mgv.append_card_requested.connect(_on_append_card_requested)

func _on_stock_clicked(_type: String) -> void:
	if current_round == null:
		return
	if current_round.current_player_index != 0:
		if hud != null: hud.show_announcement("Aguarde a sua vez!")
		return
	if current_round.current_phase != RoundState.TurnPhase.DRAW:
		if hud != null: hud.show_announcement("Você já comprou nesta rodada! Agora baixe jogos ou descarte.")
		return
		
	var drawn: CardData = current_round.draw_from_stock()
	if drawn != null:
		_update_all_ui()
		if hud != null:
			hud.show_announcement("Você comprou %s. Selecione cartas para jogar." % drawn.get_display_name())

func _on_discard_pile_clicked(_type: String) -> void:
	if current_round == null:
		return
	if current_round.current_player_index != 0:
		if hud != null: hud.show_announcement("Aguarde a sua vez!")
		return
	if current_round.current_phase != RoundState.TurnPhase.DRAW:
		if hud != null: hud.show_announcement("Você já comprou nesta rodada! Agora baixe jogos ou descarte.")
		return
		
	if current_round.discard_pile.is_empty():
		if hud != null: hud.show_announcement("O Lixo está vazio!")
		return
		
	var drawn: Array[CardData] = current_round.draw_from_discard_pile()
	if not drawn.is_empty():
		_update_all_ui()
		if hud != null:
			hud.show_announcement("Você pegou %d cartas do Lixo!" % drawn.size())

func _on_hand_card_clicked(_card: CardData) -> void:
	if current_round != null and current_round.current_player_index == 0:
		if current_round.current_phase == RoundState.TurnPhase.DRAW:
			if hud != null:
				hud.show_announcement("⚠️ Compre uma carta do MONTE ou LIXO primeiro para começar seu turno!", 2.5)

func _on_card_selection_changed(_selected: Array[CardData]) -> void:
	_update_action_buttons()

func _on_meld_button_pressed() -> void:
	if player_hand == null: return
	var selected: Array[CardData] = player_hand.get_selected_cards()
	if selected.size() < 3:
		return
		
	var res := current_round.play_new_meld(selected)
	if res.is_valid:
		player_hand.clear_selection()
		_update_all_ui()
		if hud != null:
			if res.canasta_type != MeldData.CanastaType.NONE:
				hud.show_announcement("CANASTRA FORMADA! (%s)" % ("LIMPA" if not res.is_dirty else "SUJA"), 3.0)
			else:
				hud.show_announcement("Jogo baixado com sucesso!")
		_check_round_end()
	else:
		if hud != null:
			hud.show_announcement("Erro: %s" % res.error_message)

func _on_discard_button_pressed() -> void:
	if player_hand == null: return
	var selected: Array[CardData] = player_hand.get_selected_cards()
	if selected.size() != 1:
		return
		
	_execute_player_discard(selected[0])

func _on_card_dropped_on_discard(_type: String, card: CardData) -> void:
	if current_round == null or current_round.current_player_index != 0 or current_round.current_phase != RoundState.TurnPhase.ACTION:
		return
	_execute_player_discard(card)

func _execute_player_discard(card: CardData) -> void:
	var discarded: bool = current_round.discard_card(card)
	if discarded:
		if player_hand != null:
			player_hand.clear_selection()
		_update_all_ui()
		_check_round_end()
		if not current_round.is_round_over:
			_trigger_bot_turn()

func _on_append_card_requested(meld: MeldData, card: CardData) -> void:
	if current_round == null or current_round.current_player_index != 0 or current_round.current_phase != RoundState.TurnPhase.ACTION:
		return
		
	var res := current_round.append_to_meld(meld.uid, [card])
	if res.is_valid:
		_update_all_ui()
		if hud != null:
			hud.show_announcement("Carta adicionada ao jogo na mesa!")
		_check_round_end()
	else:
		if hud != null:
			hud.show_announcement("Não é possível encaixar esta carta neste jogo.")

func _trigger_bot_turn() -> void:
	if current_round == null or current_round.is_round_over or current_round.current_player_index != 1:
		return
		
	# Add slight timer delay for bot feel
	if is_inside_tree():
		get_tree().create_timer(0.8).timeout.connect(_execute_bot_turn)
	else:
		_execute_bot_turn()

func _execute_bot_turn() -> void:
	if current_round == null or current_round.is_round_over or current_round.current_player_index != 1:
		return
		
	var bot: PlayerState = current_round.players[1]
	
	# 1. Bot Draw
	current_round.draw_from_stock()
	_update_all_ui()
	
	# 2. Bot Meld evaluation (simple heuristic)
	_bot_try_melds(bot)
	_update_all_ui()
	
	# 3. Bot Discard (discards last card in hand)
	if not bot.hand.is_empty() and current_round.current_phase == RoundState.TurnPhase.ACTION:
		var disc_card: CardData = bot.hand.back()
		current_round.discard_card(disc_card)
		
	_update_all_ui()
	_check_round_end()

func _bot_try_melds(bot: PlayerState) -> void:
	# Try groups of 3 cards in bot hand
	var h_size: int = bot.hand.size()
	for i in range(h_size):
		for j in range(i + 1, h_size):
			for k in range(j + 1, h_size):
				if i < bot.hand.size() and j < bot.hand.size() and k < bot.hand.size():
					var candidate: Array[CardData] = [bot.hand[i], bot.hand[j], bot.hand[k]]
					var res := current_round.play_new_meld(candidate)
					if res.is_valid:
						return # Melded one game per turn

func _check_round_end() -> void:
	if current_round != null and current_round.is_round_over:
		var results: Dictionary = match_mgr.finish_current_round()
		_update_all_ui()
		if hud != null:
			var win_text: String = "Você venceu a rodada!" if current_round.winner_player_id == 0 else "O Bot venceu a rodada!"
			hud.show_announcement("%s (Pontuação: Você %+d | Bot %+d)" % [
				win_text,
				results["scores"][0],
				results["scores"][1]
			], 5.0)
