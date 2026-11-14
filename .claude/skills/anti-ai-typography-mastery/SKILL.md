---
name: anti-ai-typography-mastery
description: >-
  Picks deliberate, art-directed, commercially licensed typography instead of the generic
  defaults AI tools reach for (Inter, Roboto, Montserrat, Open Sans, Poppins, Space Grotesk),
  then sets it properly (scale, leading, tracking, measure, OpenType). Use this skill whenever
  you write or review anything with type in it: a landing page, website, web app or dashboard
  UI, HTML/CSS or Tailwind, React components, a design system or tokens, a brand guide, a slide
  or poster, a pitch deck mockup, a game's HUD, menus, dialogue or subtitles, or font pairing advice. Use it even when the user never
  mentions fonts, because every page needs a typeface choice, and when they ask why a page
  "looks generic", "looks AI-made" or "looks like a template".
---

# Anti-AI typography and art direction

Generated UI tends to look generated for one reason more than any other: the type. The same five
sans-serifs, browser-default scale, loose display leading and untracked capitals. A reader clocks it
in a second. This skill replaces that reflex with a decision: read the brief for its art direction,
pick a pairing that belongs to it, check the license, and set it with care.

The full rule set (about 360 rules) lives in `references/rules.md`, and font sources with
licenses in `references/font-sources.md`. You rarely need all of it. The workflow below is enough
for most work; open a reference section when a decision needs it.

## Workflow

