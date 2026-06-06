# Devlog — Voidascend

Tento soubor zaznamenává vše, co bylo vyvinuto. Nové záznamy se přidávají pro nové funkční oblasti; navazující změny ve stejné oblasti se slučují do nejnovějšího relevantního záznamu.

---

## 2026-06-06 — Voidascend: Základní sběrač 2

- Původní Základní sběrač je přejmenovaný na Základní sběrač 1.
- Nový Základní sběrač 2 má dvě nezávislé sbírací paže, takže zvládne současně sbírat dva materiály, a má o trochu delší dosah.

---

## 2026-06-06 — Voidascend: Decoy modul

- Nový Decoy modul je mezi štíty, spouští se klávesou G a vytvoří na 5 sekund holografickou kopii hráčovy lodi na pozici kurzoru.
- Nepřátelé po dobu aktivního decoye prioritně míří střelbu na kopii místo na hráče; po zmizení decoye se chování vrátí zpět a schopnost má 20sekundový cooldown.
- Pokud je kurzor u kraje obrazovky, Decoy se posune směrem dovnitř, aby byl celý vidět; HUD zobrazuje připravenost a cooldown G schopnosti.

---

## 2026-06-06 — Voidascend: Target marker modul

- Nový zbraňový modul Target marker označí jednoho náhodného nepřítele; cíl zůstane označený až do smrti a další se vybere po 2 sekundách.
- Označený nepřítel má výrazný zaměřovací kruh a dostává o 50 % vyšší poškození; současně může být označený jen jeden cíl.

---

## 2026-06-06 — Voidascend: Orbitální bombardování

- Nový aktivní modul Orbitální bombardování se spouští klávesou F a vyžaduje zadání palebného kódu nahoru, doleva, dolů, doprava.
- Po úspěšném zadání se po mapě objeví série varovaných orbitálních výbuchů, které zraňují nepřátele a nepoškozují hráčovu loď; bombardování míří na nepřátele, ale zhruba každý čtvrtý zásah dopadne vedle.
- HUD zobrazuje připravenost a cooldown F schopnosti, pokud je modul nainstalovaný.

---

## 2026-06-06 — Voidascend: Start ve Full HD

- Hra se při spuštění otevírá ve výchozím rozlišení 1920×1080 místo 1280×720.

---

## 2026-06-06 — Voidascend: Odinstalování modulů přes pravou část hangáru

- Instalovaný modul už není potřeba trefovat na malý spodní cíl; při přetažení na pravou část hangáru se zobrazí velká zóna pro odinstalování z lodi.
- Zóna komunikuje návrat modulu do inventáře místo mazání, takže akce působí bezpečněji a srozumitelněji.
- Odinstalační zóna reaguje i nad řádky, ikonami a texty inventáře, takže se neztratí při pohybu uvnitř jedné položky.
- Pravý inventář v hangáru znovu expanduje spolu s levou částí, takže po přepnutí na Full HD nezůstává úzký.

---

## 2026-05-28 — Voidascend: Crosshair cursor v misi

- Během gameplay mise se místo starship cursoru používá nový menší PixelLab crosshair v poloviční velikosti; po odchodu z mise se cursor vrátí zpět na loď.
- Starship cursor mimo misi nechává krátký jemný afterimage trail za lodí; crosshair cursor v misi zůstává čistý bez trailu.

## 2026-05-28 — Voidascend: Full-rotation starship cursor

- Starship cursor zůstává přichycený na skutečné pozici myši a plynule se plně otáčí podle směru pohybu bez zrcadlení nebo omezení na malý tilt.

## 2026-05-28 — Voidascend: Symetrický starship cursor

- Cursor lodi má nový symetričtější PixelLab asset s čitelným hrotem vlevo nahoře a diagonální siluetou vhodnou pro pointer.

## 2026-05-27 — Voidascend: Jemnější tilt starship cursoru

- Cursor lodi už se neotáčí ocasem ani neflipuje; drží pointer pose a jen se mírně naklání podle směru pohybu myši.

## 2026-05-27 — Voidascend: Oprava natočení zrcadleného cursoru

- Zrcadlení starship cursoru při pohybu doprava už nemění výpočet úhlu natočení, takže diagonální pohyb doprava dolů nepřeklápí loď do směru dolů.

## 2026-05-26 — Voidascend: Menší a zrcadlený starship cursor

