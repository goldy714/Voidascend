# 🚀 VOID ASCENT — Game Design Document
**Verze:** 1.0  
**Platforma:** Mobilní (iOS / Android)  
**Žánr:** Arkádová střílečka + Roguelike + Ship Builder

---

## 1. PŘEHLED HRY

**Void Ascent** je mobilní arkádová hra kde hráč pilotuje modulárně sestavitelnou vesmírnou loď. Vydává se na mise po různých planetách, sbírá materiál, vylepšuje loď a bojuje s těžšími a těžšími nepřáteli. Po smrti začíná znovu, ale část pokroku si udržuje díky roguelike systému meta-progrese.

### Základní herní smyčka
1. Sestav loď v hangáru z dostupných modulů
2. Vydej se na misi na vybranou planetu
3. Bojuj, sbírej materiál, přežij boss
4. Po misi nakup a vyzkumej nové moduly
5. Opakuj — každým opakováním odemykáš lepší odměny

---

## 2. OVLÁDÁNÍ A BOJ

### Hybridní bojový systém
- **Pohyb:** Hráč ovládá loď pohybem (dotykové ovládání)
- **Střelba:** Automatická — všechny nainstalované zbraně střílí samy
- **Speciální schopnosti:** Hráč je aktivuje manuálně ťuknutím na tlačítko

### Typy misí (mix všech tří)
- **Vlnové mise** — přichází vlna za vlnou nepřátel, pak další vlna
- **Scrolling mise** — loď letí dopředu, nepřátelé přichází zprava
- **Boss mise** — každých 5 misí jeden unikátní velký boss

---

## 3. SYSTÉM LODÍ

Hráč začíná se základní lodí a postupem hry kupuje větší a silnější lodě za ingame měnu. Každá loď má unikátní grid a dvě unikátní schopnosti.

| Loď | Grid | Pasivní schopnost | Aktivní schopnost | Styl hry |
|---|---|---|---|---|
| 🔧 **Scout** (startovní) | 3×3 | +20% rychlost pohybu | Krátký dash (uhnutí) | Rychlý, agresivní |
| ⚔️ **Destroyer** | 4×3 | Zbraně mají +15% poškození | Salvová palba (všechny zbraně najednou) | Čistý combat |
| 🦾 **Harvester** | 3×4 | Sběrači mají 2× dosah | Magnetický pulz (přitáhne veškerý materiál) | Farming, bohatý run |
| 🛡️ **Fortress** | 4×4 | Štíty se pomalu regenerují | Neproniknutelný štít na 3 sekundy | Tankování, přežití |
| ⚡ **Phantom** | 3×3 | Speciální schopnosti se dobíjí 30% rychleji | Krátkodobá neviditelnost | Taktický, schopnosti |
| 🚀 **Titan** | 5×4 | Motory spotřebují méně energie | Warp skok (přeskočí část mise) | Endgame, vše najednou |

### Postup odemykání lodí
```
Scout → Destroyer nebo Harvester → Fortress nebo Phantom → Titan
```

---

## 4. MODULÁRNÍ SYSTÉM LODĚ

Loď má omezený **grid slotů**. Hráč se musí rozhodovat co do gridu dá — každé rozhodnutí je kompromis.

### Kategorie modulů

#### ⚔️ Zbraně
- Základní laser
- Dvojitý laser
- Plazmový laser
- Iontové dělo
- Rakety
- Broková střelba
- Kulomet

#### 🛡️ Štíty
- Energetický štít
- Odrazový štít (odrážuje projektily zpět)

#### ⚡ Speciální schopnosti (aktivní)
- Časové zpomalení — nepřátelé se zpomalí
- EMP — vyřadí nepřátele z provozu
- Opravná jednotka — opraví poškozené části lodě za boje
- Bojová stíhačka — přivolá AI wingmana na omezenou dobu

#### 🚀 Motory
- Čím silnější motor, tím dál loď v misi doletí
- Slabé motory = krátká mise, méně nepřátel, méně materiálu
- Silné motory = delší mise, těžší nepřátelé, více odměn
- Typy: Základní → Pokročilý → Iontový

