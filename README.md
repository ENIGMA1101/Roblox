# Vermeil Exchange

A Roblox luxury case-opening game. Players walk up to the Vermeil Exchange stall, open cases
on a spinning reel (sideways for a single open, one vertical reel per case for multi-opens),
and pull luxury items across 11 rarities, each with a parody brand that
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
  parody brands; most items are one specific product from one house. Every product name is a
  spoof (e.g. "Speedmasterr Moonwotch", not the real model name), and brand names are altered too.
- **Grails (Imperial → Ethereal → Omega):** 22 ultra-rare bragging-rights items worth $6M up to
  $100B, numbered with a global serial. Cheap cases hold one or two Imperial grails at around
  1 in 2 million. The end-game cases hold several, including Ethereal and Omega at 1 in 4 million
  up to 1 in a billion. They're listed per case in `Grails` in `Config/Cases.luau`. Grail odds are
  fixed and luck never changes them, so they stay rare. They hide behind the gem, get a
  full-screen fanfare when they land, are announced to the whole server, and are never included
  in *Sell all*. Together they add under 1% to any case's return.
- **Rarity on the reel:** each rarity has an `Fx` level (0-8) in `Config/Rarities.luau`, and
  cells get louder as it rises. Commons show a faint card. Rare and Epic cards are tinted and outlined. From
  Legendary up, cards get a gradient and the rarity name, then a shine sweep and twinkling stars.
  Grails get animated multi-colour cards with a spinning outline. Rare cells also click louder as
  they pass the centre line, so a rare item is hard to miss.
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
- **Luck** only changes which item you pull. It never changes mutations. Every source multiplies
  together into one number, shown above the luck bar as a full breakdown (e.g.
  `🍀 LUCK ×54 = Upgrades ×1.7 × 2x Luck pass ×2 × Personal ×8 × Server ×2`):
  - **Luck upgrades (cash, no max level):** each level multiplies luck by ×1.1 (level 10 ≈ ×2.6,
    20 ≈ ×6.7, 30 ≈ ×17). The price grows ×1.9 per level ($25K, …, ~$4.9B at level 20). This is
    the endless cash sink.
  - **2x Luck gamepass:** a real ×2.
  - **Personal luck stack (Robux, permanent):** the 🍀 icon on the right. ×2, then ×4, ×6, ×8…
    (+2 each buy), priced 5, 8, 11, 17, 25… Robux (×1.5 each), with one developer product per step.
  - **Server luck (Robux, 15 min, everyone in the server):** the 🌐 icon on the right. ×2 for R$33,
    ×3 for R$99, ×10 for R$199.
  - **Luck bar (free):** fills by 1 per item opened. At 30, the next open gets ×10.
  - **How it bends the odds:** each item's chance is multiplied by luck^T, where T runs from 0 for
    the case's cheapest item to 1 for its most valuable. At ×10 luck the top items are close to
    10× more likely, mid-tier items a few times more likely, and commons barely change. The case
    preview shows every rarity's normal → lucky odds, and the Luck window shows each case's top
    item chance now → next level.
  - **Diminishing returns, never a wall:** luck works at full strength until it has added
    `Luck.FullGain` (+75% of the price) to a case's return. Past that, gains slow down
    logarithmically but never stop. Temporary boosts get much more room (`BoostFullGain` +200%).
    Rough numbers: ×10 luck takes most cases to 150-240% return, ×100 to 200-360%, and a ×1000
    boost to 300-700%. Grails keep their fixed odds, so the rarest items stay rare no matter what.
- **Mutation luck:** only the **2x Mutation Luck** gamepass changes mutation odds (it halves every
  "1 in N"), so a Crown Jewel stays a 1 in 100,000 moment even with the pass. Robux cases still
  guarantee a mutation.
- **Robux:** 6 gamepasses (2x Luck, 2x Mutation Luck, Fast Open, Auto Open, Multi Open+, 2x Showcase Income),
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

## Selling luck

Create these developer products and paste the ids into `Config/Monetization.luau`:

- `ServerLuck`: three products at 33, 99 and 199 Robux (2x, 3x, 10x for 15 minutes).
- `PersonalLuck.ProductIds`: one product per step, in order, priced 5, 8, 11, 17, 25, 38,
  57, 85, 128, 192, 288, 432, 649, 973, 1460, 2189, 3284, 4926, 7389 and 11084 Robux (step N =
  5 × 1.5^(N-1)). Roblox products can't change price, which is why each step is its own
  product. Fewer ids means fewer purchasable steps; add more to extend it.
