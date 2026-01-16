# Deck System - Dokumentation

## Übersicht

Das Deck System ermöglicht es Spielern, ihr eigenes Kartendeck zu erstellen und in Kampfszenen zu verwenden. Das System besteht aus drei Hauptkomponenten:

1. **CardDatabase** - Verwaltet alle verfügbaren Karten
2. **DeckManager** - Verwaltet das aktuelle Deck des Spielers
3. **DeckEditor** - UI zum Erstellen und Bearbeiten des Decks

---

## DeckManager (Singleton)

Der `DeckManager` ist als Autoload registriert und global verfügbar.

### Wichtige Eigenschaften

- **MIN_DECK_SIZE**: 10 (Minimum-Anzahl Karten)
- **MAX_DECK_SIZE**: 999 (praktisch unbegrenzt)

### Hauptmethoden

#### Deck abrufen
```gdscript
# Alle Karten als Card-Objekte
var deck = DeckManager.get_deck()

# Nur die Card-IDs
var deck_ids = DeckManager.get_deck_card_ids()

# Deck-Größe
var size = DeckManager.get_deck_size()
```

#### Karten hinzufügen/entfernen
```gdscript
# Karte hinzufügen (gibt true zurück bei Erfolg)
DeckManager.add_card_to_deck("weak_punch")

# Karte an Index entfernen
DeckManager.remove_card_from_deck(0)

# Karte nach ID entfernen (erste Übereinstimmung)
DeckManager.remove_card_by_id("weak_punch")
```

#### Deck-Validierung
```gdscript
# Prüfen ob Deck gültig ist (min. 10 Karten)
if DeckManager.is_deck_valid():
    print("Deck ist spielbereit!")

# Prüfen ob weitere Karten hinzugefügt werden können
if DeckManager.can_add_card():
    print("Platz für mehr Karten")

# Deck-Info als String
var info = DeckManager.get_deck_info()
# Beispiel: "Deck Size: 15 (Min: 10)\nStatus: Valid ✓"
```

#### Deck-Verwaltung
```gdscript
# Deck leeren
DeckManager.clear_deck()

# Gesamtes Deck setzen
var new_deck_ids = ["weak_punch", "shield_bash", "heal_potion"]
DeckManager.set_deck(new_deck_ids)

# Deck speichern (erfolgt automatisch bei Änderungen)
DeckManager.save_deck()

# Deck laden
DeckManager.load_deck()
```

### Signals
```gdscript
# Wird aufgerufen wenn sich das Deck ändert
DeckManager.deck_changed.connect(_on_deck_changed)

# Wird aufgerufen wenn sich die Deck-Größe ändert
DeckManager.deck_size_changed.connect(_on_deck_size_changed)
```

---

## Verwendung in Kampfszenen

### Beispiel: Basis-Setup

```gdscript
extends Node2D

var hand: Array = []
var draw_pile: Array = []
var discard_pile: Array = []

func _ready():
    setup_deck()
    draw_starting_hand()

func setup_deck():
    # Deck vom DeckManager holen
    var deck_cards = DeckManager.get_deck()
    
    # In Draw Pile kopieren und mischen
    draw_pile = deck_cards.duplicate()
    draw_pile.shuffle()
    
    print("Deck geladen: %d Karten" % draw_pile.size())

func draw_card() -> Card:
    # Wenn Draw Pile leer, shuffle Discard Pile zurück
    if draw_pile.is_empty():
        if not discard_pile.is_empty():
            draw_pile = discard_pile.duplicate()
            draw_pile.shuffle()
            discard_pile.clear()
            print("Discard Pile zurück in Draw Pile gemischt")
    
    if not draw_pile.is_empty():
        return draw_pile.pop_front()
    
    return null

func draw_starting_hand(hand_size: int = 5):
    for i in range(hand_size):
        var card = draw_card()
        if card:
            hand.append(card)
            # Hier CardUI erstellen und zur Hand hinzufügen
```

### Beispiel: Karte spielen

