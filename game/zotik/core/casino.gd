class_name Casino
extends RefCounted
## "Golden Star Casino": virtual Lun only, never real money (C-20). Families
## can switch it off (Settings.casino_enabled). Expected return ~93 %.

const SYMBOLS := ["Mond", "Blatt", "Kristall", "Flamme", "Stern"]
const WEIGHTS := [30, 30, 20, 15, 5]
const TRIPLE_MULT := {"Mond": 5, "Blatt": 5, "Kristall": 12, "Flamme": 8, "Stern": 25}
const PAIR_MULT := 1
const BETS := [10, 50, 100]

static var rng := RandomNumberGenerator.new()


static func enabled() -> bool:
	return bool(Settings.get_value("casino_enabled"))


static func _roll() -> String:
	var total := 0
	for w in WEIGHTS:
		total += w
	var r := rng.randi_range(1, total)
	for i in SYMBOLS.size():
		r -= WEIGHTS[i]
		if r <= 0:
			return SYMBOLS[i]
	return SYMBOLS[0]


static func payout(reels: Array, bet: int) -> int:
	if reels[0] == reels[1] and reels[1] == reels[2]:
		return bet * int(TRIPLE_MULT[reels[0]])
	if reels[0] == reels[1] or reels[1] == reels[2] or reels[0] == reels[2]:
		return bet * PAIR_MULT
	return 0


## Returns {} if the spin is not allowed, else {reels, win}.
static func spin(bet: int) -> Dictionary:
	if not enabled() or not bet in BETS or GameState.currency < bet:
		return {}
	Inventory.add_currency(-bet)
	var reels := [_roll(), _roll(), _roll()]
	var win := payout(reels, bet)
	if win > 0:
		Inventory.add_currency(win)
	GameState.casino.spins = int(GameState.casino.spins) + 1
	GameState.casino.best_win = maxi(int(GameState.casino.best_win), win)
	return {"reels": reels, "win": win}


## Exact expected return per Lun bet (used by tests and the info text).
static func expected_return() -> float:
	var total := 0.0
	for w in WEIGHTS:
		total += w
	var ev := 0.0
	for a in SYMBOLS.size():
		for b in SYMBOLS.size():
			for c in SYMBOLS.size():
				var p: float = WEIGHTS[a] / total * WEIGHTS[b] / total * WEIGHTS[c] / total
				ev += p * payout([SYMBOLS[a], SYMBOLS[b], SYMBOLS[c]], 1)
	return ev
