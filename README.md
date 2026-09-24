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

- **Cases (32), in tabs in the case menu:**
  - **Mixed (6):** the progression ladder from $800 to $12M. Each sets odds per rarity and pulls
    from every item of that rarity.
  - **Themed (22):** PackDraw-style cases for one category or one brand: Scent Lab, Drop Day,
    Sneakerhead, Top Shelf, Tech Haul, Appel Store, Tick Tock, Bag Drop, Grail Hunter, Rolax Only,
    Ice Box, Two Wheels, Hermez Vault, Haute Horlogerie, Dream Garage, Prancing Horse,
    Hypercar Hunt, Open Water, The Gallery, Real Estate Mogul and Jet Set ($800 to $60M).
    Their odds are worked out automatically from the price: cheaper items are likelier, and items worth
    10× the case's average pull or more hide behind the gem.
  - **Robux (4), open instantly on purchase, guaranteed mutation on every item:**
    Velvet Rope (R$99), Black Card (R$333), Jackpot (R$777) and Pop Icons (R$999). Their items are
    exclusive and numbered with a global serial (#1, #2, …). Pop Icons is fully **Limited**:
    each item has a fixed supply shared by every server (e.g. only 10 Golden Lubbus will ever
    exist), shown as "#7 / 10". Sold-out items drop out of the odds.
- **Items:** 281 items in 17 categories (fashion, streetwear, sneakers, fragrance, tech,
  watches, bags, jewellery, drinks, collectibles, cars, hypercars, bikes, boats, aviation, art,
  property) plus 29 Robux exclusives. Rarity comes from value: Common → Uncommon → Rare → Epic →
  Legendary → Mythic → Sovereign, plus **Limited** for the numbered Robux items. There are about 170
  parody brands; most items are one specific product from one house.
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
- **Luck upgrades:** 20 permanent levels bought with cash (🍀 on the HUD). Each level makes the
  case's gem rarities 2.5% more likely and mutations 10% more likely, up to ×1.5 gem pulls and
  ×3 mutations at level 20. Prices grow ×1.9 per level ($25K for the first, about $4.9B for the last), so
  it's the long-term cash sink. It stacks with the Luck pass. The Luck window shows exactly how
  the next level changes every case's gem chance and the rarest mutations, and the case preview
  odds always include your current luck.
- **Robux:** 5 gamepasses (2x Luck, Fast Open, Auto Open, Multi Open+, 2x Showcase Income),
  3 cash packs that scale with your income, and optional key bundles per case. Key bundles are
  only sold inside the case preview, directly beside the full odds list.

## Selling the Robux cases

1. Create a developer product for each Robux case on the Creator Dashboard, priced 99 / 333 /
   777 / 999 Robux, and paste its id into that case's `Paid.ProductId` in `Config/Cases.luau`.
2. Pressing **OPEN R$ …** in the case preview prompts the purchase. When it goes through, the
   server opens the case inside `ProcessReceipt`, saves, and the spin plays straight away. If a
   player leaves mid-purchase, the item is waiting in their inventory next time.
3. Serial numbers live in a separate DataStore (`VermeilExchange_Serials_v1`). Never wipe or
   rename it after launch, or numbering restarts and Limited supplies reset.

Until a product id is set, the case shows "Not on sale yet". In Studio use **🛠️ Test open (dev,
free)** in the preview, or the Dev panel, to open it without paying.

## Testing the gem and mutations (developer tools)

In Studio a 🛠️ **Dev** button appears on the HUD. It opens a panel where you can:

- **Arm the next open:** *Force gem (random tier)*, *Force gem (top tier)*, or any mutation. They
  combine, so gem + Crown Jewel works. The next open (including the free case) uses them on every
  column, then they clear.
- **Open any case directly** from the panel, ×1 to ×5, without walking to the stall.
- Add $1M / $100M / $10B, make the free case ready, and set your luck level to 0, 10 or 20.

The server checks permission on every request. The panel works in Studio, and in live servers only
for UserIds listed in `GameConfig.Debug.Admins`; set `Debug.Enabled = false` to turn it off
completely. Items from forced opens are real saved items, so don't use it on a live account you care about.

## Setting things up

| What | Where |
|---|---|
| Items, values, brands per item | `Config/Items.luau` |
| Brand names, price multipliers, rarity | `Config/Brands.luau` |
| Cases: price, theme pool (category / brand / item list), RTP, Robux product | `Config/Cases.luau` |
| Themed-case return curve, gem threshold, luck cap, sold-out payout | `Config/GameConfig.luau` (`ThemedCases`, `LuckLimits`, `SoldOutCash`) |
| Mutations | `Config/Mutations.luau` |
| Starting cash, showcase, luck pass, luck upgrades, dev tools, spin timing, gem artwork | `Config/GameConfig.luau` |
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

For all 32 cases it prints the item count, expected value and return-to-player (RTP) (base, with
the Luck pass, at max luck, and at max luck plus the pass), plus the gem chance and top item.
It also runs a roll check that the roller matches the maths, and 15 simulated players over 80
hours who open mixed cases and buy luck levels. A case whose price can't be reached by its
items fails at startup with a message telling you what to change.

Mixed-case defaults:

| Case | Price | RTP | + Luck pass | Max luck + pass | Gem (base) |
|---|---|---|---|---|---|
| Street Luxe | $800 | 108% | 123% | 135% | 1 in 263 |
| Boutique Box | $5.8K | 92% | 107% | 115% | 1 in 276 |
| Atelier Crate | $48K | 85% | 95% | 109% | 1 in 153 |
| Penthouse Case | $350K | 80% | 89% | 109% | 1 in 185 |
| Monaco Vault | $2.65M | 75% | 83% | 103% | 1 in 200 |
| The Vermeil Vault | $12M | 68% | 79% | 104% | 1 in 31 |

Themed cases return ~100% at $800 down to ~71% at $60M, with gems between 1 in 28 and 1 in 480.
The Robux cases average $124K (R$99), $557K (R$333), $2.2M (R$777) and $6.3M (R$999) per pull,
guaranteed mutation included; change `TargetValue` on a case to adjust.

Median time for the simulated players to reach each mixed case: Boutique ~45 min, Atelier
~2.5 h, Penthouse ~6.5 h, Monaco ~12 h, Vermeil Vault ~17.5 h. They're still buying luck levels
at 80 hours, so max luck is the endgame chase.

The cheap cases pay slightly over 100% on purpose. Opening them is the early-game grind, and the
absolute profit is too small to matter later. Higher tiers lose money on average; progress comes
from the showcase and from jackpot pulls. The Luck pass boosts gem odds by only ×1.35 (mutations
×2) because gem pulls hold 20–60% of each case's value. A flat ×2 would push the cheap cases far
past 100% and turn the pass into a money printer. On top of that, luck is capped per case
(`LuckLimits`): it raises gem odds only until a case would return about 92% of its price, though it
always allows at least +15% value. With mutation luck on top, no case above $50K goes past ~109%,
even at max luck with the pass. The Luck window and case previews show the capped odds.

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
