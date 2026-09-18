# Pitch — the deck and the memo

Both documents for the **R3sidency x Construct** application (Fabric Ventures), in the product's own
theme.

```
./render.sh          # both → out/deck.pdf, out/memo.pdf
./render.sh deck     # one of them
open out/deck.pdf
```

No build step. Both are static HTML whose page geometry comes from `@page` in their own stylesheets,
so Chrome is the whole toolchain. `render.sh` uses a throwaway profile because headless Chrome will
not start against a profile the open browser is holding.

**The deadline on the accelerator's page is 15 September.**

---

## What is here

| path | what |
| --- | --- |
| `deck/index.html` | 13 slides, one idea each, on `@page { size: 1280px 720px; margin: 0 }` |
| `deck/assets/console.png` | the live console, captured from the deployed indexer |
| `deck/deck.css` | the theme |
| `memo/index.html` | 5 pages on A4 |
| `memo/memo.css` | the theme, on paper |
| `render.sh` | HTML → PDF |
| `out/` | the rendered PDFs |

## The theme

Terminal Noir, mirrored token-for-token from `@ethonline2026/ux-workflow` — the same values the desk,
the console and the landing site use. The deck is dark; **the memo prints on white**, because a memo
someone reads, annotates and forwards is paper. The identity carries over — the amber rule, mono for
anything measured, the restraint — the ground does not.

**Two deviations from the approved plan, both deliberate:**

1. **Plain CSS, not Tailwind.** The plan specified Tailwind with an `@source` into the design system.
   That buys utilities, and the deck composes no components from the library — so it would have added
   a build step to a document whose entire job is to be printed once. The tokens are mirrored
   verbatim instead, which is where the theme actually lives.
2. **The stack and flight diagrams are markup, not Mermaid.** Mermaid renders in its own visual
   language and would need overriding to match Terminal Noir; this *is* the theme, and it keeps the
   render free of a second toolchain.

## Fill these in before sending

Every one of these is visible in the PDFs as an amber dashed box, deliberately, so none can reach
submission unnoticed.

| where | placeholder | times |
| --- | --- | --- |
| `deck` s8 · `memo` p2 | `[tokenized fund market, sourced]` — sizing the ETF layer | 2 |
| `deck` s8 · `memo` p2 | `[share of funds that trade on-chain]` — the split behind the bottom-up SAM | 2 |
| `deck` s12 · `memo` p3 | `[specialist name]` — the L2/DeFi hire, once the discussion closes | 2 |
| `deck` s12 · `memo` p3 | `[mentor name]` — the Bloomberg risk advisor | 2 |
| `memo` p3 | `[traction]` — anything real that is not already in the repository | 1 |

Five distinct labels, nine occurrences. To find them all after an edit:

```bash
grep -o '\[[^]]*\]' deck/index.html memo/index.html | sort -u
```

## Every figure, and where it came from

Nothing here is from memory. If it is not in this table it is not on a slide.

| figure | value | source |
| --- | --- | --- |
| Crypto hedge fund AUM | $90–100B | CoinLaw, 2026 |
| Crypto hedge funds | 400+ (870+ crypto funds tracked) | Crypto Fund Research, Mar 2026 |
| Managed tokenized / RWA value | $26.7B | RWA.xyz, Jun 2026 |
| Autonomous agents' share of TVL in top-tier DeFi pools | ~30% | Chainlink × Ark Invest, May 2026 |
| Stablecoin circulating supply | $314B (Jun 2026) | CoinLaw |
| DeFi TVL | ~$71B (implied: $314B ÷ 4.4) | CoinLaw |
| Stablecoin monthly volume | $1.79T · 88% exchange/bot/arbitrage | stablecoininsider, 2026 |
| On-chain settlement, 2024 | $27.6T | Fabric Ventures |
| Smart wallets | 26M | Fabric Ventures |

Market arithmetic, so it can be checked rather than trusted:

```
TAM   top-down      ($95.0B + $26.7B) × 25 bps        = $304M / yr
SAM   bottom-up     400 funds × $237M mean × 25 bps   = $237M / yr
      value theory  the same capital at 100 bps       = $1.2B / yr
SOM   2% of funds   8 × $237M × 25 bps                = $4.7M / yr
      5% of funds   20 × $237M × 25 bps               = $11.9M / yr
```

## Two things the deck says that a pitch usually does not

Both came out of the research and both are load-bearing, so they are recorded here to stop a later
edit from quietly softening them into claims:

**The decacorn number is not there.** The near-term business is $5–12M ARR at 2–5% penetration. What
makes the category large is the ETF layer, and no credible projection for it could be sourced — so
the deck says so rather than quoting a figure from a press release. A fund that reads carefully will
notice the omission either way; the difference is whether they notice it before or after you.

**The competitive quadrant is not empty.** `Brava Finance` occupies automated-and-accountable today —
mandate automation, risk scoring, audit-ready reporting, Safe-based non-custodial execution. Claiming
that quadrant would be the first thing checked and the first thing disproved. The differentiation is
therefore narrower and checkable: *forecast-driven* rather than policy-driven, and accountability
**required** by a schema (`citations: z.array(...).min(1)`) rather than **reported** by a job.

## Review

The thirteen slides were rendered and read at slide geometry, in batches. One defect was found —
slide 9's axis labels collided, making two axes read as one garbled row — and fixed by moving them
into a caption above the quadrant, which cannot collide. The deck re-rendered to 13 pages after the
fix.

The two render warnings worth knowing about:

- Chrome writes a complete PDF and then does not exit — the web fonts keep a connection open, a
  pending request pauses virtual time, and `--virtual-time-budget` therefore never expires. Waiting on
  the process hangs the build with a finished PDF already on disk, which is the state a previous run
  was found in. `render.sh` starts Chrome in the background, polls the artifact until its size
  settles, and kills Chrome; the exit code is not consulted at all.
- There is no PDF library on this machine (no poppler, no qpdf, and `pip` is broken under Homebrew's
  Python 3.14), so verification is visual per slide plus macOS Spotlight for page counts
  (`mdls -name kMDItemNumberOfPages`). If you install `poppler` later, `pdftotext out/deck.pdf -`
  becomes the cheapest possible check that every slide still carries its text.