#### 🦾 Sběrači (klepeta)
- Vypadají jako mechanická klepeta na boku lodě
- Automaticky se natáhnou k padlým nepřátelům a materiálu
- Bez nákladního prostoru nemají kam materiál uložit
- Více klepet = rychlejší a větší sběr

#### 📦 Nákladní prostor
- Bez něj nelze sbírat materiál
- Typy: Malý, Střední, Velký

### Strategická dilemata
- Víc zbraní = silnější boj, ale méně sběračů = méně materiálu
- Silné motory = delší mise, ale zaberou cenné sloty
- Bez nákladního prostoru klepeta jsou zbytečná
- Speciální schopnosti jsou silné, ale zaberou sloty zbraní

---

## 5. SYSTÉM MATERIÁLŮ A OBCHODU

### Dva druhy materiálu

| Materiál | Jak se získává | K čemu slouží |
|---|---|---|
| ⚙️ **Kovový šrot** (základní) | Padá z každého nepřítele, asteroidů, během misí | **Nákup** modulů v obchodě |
| 💎 **Void krystal** (vzácný) | Padá z všech nepřátel (málé množství), vzácných nepřátel (střední), bossů (velké množství) | **Výzkum** nových modulů |

### Systém výzkumu a nákupu
```
Void krystal → VÝZKUM → modul se odemkne v obchodě
Kovový šrot  → NÁKUP  → odemknutý modul si koupíš do lodě
```
Hráč nemůže koupit modul který nevyzkoumal. Výzkum je jednorázový, nákup opakovaný.

### Strom výzkumu — příklad (zbraně)
```
Základní laser (zdarma)
	↓ [výzkum: 2 💎]
Dvojitý laser
	↓ [výzkum: 5 💎]
Plazmový laser
	↓ [výzkum: 10 💎]
Iontové dělo (endgame)
```

### Příklad cen modulů

| Modul | Výzkum (💎) | Nákup (⚙️) |
|---|---|---|
| Kulomet | 3 | 150 |
| Bojová stíhačka | 8 | 400 |
| Iontový motor | 12 | 600 |
| Magnetický sběrač | 5 | 250 |
| Velký nákladní prostor | 4 | 200 |

### Zobrazení v obchodě
- 🔒 **Nezkoumané** → silueta, vidí cenu výzkumu
- 🔓 **Vyzkoumaný** → vidí cenu v kovovém šrotu, může koupit
- ✅ **Koupený a instalovaný** → svítí zeleně v gridu lodě

---

## 6. MAPA SVĚTA — PLANETY

### Struktura každé planety
```
Planeta → Mise 1 → Mise 2 → Mise 3 → BOSS → další planeta
```

### Planety a bossové

| # | Planeta | Prostředí | Nepřátelé | Boss | Boss loot |
|---|---|---|---|---|---|
| 1 | 🧊 **Glacius** | Ledová, bouře, meteority | Ledové drony, zmrazovací lodě | **Cryo Titan** | ❄️ Cryo Cannon — střely zpomalují nepřátele |
| 2 | 🌋 **Infernus** | Sopečná, láva, výbuchy | Ohnivé rakety, kamikaze lodě | **Magma Colossus** | 🔥 Magma Burst — výbuch poškodí všechny okolní nepřátele |
| 3 | ☢️ **Toxar** | Toxická mlha, kyselý déšť | Jedovaté drony, regenerující se lodě | **Plague Carrier** | ☣️ Toxic Shield — štít poškozuje přibližující se nepřátele |
| 4 | 🌑 **Shadowveil** | Temný vesmír, nulová viditelnost | Neviditelné lodě, EMP útoky | **Phantom Leviathan** | 👻 Phase Drive — loď se na 2 sekundy stane nehmotnou |
| 5 | 💀 **Void Station** | Nepřátelská vesmírná stanice | Elitní vojáci, obranné věže | **Void Commander** | ⚫ Void Core — pasivně zesílí všechny moduly o 20% |

### Nepřátelé
- Asteroidy a meteority (pohyblivé překážky)
- Nepřátelské lodě různých typů (střílí zpět)
- Vzácní nepřátelé (více Void krystalů)
- Boss lodě s unikátními útoky a fázemi

