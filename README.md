# Aetherveil

A fantasy action RPG on Roblox. Players choose an element, equip enchanted weapons and fight in the Veil.

This repo holds all the game's scripts. The world itself (the Void Dimension map, lighting) lives in the Studio place.

## Project layout

```
src/
├─ ReplicatedStorage/
│  ├─ Aetherveil/
│  │  ├─ Config/           ← edit these to balance or add content
│  │  │  ├─ Elements       elements, unlock costs, abilities
│  │  │  ├─ Weapons        weapons, rarities, prices, stats, 3D look
│  │  │  ├─ Store          game pass + developer product IDs, currency, rewards
│  │  │  └─ Settings       graphics / VFX / volume options and defaults
│  │  └─ Shared/
│  │     ├─ Net            remotes (Request, Data, Toast, Ability)
│  │     └─ WeaponModel    builds weapon models for tools and previews
│  └─ PortalConfig         Void element (Portal Walker) tuning
├─ ServerScriptService/
│  ├─ Aetherveil/
│  │  ├─ Main              bootstrap + validated request handlers
│  │  └─ Services/
│  │     ├─ PlayerData        DataStore: session lock, retries, autosave, BindToClose
│  │     ├─ Currency          Aether Shards (server only)
│  │     ├─ Purchases         game passes, ProcessReceipt for currency packs
│  │     ├─ ElementService    unlock / select elements
│  │     ├─ WeaponService     equip weapons, build tools, melee hits
│  │     ├─ ShopService       buy weapons with shards
│  │     ├─ ElementAbilities  Fire/Water/Earth/Air/Lightning abilities
│  │     ├─ Combat            damage, kill credit, kill rewards
│  │     ├─ GameFlow          menu ↔ game, spawning, respawning, passive income
│  │     └─ Notify            toasts to the client
│  └─ PortalServer         Void element powers (Q/E/R/F)
├─ ServerStorage/PortalService
└─ StarterPlayer/StarterPlayerScripts/
   ├─ AetherveilClient/    the whole UI
   │  ├─ App               layers, navigation, Play / return to menu
   │  ├─ MainMenu          title screen and main navigation
   │  ├─ Pages/            ElementsPage, WeaponryPage, ShopPage, SettingsPage, WeaponCard
   │  ├─ HUD               in-game menu button, shards, ability bar
   │  ├─ Backdrop          cinematic menu camera, vignettes, motes, music
   │  ├─ Overlay           loading screen, toasts, confirm dialogs
   │  ├─ UIKit             buttons, cards, pills, ornaments, page shell
   │  ├─ Previews          3D element emblems and weapon models in cards
   │  ├─ Animator, Sound, Theme, State, SettingsApplier
   ├─ PortalClient         Void HUD and controls
   └─ PortalVisuals        Void visuals
```

## Menu background

The title screen is a real 3D scene in `workspace.MenuScene` plus terrain around (-6000, 0, -6000). To rebuild or tweak it, edit `tools/BuildMenuScene.luau` and run it in Studio's command bar (Edit mode). The menu's camera uses the `MenuCamera` and `MenuFocus` parts. The colors for each element are set in `AetherveilClient/Backdrop` (`LOOKS`).

## Setting up purchases

Open `src/ReplicatedStorage/Aetherveil/Config/Store` and paste your IDs:

| What | Where | Notes |
|---|---|---|
| VIP, Extra Equipment Slot, Element Boost, Exclusive Armory, Aether Aura | `Store.Gamepasses[...].Id` | Create them as game passes |
| Portal Walker (unlocks Void) | `PortalConfig.GAMEPASS_ID` | Already existed; Void is free for everyone until this is set |
| Shard packs (Pouch → Vault) | `Store.Products[...].Id` | Create them as developer products |

While an ID is `0`, the item shows "Not on sale yet" and can't be bought.

In Studio, turn on **Game Settings → Security → Enable Studio Access to API Services** so progress saves while testing. Without it, players get a temporary profile and a notice that progress won't save.

## Adding content

- **New element:** add an entry to `Elements.List` and its id to `Elements.Order`. Pick ability types from Bolt, Beam, Nova and Dash. No other code changes are needed.
- **New weapon:** add an entry to `Weapons.List` and its id to `Weapons.Order`. The `Look` table controls the 3D model.
- **New game pass:** add it to `Store.Gamepasses`, then check `Purchases.Owns(player, "YourKey")` wherever its perk applies.

## Controls

| | |
|---|---|
| Main menu | Mouse, ↑/↓ + Enter, or gamepad |
| Back | Back button, Backspace, gamepad B |
| Elemental abilities | Q / E / R (Void: Q / E / R / F) |
| Weapons | Click to swing |
| Return to menu | MENU button, top left (not while in combat or in the Void) |

## Syncing

The scripts can be synced into the place with [Rojo](https://rojo.space) using `default.project.json`. Note that `Players.CharacterAutoLoads` must be off, because players spawn from the menu. The server also sets this on startup.
