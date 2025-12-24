# myprogress
# My Progress

A comprehensive progression system for Luanti that tracks player actions, awards experience points (XP), and grants trophies for major milestones.

## Features

* **6 Skills:** Mining, Digging, Lumbering, Farming, Building, and Combat.
* **Exponential Leveling:** Requirements grow as you get stronger, making high levels a true achievement.
* **3D Trophy System:** Earn physical trophies to decorate your base.
* **5 Material Tiers:** Progress from **Bronze** to **Silver**, **Gold**, **Mese**, and the legendary **Diamond**.
* **HUD:** A sleek, real-time interface tracking your progress toward the next level.
* **Leaderboard:** Compete with others using the `/top` command.

## Trophies

Trophies are awarded automatically as you level up your skills. Each skill has its own unique 3D model.
They automatically go into your inventory.

| Level | Tier |
| :--- | :--- |
| 1 - 2 | **Bronze** |
| 3 - 4 | **Silver** |
| 5 - 7 | **Gold** |
| 8 - 9 | **Mese** |
| 10+ | **Diamond** |

## Configuration

This mod supports the Minetest Settings menu. You can change the game pace without touching any code:

1. Go to **Settings** -> **All Settings** -> **Mods** -> **myprogress**.
2. Locate **myprogress_difficulty**.
3. Choose between:
    * **Hard**: Standard exponential growth (Default).
    * **Easy**: 50% XP requirements for faster leveling.

## Commands

* `/top`: Displays the global leaderboard for Total XP.
* `/mystats` : Displays all the info about your progress
