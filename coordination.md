# Coordination — Voidascend

Tento soubor zachycuje přesný stav rozepsané práce. Při každém startu sezení ho přečti. Při každém ukončení (i násilném) ho aktualizuj. Obsah se přepisuje — udržuje vždy aktuální stav, ne historii (ta patří do devlog.md).

---

## Aktuální stav

**Datum poslední aktualizace:** 2026-04-19
**Projekt:** Voidascend
**Aktivní úkol:** Tester menu
**Stav:** hotovo

### Co je hotovo (initial commit)
- Celá herní smyčka: main_menu → hub → planet_map → game → hub
- Datová vrstva: 2 lodě, 5 planet, 23 modulů v 6 kategoriích
- Save/load systém (JSON)
- Hangár, shop, wave spawner, HUD, tutorial
- Meta progrese, tester mode

### Změny v tomto sezení
- `project.godot` — viewport změněn z 1920×1080 na 1280×720
- `scripts/module_icon.gd` — přidáno `mouse_filter = MOUSE_FILTER_IGNORE` → drag modulů funguje i kliknutím na ikonu
- `master` větev přejmenována na `main` (GitHub default branch přepnut ručně uživatelem)
- `scripts/game.gd` — přidáno 5. rozlišení do pause menu: 3840×2160 (4K / UHD)
- `scripts/autoloads/settings_menu.gd` — nový autoload, vizuálně identický s pause menu z mise; stejné tlačítka, tip, rozlišení submenu
- `project.godot` — registrován autoload SettingsMenu
- `scripts/hangar.gd`, `shop.gd`, `planet_map.gd`, `hub.gd` — Esc otevírá SettingsMenu.open()
- `scripts/main_menu.gd` — Esc + ⚙ tlačítko volají SettingsMenu.open(); odstraněno duplicitní _open_resolution_menu

### Co je potřeba od uživatele
- Reload projektu v Godot editoru (Project → Reload Current Project) kvůli novému autoloadu SettingsMenu — jinak parse error v hangar/shop/planet_map/hub/main_menu

---

## Šablona pro aktivní úkol

Při zahájení práce na úkolu vyplň a vlož sem:

```
**Projekt:** Voidascend
**Aktivní úkol:** <co děláme>
**Stav:** in-progress | blocked | waiting-for-user

### Kroky
- [x] hotový krok
- [ ] aktuální krok ← ZDE JSME SKONČILI
- [ ] další krok

### Otevřené soubory / změny
- `scripts/soubor.gd` — co v něm měníme

### Rozhodnutí a kontext
- důležité rozhodnutí nebo kontext, který není zřejmý z kódu

### Co je potřeba od uživatele (pokud blocked)
- otázka nebo blokátor
```

---

## Instrukce pro Claude

1. **Na začátku sezení:** přečti tento soubor → navaz přesně tam, kde předchozí sezení skončilo.
2. **Během práce:** aktualizuj sekci "Aktuální stav" při každé větší změně (nový krok hotov, nový blokátor, nové rozhodnutí).
3. **Na konci sezení:** aktualizuj stav na poslední nedokončený krok, přidej kontext nutný pro navázání.
4. **Po dokončení úkolu:** přesuň shrnutí do devlog.md, sekci "Aktuální stav" vynuluj.
