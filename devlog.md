# Devlog — Voidascend

Tento soubor zaznamenává vše, co bylo vyvinuto. Záznamy se pouze přidávají, nikdy nemění ani nemažou.

---

## 2026-04-20 — Voidascend: Tester mode toggle v hub menu

- `scripts/hub.gd` — dedikované tlačítko "🧪 Tester režim: ZAP/VYP" na začátku tester menu. Text a barva se řídí aktuálním stavem; kliknutí volá `toggle_tester_mode()` + reload scény.
- `scripts/hub.gd` — "🔓 Odemknout všechny moduly" oddělen od toggle: teď volá jen `research_all_modules()`, tester flag nezapíná. Barva změněna na modrou.
- Důvod: toggle byl skrytě zabalený v "Odemknout všechny moduly" — uživatel nevěděl jak zapnout tester režim samostatně.

---

## 2026-04-20 — Voidascend: Responsive tutoriálové menu

- `scripts/tutorial.gd` — `STEPS[*].arm_target` převedeno z absolutních pixelů na normalizované Vector2 (0..1 vůči viewportu). `_show_step` násobí velikostí viewportu. `_build_bubble` používá `offset_left = vp.x * 0.16`, `offset_top = vp.y * 0.49` — bublina má cca 312 px výšky na 720p (původně jen 135 px), proporce na 1080p zachovány.
- `scripts/tutorial_draw.gd` — konstanta `FP` nahrazena helperem `_get_fp()` (`vp.x * 0.081, vp.y * 0.859`). `_draw_tail` počítá `bx` a `mid_y` z viewportu — tail teď míří horizontálně od bubliny k helmě v jakémkoliv rozlišení.
- Důvod: tutoriál byl navržen pro 1920×1080, ale viewport projektu byl změněn na 1280×720 → postava byla mimo obrazovku a bublina příliš úzká.

---

## 2026-04-20 — Voidascend: Testovací moduly (skrytá sekce)

- `scripts/autoloads/game_data.gd` — nový flag `is_test: true` na modulech (první kandidát: `magnet_collector`). Helper `is_test_module(id) -> bool`. `toggle_tester_mode()` při přechodu ON→OFF projde `installed_modules` a každý slot s test modulem nahradí "" (auto-uninstall). `owned_modules` counts zůstávají — modul jen zmizí z UI
- `scripts/shop.gd` — přidána záložka 🧪 "Testovací" (viditelná jen v tester režimu, žlutě zabarvená). Test moduly se zobrazí pouze v této záložce; v ostatních (včetně "Vše") jsou skryté. V záložce "Testovací" zobrazeny pouze test moduly
- `scripts/hangar.gd` — inventář filtruje test moduly, pokud není tester_mode (vlastněné kopie zůstávají v `owned_modules`, jen UI je skryje)
- Účel: holding area pro experimentální moduly, které se do build/release nedostanou nebo se zatím balancují. První modul tímto způsobem odkloněný: magnet_collector (IK rameno — vizuálně uložené na později)

---

## 2026-04-20 — Voidascend: Sběrače jako fyzická ramena