1. **Name the art direction.** Before any CSS, write one line: who it's for, the mood, and the
   period or reference it should evoke ("small Asheville pottery studio, warm and handmade,
   slow-living"). If the brief has an existing brand or design system, that wins: work within its
   fonts and tokens instead of replacing them.
2. **Pick from the matrix below.** Find the nearest row and take its display, body and accent
   faces, or a deliberate substitute of the same kind. At most two families, plus a monospace if
   there's data or code.
3. **Check the license.** Use only fonts from `references/font-sources.md` (OFL, Apache 2.0, or a
   free commercial license such as Fontshare's ITF Free Font License). Say which license applies
   when you recommend a font. Never ship a "personal use only" font.
4. **Set it.** Apply the spacing and detail rules in the checklist. These are what make a good font
   look designed rather than merely installed.
5. **Check the red flags** before you hand it over.

## Defaults you avoid, and why

These faces aren't bad; they're *unchosen*. Used as a reflex, they read as template.

- **Inter, Roboto, Open Sans, Lato** as display type: neutral to the point of invisible. Inter is
  fine for dense tables and app chrome when the brand calls for it.
- **Montserrat**, and **Playfair Display + Montserrat** in particular: the canonical 2016 template pairing.
- **Poppins** for finance, law or medicine: its round, bubbly forms undercut trust.
- **Space Grotesk** on every AI or crypto page: today's generic tech uniform.
- **Lobster, Pacifico, Brush Script** for "vintage": costume, not history.
- **Courier New** as a monospace: thin and dated next to JetBrains Mono, IBM Plex Mono or Geist Mono.
- **System stacks** (`-apple-system`, `Segoe UI`) on an expressive page: fine for an internal tool.

If the user asks for one of these by name, use it; this skill is about defaults, not overruling people.

## Art direction matrix

### Web, brand and product

| Art Direction / Brand Vibe | Display / Headline Font | Body / UI Font | Accent / Mono Font | Key Styling Rules (Tracking, Leading, Case) | 
| ----- | ----- | ----- | ----- | ----- | 
| **1. High-Craft Editorial / AI Research / Modern SaaS** *(Linear, Anthropic, Substack)* | **Instrument Serif** or **Newsreader** | **Geist** or **Plus Jakarta Sans** | **Geist Mono** | Mix *Italic* serif keywords inside Roman headlines. Tight H1 tracking (`-0.03em`), warm off-white canvas (`#FAF9F6`). | 
| **2. Swiss Neo-Grotesque / Design Studio / Architecture** | **Switzer** or **General Sans** *(Fontshare)* or **Archivo** | **Switzer** or **Hanken Grotesk** | **IBM Plex Mono** | Flush-left, rag-right. Heavy weight contrast (`700` vs `400`), `1px` grid rules, tight leading (`1.02`). | 
| **3. Haute Couture / Luxury Hospitality / Perfume / Jewelry** | **Bodoni Moda** or **Boska** *(Fontshare)* or **Cormorant Garamond** | **Tenor Sans** or **Plus Jakarta Sans** | — | Massive display scale (`72px+`), generous whitespace, tiny uppercase labels (`10px`, `+0.18em` tracking). | 
| **4. Developer Tools / DevOps / Data Infrastructure** | **Geist** or **Schibsted Grotesk** | **Geist** or **IBM Plex Sans** | **JetBrains Mono** or **Monaspace Neon** | Dark mode (`#090A0D`), `tabular-nums`, slashed zeros, crisp `1px` borders, tight UI density (`14px` body). | 
| **5. Neo-Brutalist / Creative Agency / Culture Zine** | **Syne** or **Clash Display** *(Fontshare)* or **Unbounded** | **Space Mono** or **Work Sans** | **Space Mono** | Extreme scale jumps (`10vw` H1), raw `#000` borders, zero border-radius, high-contrast lime/acid accents. | 
| **6. Warm Artisanal / Organic Food / Ceramics / Slow Living** | **Fraunces** *(Variable: SOFT=80, WONK=1)* or **Zodiak** *(Fontshare)* | **Commissioner** or **Satoshi** *(Fontshare)* | **Courier Prime** | Warm cream paper (`#F5F0E6`), espresso ink (`#231F1E`), soft organic curves, generous `1.65` line-height. | 
| **7. Fintech / Wealth Management / High-Trust Institutional** | **Source Serif 4** or **Libre Baskerville** | **Plus Jakarta Sans** or **IBM Plex Sans** | **IBM Plex Mono** | Deep navy/slate palette, `tabular-nums` everywhere, authoritative Sentence case, clear hierarchy. | 
| **8. Literary / Book Publishing / Long-Form Essay / Academia** | **EB Garamond** or **Crimson Pro** | **Newsreader** or **Source Serif 4** | **Fira Sans** *(Captions/Charts)* | Measure strictly `60ch`–`65ch`, drop caps, oldstyle numerals (`onum`), footnote margin notes. | 
| **9. Industrial / Hardware / Automotive / Robotics** | **Chakra Petch** or **Space Grotesk** or **Cabinet Grotesk** *(Fontshare)* | **IBM Plex Sans** | **IBM Plex Mono** | Technical schematics vibe, uppercase tracked micro-labels (`SPEC // 04`), sharp corner radii. | 
| **10. Healthcare / Civic / EdTech / Accessibility-First** | **Atkinson Hyperlegible Next** or **Lexend** | **Atkinson Hyperlegible** or **Source Sans 3** | **Fira Code** | High contrast (`>= 7:1`), wide apertures, unambiguous `I / l / 1`, generous tap targets and line-height (`1.6`). | 
| **11. Streetwear / Music / Youth Culture / Experimental** | **Melodrama** *(Fontshare)* or **Le Murmure** *(Velvetyne)* | **Uncut Sans** or **Archivo** | **Space Mono** | Condensed monumental headlines, kinetic marquee banners, layered brutalist collage grids. | 
| **12. Friendly Consumer App / Productivity / Creator Economy** | **Bricolage Grotesque** or **Outfit** | **Plus Jakarta Sans** or **Onest** | **Geist Mono** | Ink-trap warmth (`Bricolage`), bouncy proportions, Sentence case, vibrant but grounded color accents. | 

### Games and interactive HUDs

Four jobs per game, not two: the title and menus (world-building), dialogue and tooltips
(readability), and the numbers that change while you play (fixed-width figures).

| Game Genre / Visual Direction | Zone / Title / Logo Display Font | Dialogue / Inventory / Tooltip Font | HUD Numerals & Telemetry Font | Key HUD Styling Rules (Scale, Scrims, Motion) | 
| ----- | ----- | ----- | ----- | ----- | 
| **13. Soulslike / Dark Gothic Fantasy** *(Elden Ring, Bloodborne)* | **Cinzel** or **IM Fell English** | **Cormorant Garamond** or **EB Garamond** | **Cinzel** *(Tabular)* | Wide uppercase tracking (`+0.20em`) on zone banners, gold/bone ink (`#E6DEC8`), black gradient vignette scrims. | 
| **14. Hard Sci-Fi / Mecha / Tactical FPS** *(Halo, Titanfall, Armored Core)* | **Chakra Petch** or **Orbitron** or **Michroma** | **Rajdhani** or **Exo 2** | **Share Tech Mono** or **JetBrains Mono** | Angled `45°` chamfered HUD frames, cyan/amber telemetry, `tabular-nums`, uppercase micro-tags (`SYS // ONLINE`). | 
| **15. Cyberpunk / Dystopian / Netrunner** *(Cyberpunk 2077, Ghostrunner)* | **Syncopate** or **Syne** or **Unbounded** | **Barlow** or **Space Grotesk** | **Departure Mono** or **Space Mono** | High-contrast acid yellow/magenta/cyan, slanted `10°` italic stat callouts, chromatic edge glow, `1px` grid brackets. | 
| **16. Cozy Indie / Farming Sim / Wholesome RPG** *(Stardew, Animal Crossing)* | **Fraunces** *(SOFT=100)* or **Sour Gummy** | **Nunito** or **Quicksand** or **Plus Jakarta Sans** | **Fredoka** *(Medium)* | Rounded dialogue bubbles (`border-radius: 20px`), warm cream `#FBF6EC` cards, deep espresso `#362A24` text, bouncy spring transitions. | 
| **17. Retro 8-Bit / 16-Bit Pixel Art** *(Celeste, Sea of Stars, Undertale)* | **Press Start 2P** or **Jacquard 12** or **Pixelify Sans** | **Silkscreen** or **VT323** or **Departure Mono** | **Silkscreen** | Render strictly at integer multiples (`16px`, `24px`, `32px`). Zero anti-aliasing (`image-rendering: pixelated`), hard `2px` pixel drop shadows. | 
| **18. Survival Horror / Psychological / Analog CRT** *(Resident Evil, Signalis)* | **Special Elite** or **IM Fell DW Pica** | **Courier Prime** or **IBM Plex Sans** | **Xanh Mono** or **IBM Plex Mono** | Stark monochrome + blood crimson highlights, sparse negative space, typewriter reveal animations, subtle CRT scanline overlay. | 
| **19. Arcade Fighter / Action / Kart Racer** *(Street Fighter, Guilty Gear)* | **Bungee** or **Russo One** or **Faster One** | **Kanit** *(Bold Italic)* or **Archivo** | **Kanit** *(Black Italic)* | Heavy `paint-order: stroke fill` black outlines (`4px`), hard offset shadows, skewed `-8deg` combo counters (`HIT x24!`). | 
| **20. Grand Strategy / 4X / City Builder** *(Civilization, Stellaris, Manor Lords)* | **Libre Baskerville** or **Newsreader** | **IBM Plex Sans** or **Fira Sans** | **IBM Plex Mono** | Compact `13px`–`14px` nested tooltip tables, `tabular-nums` resource yields (`+42.5`), parchment/slate divided panels. | 
| **21. High-Fantasy JRPG / Visual Novel** *(Metaphor, Persona, Fire Emblem)* | **Cinzel Decorative** or **Philosopher** | **Plus Jakarta Sans** or **M PLUS Rounded 1c** | **Outfit** *(Bold)* | Asymmetric character portrait + 2–3 line dialogue box (`50ch` max), distinct speaker nameplate badge, keyword highlight pills. | 

For anything off the matrix, read "Font pairing archetypes" in `references/rules.md`, or study the
reference style it's closest to in "Editorial, print-inspired and expressive techniques".

## When it's a game

Everything above holds, plus what a screen in motion demands. The full set is "Game development,
HUDs, diegetic UI and interactive worlds" in `references/rules.md`; these matter most:

- **Separate the world from the readout.** An atmospheric face for titles, zone names and menus;
  a plain, open, legible one for tooltips, inventory and subtitles.
- **No engine default and no Arial** anywhere a player looks. In Godot that means setting the
  project's default theme font (Project Settings > GUI > Theme > Custom Font) so popups and
  tooltips don't fall back to the engine's own face. A variable font opens at its default
  instance, often Thin, so save a `FontVariation` at the weight you want and point to that.
- **Fixed-width digits on everything live**: health, ammo, speed, timers, money, gauges. If the
  chosen face has proportional digits and no `tnum` feature (many display faces don't), add a
  monospace or tabular face just for figures.
- **Size for the screen it runs on.** Essential HUD text at least 22 px at 1080p for TV play, and
  test at 1280 x 800 for handhelds, where tight condensed faces turn into barcodes.
- **Back every HUD line that sits over the 3D world**: a scrim, a soft shadow or a 1-2 px dark
  outline. Bare white text vanishes against snow and sky.
- **Captions are settings**: Small/Medium/Large/XL size, an adjustable background, speaker names.
- **Pixel fonts only at whole multiples** of their grid (8, 16, 24, 32 px), with smoothing off.
- **In-world text matches its surface**: a stamped gauge, a typed form, a CRT's glow.
- **Large or 3D text** (title cards, signs on in-world props): use a signed-distance-field
  (MSDF) font so it stays sharp when scaled.

## Checklist before you hand it over

1. **No unchosen defaults.** Every family in the CSS was picked for this brief.
2. **Licensed.** Every font is OFL, Apache 2.0 or free-commercial, from a source you can name.
3. **Matches the art direction** you wrote down in step 1.
4. **Spacing.** Display: tracking `-0.02em` to `-0.04em`, leading `0.95` to `1.15`. Body: leading
   `1.5` to `1.65`, measure `55ch` to `68ch`. All-caps labels: tracking `+0.04em` to `+0.12em`.
5. **Fluid size.** Headings use `clamp()` so mobile and desktop are both art-directed; the scale is
   a ratio (1.2, 1.25, 1.333) rather than guessed pixels.
6. **Details.** `font-variant-numeric: tabular-nums` on prices, tables and stats;
   `text-wrap: balance` on headings; real quotes, apostrophes, dashes, `×` and `…` in the copy; a
   non-breaking space between a number and its unit; italics loaded if the copy uses `<em>`.
7. **Contrast.** Body text at least 4.5:1. Soft off-black on warm off-white beats `#000` on `#fff`.
8. **Performance.** One or two variable `.woff2` files with `font-display: swap`, not eight static weights.
9. **Games**: no engine-default text left; live numbers in fixed-width figures; HUD text backed
   against the 3D world; essential text large enough for the screen it ships on.

## Red flags

- A template smell: Montserrat + Open Sans + a purple gradient + three rounded cards; Space Grotesk
  on near-black with glowing cyan; Playfair on pastel pink with faux gold.
- Browser-default heading ratios left as they are.
- Light (300) or Black (900) weight for body text.
- Centered paragraphs longer than three lines.
- Periods on standalone headlines, nav links and buttons; mixed casing across a nav.
- A currency or symbol falling back to Times because the font lacks it.

More, with fixes for "it looks cheap", "it looks like every AI startup" and "it's tiring to read":
"Common mistakes, red flags and troubleshooting" in `references/rules.md`.

## What to say

When you choose type, say so in a sentence or two: the art direction, the pairing, why it fits, and
the license. For example: "Warm and handmade, so Fraunces (soft, slightly wonky) for headings and
Commissioner for body. Both OFL on Google Fonts." That lets the user push back on the choice rather
than discover it.