```gdscript
func play_card(card: Card):
    # Karte aus Hand entfernen
    var index = hand.find(card)
    if index >= 0:
        hand.remove_at(index)
    
    # Karteneffekte ausführen
    for effect in card.effects:
        execute_effect(effect)
    
    # Karte auf Discard Pile legen
    discard_pile.append(card)

func execute_effect(effect: CardEffect):
    match effect.type:
        "damage":
            deal_damage(effect.value, effect.target)
        "heal":
            heal(effect.value)
        "block":
            gain_block(effect.value)
        "draw_cards":
            for i in range(effect.value):
                draw_card()
        # ... weitere Effekttypen
```

### Beispiel: Deck während des Spiels anpassen

```gdscript
# Karte dauerhaft zum Deck hinzufügen (Belohnung)
func add_card_reward(card_id: String):
    DeckManager.add_card_to_deck(card_id)
    print("Karte zum Deck hinzugefügt: ", card_id)

# Karte dauerhaft aus Deck entfernen (z.B. "Karte entfernen" Event)
func remove_card_from_deck_permanently(card_id: String):
    DeckManager.remove_card_by_id(card_id)
    print("Karte aus Deck entfernt: ", card_id)
```

---

## CardDatabase

Zugriff auf alle verfügbaren Karten im Spiel.

### Wichtige Methoden

```gdscript
# Einzelne Karte abrufen
var card = CardDatabase.get_card_by_id("weak_punch")

# Alle Karten
var all_cards = CardDatabase.get_all_cards()

# Nach Typ filtern
var attack_cards = CardDatabase.get_cards_by_type("attack")

# Nach Effekttyp filtern
var damage_cards = CardDatabase.get_cards_by_effect_type("damage")
var heal_cards = CardDatabase.get_cards_by_effect_type("heal")

# Nach Seltenheit filtern
var rare_cards = CardDatabase.get_cards_by_rarity("rare")

# Nach Energiekosten filtern
var one_cost_cards = CardDatabase.get_cards_by_energy_cost(1)

# Zufällige Karte
var random_card = CardDatabase.get_random_card()
```

### Verfügbare Effekttypen für Filter
- `"damage"` - Schadenseffekte
- `"heal"` - Heileffekte
- `"block"` - Blockeffekte
- `"draw_cards"` - Karten ziehen
- `"discard_cards"` - Karten abwerfen
- `"energy"` - Energieeffekte
- `"status_effect"` - Statuseffekte

---

## Card Klasse

Jede Karte ist ein `Card`-Objekt mit folgenden Properties:

```gdscript
card.id              # String - Eindeutige ID
card.name            # String - Anzeigename
card.description     # String - Beschreibung
card.type            # String - Kartentyp (attack, defense, cantrip)
card.rarity          # String - Seltenheit (common, uncommon, rare, legendary)
card.energy_cost     # int - Energiekosten
card.target          # String - Zieltyp
card.effects         # Array[CardEffect] - Alle Effekte
card.keywords        # Array[String] - Keywords
card.card_arts       # Array[String] - Pfade zu Icons
```

### Nützliche Card-Methoden

```gdscript
# Farbe basierend auf Seltenheit
var color = card.get_rarity_color()

# Prüfungen
if card.is_attack_card():
    print("Das ist eine Angriffskarte")

if card.has_keyword("fire"):
    print("Feuerkarte!")

# Karte duplizieren
var card_copy = card.duplicate_card()
```

---

## Deck Editor

Der Deck Editor ist über das Player Menu zugänglich (`player_menu.tscn`).

### Features
- **Filter nach Effekttypen**: All, Damage, Block, Heal, Draw, Discard, Energy, Status
- **Karten hinzufügen**: Klick auf Karte in "Available Cards"
- **Karten entfernen**: Klick auf Karte in "Your Deck"
- **Deck Info**: Zeigt aktuelle Größe und Validierungsstatus
- **Auto-Save**: Deck wird automatisch bei jeder Änderung gespeichert

### Zugriff zum Deck Editor

