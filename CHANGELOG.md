# Changelog

## 2026-10-30 — Concept background and loading bar

### Added
- A 3D title-screen world like the concept, built at (-6000, 0, -6000) by `tools/BuildMenuScene.luau`:
  - a terrain valley with jagged mountains and a cliff
  - two giant swords planted in earth mounds, with cracked ground and rocks around them
  - a low, ground-level camera that drifts and follows the mouse a little
- The menu background takes on your equipped element's look: sky, fog, clouds, rock and grass colors, the sword gem's glow and the embers. Void adds a black hole, and Lightning adds storm flashes. Hovering an element card previews its look.
- The loading screen now has a progress bar that counts assets as they load ("Loading assets… 12 / 89"), then prepares the world and loads your profile.

### Changed
- Earth is now the only free element. Fire, Water and Air cost 750 shards, Lightning costs 1,500, and Void needs the Portal Walker game pass.
- Game pass checks use real ownership only, with no free test access.
- The game's normal lighting is restored when you leave the menu.
- The loading screen now stays up until everything is loaded:
  - the game itself
  - every asset in the menu world, interface, sounds and map
  - the area around the menu camera
  - any downloads still in progress
  - your profile
- A **SKIP** button in the bottom right lets players go straight to the menu. Their profile still loads first.

## 2026-10-30 — Main menu and GUI system

### Added
- Fantasy title screen with PLAY, ELEMENTS, WEAPONRY, SHOP and SETTINGS. The highlight bar slides between items, fades out to the left and ends in a diamond. Behind it, a cinematic camera drifts over the Void Dimension with menu music.
- **Elements** menu with six elements: Fire, Water, Earth, Air, Lightning and Void. Each card has a 3D emblem, a description and its abilities. You can unlock elements with shards or a game pass. Your selection is saved.
- **Weaponry** menu where you equip the weapons you own. There are nine enchanted weapons across six rarities, each with a spinning 3D preview. Epic and higher have a shimmering frame.
- **Shop** with three tabs:
  - Weapons, bought with shards
  - Game Passes: VIP, Extra Equipment Slot, Element Boost, Exclusive Armory, Aether Aura and Portal Walker
  - Aether Shards packs, bought with Robux through ProcessReceipt
- **Settings**: graphics (Low to Ultra), VFX quality (Off to High), and Master, Music and SFX volume. Changes apply instantly and are saved.
- Loading screens, toasts, confirmation dialogs, hover and click animations, and UI sounds.
- In-game HUD with a MENU button, a shard counter and an ability bar.
- Elemental abilities for Fire, Water, Earth, Air and Lightning (Q/E/R): bolts, beams, novas and dashes.
- Weapons appear as tools with melee hit detection and swing trails.
- Server-side player data: DataStore with session locking, retries, autosave and save on shutdown.
- Shards come from kills (30), from playing (10 per minute) and from Robux packs. VIP gives ×1.5.

### Changed
- Void is now an element. The Portal Walker powers only work while you play as Void.
- Players start in the main menu and spawn when they press Play (`CharacterAutoLoads` is off).
