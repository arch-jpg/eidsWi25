# 📜 Game Design Document (GDD)

## 1. Einleitung & Vision
### 1.1 Überblick
> [Kurze Beschreibung des Spiels und seines Ziels.]

### 1.2 Ziele
> [Was soll das Spiel erreichen? (z. B. Spaß, Spannung, Wiederholbarkeit)]

### 1.3 Zielplattformen
> [z. B. PC (Windows), Nintendo Switch]

### 1.4 Zielgruppe
> [Casual, Hardcore, Teenager, Strategiefans usw.]

---

## 2. Gameplay Overview

### 2.1 Core Gameplay Loop
>  kämpfen → belohnt werden → upgraden → sterben

### 2.2 Steuerung
> Maus, Tastatur, Touch-Pad?

### 2.3 Kamera & Perspektive
> 2D Side-View

### 2.4 Fortschrittssystem
> Karten freischalten durch Kämpfen, Elektrum sammeln für trading
> Player Stats upgraden ?

### 2.5 Schwierigkeitsgrad & Balancing
> gibt nur einen

---

## 3. Welt & Story

### 3.1 Setting
> Mittelalter, Fantasy, Bedrückent, Ernst, Wahnsinnig 

### 3.2 Hauptcharakter(e)
> - Name: [Spieler legt fest]  
> - Rolle: Anti-Hero 
> - Motivation: gab keine Milch  
> - Fähigkeiten: Karten

### 3.3 Nebencharaktere
> Händler, Spielergruppe?

### 3.4 Storystruktur
> 1. wird böse/wahnsinnig weil keine Milch 
> 2. bekämpf alle bis zum Gutsherren 
> 3. Evil Nummer Eins

## 4. Systeme & Regeln

### 4.1 Kampfsystem
> Rundenbasiert mit Karten
> Energie System versteckt, 1xAtt 1xDef und Inf Cantrips pro Zug
> Große Dmg etc. Zahlen!
> ~~Elemental/Piercing/Slash/Blund Dmg Types?~~
> crit Dmg als Card effect
> Statuseffekte? Weak -> Macht weniger dmg, Vulnerable mache mehr Dmg, (Spikes?Werfe Dmg zurück), Dodge?Playerstat?
> Strength?, Stun?, Blind?, Verwundbarkeit für bestimmte Cards?, Poison/Fire/TickDmg?, 
> Block
> Tokens als Zeit und Reaktion Counter der effekte

### 4.2 Inventar & Items
> Kartendeck, ~~5 auf Hand~~/Overdraw , 15 im Deck? 
> Card-Collection
> Relikte?

### 4.3 KI-System
> scripted attack patterns

### 4.4 Wirtschaft / Handel
> mit Elektrum Karten kaufen

---

## 5. Interface (UI / UX)

### 5.1 HUD
> SpielerHP, GegnerHP, Karten, Leglimitierung, Relikte, Gegner move, Knopf für Deck, End-Turn

### 5.2 Menüs & Navigation
- Hauptmenü
	- Spielen
		- Start Round
		- Change Deck
		- Händler
	- Exit
	- Titel
	- Lautstärke oder Mute ?

### 5.3 Nutzererlebnis
> sehr intuitiv 

---

## 6. Grafik & Audio

### 6.1 Grafikstil
> 2D Pixelart

### 6.2 Farbpalette & Atmosphäre
> schwarz, braun, weiß, grau, rot, orange

### 6.3 Animationen
> idle, angriff, sterben

### 6.4 Sounddesign
> ?

---

## 7. Technische Details

### 7.1 Engine & Tools
> Godot 4.4, Aseprite, VSCode

### 7.2 Plattformanforderungen
> soll laufen


### 7.4 Speichersystem
> Carddatabase als Json
> lokal in json, sav?

---

## 8. Produktionsplan

### 8.1 Teamstruktur
> alles

### 8.2 Zeitplan / Milestones
> - Mainmenu
> - Spielermenu
> - Karten
> - Deckbuilder
> - Kampf-loop
> - Map-Design
> - Gegner und Spieler Design
> - Balancing


---

## 9. Testing & QA

### 9.1 Testmethoden
> selber spielen

### 9.2 Feedback-Zyklus
> Leute die wir zum testen zwingen
> Übungleiter
> wir

> wenn Feedback dann wird geändert

### 9.3 Balancing-Prozess
> nach gefühl

---