```gdscript
# Von einer anderen Scene zum Deck Editor wechseln
get_tree().change_scene_to_file("res://scenes/deck_editor/deck_editor.tscn")
```

---

## Speicherung

Das Deck wird automatisch gespeichert in:
```
user://player_deck.save
```

Format:
```json
{
    "deck": ["weak_punch", "shield_bash", "heal_potion", ...]
}
```

---

## Beispiel: Komplettes Kampfsystem

```gdscript
extends Node2D

const STARTING_HAND_SIZE = 5
const MAX_HAND_SIZE = 10

var hand: Array = []
var draw_pile: Array = []
var discard_pile: Array = []
var current_energy: int = 3
var max_energy: int = 3

func _ready():
    if not DeckManager.is_deck_valid():
        push_error("Deck ist nicht gültig!")
        return
    
    setup_battle()

func setup_battle():
    # Deck laden
    var deck = DeckManager.get_deck()
    draw_pile = deck.duplicate()
    draw_pile.shuffle()
    
    # Starthand ziehen
    for i in range(STARTING_HAND_SIZE):
        draw_card_to_hand()
    
    print("Kampf gestartet mit %d Karten" % draw_pile.size())

func draw_card_to_hand() -> bool:
    if hand.size() >= MAX_HAND_SIZE:
        print("Hand ist voll!")
        return false
    
    var card = draw_card()
    if card:
        hand.append(card)
        # Hier: CardUI erstellen und anzeigen
        return true
    
    return false

func draw_card() -> Card:
    if draw_pile.is_empty():
        reshuffle_discard_pile()
    
    if not draw_pile.is_empty():
        return draw_pile.pop_front()
    
    return null

func reshuffle_discard_pile():
    if discard_pile.is_empty():
        return
    
    draw_pile = discard_pile.duplicate()
    draw_pile.shuffle()
    discard_pile.clear()
    print("Deck neu gemischt!")

func can_play_card(card: Card) -> bool:
    return card.energy_cost <= current_energy

func play_card(card: Card):
    if not can_play_card(card):
        print("Nicht genug Energie!")
        return
    
    # Energie abziehen
    current_energy -= card.energy_cost
    
    # Karte aus Hand entfernen
    hand.erase(card)
    
    # Effekte ausführen
    for effect in card.effects:
        apply_effect(effect)
    
    # Auf Discard Pile legen
    discard_pile.append(card)

func apply_effect(effect: CardEffect):
    # Effekte hier implementieren
    pass

func end_turn():
    # Alle Handkarten abwerfen
    discard_pile.append_array(hand)
    hand.clear()
    
    # Energie zurücksetzen
    current_energy = max_energy
    
    # Neue Karten ziehen
    for i in range(STARTING_HAND_SIZE):
        draw_card_to_hand()
```

---

## Tipps & Best Practices

1. **Deck-Validierung**: Prüfe immer mit `DeckManager.is_deck_valid()` bevor ein Kampf startet
2. **Karten duplizieren**: Verwende `card.duplicate_card()` wenn du eine Karte modifizieren willst ohne das Original zu ändern
3. **Signals nutzen**: Verbinde dich mit `DeckManager.deck_changed` um auf Deck-Änderungen zu reagieren
4. **Effekttypen**: Nutze `CardDatabase.get_cards_by_effect_type()` für intelligente Filter
5. **Auto-Save**: Das Deck wird automatisch gespeichert, kein manuelles Speichern nötig

---

## Fehlerbehandlung

```gdscript
# Prüfen ob Karte existiert
if not CardDatabase.card_exists("unknown_card"):
    push_error("Karte existiert nicht!")

# Prüfen ob Deck geladen wurde
if DeckManager.get_deck_size() == 0:
    push_warning("Deck ist leer!")
    DeckManager.create_default_deck()

# Prüfen ob genug Karten zum Ziehen
if draw_pile.is_empty() and discard_pile.is_empty():
    push_warning("Keine Karten mehr zum Ziehen!")
```
