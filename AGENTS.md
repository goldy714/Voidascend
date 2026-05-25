# AGENTS — Voidascend

Tento soubor obsahuje stabilní instrukce pro AI agenty pracující na projektu. Průběžný stav rozepsané práce patří do `coordination.md`; historický changelog patří do `devlog.md`.

## Start sezení v gitu

1. Na začátku každé session zkontroluj `git status`.
2. Pokud pracovní strom neobsahuje rozpracované změny, fetchni nové změny a checkoutni `main`.
3. Pokud checkout nebo fetch blokují lokální změny či konflikt, nepoužívej force; zastav a požádej uživatele o rozhodnutí.

## Práce se stavem

1. **Na začátku sezení:** přečti `coordination.md` a navaz přesně tam, kde předchozí sezení skončilo.
2. **Během práce:** aktualizuj v `coordination.md` sekci "Aktuální stav" při každé větší změně (nový krok hotov, nový blokátor, nové rozhodnutí).
3. **Na konci sezení:** aktualizuj stav na poslední nedokončený krok a přidej kontext nutný pro navázání.

## Dokumentace změn

1. **Každá větší dokončená změna:** zapiš do `devlog.md` krátký funkční záznam. Stačí 1–2 odrážky o tom, co se změnilo pro uživatele nebo hru; nepiš cesty k souborům ani technické detaily, pokud nejsou nezbytné.
2. **Po dokončení úkolu:** zkontroluj, že větší změny mají záznam v `devlog.md`, a v `coordination.md` vynuluj sekci "Aktuální stav".
