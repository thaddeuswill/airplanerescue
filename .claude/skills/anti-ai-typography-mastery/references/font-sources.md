# Where to get free commercial fonts

Every font you put in front of a client, into a shipped product or into a released game needs a
license that allows it. These sources host fonts under the SIL Open Font License (OFL), Apache 2.0,
CC0, or a foundry's own free-commercial license. Tier 4 sites mix licenses: check each font.

How to load them:
- **Google Fonts** on the web: `<link href="https://fonts.googleapis.com/css2?family=Instrument+Serif:ital@0;1&family=Geist:wght@100..900&display=swap" rel="stylesheet">`. Ask for the variable axis range (`wght@100..900`) and the italics you use.
- **Fontshare** on the web: `<link href="https://api.fontshare.com/v2/css?f[]=satoshi@400,500,700&f[]=zodiak@400,700&display=swap" rel="stylesheet">`.
- **Everything else, and every game**: download the files (`.woff2` for the web; `.ttf`/`.otf` for Godot, Unity or Unreal), ship them inside the project, and keep each license file next to its font. The OFL requires the license to travel with the font.

Never guess font licensing—especially when shipping commercial games on Steam, consoles, mobile stores, or SaaS apps. Use these vetted repositories that host high-craft **SIL Open Font License (OFL)**, **Apache 2.0**, or **Commercial-Free** typefaces:

### 1. Tier-1 Curated Open-Source Foundries & Repositories
* **Fontshare (`fontshare.com`)** — Run by the Indian Type Foundry (ITF). Arguably the single best source for free commercial fonts that look like \$400 retail Swiss/European typefaces. Standouts: *Clash Display, Satoshi, Cabinet Grotesk, General Sans, Switzer, Zodiak, Erode, Boska, Gambetta, Chillax, Melodrama*. (100% Free for Commercial Use via ITF Free Font License).
* **Google Fonts (`fonts.google.com`)** — Filter specifically for **Variable** fonts and recently commissioned high-craft releases. Avoid the top 10 overused defaults; dig into newer commissions like *Instrument Serif, Instrument Sans, Bricolage Grotesque, Newsreader, Fraunces, Geist, Geist Mono, Syne, Plus Jakarta Sans, Commissioner, Bodoni Moda, Unbounded, Onest, Golos Text, Atkinson Hyperlegible, Hanken Grotesk, Schibsted Grotesk*. (100% OFL / Apache 2.0).
* **Velvetyne Type Foundry (`velvetyne.fr`)** — Avant-garde French open-source type foundry. Incredible for experimental, brutalist, editorial, and cultural projects. Standouts: *Le Murmure, Karrik, Trickster, Compagnon, Gulax, vg5000, Sporting Grotesque*. (100% Open Source / OFL).
* **Collletttivo (`collletttivo.it`)** — Italian open-source type design collective producing bold, contemporary display and grotesque faces. Standouts: *Mazius Display, Ortica, Ribes, Mattone, Run*. (100% OFL).
* **Open Foundry (`open-foundry.com`)** — Curated showcase of the best open-source fonts with live interactive specimen testers. Standouts: *Young Serif, Work Sans, Archivo, Space Mono, Syne, League Spartan*. (100% OFL).
* **Uncut (`uncut.wtf`)** — Curated catalog focusing on contemporary, slightly brutalist, neo-grotesque, and experimental open-source fonts. Standouts: *Uncut Sans, Ortica, Switzer, Archivo*. (100% Open Source / Commercial Free).
* **The League of Moveable Type (`theleagueofmoveabletype.com`)** — The original open-source type foundry. Standouts: *League Gothic, Ostrich Sans, Junction, Sorts Mill Goudy, Chunk*. (100% OFL).
* **atipo foundry (`atipofoundry.com`)** — Spanish independent foundry offering "Pay What You Want" (including \$0 or ultra-low full family unlocks) and free commercial weights for iconic modern fonts like *Silka, Basier, Geomanist, Calps*.

