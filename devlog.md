# Devlog — Voidascend

Tento soubor zaznamenává vše, co bylo vyvinuto. Záznamy se pouze přidávají, nikdy nemění ani nemažou.

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
