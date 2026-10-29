# Changelog

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