- Starship cursor je o něco menší a při pohybu doprava se jeho obrázek zrcadlí, aby směr letu působil přirozeněji.

## 2026-05-26 — Voidascend: Plynulejší starship cursor

- Starship cursor teď krátce dohání skutečnou myš místo okamžitého skoku na její pozici.
- Zatáčení je omezené rychlostí, takže prudké změny směru působí širším obloukem a méně trhaně.

## 2026-05-26 — Voidascend: Oprava směru starship cursoru

- Dynamický cursor lodi už se natáčí špičkou po směru pohybu místo ocasem dopředu.

## 2026-05-26 — Voidascend: Dynamický starship cursor

- Cursor lodi se vykresluje jako vrchní overlay a plynule se natáčí podle směru pohybu myši, zatímco klikací bod zůstává na špičce.

## 2026-05-26 — Voidascend: Větší starship cursor

- PixelLab kurzor lodi je větší a natočený špičkou do levého horního rohu, aby působil čitelněji jako pointer.

## 2026-05-26 — Voidascend: PixelLab starship cursor

- Hra používá nový PixelLab kurzor ve tvaru malé top-down lodi se špičkou jako pointer.
- Cursor se nastavuje globálně přes autoload a drží stejný vzhled i nad tlačítky a drag/drop prvky.

## 2026-05-26 — Voidascend: Biome styl gameplay misí

- Během běžící mise se pozadí a ambientní částice jemně mění podle vybrané planety: led, láva, toxické spóry, stínové moty nebo stanice.
- Seznam misí na mapě zůstává čistý; biome motiv patří přímo do gameplay scény.

## 2026-05-26 — Voidascend: Animace panelu misí

- Panel misí při změně vybrané planety rychle přejde jemným fade/scale efektem, takže změna obsahu působí plynuleji.

## 2026-05-26 — Voidascend: Přesnější centrování planet nad popisky

- Mapa planet používá pro zobrazení oříznuté viditelné regiony PNG assetů, takže transparentní okraje už neposouvají planetu vůči názvu pod ní.

## 2026-05-26 — Voidascend: Zarovnání hover zoomu planet

- Planetární assety se při hover zoomu škálují kolem pevného pivotu a mapa kompenzuje vizuální střed PNG, takže planety zůstávají zarovnané s popisky.

## 2026-05-26 — Voidascend: Plynulejší hover zoom planet

- Hover na mapě planet je výraznější a rychle plynule dorůstá kolem středu planety, zatímco popisky a progress dots zůstávají stabilní.

## 2026-05-26 — Voidascend: Výraznější planetární barvy misí

- Řádky misí, stavové badge, texty a akční tlačítka v panelu misí výrazněji přebírají barvu vybrané planety i u splněných a zamčených stavů.

## 2026-05-26 — Voidascend: Hover efekt planet

- Planety na mapě se při najetí kurzorem jemně zvětší a už nezobrazují systémový tooltip s názvem planety.

## 2026-05-26 — Voidascend: Scrollovatelný vývojářský přehled

- Vývojářský přehled se přizpůsobuje velikosti obrazovky a obsah s architekturou i devlogem se posouvá uvnitř panelu místo přetékání mimo viewport.

## 2026-05-26 — Voidascend: Planetární motiv panelu misí

- Detail misí na mapě přebírá barvy vybrané planety pro pozadí panelu, řádky misí, badge a akční tlačítka.
- Aktivní mise, splněné mise i zamčené položky zůstávají stavově odlišené, ale vizuálně ladí s aktuální planetou.

## 2026-05-26 — Voidascend: PixelLab planety a responsivní mapa

- Mapa planet používá nové PixelLab PNG assety pro Glacius, Infernus, Toxar, Shadowveil a Void Station místo jednoduchých kruhů.
- Pozice planet, popisků a click zón se přepočítávají podle velikosti obrazovky; na užších viewports se panel misí přesune dolů a planety se zmenší, aby zůstaly na mapě čitelné.

## 2026-05-26 — Voidascend: PixelLab assety lodi a modulů

- Scout loď má nový PixelLab top-down trup s prázdnou 3×3 montážní plochou; kreslení používá nový PNG trup pod stávajícím module gridem, takže pozice slotů zůstávají zachované.
- Modulové assety jsou sjednocené od základních po pokročilé zbraně, štíty, motory, cargo a speciály; směrové moduly drží severní orientaci a zbraně mají čitelný kanón místo paprsku.
- Kreslení dává přednost novým jednovrstvým PNG assetům, ale dál zachovává podporu starších vrstvených i procedurálních fallbacků.

