# Coordination — Voidascend

Tento soubor zachycuje přesný stav rozepsané práce. Při každém startu sezení ho přečti. Při každém ukončení (i násilném) ho aktualizuj. Obsah se přepisuje — udržuje vždy aktuální stav, ne historii (ta patří do devlog.md).

---

## Aktuální stav

**Datum poslední aktualizace:** 2026-04-20
**Projekt:** Voidascend
**Aktivní úkol:** Dedikované tlačítko pro zap/vyp tester režimu v tester menu
**Stav:** hotovo, čeká na test uživatelem

### Změny v tomto sezení
- `scripts/hub.gd` — přidáno dedikované toggle tlačítko "🧪 Tester režim: ZAP/VYP" na začátek tester menu (hned po titulku). Text a barva odpovídají aktuálnímu stavu. Kliknutí volá `GameData.toggle_tester_mode()` + reload scény.
- `scripts/hub.gd` — "🔓 Odemknout všechny moduly" oddělen od toggle: dříve volal `toggle_tester_mode()` + `research_all_modules()`, teď volá jen `research_all_modules()`. Barva změněna na modrou (unlock akce, ne tester-specific).

### Rozhodnutí a kontext
- Uživatel nevěděl jak zapnout tester mód — ovládání bylo skryté v kombinovaném tlačítku "Odemknout všechny moduly" které dělalo dvě věci najednou
- Rozdělení: toggle = jen on/off flag; unlock = jen research; buy-10x = zůstává jen v tester módu

### Co je potřeba od uživatele
- Otevřít hub → kliknout na tlačítko "TESTER: VYP" vpravo dole → v menu kliknout na "Tester režim: VYP (klikni pro ZAP)" → ověřit že se zapne (text se změní, zobrazí se "Koupit 10×" tlačítko, v Obchodě se objeví záložka 🧪 Testovací).

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