---

## 7. ROGUELIKE SYSTÉM

### Po smrti
- Hráč ztratí loď a moduly nainstalované v ní
- **Udržuje si:** odemčené moduly v obchodě, část nasbíraného materiálu, meta-progresní odměny

### Meta-progrese — systém opakování
Každá planeta má stupnici opakování (0–10 hvězd). Za každý run (i neúspěšný) hráč získává hvězdy.

#### Příklad odměn — planeta Glacius 🧊
| Opakování | Odměna |
|---|---|
| 2. run | +10% startovní materiál |
| 3. run | Odemkne nový modul v obchodě |
| 5. run | Startovní loď má předinstalovaný 1 slot navíc |
| 7. run | +25% materiál z nepřátel na této planetě |
| 10. run | Permanentní odemknutí unikátního modulu té planety |

#### Typy permanentních odměn
| Typ | Popis |
|---|---|
| 💰 Materiálový bonus | Začínáš s více materiálem |
| 🔧 Startovní modul | Loď začíná s jedním modulem navíc zdarma |
| 📦 Větší grid | Aktuální loď dostane +1 slot navíc |
| 🏪 Nové zboží | Odemkne lepší moduly v obchodě |
| ⭐ Unikátní modul | Speciální modul pouze z té planety |
| 🛡️ Pasivní buff | Např. +10% HP permanentně |

### Výsledný efekt progrese
```
1. run  → těžké, umíráš
5. run  → začínáš být silnější
10. run → planeta je zvládnutelná i pro nováčka
```

### Pomocná mechanika
Po 3 neúspěšných pokusech hráč dostane volitelnou pomocnou odměnu (bonus materiál).

---

## 8. BOSS LOOT — UNIKÁTNÍ MODULY

Každý boss upustí modul inspirovaný jeho stylem boje. **Jinak ho nelze získat.** Opakováním planety bosse porazíš znovu, ale unikátní modul dostaneš pouze jednou.

| Boss | Styl boje | Unikátní modul | Efekt |
|---|---|---|---|
| 🧊 Cryo Titan | Zmrazovací paprsky, ledové kry | ❄️ **Cryo Cannon** | Střely zpomalují nepřátele |
| 🌋 Magma Colossus | Ohnivé výbuchy, láva, fáze | 🔥 **Magma Burst** | Výbuch poškodí všechny nepřátele okolo |
| ☢️ Plague Carrier | Toxické mračno, regenerace | ☣️ **Toxic Shield** | Štít poškozuje nepřátele kteří se přiblíží |
| 🌑 Phantom Leviathan | Teleportace, neviditelnost | 👻 **Phase Drive** | Loď se na 2 sekundy stane nehmotnou |
| 💀 Void Commander | Vše najednou, elitní zbraně | ⚫ **Void Core** | Pasivně zesílí všechny ostatní moduly o 20% |

---

## 9. VIZUÁLNÍ STYL

- **Styl:** Moderní vesmír — efekty výbuchů, animované lasery, zářící štíty
- **Platforma:** Mobilní (dotykové ovládání)
- **Perspektiva:** 2D, pohled shora nebo zboku (scrolling)
- **UI:** Přehledné mobilní rozhraní, velká tlačítka pro speciální schopnosti

---

## 10. TECHNICKÉ POZNÁMKY PRO VÝVOJ

### Doporučený stack
- **Engine:** Godot 4 (podpora mobilních platforem, GDScript nebo C#)
- **Alternativa:** Unity s C# (větší ekosystém, více tutoriálů pro mobilní hry)
- **Vývoj:** Claude Code pro asistenci při programování

### Klíčové systémy k implementaci
1. Modulární grid systém lodě
2. Automatická střelba + manuální speciální schopnosti
3. Systém sběračů (klepeta + nákladní prostor)
4. Generátor vln nepřátel s rostoucí obtížností
5. Systém materiálů (šrot + void krystal)
6. Obchod s výzkumem a nákupem
7. Uložení meta-progrese mezi runy
8. Boss AI s fázemi

---

*Game Design Document — Void Ascent v1.0*  
*Vytvořeno: duben 2026*