- `scripts/collector_arm.gd` — nový skript (class_name CollectorArm, Node2D). State machine IDLE → REACHING → GRABBING → RETRACTING. Dva vizuální typy: teleskopická trubka s klepetem (otvírá se při nataho­vání, zavírá při uchopení) a 2-link IK rameno s magnetickou podkovou na tipu (law of cosines, elbow_sign = náhodná strana ohybu)
- `scripts/autoloads/game_data.gd` — `get_player_stats()` vrací nově `stats["collectors"]` (array {slot, type, reach, attract_radius}) pro každý instalovaný sběrač. basic_collector → "telescope" reach 90. magnet_collector → "ik" reach 180, attract_radius 120 (pasivní přitahování okolních pickupů k tipu)
- `scripts/pickup.gd` — claim/unclaim/is_claimed API, `attract_to_point(p, strength)`. Claimed pickup má zastavenou vlastní fyziku (pozici řídí arm). Zpětně kompatibilní `attract_to(target)` alias
- `scripts/player.gd` — `_apply_modules` volá `_spawn_collector_arms(ship)` — CollectorArm instance pro každý záznam ve stats.collectors, pozicovaný přes ShipDraw.get_grid_origin + CELL. Odstraněn starý `_attract_pickups()`. Arm se nespawnuje bez cargo modulu
- `scripts/ship_draw.gd` — `draw_ship()` má parametr `draw_collectors: bool = true`. Když false (na hráčské lodi v misi), collector slot vykreslí `_draw_collector_mount` (malý socket) místo plné ikony — rameno pak overlay-uje jako samostatný Node2D. V hangáru/shopu zůstala plná ikona

---

## 2026-04-19 — Voidascend (initial commit — retrospektiva)

**Projekt:** `Voidascend/` — Godot 4.6, GL Compatibility renderer, 1920×1080

### Co bylo hotovo v initial commitu

**Herní smyčka:**
- Scény: `main_menu` → `hub` → `planet_map` → `game` → zpět do `hub`
- Pause menu s tipy, navigací a výběrem rozlišení (HD / HD+ / Full HD / 2K / Fullscreen)

**Datová vrstva (`game_data.gd` autoload):**
- 2 lodě: Scout (3×3 grid, dash ability) a Destroyer (4×3 grid, salvo ability)
- 5 planet: Glacius, Infernus, Toxar, Shadowveil, Void Station — odemykání postupem (4 mise = nová planeta)
- 23 modulů ve 6 kategoriích: zbraně (basic_laser, double_laser, plasma_laser, ion_cannon, rockets, shotgun, minigun), štíty (energy, reflect), motory (basic, advanced, ion), sběrače (basic, magnet), cargo (small, medium, large), speciální schopnosti (time_slow, emp, repair_unit, fighter_drone)
- Systém výzkumu (void_crystals) + nákupu (metal_scrap)
- Instalace modulů do mřížky slotů, swap/move/unequip
- Výpočet statistik hráče z instalovaných modulů + lodní passive bonusy
- Meta progrese: bonusy za opakované běhy na planetě (metal_pickup_mult, start_metal_bonus)
- Ukládání/načítání stavu do JSON (`user://savegame.json`)
- Tester mode (neomezené suroviny)

**Herní scéna (`game.gd`):**
- Generovaný hvězdný background
- Wave spawner se signály (wave_started, wave_completed, all_waves_completed)
- HUD s HP, metal, crystals, wave číslem, ability timer
- Game over / victory flow s výpisem sebraných surovin
- Přenos výsledků zpět do GameData (metal keep 100% při výhře, 50% při prohře)

**Ostatní skripty:**
- `player.gd` — pohyb, střelba, ability systém, sběr pickupů, smrt
- `enemy_basic.gd` — základní nepřítel + wave_spawner s variantami (basic, rare)
- `hangar.gd`, `hangar_inv_row.gd`, `hangar_slot_btn.gd` — správa modulů v hangáru
- `hub.gd` — přehled zdrojů a navigace
- `shop.gd` — výzkum a nákup modulů
- `planet_map.gd` — výběr planety a mise
- `pickup.gd` — sběr krystalů a kovu
- `hud.gd` — herní overlay
- `tutorial.gd`, `tutorial_draw.gd` — tutoriál pro nové hráče
- `ship_draw.gd`, `ship_preview.gd`, `ship_hangar_view.gd` — vizualizace lodí

**Assets:**
- Generované PNG assety (`assets/generate_assets.py`)
- Lode: scout, destroyer
- Nepřátelé: enemy_basic, enemy_rare
- Moduly: cargo, collector, engine, shield, special, weapon
- Pickupy: crystal, metal
- Kulky: player, enemy
- FX: planet_glacius
