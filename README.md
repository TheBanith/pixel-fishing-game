# Pixel Fishing — Godot 4.3 (GL Compatibility)

Retro 320x180 16-bit pixel-art fishing game.

## Run
Open this folder in Godot 4.3+ (Project List -> Import -> select project.godot),
then F5 to run Main.tscn.

## Controls
- CAST  : Space  (or the CAST button) — drops the hook into the water
- REEL  : R / hold REEL button — once a fish bites, hold to win the tension minigame
- SHOP  : SHOP button — spend coins on gear upgrades (game pauses while open; Esc also closes)
- Keep the tension marker inside the GREEN zone to fill the progress bar and land the fish.
  Let tension hit 0 or 100 and it escapes.

## Audio (scripts/AudioManager.gd autoload)
Six channels (Splash/Bite/Reel/Catch/Coin/UI_Click), each an AudioStreamPlayer with a
safe loader — missing files are skipped silently. WAVs in assets/ are procedurally
generated 16-bit retro SFX (noise splash, square thump, ratchet loop, jingle, two-tone
coin, blip). Triggers: splash on line-in + pull-out, bite thump on strike, reel ratchet
loops while holding REEL during a fight, catch jingle on landing, coin on every sale and
upgrade purchase, click on all menu buttons. AudioManager runs while the tree is paused.

## Juice & Game Feel
- FloatingText.tscn/gd: "+N Coins!" pops (sales), catch names, "COOLER FULL!", escapes —
  float up + fade over 1.5 s, self-freeing.
- SplashParticles.tscn/gd: one-shot CPUParticles2D water splash; small on line-in,
  medium at bite/escape, large (double) when a boss is pulled out; self-frees on finish.
- CameraShake.gd: Camera2D shake(intensity, duration); light on bite, heavy on Stage-3
  boss hookup and boss landing.

## Stages & World Map (data/fish_data.json + scripts/Map.gd)
Every fish has a "stage" property. MAP on the HUD opens the World Map (pauses game):
- Oak Creek (Lv.1 Rod): Common Bass, River Carp, Stream Trout - background1
- Sunset Lake (Lv.2 Rod): Green Bass, Golden Carp, Silver Trout - background2
- Twilight Rapids (Lv.3 Rod): Trophy Bass, Royal Trout - background3
Locked stages show "Requires Lv.N Rod". Selecting a stage sets GameData.current_stage,
swaps the background via Main.load_stage(), clears active fish, and repopulates from
GameData.get_available_fish().

## Fish Market (data + scripts/Market.gd)
Catches no longer pay instantly — they land in your cooler as rich entries
(species, rarity, rolled weight 0.6x-1.8x base, sprite). Open the MARKET to sell:
- Payout formula: round(base_coins * weight / base_weight) — heavier fish pay more.
- Per-fish rows: thumbnail, rarity-colored name tag [R1-R5], weight, payout, individual SELL.
- Header shows COOLER n/max and total estimated value; SELL ALL dumps everything in one click
  (disabled when empty). Game pauses while open; Esc closes.
- HUD counters (COINS / BOX n/max) update live via GameData.coins_changed / cooler_changed.

## Gear Shop (data/shop_data.json + scripts/Shop.gd)
Three upgrade paths, max level 3 each:
- ROD     : widens the green safe zone (35 -> 48 -> 65)
- REEL    : faster hook sink + retrieve, stronger reel rate (x1.0 -> x1.3 -> x1.6)
- COOLER  : max stored fish 5 -> 10 -> 15 (catches are lost when full — HUD shows BOX n/max)
BUY buttons disable on insufficient coins or max level. Icons: fishing_reel1/fishing_ree2,
tackle_box1/2/3.

## Layout
- project.godot         : 320x180 viewport, canvas_items stretch, Nearest filter, GameData autoload
- data/fish_data.json   : 8 fish catalog (id,name,sprite,depth,speed,rarity,weight,coins)
- scripts/GameData.gd   : autoload singleton (coins, cooler, gear tiers, fish DB)
- scripts/Player.gd     : angler + rod-tip position
- scripts/Fish.gd       : swimming fish (bounce at bounds, in "fish" group)
- scripts/FishSpawner.gd: keeps a population alive, respawns on landing
- scripts/FishingLine.gd: draws line + hook via CanvasItem._draw
- scripts/FishingManager.gd: state machine IDLE->CASTING->HOOKED->REELING->CAUGHT + tension minigame
- scripts/HUD.gd        : pixel-bordered CAST/REEL buttons, coins, tension + progress bars
- scripts/Main.gd       : scene wiring

## Notes
- All sprites are 512x768 PNGs, scaled down in-scene for the 320x180 viewport.
- Apply Neumann nearest-neighbor upscaling per sprite if you want razor-sharp pixels
  when exported at a higher windowed resolution (set font/handheld scaling in project settings).
