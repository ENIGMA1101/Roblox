# Vermeil Exchange

A Roblox luxury case-opening game. Players walk up to the Vermeil Exchange stall, open cases
on a vertical reel, and pull luxury items across 7 rarities, each with a parody brand that
nudges its price. On top of that there's a rare mutation that multiplies the value by ×1.1 up to ×15.
When a case's top rarities hit, the reel lands on a **yellow gem** first. The gem pops,
flickers and bursts, then the reel re-spins through the rare pool to reveal the prize.

Everything is written from scratch in Luau. The old scripts were only used as a reference for
the idea.

## Getting it into Studio

**Option A: quick test place**

1. Install [Rojo](https://rojo.space) (the CLI).
2. `rojo build place.project.json -o VermeilExchange.rbxl`
3. Open `VermeilExchange.rbxl` in Studio and press Play. You get a 100×100 baseplate and a spawn
   facing the stall, and the stall builds itself at (50, 0, 50).

**Option B: sync into your existing map (recommended for real work)**

1. Install the Rojo CLI and the Rojo Studio plugin.
2. Run `rojo serve` in this folder, then click **Connect** in the Rojo plugin inside your place.
3. The scripts appear in ReplicatedStorage, ServerScriptService and StarterPlayerScripts.
   `default.project.json` never touches Workspace, so your map is safe.

**Then, for both options:**

- **Saving:** Game Settings → Security → *Enable Studio Access to API Services*. Without it the
  game still runs, but uses in-memory data and prints a warning. Note that with it on, Studio
  reads and writes your live game's data.
- **Your own stall:** tag your counter part `CaseStall` in the Tag Editor. The auto-built stall is
  then skipped and your part gets the "Open Cases" prompt. Tag any screen part
  `BestPullDisplay` to show the server's best pull on it. Tag decorative parts `SpinDecor` to make
  them spin. You can place as many stalls as you like.
- **Keep an editable copy of the stall:** run this in the command bar (edit mode), then set
  `AutoBuild = false` in `StallService`:
  `require(game.ServerScriptService.Server.Services.StallBuilder).build(Vector3.new(50, 0, 50), 0)`

## Layout

```
src/shared   → ReplicatedStorage.Shared
  Config/        every number, item, brand, case, mutation, product and sound id
  Catalog        lookups, config validation, all odds maths (shared by server + preview)
  Roller         all randomness (server rolls; client only uses it for cosmetic reel filler)
  Format, Net, Signal
src/server   → ServerScriptService.Server
  DataService    session-locked DataStore saves (no dupes on server hop), autosave, BindToClose
  PlayerState    the only code that changes cash/items/keys/showcase; syncs the client
  CaseService    open + free case: validate, charge, roll, save, then return results
  ShowcaseService  passive income tick, slot purchases, offline earnings
  MonetizationService  ProcessReceipt (idempotent, saves before granting)
  Passes         gamepass ownership
  StallBuilder / StallService   the map stall, prompts, best-pull screen
src/client   → StarterPlayerScripts.Client
  UI/Spinner     the reel, gem sequence, rarity + mutation reveals
  UI/CaseShop    case grid + preview with every odd
  UI/Inventory   items + showcase tabs
  UI/Hud, Store, Toast, Window, Kit, Theme, ItemVisual, Root
tools/balance.py   economy simulator (needs Python 3 + the luau CLI)
```

The server decides every result before the client animates anything. The spin is a replay,
so exploiters can't change outcomes, and leaving mid-spin never loses an item.

## How the game plays

- **Cases:** 6 tiers from $650 to $10M. Each case sets its own rarity odds and which rarities
  hide behind the gem (cheap cases put Epic/Legendary behind it, the top case only Sovereign).
- **Items:** 31 items over Common → Uncommon → Rare → Epic → Legendary → Mythic → Sovereign.
  Each item has 1–5 parody brands (about 80 in total); prestige brands are rarer and worth up to ×1.25.
- **Mutations:** rolled independently on every pull. Values below are the defaults and can all be changed in `Config/Mutations.luau`:

  | Mutation | Value | Chance |
  |---|---|---|
  | Polished | ×1.1 | 1 in 20 |
  | Engraved | ×1.25 | 1 in 60 |
  | Gilded | ×1.5 | 1 in 150 |
  | Iced Out | ×2 | 1 in 400 |
  | Rose Gold | ×3 | 1 in 1,200 |
  | Obsidian | ×4.5 | 1 in 4,000 |
  | Prismatic | ×6.5 | 1 in 12,500 |
  | Celestial | ×10 | 1 in 50,000 |
  | Crown Jewel | ×15 | 1 in 200,000 |

  Bigger tiers get louder reveals (flash, shake, rainbow strokes).
- **Money:** sell items, showcase your best items for cash per second (with diminishing
  returns, so the late game stays grindy), a small base income, 25% offline earnings, and a
  free Street Luxe case every 5 minutes.
- **Robux:** 5 gamepasses (2x Luck, Fast Open, Auto Open, Multi Open+, 2x Showcase Income),
  3 cash packs that scale with your income, and optional key bundles per case. Key bundles are
  only sold inside the case preview, directly beside the full odds list.

## Setting things up

| What | Where |
|---|---|
| Items, values, brands per item | `Config/Items.luau` |
| Brand names, price multipliers, rarity | `Config/Brands.luau` |
| Case prices, odds, gem rarities, Robux keys | `Config/Cases.luau` |
| Mutations | `Config/Mutations.luau` |
| Starting cash, showcase, luck, spin timing, gem artwork | `Config/GameConfig.luau` |
| Gamepass and product ids | `Config/Monetization.luau` (set `StudioOwnsAllPasses = true` to test passes) |
| Sound ids | `Config/Sounds.luau` (each has a suggested search) |

The config is validated on startup: bad brand ids, odds that don't add up to 100, or empty rarities
error immediately with a clear message.

**Never rename an `Id`** (item, brand, mutation, case) after launch, because saves point at them. Rename
the `Name` instead. An item id that disappears is moved to a hidden `Orphans` table rather than
deleted, so putting the id back restores it.

## Balancing

```
LUAU=/path/to/luau python3 tools/balance.py            # full report
LUAU=/path/to/luau python3 tools/balance.py --quick    # EV table only
```

It prints each case's expected value and return-to-player (RTP) with and without the Luck pass. It
also runs a 400k-roll check that the roller matches the maths, and 15 simulated players
over 80 hours. Current defaults:

| Case | Price | RTP | RTP with Luck | Gem | Median time to reach |
|---|---|---|---|---|---|
| Street Luxe | $650 | 107% | 123% | 1 in 263 | start |
| Boutique Box | $5.2K | 91% | 112% | 1 in 276 | 40 min |
| Atelier Crate | $41K | 85% | 95% | 1 in 153 | 2 h |
| Penthouse Case | $305K | 80% | 89% | 1 in 185 | 6 h |
| Monaco Vault | $2.35M | 75% | 81% | 1 in 200 | 12 h |
| The Vermeil Vault | $10M | 69% | 78% | 1 in 31 | 18 h |

The cheap cases pay slightly over 100% on purpose. Opening them is the early-game grind, and the
absolute profit is too small to matter later. Higher tiers lose money on average; progress comes
from the showcase and from jackpot pulls. The Luck pass boosts gem odds by only ×1.35 (mutations
×2) because gem pulls hold 20–60% of each case's value. A flat ×2 would push the cheap cases far
past 100% and turn the pass into a money printer.

## Advice for the best result

1. **Art is the biggest upgrade.** Every item currently shows an emoji. Render each item as a
   512×512 transparent PNG, using the same camera angle and lighting for all of them, and put the ids in `Image`. Do
   the same for the gem (`GameConfig.GemImage`), using a brilliant-cut gold gem like the one in your video.
2. **Sound is half of the gem moment.** Pick a crisp, short **Tick**, a deep **GemHit**, a
   **GemRiser** about as long as `Spin.GemHold` (1.6 s), and a sparkly **GemBurst**. If the riser
   is longer, raise `GemHold` to match. The reveal sound is pitched up per rarity automatically.
3. **Keep the odds honest.** The reel filler uses each case's real odds, and near-misses are not
   rigged. Roblox requires odds to be shown before any paid random item is bought, so keep the Robux key button inside
   the preview. Also answer the Experience Questionnaire accurately, since it asks about paid random items
   and gambling-like content and sets your age rating.
4. **Parody brands still carry some risk.** Keep the names clearly spoofed and never use real logos,
   fonts or product photos.
5. **Tune with real data.** Add `AnalyticsService` economy events (cases opened per tier, gem
   hits, sells, showcase income) and compare them to the simulator, then adjust config rather than code.
6. **Next features, in the order I'd add them:**
   - a collection index (discover every item × brand × mutation, with rewards)
   - daily login streak
   - global leaderboards for best pull and net worth
   - chat announcements for gem hits and tier-4+ mutations
   - rebirths (a clean prestige loop on top of the showcase)
   - case battles like the video, as a later multiplayer mode
   - trading, only once the economy is stable (session locking is already in place to prevent dupes)
7. **Test on a phone.** Use Studio's device emulator. The UI scales from a 1280×760 design size;
   check the spinner with 5 columns on the smallest screen you support.

## Not yet verified

This was built without Roblox Studio. The code passes `luau-lsp` analysis against the Roblox API
types, is formatted with StyLua, and the economy maths is checked by the simulator. It has **not**
been play-tested in Studio yet, so expect some visual tuning (sizes, timings, colours) on the
first run. All sounds are silent until you add ids.