- Gamepasses: create **2x Luck** and **2x Mutation Luck** (plus the others) and paste their ids
  into `Passes`.

## Testing the gem and mutations (developer tools)

In Studio a 🛠️ **Dev** button appears on the HUD. It opens a panel where you can:

- **Arm the next open:** *Force gem (random tier)*, *Force gem (top item)*, *Force grail*
  (a random grail from that case, e.g. open The Vermeil Vault for Ethereal/Omega), or any mutation. They
  combine, so gem + Crown Jewel works. The next open (including the free case) uses them on every
  column, then they clear.
- **Open any case directly** from the panel, ×1 to ×5, without walking to the stall.
- Add $1M / $100M / $10B, make the free case ready, set your luck level to 0, 10 or 25, fill the
  luck bar, start 2x / 3x / 10x server luck for 2 minutes, and add or reset personal luck steps.

The server checks permission on every request. The panel works in Studio, and in live servers only
for UserIds listed in `GameConfig.Debug.Admins`; set `Debug.Enabled = false` to turn it off
completely. Items from forced opens are real saved items, so don't use it on a live account you care about.

## Setting things up

| What | Where |
|---|---|
| Items, values, brands per item | `Config/Items.luau` |
| Brand names, price multipliers, rarity | `Config/Brands.luau` |
| Cases: price, theme pool (category / brand / item list), RTP, Robux product | `Config/Cases.luau` |
| Themed-case return curve, gem threshold, luck strength, sold-out payout | `Config/GameConfig.luau` (`ThemedCases`, `Luck`, `LuckUpgrades`, `SoldOutCash`) |
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

For all 32 cases it prints the item count, expected value and return-to-player (RTP): base, with
the 2x Luck pass, at a late-game reference luck (level 20 + 4 personal buys = ×54, and ×108 with the pass),
and with a ×100 boost on top. It also prints the gem chance, the top item, and a luck curve (RTP and
top-item odds at ×1 to ×10K luck). Then it runs a roll check that the roller matches the maths, and
15 simulated players over 80 hours who open mixed cases and buy luck levels. A case whose price
can't be reached by its items fails at startup with a message telling you what to change.

Mixed-case defaults:

| Case | Price | RTP | + 2x Luck pass | Luck ×108 | ×108 + ×100 boost | Gem (base) |
|---|---|---|---|---|---|---|
| Street Luxe | $800 | 108% | 136% | 315% | 765% | 1 in 263 |
| Boutique Box | $5.8K | 92% | 126% | 312% | 766% | 1 in 276 |
| Atelier Crate | $48K | 85% | 99% | 243% | 647% | 1 in 153 |
| Penthouse Case | $350K | 80% | 96% | 238% | 605% | 1 in 185 |
| Monaco Vault | $2.65M | 75% | 92% | 233% | 556% | 1 in 200 |
| The Vermeil Vault | $12M | 68% | 84% | 218% | 509% | 1 in 31 |

Themed cases return ~100% at $800 down to ~71% at $60M, with gems between 1 in 28 and 1 in 480.
The Robux cases average $124K (R$99), $557K (R$333), $2.2M (R$777) and $6.3M (R$999) per pull,
guaranteed mutation included; change `TargetValue` on a case to adjust.

Median time for simulated free players (no passes, no Robux luck) to reach each mixed case:
Boutique ~45 min, Atelier ~3 h, Penthouse ~5.5 h, Monaco ~9 h, Vermeil Vault ~11 h. They're still
buying luck levels at 80 hours, so max luck is the endgame chase.

Luck is deliberately strong: players who stack it really are OP, and cases pay well over 100%.
What keeps it from breaking the game:
- The logarithmic slowdown past `Luck.FullGain`.
- Luck upgrade prices that grow ×1.9 per level while luck grows ×1.1.
- Grails and mutations that luck never touches.

To tone luck down, lower `FullGain`/`Softness` (or the Boost versions). To make it even stronger, raise them.

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
   check the spinner with 5 columns and the sideways single reel on the smallest screen you support.

## Not yet verified

This was built without Roblox Studio. The code passes `luau-lsp` analysis against the Roblox API
types, is formatted with StyLua, and the economy maths is checked by the simulator. It has **not**
been play-tested in Studio yet, so expect some visual tuning (sizes, timings, colours) on the
first run. All sounds are silent until you add ids.