## 2026-05-26 — Voidascend: Doladění přetahování v hangáru

- Náhled přetahovaného modulu kreslí samotný modul přímo uprostřed čtverce, takže už neujíždí do rohu.
- Slot lodi pod kurzorem se při přetahování zvýrazní jako aktivní drop target.

## 2026-05-26 — Voidascend: Oprava přetahování v hangáru

- Přetahovaný modul je nově vycentrovaný přímo pod kurzorem při přesunu z inventáře i mezi sloty lodi.
- Náhled při přetahování už nezobrazuje druhý posunutý čtverec uvnitř ikony.

## 2026-05-25 — Voidascend: Dvoudílné modulové dlaždice

- Modulové ikony jsou znovu vygenerované jako čtvercové základny s výraznou samostatnou komponentou nahoře.
- Zbraně a technické moduly mají čitelnější vrchní část vhodnou pro pozdější rotaci, zatímco cargo, motory a speciály si drží vlastní vizuální charakter.

---

## 2026-05-25 — Voidascend: Square top-facing moduly

- Modulové ikony jsou sjednocené do čtvercových top-facing dlaždic, které vyplňují většinu dostupného prostoru.
- Ikony zůstávají průhledné kolem okrajů a zachovávají samostatné rozlišení jednotlivých modulů.

---

## 2026-05-25 — Voidascend: PixelLab moduly

- Každý modul má novou vlastní PixelLab ikonu místo sdílení jen šesti kategoriových symbolů.
- Hangár, obchod i náhled lodi používají nové ikonové PNG; původní procedurální kreslení zůstává jako záloha.

---

## 2026-05-25 — Voidascend: PixelLab nepřátelé

- Základní a vzácný nepřítel mají nové detailnější PixelLab sprity s průhledným pozadím, čitelným tvarem a výraznějším barevným odlišením.
- Generátor assetů tyto nové sprity při běžném spuštění nepřepíše starými placeholdery.

---

## 2026-05-25 — Voidascend: Dev window čte devlog

- Vývojářský přehled bere poslední změny automaticky z `devlog.md`, takže se nové záznamy nemusí dopisovat ještě do skriptu.

---

## 2026-05-25 — Voidascend: Animovaný dash Scouta

- Dash Scouta už není okamžitý teleport; loď se krátce plynule přesune cílovým směrem.
- Během dashe se zobrazuje modrý energetický tah a krátká dojezdová záře, nezranitelnost zůstává zachovaná.

---

## 2026-05-25 — Voidascend: Tester odemčení misí

- Tester menu umí jedním tlačítkem odemknout všechny mise.

---

## 2026-05-25 — Voidascend: AI workflow pravidla

- AI workflow má samostatné instrukce, start na mainu, krátký devlog a vlastní feature branch pro každou session.

---

## 2026-05-25 — Voidascend: Pohyblivé herní pozadí

- Herní scéna používá nový opakovatelný hvězdný background, který se plynule posouvá dolů a vytváří pocit letu vpřed.
- Původní vzhled pozadí zůstal zachovaný: stejná tmavá barva, seed a počet hvězd, jen se vykreslují ve dvou navazujících kopiích.

---

## 2026-05-20 — Voidascend: Doladění náhledu při přetahování

- Náhled přetahovaného modulu je menší, průsvitný a centrovaný na kurzoru.

---

## 2026-05-20 — Voidascend: Vizuální náhled při přesunu modulů

- Přetahování modulů v hangáru nově zobrazuje vizuální dlaždici modulu místo textového popisku.
- Chování je sjednocené pro moduly z inventáře i pro přesun mezi sloty lodi.

---

## 2026-05-20 — Voidascend: Úprava měřítka lodi v hangáru

- Náhled lodi v hangáru se teď přizpůsobuje dostupnému prostoru a nepřekrývá okolní UI.
- Interaktivní sloty zůstávají zarovnané s vizuálním náhledem lodi.

---

## 2026-05-20 — Voidascend: Dev window pro architekturu a poslední změny

- Přidán vývojářský přehled otevřitelný přes F1 nebo z nastavení.
- Přehled stručně popisuje architekturu hry a obecné změny od posledního spuštění.
- Obsah je určený jako rychlá orientace, ne jako detailní technický changelog.

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