### 2. Tier-2 Corporate & Tech Open-Source Type Systems
* **Vercel Geist (`vercel.com/font`)** — *Geist Sans* & *Geist Mono*. Sharp, engineered Swiss-meets-developer aesthetic. (OFL).
* **IBM Plex (`ibm.com/plex`)** — *IBM Plex Sans, Serif, Mono, Condensed*. Masterclass in corporate, industrial, and technical superfamily design. (OFL).
* **Adobe Source (`github.com/adobe-fonts`)** — *Source Sans 3, Source Serif 4, Source Code Pro*. Benchmark editorial and UI workhorses. (OFL).
* **GitHub Monaspace (`monaspace.githubnext.com`)** — *Neon, Argon, Xenon, Radon, Krypton*. Five harmonized monospace families with texture healing and coding ligatures. (OFL).
* **JetBrains Mono (`jetbrains.com/lp/mono`)** — Tall x-height, crisp oval glyphs, phenomenal readability for code and technical metadata. (OFL).
* **Mozilla Fira (`github.com/mozilla/Fira`)** — *Fira Sans, Fira Code, Fira Mono*. Warm humanist precision engineered for screens. (OFL).
* **Braille Institute (`brailleinstitute.org/freefont`)** — *Atkinson Hyperlegible* & *Atkinson Hyperlegible Next*. Gold standard for maximum character differentiation. (OFL).

### 3. Tier-3 Dedicated Commercial-Free Game Dev Font Sources
* **Google Fonts — Game & Display Gems (`fonts.google.com`)**:
  * *Sci-Fi / Mecha*: `Chakra Petch`, `Rajdhani`, `Exo 2`, `Oxanium`, `Orbitron`, `Michroma`, `Share Tech Mono`, `Audiowide`. (OFL).
  * *Dark Fantasy / Medieval*: `Cinzel`, `Cinzel Decorative`, `IM Fell English`, `IM Fell DW Pica`, `Cormorant Garamond`, `Uncial Antiqua`, `Almendra`, `MedievalSharp`. (OFL).
  * *Cozy / Hand-Drawn / Indie*: `Fredoka`, `Quicksand`, `Nunito`, `Patrick Hand`, `Gaegu`, `Sour Gummy`, `Short Stack`, `Mali`. (OFL).
  * *Pixel / Retro / Arcade*: `Press Start 2P`, `Silkscreen`, `VT323`, `Pixelify Sans`, `Tiny5`, `Jacquard 12`, `Jacquard 24`, `Bungee`, `Russo One`, `Kanit`. (OFL).
  * *Horror / Noir / Typewriter*: `Special Elite`, `Courier Prime`, `Xanh Mono`, `Syne Mono`, `Creepster` *(sparingly for campy B-movie horror)*. (OFL / Apache 2.0).
* **Kenney Assets (`kenney.nl/assets?q=font`)** — CC0 (Public Domain) crisp pixel and UI fonts built specifically for indie game engines (Unity, Godot, Unreal) with zero attribution required.
* **Departure Mono (`departuremono.com`)** — Stunning open-source pixel-inspired monospaced font blending early computer terminals with crisp modern legibility. (OFL).
* **04b (`04.jp.org`)** — Legendary Japanese bitmap pixel font collection (*04b_03*, *04b_19*, *04b_30*) free for commercial and personal projects.
* **Itch.io Free Game Fonts (`itch.io/game-assets/free/tag-fonts`)** — Massive indie game asset hub; always filter/verify the creator's license box (many offer CC0 or CC-BY commercial-ready pixel & fantasy bitmap fonts).

### 4. Tier-4 Independent Freebies & Aggregators (Verify License Per Font!)
* **Fontesk (`fontesk.com`)** — Filter strictly by **"Free for Commercial Use"** tag. Great for finding niche indie display serifs and retro grotesks.
* **Befonts (`befonts.com`)** — Check each font's license badge carefully; many independent designers drop 1–2 free commercial weights here as demos.
* **Dirtyline Studio (`dirtylinestudio.com/freebies`)** — High-fashion, brutalist, and Y2K/acid-graphics display fonts with generous free commercial options.
* **Pangram Pangram (`pangrampangram.com`)** — *Free to try* for personal/pitch mockups (requires commercial license for live product/game launch—crucial distinction!).
