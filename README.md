# Zombie?

**Zombie?** is an intense Co-op Zombie Survival (Wave Shooter) game on Roblox. Players must work together to survive endless waves of the undead, complete challenging missions, and upgrade their arsenal to face powerful bosses.

## 🎮 Game Overview

*   **Genre:** Co-op Survival / Wave Shooter
*   **Goal:** Survive increasingly difficult waves, defeat bosses, and complete the story (Wave 50).
*   **Perspective:** First-Person / Third-Person Shooter

## 🕹️ Game Modes

*   **Story Mode:** The standard mode where players aim to survive until Wave 50 to complete the chapter.
*   **Crazy Mode:** A hardcore challenge for veteran players.
    *   *Rules:* No Revives, Friendly Fire ON, Limited Perks, Increased Enemy Stats.

## ✨ Key Features

### Combat System
*   **Raycast Ballistics:** Accurate shooting mechanics with recoil, spread, and damage drop-off.
*   **Critical Hits:** Headshot multipliers reward precision aiming.
*   **Weapon Variety:** Pistols, Assault Rifles, Shotguns, SMGs, LMGs, and Snipers.
*   **Upgrades:** In-game "Pack-a-Punch" style weapon upgrades (Levels 1-3).

### Enemy Roster
*   **Common Infected:** Standard zombies.
*   **Runner:** Low HP but high speed.
*   **Shooter:** Ranged attacker that leaves acid pools.
*   **Tank:** Massive HP pool, requires focused fire.
*   **Bosses:** Unique encounters with multi-phase mechanics:
    *   *Plague Titan:* Radiation aura and corrosive slams.
    *   *Void Ascendant:* Orbital strikes and platforming phases.
    *   *The Blighted Alchemist:* Chemical warfare.

### Progression & Economy
*   **Points (Session):** Earned by damaging zombies. Used for buying weapons, perks, and unlocking map areas. Reset after game over.
*   **Coins (Persistent):** Earned by completing waves and games. Used for skins and permanent unlocks.
*   **XP & Levels:** Account progression that unlocks Titles and Rewards.
*   **Skill Tree:** Permanent passive buffs (Health+, Reload Speed+, etc.).
*   **Perks:** In-game buffs (Juggernog-style HP boost, Speed Cola-style reload boost, etc.).

### Mission System
*   **Daily & Weekly Tasks:** Rotating objectives (e.g., "Get 50 Headshots") to earn rewards.
*   **Reroll System:** Players can reroll missions they don't like.

## 🛠️ Technical Architecture

The project utilizes a robust **Service-Manager Pattern** to ensure scalability and maintainability.

### Core Structure
*   **ServerScriptService (Logic):**
    *   `GameManager`: Orchestrates the main game loop (Wave State, Voting, Win/Loss).
    *   `WeaponManager`: Server-side validation for combat and hit registration.
    *   `DataStoreManager`: Handles all data persistence (Player Data & Global Data) with caching.
    *   `LobbyManager`: Manages pre-game logic, profiles, and daily rewards.
*   **ReplicatedStorage (Shared):**
    *   `GameConfig`: Centralized configuration for balancing (Economy, Difficulty).
    *   `ZombieConfig` & `WeaponModule`: Data definitions for entities and items.

### Key Technologies
*   **DataStoreService:** For saving player stats, inventory, and leaderboards.
*   **RemoteEvents/Functions:** Secured networking for Client-Server communication.
*   **ModuleScripts:** Modular code organization.

## 📝 Credits
*   **Development:** One-Man Army Agent (Game Design, UI/UX, Programming, VFX, Building, Audio, Physics, Animation).

---
*Documentation generated automatically based on project analysis.*
