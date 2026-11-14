# Typography rules, in full

The detailed rule set behind SKILL.md: 358 numbered rules in nine sections. Read the section you
need rather than the whole file. Each rule names concrete fonts and values; treat them as strong
defaults with reasons, and break one only on purpose, for the art direction in front of you.

## Contents

- [Breaking the "AI Default" Curse](#breaking-the-ai-default-curse) (rules 1-50)
- [Anatomy, Classification & Micro-Details](#anatomy-classification--micro-details) (rules 51-115)
- [Hierarchy, Scale & Layout Rhythm](#hierarchy-scale--layout-rhythm) (rules 116-180)
- [Font Pairing Archetypes & Mechanics](#font-pairing-archetypes--mechanics) (rules 181-215)
- [Variable Fonts & Modern CSS Typography](#variable-fonts--modern-css-typography) (rules 216-240)
- [Web, UI, Mobile & Accessibility Typography](#web-ui-mobile--accessibility-typography) (rules 241-265)
- [Editorial, Print-Inspired & Expressive Web Techniques](#editorial-print-inspired--expressive-web-techniques) (rules 266-290)
- [Common Mistakes, Red Flags & Troubleshooting](#common-mistakes-red-flags--troubleshooting) (rules 291-323)
- [Game Development, HUDs, Diegetic UI & Interactive Worlds](#game-development-huds-diegetic-ui--interactive-worlds) (rules 324-358)

## Breaking the "AI Default" Curse

Rules 1-50.

1. Never use `Inter` as a default display font; if used at all, restrict it to dense data tables.

2. Banish `Roboto` from editorial, luxury, lifestyle, and creative portfolio concepts.

3. Avoid `Montserrat` for modern tech startups; it screams 2016 template aesthetics.

4. Do not pair `Playfair Display` with `Montserrat`; it is the ultimate cliché Canva pairing.

5. Reject `Poppins` for serious financial, legal, or medical interfaces due to its overly geometric, bubbly terminals.

6. Never use `Lobster`, `Pacifico`, or `Brush Script` for authentic vintage or artisanal branding.

7. Avoid `Open Sans` when trying to convey high-craft design; its neutrality borders on invisibility.

8. Do not rely on system font stacks (`-apple-system`, `Segoe UI`) when building expressive landing pages.

9. Stop using `Oswald` compressed uppercase for every "bold" or "fitness" header.
10. Never use `Raleway` with its default 'W' unless you explicitly intend a quirky, mid-2010s indie vibe.
11. Avoid `Lora` for high-fashion editorial; choose a higher-contrast Didone or sharper transitional serif instead.
12. Do not use `Space Grotesk` for every single Web3, AI, or crypto project—it has become the new generic tech uniform.
13. Reject `DM Sans` when the brand requires sharp, authoritative precision; its soft geometry feels too casual.
14. Never leave `font-weight: 400` and `font-weight: 700` as your only typographic hierarchy tools.
15. Avoid pure black (`#000000`) text on pure white (`#FFFFFF`) backgrounds; use deep charcoals (`#111214`) on warm off-whites (`#FAF9F6`).
16. Never use default browser `line-height` (`normal`); always calculate optical leading.
17. Stop setting display headlines at `line-height: 1.5`; tighten display leading to `0.95`–`1.15`.
18. Never leave uppercase text at `letter-spacing: 0`; always track out all-caps by `+0.04em` to `+0.12em`.
19. Avoid tracking out lowercase body text; it destroys word-shape recognition (bouma).
20. Never stretch or squish fonts via CSS `transform: scaleX()` or `scaleY()`.
21. Avoid faux bolds and faux italics; always load the true cut of the typeface.
22. Do not mix two different geometric sans-serifs in the same layout (e.g., `Futura` + `Poppins`).
23. Never pair two high-contrast serifs together; they will fight for visual dominance.
24. Avoid centered body paragraphs longer than three lines; left-align (rag-right) for readability.
25. Never justify text on the web without enabling `hyphens: auto` and proper `word-spacing` controls, or you will create "rivers" of whitespace.
26. Stop using `px` for font sizes; use `rem` for scalability and `clamp()` for fluid viewport typography.
27. Never ignore OpenType features (`font-feature-settings`); enable oldstyle figures (`onum`) in editorial body copy.
28. Always enable tabular figures (`tnum`) for financial dashboards, pricing tables, countdowns, and data grids.
29. Never use straight dumb quotes (`"` and `'`); always use typographically correct curly quotes (`“ ”` and `‘ ’`).
30. Replace double hyphens (`--`) with true em-dashes (`—`) with hair spaces or zero spaces depending on house style.
31. Use true en-dashes (`–`) for number ranges (e.g., `1990–2026`), never hyphens.
32. Avoid widows (single words on the last line of a paragraph) by adjusting measure or using `text-wrap: balance` / `text-wrap: pretty`.
33. Apply `text-wrap: balance` to all headings and subheadings up to 4 lines.
34. Never let line lengths exceed 75 characters (`75ch`) for body copy; aim for `55ch`–`68ch`.
35. Avoid line lengths shorter than `35ch` in multi-column layouts to prevent erratic eye-tracking.
36. Do not put drop shadows behind body text to solve contrast issues; fix the background luminance instead.
37. Never use gradient text fills on complex serifs; gradients only work cleanly on bold, low-contrast grotesks or display faces.
38. Avoid thin font weights (`100`–`200`) at sizes smaller than `36px`; subpixel rendering will shatter the strokes.
39. Do not use `font-smoothing: antialiased` blindly on Windows/low-DPI screens where subpixel rendering aids legibility.
40. Never ignore the x-height differential when pairing a serif and a sans-serif on the same baseline.
41. Avoid pairing a humanist sans with a rigid modern Didone unless creating intentional postmodern friction.
42. Never use default Tailwind `prose` typography without customizing type scale, measure, and color tokens.
43. Stop defaulting to 3-tier scales (`h1`, `h2`, `p`); use micro-labels, kickers, pull-quotes, captions, and lead paragraphs.
44. Never use all-caps for long paragraphs or legal disclaimers; it reduces reading speed by up to 15%.
45. Avoid placing tight tracking (`-0.04em`) on small UI labels (`11px`–`13px`); small type needs breathing room (`+0.01em` to `+0.03em`).
46. Tighten tracking (`-0.02em` to `-0.05em`) on large display headers (`48px`+) to lock letters into cohesive shapes.
47. Never use script fonts in all-caps; capital script glyphs are not designed to connect horizontally.
48. Avoid pairing fonts from the exact same historical era if they have identical skeleton proportions.
49. Never treat typography as an afterthought after boxes are drawn; build the grid around the baseline and x-height.
50. Always inspect the lowercase `a`, `g`, `e`, `t`, and uppercase `Q`, `R`, `G`—these "tell" characters define a typeface's soul.

## Anatomy, Classification & Micro-Details

Rules 51-115.

51. Distinguish between **Neo-Grotesks** (Helvetica, Inter, Neue Haas) and **Grotesks** (Akzidenz-Grotesk, Work Sans, Space Grotesk)—Grotesks have quirkier, warmer irregularities.

52. Use **Humanist Sans-Serifs** (Gill Sans, Frutiger, Plus Jakarta Sans, Lato, Source Sans) when warmth, empathy, and human touch are needed.

53. Choose **Geometric Sans-Serifs** (Futura, Avant Garde, Outfit, Syne) for architectural, modernist, or bold graphic statements.

54. Deploy **Old-Style / Garalde Serifs** (Garamond, Sabon, Crimson Pro, EB Garamond) for literary, historical, academic, and timeless bookish elegance.

55. Select **Transitional Serifs** (Baskerville, Times, Libre Baskerville, Newsreader) for journalism, authority, and high-trust institutions.

56. Use **Didone / Modern Serifs** (Bodoni, Didot, Bodoni Moda, Playfair) sparingly for haute couture, luxury hospitality, and dramatic mastheads.

57. Choose **Slab Serifs / Egyptians** (Rockwell, Clarendon, Zilla Slab, Arvo, Roboto Slab) for industrial, engineering, rugged, or editorial sub-branding.

58. Utilize **Scotch Romans** (Miller, Georgia, Fraunces) for rich, chewy, high-personality editorial body and display copy.

59. Look at **aperture size**: wide apertures (`Fira Sans`, `Atkinson Hyperlegible`) boost UI legibility; tight apertures (`Helvetica`, `Syne`) feel sleek, closed, and monumental.

60. Check the **x-height**: tall x-heights (`Work Sans`, `Merriweather`) read larger at small sizes; low x-heights (`EB Garamond`, `Futura`) feel classical and airy.

61. Evaluate **stroke contrast**: high contrast (`Bodoni`) requires large sizes; low contrast (`Plus Jakarta Sans`) survives tiny mobile viewports.

62. Observe **stress axis**: diagonal stress feels calligraphic and organic; vertical stress feels mechanical, modern, and rational.

63. Examine **terminals**: ball terminals add Victorian/literary charm; sheared/angled terminals add speed and modernism; perpendicular terminals feel clinical.

64. Inspect the lowercase `g`: double-storey `g` feels literary, traditional, and complex; single-storey `g` feels geometric, clean, and contemporary.

65. Inspect the lowercase `a`: double-storey `a` anchors body text with rhythm; single-storey `a` gives a playful, schoolbook, or modernist geometric vibe.

66. Look at the tail of the uppercase `Q`: sweeping tails add baroque drama; short straight tails keep vertical spacing clean.

67. Check the leg of the uppercase `R`: a curved, expressive leg adds humanist warmth; a straight diagonal leg feels mechanical.

68. Use **ink traps** (`Syne`, `Bricolage Grotesque`, `Plus Jakarta`, `Whyte Inktrap` alternatives like `Instrument Sans`) to give modern digital type a tactile, print-inspired edge.

69. Leverage **optical sizing (`opsz`)** in variable fonts so hairline details thicken automatically at `14px` and sharpen at `96px`.

70. Use **superfamilies** (typefaces with matching Sans, Serif, and Mono cuts like `IBM Plex`, `Source`, `Instrument`, `Fraunces`+`Commissioner`) for cohesive multi-layered systems.

71. Check diacritic support (`À, É, Ñ, Ü, Ç, Ø`) before committing to any free display font for international products.

72. Verify currency symbols (`$`, `€`, `£`, `¥`, `₹`, `₿`) match the weight and height of the numerals.

73. Ensure math operators (`+`, `−`, `×`, `÷`, `=`, `%`) align with the cap-height or x-height properly.

74. Check arrow glyphs (`→`, `↗`, `↘`, `←`)—many cheap free fonts have clunky, mismatched arrows that ruin UI buttons.

75. Use `tabular-nums` (`font-variant-numeric: tabular-nums`) in shopping carts, stock tickers, and tables so numbers don't jitter during updates.

76. Use `proportional-nums` (`font-variant-numeric: proportional-nums`) in body sentences so the number `1` doesn't have awkward white gaps around it.

77. Use `slashed-zero` (`font-variant-numeric: slashed-zero`) in developer tools, API keys, license codes, and technical dashboards to distinguish `0` from `O`.

78. Use `diagonal-fractions` (`font-variant-numeric: diagonal-fractions`) in recipe sites, architectural specs, and e-commerce sizing (`1/2`, `3/4`).

79. Enable standard ligatures (`liga`) in serifs so `fi`, `fl`, `ffi`, and `ffl` don't collide awkwardly.

80. Disable standard ligatures when tracking out uppercase display headers (`letter-spacing > 0.08em`), otherwise `FI` stays glued together while other letters spread apart.

81. Use discretionary ligatures (`dlig`) like `ct`, `st`, and `sp` in luxury headings or book covers for bespoke artisanal flair.

82. Check italic angles: steep italics (`12°–16°`) feel urgent and dynamic; shallow italics (`6°–9°`) feel calm and composed.

83. Distinguish between **true italics** (calligraphic, cursive letterforms like a single-storey `a` and `f` with a descender) and **obliques** (slanted roman letters).

84. Never pair an oblique sans with a calligraphy-heavy serif unless the contrast is deliberately theatrical.

85. Look at ascender height vs. cap height: ascenders taller than capitals (`EB Garamond`, `Crimson Pro`) create graceful, rhythmic top edges in paragraphs.

86. Check descender depth (`g`, `j`, `p`, `q`, `y`): deep descenders require generous `line-height` (`1.55+`) to prevent line collisions.

87. Use **condensed** widths for vertical space efficiency in data-dense headers, badges, and editorial kickers.

88. Use **extended/wide** widths for hero statements, automotive/tech branding, and brutalist or luxury banners.

89. Avoid mixing condensed and extended fonts on the exact same horizontal baseline unless creating deliberate poster collage chaos.

90. Pay attention to counter shapes (the enclosed spaces inside `o`, `p`, `d`, `b`): circular counters feel friendly; squarish/superellipse counters (`Eurostile`, `Space Grotesk`) feel industrial and futuristic.

91. Check the crossbar of the lowercase `e`: a tilted crossbar (`Centaur`, `Jenson`, `Newsreader`) signals Renaissance humanism; a horizontal crossbar signals rational modernism.

92. Notice the vertex of `M`, `N`, `V`, `W`: razor-sharp apexes feel aggressive and precise; flat-topped apexes feel sturdy and architectural.

93. Evaluate the shoulder of `n`, `m`, `h`: deep branching feels organic and calligraphic; high branching feels rigid and mechanical.

94. Inspect punctuation weight: heavy, oversized periods and commas give a punchy, editorial, brutalist tone; delicate punctuation feels refined.

95. Use hanging punctuation (`hanging-punctuation: first last` in CSS) so quotation marks hang cleanly outside the left margin of pull-quotes.

96. Check bullet points and list markers: custom styling or matching the bullet size to the x-height elevates list legibility dramatically.

97. Never use default underlines (`text-decoration: underline`) on serif display links if they slice aggressively through descenders; use `text-underline-offset: 0.18em` and `text-decoration-thickness: 1px`.

98. Use `text-decoration-skip-ink: auto` so underlines cleanly break around descending letters (`g`, `y`, `p`).

99. Inspect small caps (`font-variant-caps: small-caps` or `all-small-caps`)—only use them if the font contains **true** drawn small caps, never browser-scaled fake small caps.
100. True small caps have the same stroke thickness as lowercase letters; fake small caps look skinny and anemic next to normal text.
101. Match border-radius of UI containers to the corner radius of your chosen typeface's terminals (sharp fonts = sharp corners; rounded fonts = pill buttons).
102. Match icon stroke weight (`1.5px` vs `2px`) to the stem thickness of your UI body font at `16px`.
103. Match icon corner caps (round vs butt) to your primary sans-serif's stroke endings.
104. Check kerning pairs (`AV`, `To`, `Wa`, `Yo`, `LT`, `P.`) in large display titles; manually adjust with `<span>` letter-spacing if the free font's kerning table is weak.
105. Always set `font-kerning: normal` explicitly in your base CSS reset.
106. Avoid setting body font size below `16px` (`1rem`) on desktop for long-form reading; `17px`–`19px` is the sweet spot for modern screens.
107. Use `14px`–`15px` for dense SaaS application interfaces, sidebars, and metadata tables.
108. Never set micro-labels or legal text smaller than `11px` (`0.6875rem`).
109. Use color contrast ratios of at least `4.5:1` for body text and `3:1` for large display text (`24px+` regular or `19px+` bold).
110. Reduce opacity slightly (`0.75`–`0.85`) or shift toward warm/cool mid-grays for secondary metadata instead of shrinking font size below `12px`.
111. Use **monospace fonts** for timestamps, version numbers, coordinates, tags, and breadcrumbs to create an immediate "crafted/technical" visual anchor.
112. Pair a lush, expressive serif headline with a crisp monospace kicker (`11px`, uppercase, `+0.1em` tracking) for an instant editorial-tech aesthetic.
113. Never use Comic Sans-adjacent rounded fonts (`Fredoka`, `Bubblegum`) for B2B SaaS unless the brand identity is explicitly toy-like or playful.
114. Avoid distressed, grunge, or eroded fonts on the web; they bloat file sizes, render poorly at small scales, and look dated.
115. Test every chosen font in both Light Mode and Dark Mode—fonts appear visually heavier on dark backgrounds due to irradiation illusion; lighten weight by 50–100 units or increase tracking by `+0.01em` in Dark Mode.

## Hierarchy, Scale & Layout Rhythm

Rules 116-180.

116. Use a mathematical **modular scale** rather than random pixel guessing:
     * **Minor Second (`1.067`)**: Dense SaaS dashboards, mobile UIs.
     * **Major Second (`1.125`)**: Versatile web apps, documentation, corporate sites.
     * **Minor Third (`1.200`)**: Balanced editorial blogs, marketing pages.
     * **Major Third (`1.250`)**: Expressive portfolios, SaaS hero pages.
     * **Perfect Fourth (`1.333`)**: High-impact editorial, fashion, art galleries.
     * **Golden Ratio (`1.618`)**: Poster-like brutalist layouts, architectural monographs.
117. Create hierarchy through **contrast of scale** (e.g., `72px` H1 paired with `16px` body = 4.5x ratio) rather than making everything mildly big.
118. Create hierarchy through **contrast of weight** (e.g., `800 ExtraBold` heading paired with `400 Regular` body).
119. Create hierarchy through **contrast of posture** (e.g., `Italic` serif pull-quote paired with `Roman` sans-serif body).
120. Create hierarchy through **contrast of case** (e.g., `UPPERCASE` micro-kicker above a `Sentence case` display title).
121. Prefer **Sentence case** over Title Case for modern UI buttons, navigation, and headings—it feels more human, conversational, and scannable.
122. Reserve **Title Case** for formal publications, legal documents, book titles, and traditional luxury institutions.
123. Never stack three different font families in a single component; limit the entire design system to 2 families (or 3 max if one is a utility monospace).
124. Establish a strict **8pt or 4pt baseline grid** so line heights (`24px`, `28px`, `32px`, `48px`) align harmoniously across adjacent columns.
125. Ensure the spacing *above* a heading (`margin-top: 2.5em`) is at least 2x to 3x larger than the spacing *below* it (`margin-bottom: 0.6em`) so the heading visually attaches to the paragraph it introduces (Law of Proximity).
126. Keep paragraph bottom margins (`1.25em`–`1.5em`) consistent throughout long-form articles.
127. Use **lead paragraphs** (`1.25rem`–`1.35rem`, lighter weight or slightly looser leading) at the start of articles to bridge the jump from H1 to body text.
128. Style **pull-quotes** using the display font at `1.5rem`–`2rem`, distinct from standard `<blockquote>` citations.
129. Differentiate **captions** (`0.8125rem`, italic or monospace, muted color) clearly from surrounding body copy so readers don't accidentally read captions mid-sentence.
130. Use **asymmetric typographic layouts** (e.g., wide left-aligned display headline in column 1–8, indented body copy in columns 5–11) to escape boxy AI templates.
131. Anchor the top-left corner of editorial pages with a tiny, high-precision typographic index marker (e.g., `FIG. 01 — ARCHIVE 2026`).
132. Use **hairline rules (`1px solid`)** between stacked typographic rows (like editorial tables of contents or archive lists) to create Swiss grid precision.
133. Never wrap every paragraph or heading inside a rounded card box; let typography float directly on the canvas using whitespace for separation.
134. Use **negative space** aggressively—at least 35%–45% of an editorial or luxury viewport should remain empty canvas.
135. Align numerical lists and bullet lists with **hanging indentation** (`padding-left: 1.5em; text-indent: -1.5em` or clean CSS Grid columns) so wrapped lines align with the text, not under the bullet.
136. Style inline links subtly—use a tinted underline (`border-bottom` or `text-decoration-color`) rather than jarring default `#0000EE` blue.
137. Make inline `<code>` tags slightly smaller (`0.875em`) than surrounding body text, because monospace fonts have larger visual footprints and wider characters.
138. Add subtle horizontal padding (`0.25em 0.4em`) and a low-contrast background pill to inline `<code>` snippets so they don't collide with adjacent words.
139. Style keyboard shortcuts (`<kbd>`) with crisp borders, subtle bottom shadow, and monospace uppercase glyphs.
140. Never center-align bulleted lists; left-align the list block even if the section header is centered.
141. Avoid placing text directly over busy photography without a directional scrim gradient, a backdrop blur, or placing text inside a clean typographic cutout panel.
142. Use **vertical rotated text** (`writing-mode: vertical-rl; transform: rotate(180deg)`) sparingly for margin notes, section numbers, or brutalist index tabs.
143. Ensure fluid typography scales smoothly between mobile (`375px`) and desktop (`1440px`) using `clamp(2.25rem, 5vw + 1rem, 5.5rem)`.
144. Never let H1 sizes shrink so much on mobile that they look identical to H2s; maintain at least a `1.4x` visual jump on small screens.
145. Keep button labels concise (1–3 words), set `white-space: nowrap`, and use `font-weight: 500` or `600` for crisp tap targets.
146. Avoid uppercase text inside long form-input labels; use clear Sentence case above inputs for rapid form completion.
147. Use `tabular-nums` inside input fields that accept prices, dates, phone numbers, or credit cards.
148. Design empty states and error messages with warm, human typography—never cold monospace system errors unless building a CLI tool.
149. Create visual cadence in long articles by inserting subheadings (`H2`/`H3`) every 250–350 words.
150. Never stack an `H2` immediately followed by an `H3` without introductory body text between them.
151. Use **drop caps** (`::first-letter`) in long-form editorial essays—float them across 2–3 lines using a high-contrast display serif.
152. Match the baseline of a drop cap cleanly with the bottom of the 2nd or 3rd line of body text.
153. Avoid overly decorative initials for drop caps on clean modern blogs; stick to a bold cut of your primary serif.
154. Use **small-caps lead-ins** (the first 3–5 words of an opening paragraph in small caps) as a sophisticated alternative to drop caps.
155. Style blockquotes with a thick left vertical bar (`3px`) or oversized opening quotation glyph in a muted accent hue.
156. Differentiate **footnotes and sidenotes**: on desktop screens (`1280px+`), place footnotes in the right margin aligned horizontally with their reference marker.
157. Use superscript numerals (`<sup>`) styled with `font-size: 0.7em; line-height: 0; vertical-align: super` so they don't disrupt the line-height of the paragraph they sit inside.
158. Never let superscripts push down the line below them—explicitly set `line-height: 0` on `sup` and `sub` elements.
159. Group related metadata (Author • Date • Read Time) using subtle middle dots (`·`) or slashes (`/`) with generous horizontal spacing (`0.5em`).
160. Avoid heavy pipe characters (`|`) as metadata separators; they look like capital `I`s or lowercase `l`s and clutter the line.
161. Use **breadcrumb trails** set in `12px`–`13px` muted sans or mono with chevron (`›`) or slash (`/`) separators.
162. Ensure navigation bar links have ample horizontal breathing room (`gap: 2rem` to `2.5rem`)—cramped navbars look amateurish.
163. Keep primary navbar links to 4–6 items maximum so typography stays clean and scannable.
164. Design footers with bold, oversized brand wordmarks or dramatic typographic colophons rather than cramped 6-column link farms.
165. Include a **colophon** in creative/portfolio sites stating the typefaces used (e.g., *"Set in Newsreader & Geist Mono"*), which signals deep design intentionality.
166. Use contrast between **tight display headers** and **airy metadata** to create tension and sophistication.
167. Never put exclamation marks (`!`) in luxury, minimalist, or serious institutional copy; let the typography carry the authority.
168. Avoid excessive bolding (`<strong>`) inside body paragraphs; bolding more than 10% of a paragraph makes everything look noisy and cheap.
169. Use *italics* for subtle emphasis inside sentences, and **bold** only for scannable key terms or list lead-ins.
170. Maintain consistent optical margin alignment—nudge left-aligned large display letters like `T`, `V`, `W`, `Y`, `A`, `O` slightly negative (`margin-left: -0.04em`) so their visual mass aligns with body text below.
171. Check the vertical alignment of text inside buttons and badges—some fonts have unbalanced ascender/descender metrics requiring a `1px` top/bottom padding tweak to look optically centered.
172. Use CSS `leading-trim` / `text-box-trim` (where supported) or precise line-height ratios to eliminate extra half-leading whitespace above and below headings.
173. Never rely on bold color alone to indicate active navigation states; pair color shifts with weight changes, underlines, or indicator dots.
174. Create rich **editorial tables** using horizontal hairline dividers (`border-bottom`), zero vertical grid lines, left-aligned text columns, and right-aligned `tabular-nums` numerical columns.
175. Align table column headers with their column data (left-align text headers, right-align number headers).
176. Use `font-variant-position: sub` and `super` for chemical formulas ($\text{H}_2\text{O}$) and ordinal indicators when supported by the font.
177. Avoid wrapping acronyms (`NASA`, `API`, `HTML`, `USA`) in full-size caps inside body text if your font supports `c2sc` (capitals to small caps)—small-cap acronyms blend seamlessly into running prose.
178. Test your typographic hierarchy in **grayscale** first; if the page lacks clear focal points without color, your scale, weight, and spacing are weak.
179. Squint at your layout (the blur test): you should immediately see clear typographic blocks, clear entry points, and balanced whitespace.
180. Never stop at the first font pairing that "looks okay"—test 3 contrasting pairings side-by-side against real copy, not *Lorem Ipsum*.

## Font Pairing Archetypes & Mechanics

Rules 181-215.

181. **The Editorial Powerhouse**: High-contrast Serif Headline + Neutral/Humanist Sans Body (e.g., `Instrument Serif` + `Plus Jakarta Sans`).
182. **The Modern Tech Precisionist**: Crisp Grotesque Headline + Technical Monospace Metadata + Clean Sans Body (e.g., `Geist` + `Geist Mono`).
183. **The Neo-Brutalist Swiss**: Heavy Compressed/Wide Grotesque Display + Raw Monospace Body (e.g., `Syne` or `Archivo Black` + `Space Mono` or `IBM Plex Mono`).
184. **The Literary & Intellectual**: Warm Old-Style/Transitional Serif for both Headlines and Body, paired with a Geometric Sans for UI/Captions (e.g., `Newsreader` + `Outfit`).
185. **The Warm Humanist SaaS**: Soft-terminal Humanist/Geometric Sans Headline + Ultra-legible Humanist Sans Body (e.g., `Bricolage Grotesque` + `Inter` or `Source Sans 3`).
186. **The Haute Couture / Luxury**: Dramatic Didone Display (tight tracking, ultra-thin or ultra-bold) + Airy Uppercase Sans Subtitles (e.g., `Bodoni Moda` + `Tenor Sans`).
187. **The Industrial / Architectural**: Geometric/Neo-Grotesque Display + Technical Slab or Monospace (e.g., `Space Grotesk` or `Chakra Petch` + `IBM Plex Mono`).
188. **The Organic / Artisanal Craft**: Quirky Scotch Roman or Ink-Trap Serif + Warm Organic Sans (e.g., `Fraunces` + `Commissioner` or `Work Sans`).
189. **The Cyber / Sci-Fi / Gaming**: Angular/Modular Display + Crisp Terminal Monospace (e.g., `Orbitron` or `Syne` + `JetBrains Mono`).
190. **The Academic / Research**: Classical Garamond/Baskerville Serif + Humanist Sans for charts and tables (e.g., `EB Garamond` + `Fira Sans`).
191. **Rule of Contrast**: Pair fonts that share **one** structural trait (e.g., matching x-height or width proportion) while contrasting sharply in **two** traits (e.g., Serif vs. Sans, High Contrast vs. Monoline).
192. **Rule of Single-Family Mastery**: Use a single variable font with massive optical and weight range (like `Fraunces`, `Bricolage Grotesque`, or `Newsreader`) across the entire site—using weight, italic, and optical size for variety.
193. **Superfamily Harmony**: Pair `IBM Plex Sans` + `IBM Plex Serif` + `IBM Plex Mono` for guaranteed identical x-heights, cap-heights, and stroke harmony.
194. **Superfamily Harmony II**: Pair `Source Serif 4` + `Source Sans 3` + `Source Code Pro` for open-source editorial and documentation perfection.
195. **Superfamily Harmony III**: Pair `Instrument Serif` + `Instrument Sans` for ultra-modern, high-fashion editorial and creative agency work.
196. **Never pair two script fonts** together under any circumstances.
197. **Never pair two display/novelty fonts** together (e.g., `Syne` + `Cinzel` = visual chaos).
198. When pairing a Serif and a Sans, ensure the **sans-serif** is never dramatically more decorative than the serif unless the sans is the main display hero.
199. Check the **cap-height alignment** when placing a badge or tag next to a headline; adjust vertical alignment with Flexbox `items-baseline` rather than `items-center` when mixing typefaces.
200. Match the **mood/temperament**: an exuberant, bouncy serif (`Fraunces` with high `SOFT` axis) clashes with a cold, clinical, sharp sans (`Eurostile`).
201. Use a **serif for empathy and storytelling**, and a **sans-serif for utility, navigation, and controls**.
202. Flip the script for editorial magazines: use a **bold, punchy grotesque sans** for headlines and a **classic, readable serif** for long-form body text (`Archivo` headlines + `Lora` or `Crimson Pro` body).
203. Use **monospace as an accent voice**, never as long-form paragraph copy (unless designing a developer IDE, terminal, or conceptual art zine).
204. Keep monospace line lengths shorter (`50ch`–`60ch`) because fixed-width characters take up \~20% more horizontal space than proportional fonts.
205. Pair a **condensed display sans** (`Antonio`, `Oswald`, `Fjalla One`, `Bebas Neue`) with a **wide or normal-width body sans** (`Plus Jakarta Sans`) to create dynamic dimensional contrast.
206. Avoid pairing `Bebas Neue` (which has no lowercase) with an overly delicate serif; pair it with clean, sturdy grotesks (`Work Sans`, `Inter`).
207. When using an **all-caps display font** (`Cinzel`, `Bebas Neue`, `Syncopate`), always provide a lowercase-capable secondary font for all subheadings and UI controls.
208. Check the **numeral styles** of both paired fonts—if your display font uses oldstyle ranging numerals and your UI font uses lining numerals, keep them separated by context.
209. Pair **geometric sans** (`Outfit`, `Jost`) with **transitional/modern serifs** (`Libre Baskerville`, `Bodoni Moda`) because both share clean, circular `O` shapes and rational vertical axes.
210. Pair **humanist sans** (`Source Sans 3`, `Fira Sans`) with **old-style serifs** (`EB Garamond`, `Crimson Pro`) because both share organic, calligraphic, diagonal-stress skeletons.
211. Use **Slab Serifs** (`Zilla Slab`, `Arvo`, `Bitter`) as a bridge font—they carry the authority of a serif with the sturdy, monolinear geometry of a sans-serif.
212. Pair `Bitter` (an incredible screen-optimized slab serif) with `Fira Sans` or `Work Sans` for rugged, high-legibility journalism or outdoor/hardware brands.
213. Test your font pairing at **extreme scale differences**: `88px` headline vs `14px` body, and `20px` card title vs `13px` caption.
214. Verify that the **bold weight** of your body font doesn't look heavier than the **regular weight** of your display font.
215. When in doubt, anchor your layout with one neutral workhorse (`Geist`, `Plus Jakarta Sans`, `Work Sans`) and let one expressive display font (`Instrument Serif`, `Syne`, `Fraunces`, `Playfair`, `Unbounded`) do all the heavy emotional lifting.

## Variable Fonts & Modern CSS Typography

Rules 216-240.

216. Embrace **Variable Fonts** (`.woff2`)—one single HTTP request gives you infinite weights (`100`–`900`), widths, slants, and optical sizes.
217. Leverage the `wght` (Weight) axis for smooth hover transitions (`font-variation-settings: "wght" 400` to `"wght" 650` on hover—just watch out for layout shift!).
218. Prevent layout shift during hover weight animations by using an invisible pseudo-element (`::after { content: attr(data-text); font-weight: 700; height: 0; visibility: hidden; }`) or using a **duplexed/uniwidth font** (`Archivo`, `Recursive`, `JetBrains Mono`) where every weight has the exact same character width!
219. Use the `opsz` (Optical Size) axis in fonts like `Fraunces`, `Newsreader`, `Roboto Flex`, and `Bodoni Moda`—set `font-optical-sizing: auto` in CSS.
220. Explore custom axes in `Fraunces`: `SOFT` (`0` to `100` for terminal roundness) and `WONK` (`0` or `1` for quirky leaning characters).
221. Explore `Recursive`: it morphs seamlessly across `MONO` (proportional to monospace), `CASL` (linear to casual brush), `wght`, and `slnt` (slant)!
222. Use `Roboto Flex` when you need granular parametric control over ascender height (`YTAS`), descender depth (`YTDE`), x-height (`XOPQ`), and counter width.
223. Always serve fonts in `.woff2` format—it offers \~30% better compression than `.woff` and makes `.ttf`/`.otf` web delivery obsolete.
224. Subset your `.woff2` font files to include only needed Unicode ranges (e.g., `Latin` + `Latin-Extended`) to cut file size from `250KB` down to `18KB`.
225. Use `font-display: swap` for body fonts so text renders immediately without FOIT (Flash of Invisible Text).
226. Use `font-display: optional` or `block` (with preloading) for iconic hero display fonts or icon fonts so users don't experience jarring FOUT (Flash of Unstyled Text) on above-the-fold headlines.
227. Preload critical above-the-fold `.woff2` files via `<link rel="preload" as="font" type="font/woff2" crossorigin>` in the `<head>`.
228. Configure `size-adjust`, `ascent-override`, `descent-override`, and `line-gap-override` in your `@font-face` fallback stack to eliminate Cumulative Layout Shift (CLS) during font swap.
229. Use CSS `clamp()` for fluid type scales without media query breakpoints:
     `font-size: clamp(1rem, 0.92rem + 0.39vw, 1.25rem);`
230. Combine `vw` units with `rem` units inside `clamp()` (`clamp(2rem, 4vw + 1rem, 5rem)`) so users can still zoom the page using browser `Ctrl/Cmd +` zoom (pure `vw` breaks WCAG zoom accessibility!).
231. Use `-webkit-text-stroke` carefully—only on massive display fonts (`80px+`) with `paint-order: stroke fill` so the stroke renders *behind* the fill rather than eating inward into thin letter stems.
232. Use `background-clip: text; color: transparent;` for subtle metallic or iridescent light sweeps across bold display typography.
233. Apply `text-rendering: optimizeLegibility` on display headings (`24px+`) to activate kerning and ligatures, while keeping `optimizeSpeed` on massive 10,000-row data tables if rendering performance bottlenecks.
234. Use `-webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale;` on macOS/iOS for light-on-dark typography so white stems don't bloom and look bloated.
235. Set `quotes: "“" "”" "‘" "’";` in CSS for `<q>` and `<blockquote>` elements to enforce authentic typographic quotation marks automatically.
236. Use CSS `initial-letter: 3;` for native, pixel-accurate editorial drop caps across modern browsers.
237. Use `ch` units (`max-width: 65ch`) for setting text container widths—it adapts automatically if the font family or font size changes.
238. Use `ex` units (`height: 1ex`) when aligning inline SVG icons or dividers directly to the x-height of lowercase text.
239. Use `cap` units (`height: 1cap`) when sizing badges, status dots, or inline icons to match the exact height of capital letters.
240. Test fonts on both Windows (ClearType subpixel rendering) and macOS (grayscale subpixel rendering)—thin fonts (`weight < 300`) often look brittle on Windows displays.

## Web, UI, Mobile & Accessibility Typography

Rules 241-265.

241. Never sacrifice legibility for aesthetic novelty in primary navigation, body copy, checkout flows, or error states.
242. For dyslexic or low-vision accessibility, prioritize fonts with distinct character silhouettes: clear distinction between `I` (capital i), `l` (lowercase L), and `1` (digit one), plus `b/d` and `p/q` asymmetry (`Atkinson Hyperlegible`, `Lexend`, `IBM Plex Sans`).
243. Use `Atkinson Hyperlegible` (designed by the Braille Institute) for healthcare, civic, accessibility-first, and public utility interfaces.
244. Use `Lexend` for educational platforms, reading apps, and cognitive ease—its variable `HEXP` axis widens inter-character spacing to boost reading fluency.
245. Ensure uppercase `I`, lowercase `l`, and digit `1` are immediately distinguishable in any font used for passwords, tracking codes, or technical documentation.
246. Avoid geometric sans-serifs where `O` and `0` are identical circles in financial or technical interfaces.
247. Set touch-target labels and mobile form inputs to at least `16px` (`1rem`) on iOS—anything smaller than `16px` triggers automatic Safari viewport zoom on focus!
248. Increase line-height slightly on mobile viewports (`1.55`–`1.65`) compared to desktop (`1.45`–`1.55`) to aid thumb-scrolling and narrow-column eye tracking.
249. Decrease display headline scale ratios on mobile (`375px`)—a `96px` desktop H1 should scale down to `36px`–`44px` on mobile, not `64px` where single words wrap mid-word.
250. Add `overflow-wrap: break-word` and `word-break: normal` to headings so long German or technical words don't blow out mobile horizontal scrollbars.
251. Never truncate important headlines with `text-overflow: ellipsis` (`...`) unless inside a strict single-line table cell or chip; allow headings to wrap naturally.
252. Use `tabular-nums` on every timer, stopwatch, progress percentage (`0%` → `100%`), and pagination counter (`1 / 12`) so UI controls don't vibrate horizontally as digits tick.
253. Keep badge and pill text ultra-concise (`10px`–`12px`, `font-weight: 600`, `letter-spacing: +0.05em`, uppercase) with balanced padding (`4px 10px`).
254. Avoid italicizing entire UI alerts, tooltips, or helper text blocks; italics are harder to scan quickly on low-DPI screens.
255. Use semantic color + icon + clear typographic hierarchy for form validation errors—never rely on red text alone.
256. Style placeholder text (`::placeholder`) with sufficient contrast (`>= 3:1`, e.g., `#6B7280` on white) while keeping it visibly lighter than actual user-entered input text (`#111827`).
257. Design multi-step wizards and progress bars with clear numerical indices (`01`, `02`, `03`) set in a crisp monospace or tabular sans.
258. In dense SaaS tables, use `13px`–`14px` regular weight for cell data, `11px`–`12px` uppercase semibold for column headers, and subtle row padding (`12px 16px`).
259. Use right-alignment for currency and numeric columns in tables, and left-alignment for dates (formatted cleanly as `Nov 13, 2026` or ISO `2026-11-13` in monospace).
260. Never use ALL CAPS for error toast notifications—it feels like the software is shouting at the user.
261. Pair crisp sans-serif UI controls with an editorial serif welcome greeting on user dashboards to inject warmth into sterile SaaS products.
262. Use micro-typography in cards: `Category Kicker` (`11px` uppercase tracked) → `Card Title` (`18px–20px` semibold tight) → `Summary` (`14px` regular muted) → `Metadata` (`12px` mono).
263. Ensure dark-mode surfaces use elevated gray tiers (`#0D0E11` base, `#16181D` card, `#1F2229` popover) paired with crisp off-white text (`#F3F4F6` primary, `#9CA3AF` secondary) rather than harsh `#FFFFFF` on `#000000`.
264. Check how thin serif hairlines render in Dark Mode—high-contrast Didones (`Bodoni`) can disappear into dark backgrounds if scaled too small; keep them above `32px` in dark themes.
265. Use localized font fallbacks for CJK (Chinese, Japanese, Korean), Arabic, or Cyrillic scripts (`Noto Sans JP`, `Noto Serif KR`, `IBM Plex Sans Arabic`) that match the x-height and stroke weight of your Latin font.

## Editorial, Print-Inspired & Expressive Web Techniques

Rules 266-290.

266. Study Swiss International Style (Müller-Brockmann): use asymmetric grids, flush-left/rag-right grotesks (`Neue Haas` / `Archivo` / `Inter Tight`), massive scale jumps, and strict horizontal rules.
267. Study French Editorial & Fashion (M/M Paris, Vogue): pair razor-sharp high-contrast serifs (`Bodoni Moda`, `Cormorant Garamond`) with tiny uppercase spaced sans-serif captions (`10px`, `+0.18em` tracking).
268. Study Brutalist / Anti-Design Web (Balenciaga, Brutalist Websites): mix raw system defaults (`Times New Roman`, `Courier`) or hyper-stretched/condensed display fonts (`Syne`, `Unbounded`, `Anton`) with exposed `1px` black borders and zero border-radius.
269. Study Japanese Modernist Editorial: combine ultra-clean geometric grids, vertical index labels, abundant whitespace, and dual-script harmony (`Plus Jakarta Sans` + `Noto Sans JP`).
270. Study Mid-Century Modernist Design (Saul Bass, Paul Rand): use geometric sans (`Futura` / `Jost` / `Outfit`), warm slab serifs (`Rockwell` / `Zilla Slab`), playful baseline shifts, and warm paper-stock backgrounds (`#F4EFE6`).
271. Study 1970s Psychedelic & Retro Editorial: use lush, high-contrast, bulbous serif display faces (`Fraunces` with `WONK=1, SOFT=100`, `Cooper Black` style `Bagel Fat One` or `Shrikhand`) paired with warm earth tones.
272. Study Contemporary Tech / AI Research Labs (Anthropic, Linear, Vercel, OpenAI): pair crisp neo-grotesks (`Geist`, `Inter Tight`) with authoritative literary serifs (`Newsreader`, `Source Serif 4`, `Instrument Serif`) to signal "human intelligence + computational rigor."
273. Use **oversized edge-to-edge hero typography** (`12vw`–`18vw`) that bleeds right up to the viewport margins (`letter-spacing: -0.04em`).
274. Create **editorial mastheads** with thin top and bottom borders, flanked by issue numbers (`VOL. 04`), dates, and price/location tags in `11px` monospace.
275. Mix **roman and italic words inside the same H1 headline** (e.g., `"Crafting *timeless* digital *experiences*"`) using an expressive editorial serif (`Instrument Serif`, `Newsreader`, `Playfair Display`) for instant literary sophistication.
276. Highlight key words inside a monochrome headline using a **hand-drawn SVG underline**, a **pill border**, or a **subtle italic serif swap** mid-sentence!
277. Swapping a single keyword inside a clean sans-serif headline into an **italic high-contrast serif** (e.g., `Geist` headline with one word in `Instrument Serif Italic`) is one of the highest-leverage anti-AI typographic moves available.
278. Use **inline visual chips/avatars** embedded right inside display headlines (`"Built for [icon] ambitious teams"`) matched to the cap-height of the surrounding type.
279. Create **typographic indexes / directories** using full-width hover rows (`border-b`) where the project title is large serif on the left, category is sans in the middle, and year is tabular mono on the right.
280. Use **superscript category counts** next to filter tabs or headlines (e.g., `Selected Work ⁽¹⁴⁾`) set in `0.45em` monospace or sans.
281. Add subtle **paper grain / noise textures** (`opacity: 0.03`) over warm off-white backgrounds to give editorial serifs a tactile letterpress feel.
282. Use **hanging numbers** (`01.`, `02.`, `03.`) set in a distinct typeface (e.g., serif numbers for sans titles, or mono numbers for serif titles) in feature lists.
283. Frame pull-quotes with oversized opening and closing quotation marks (`“ ”`) rendered at `4rem` in a muted brand accent color.
284. Use **strikethrough styling** (`line-through`) deliberately for comparative storytelling (e.g., `~~Generic templates~~` → `Bespoke systems`) rather than just e-commerce discounts.
285. Design **newspaper-style multi-column layouts** (`column-count: 2` or `3`, `column-gap: 2.5rem`, `column-rule: 1px solid`) for long-form essays on wide desktop monitors.
286. Balance column heights automatically with `column-fill: balance`.
287. Place a **standing cap** or **fleuron / dingbat ornament** (`❦`, `✦`, `※`, `§`, `¶`) between major essay sections instead of generic `<hr>` lines.
288. Use section signs (`§ 01`), pilcrows (`¶`), and asterisms (`⁂`) as authentic literary typographic markers.
289. Create **kinetic / scroll-linked typography** where display lines shift subtly horizontally (`translateX`) on scroll, or variable font weight smoothly thickens as a section enters the viewport.
290. Never let scroll-linked kinetic text make body paragraphs move—keep readable copy rock-solid and stationary.

## Common Mistakes, Red Flags & Troubleshooting

Rules 291-323.

291. **Red Flag**: Using `Montserrat` + `Open Sans` + purple-to-blue gradient + 3 rounded feature cards = instant AI-generated template smell.
292. **Red Flag**: Using `Space Grotesk` + dark `#0B0F19` background + glowing cyan neon borders = generic 2023 crypto template.
293. **Red Flag**: Using `Playfair Display` + pastel pink background + gold faux-foil gradient = generic wedding/beauty Canva template.
294. **Red Flag**: Leaving default `H1` (`32px`), `H2` (`24px`), `H3` (`18.72px`), `P` (`16px`) browser ratios untouched.
295. **Red Flag**: Using `font-weight: 300` (Light) for body copy on white backgrounds—it fails contrast legibility on standard screens.
296. **Red Flag**: Using `font-weight: 900` (Black) for body paragraphs—it turns paragraphs into illegible black bricks.
297. **Red Flag**: Setting `letter-spacing: -0.05em` on body text—letters crash into each other and cause eye strain.
298. **Red Flag**: Centering a 12-line "About Us" paragraph—readers lose their place every time their eyes scan back to the left edge.
299. **Red Flag**: Putting a full-stop period at the end of standalone headlines, navigation links, or button labels (unless using a deliberate punchy brutalist tagline style like `"Ship faster. Break nothing."`).
300. **Red Flag**: Inconsistent casing across navigation items (`Home`, `about us`, `PRICING`, `Contact Us`). Pick one rule and enforce it everywhere.
301. **Red Flag**: Using `Lobster`, `Bebas Neue`, `Oswald`, `Raleway`, or `Anton` for long-form body copy.
302. **Red Flag**: Loading 8 separate static Google Font files (`300`, `300i`, `400`, `400i`, `500`, `600`, `700`, `800`) instead of 1–2 variable `.woff2` files, destroying Core Web Vitals (LCP/FCP).
303. **Red Flag**: Forgetting to include italic styles when your copy uses `<em>` or `<i>`, forcing the browser to synthesize ugly slanted faux-italics.
304. **Red Flag**: Using a font whose `€` or `£` symbol is missing, causing the browser to fall back to `Times New Roman` for just the currency symbol next to a geometric sans number (`€` in Times + `99` in Futura!).
305. **Red Flag**: Mixing straight apostrophes (`It's`) and curly apostrophes (`It’s`) on the same page.
306. **Red Flag**: Using `x` instead of the true multiplication sign `×` (`1920 × 1080`, not `1920 x 1080`).
307. **Red Flag**: Using `...` (three separate periods) instead of the true ellipsis character `…` (`U+2026`) or properly spaced ellipsis.
308. **Red Flag**: Leaving orphan numbers or units split across line breaks (`100` on line 1, `km` on line 2)—always bind numbers to units with a non-breaking space (`100&nbsp;km` or `100\u00A0km`).
309. **Red Flag**: Allowing brand names or people's first/last names to split awkwardly across lines in narrow columns—wrap key proper nouns in `whitespace-nowrap`.
310. **Red Flag**: Using `text-transform: uppercase` in HTML/CSS on words like `"straße"` where German `ß` turns into `SS` or `ẞ` unexpectedly—always test localization casing!
311. **Red Flag**: Making H2s larger than H1s visually through color or weight even if their pixel size is smaller.
312. **Red Flag**: Having zero visual rhythm—every section has the exact same centered `H2` + centered `P` + 3-column grid structure.
313. **Red Flag**: Using `Courier New` as your monospace font—it looks thin, spidery, and dated compared to `JetBrains Mono`, `Geist Mono`, `IBM Plex Mono`, or `Space Mono`.
314. **Red Flag**: Using `Times New Roman` unironically as a fallback when a serif fails to load—always specify graceful fallbacks (`"Instrument Serif", "Newsreader", Georgia, "Times New Roman", serif`).
315. **Red Flag**: Overusing `drop-shadow` or `text-shadow` on UI text—crisp contrast beats fuzzy shadows every single time.
316. **Troubleshooting "My page looks cheap/template-y"**: Replace your geometric sans headline with an editorial serif (`Instrument Serif`, `Newsreader`, `Fraunces`), warm up your background from `#FFFFFF` to `#FAF8F5`, tighten H1 tracking to `-0.03em`, and add a `11px` uppercase monospace kicker above the H1.
317. **Troubleshooting "My tech/SaaS site looks like every other AI startup"**: Ditch `Inter` + `Space Grotesk`. Switch to `Geist` + `Geist Mono` or `Plus Jakarta Sans` + `IBM Plex Mono`, introduce `1px` structural grid borders, use `tabular-nums` for metrics, and mix an italic serif word into your hero headline.
318. **Troubleshooting "My luxury brand looks like a cheap blog"**: Increase whitespace by 50%, reduce body size to `15px`–`16px` with generous `1.7` line-height, use a high-contrast Didone (`Bodoni Moda` or `Cormorant Garamond`) at massive display sizes (`72px+`), and track out small uppercase labels to `+0.16em`.
319. **Troubleshooting "My text feels hard to read / fatiguing"**: Check measure (shorten to `62ch`), increase line-height (`1.55`), soften pure `#000` text to `#18181B`, and switch from a geometric sans to a humanist sans (`Source Sans 3`, `Plus Jakarta Sans`) or sturdy transitional serif (`Newsreader`, `Lora`).
320. **Troubleshooting "My headings feel floaty and disconnected"**: Tighten `letter-spacing` (`-0.025em`), tighten `line-height` (`1.05`), and cut `margin-bottom` in half while doubling `margin-top`.
321. Always audit licensing before shipping—verify whether a font is **SIL Open Font License (OFL)**, **Apache 2.0**, **MIT**, or **Free for Personal Use Only** (never ship personal-use-only fonts into commercial client codebases!).
322. Keep a curated personal "Type Drawer" of 25–30 battle-tested free commercial fonts across every genre so you never scramble or fall back to AI defaults.
323. Remember: **Typography is 95% of web design** (Oliver Reichenstein). Nail the type, spacing, and hierarchy, and the page looks designed before a single image or illustration is added.

## Game Development, HUDs, Diegetic UI & Interactive Worlds

Rules 324-358.

324. **Never use default `Arial`, `Roboto`, or `Inter` in a game HUD**—it immediately breaks immersion and makes a \$60 title feel like an unpolished Unity/Unreal prototype.
325. **Separate Display Lore from Functional HUD**: use an atmospheric, world-building typeface for Zone Titles (`"ASHEN CATHEDRAL"`), Boss Banners, and Main Menus, paired with an ultra-legible, high-aperture typeface for Inventory Stats, Tooltips, and Subtitles.
326. **The 10-Foot Console Rule**: players sit 6–10 feet away from living-room TVs; never set essential HUD tooltips, item stats, or dialogue subtitles smaller than `22px`–`28px` at `1080p` (`2.2vh`–`2.6vh`).
327. **The Steam Deck / Handheld Rule**: test all in-game UI at `1280 × 800` on a 7-inch screen; condensed fonts with tight counters (`Bebas Neue`, `Oswald`) turn into unreadable vertical barcodes at handheld sizes.
328. **Always back dynamic HUD text against moving 3D gameplay**—since background luminance changes constantly from snow to dark caves, use subtle dark radial scrims, soft outer glows (`text-shadow: 0 2px 8px rgba(0,0,0,0.85)`), or crisp `1px`–`2px` dark outlines (`paint-order: stroke fill`).
329. **Never rely on pure white (`#FFFFFF`) text with zero backing** over bright skyboxes or snow levels—it becomes 100% invisible.
330. **Enforce `tabular-nums` on every live combat counter**: Health (`HP`), Mana (`MP`), Stamina, Ammo (`30 / 120`), Speedometers (`248 KM/H`), Combo Multipliers (`x14`), and Speedrun Timers (`04:12.89`) must never jitter horizontally as digits update at 60–120 FPS.
331. **Use duplexed / uniwidth fonts for dynamic buttons and skill bars** so cooldown timers (`4.2s` → `4.1s`) or hover states don't cause neighboring inventory slots to shift by 1 pixel.
332. **Pixel Art Fonts Must Render at Integer Multiples**: if a bitmap pixel font is designed on an `8px` or `16px` grid (`Press Start 2P`, `Silkscreen`, `VT323`, `Pixelify Sans`), only render it at `8px`, `16px`, `24px`, `32px`, or `48px`—rendering at `13px` or `19px` causes uneven pixel-stretching ("mixels") and blurry anti-aliasing.
333. **Disable subpixel anti-aliasing (`font-smooth: never; -webkit-font-smoothing: none; image-rendering: pixelated;`)** when rendering crisp 8-bit/16-bit pixel fonts in HTML5/Canvas/WebGL games.
334. **Never set long RPG lore codices or dialogue trees in `Press Start 2P`**—all-caps 8-bit fonts cause rapid eye fatigue after 3 sentences; use a higher-res pixel font (`Silkscreen`, `Pixelify Sans`, `Jacquard 12` / `Tiny5` for headers + `Departure Mono` or `VT323` for body) or a clean low-res humanist font.
335. **Soulslike / Dark Fantasy Typography**: pair classic Roman/Renaissance high-contrast serifs (`Cinzel`, `Cormorant Garamond`, `IM Fell English`, `EB Garamond`) with wide uppercase letter-spacing (`+0.15em` to `+0.25em`) for `"YOU DIED"`, `"AREA DISCOVERED"`, and Boss health bars.
336. **Add subtle horizontal fade/bloom animations** to Dark Fantasy title banners (`letter-spacing` expanding slightly from `+0.15em` to `+0.22em` over 1.2s) rather than bouncy elastic easing.
337. **Sci-Fi / Mecha / Tactical Shooter HUDs**: use squarish, wide-stanced technical sans-serifs (`Chakra Petch`, `Rajdhani`, `Exo 2`, `Orbitron`, `Oxanium`, `Michroma`) paired with crisp monospace telemetry (`JetBrains Mono`, `Share Tech Mono`, `IBM Plex Mono`).
338. **Cyberpunk / Dystopian Street-Tech**: mix hyper-wide extended display fonts (`Syncopate`, `Michroma`, `Syne`) with condensed brutalist industrial tags (`Antonio`, `Barlow Condensed`) and slanted/italic telemetry readouts (`10°–12°` oblique).
339. **Cozy Indie / Farming Sim / Wholesome Adventure**: use warm, rounded, hand-crafted humanist sans-serifs (`Fredoka`, `Quicksand`, `Nunito`, `Patrick Hand`, `Gaegu`) or bouncy soft serifs (`Fraunces` with `SOFT=100`, `Sour Gummy`) on warm parchment/wood-textured dialogue boxes (`#FBF5E8` with `#3B2F2F` dark cocoa ink).
340. **Horror / Psychological Thriller / Found Footage**: use distressed typewriter monospaces (`Special Elite`, `Courier Prime`, `Xanh Mono`), stark clinical grotesks (`Archivo`), or jagged antique serifs (`IM Fell DW Pica`, `Playfair Display` ultra-tight) with sudden scale isolation and generous dark negative space.
341. **Retro Arcade / Fighting Games / Shmups**: use heavy, italicized, forward-leaning display faces (`Russo One`, `Bungee`, `Faster One`, `Black Ops One`, `Kanit` ExtraBold Italic) with hard offset drop shadows (`4px 4px 0px #000`) and thick `paint-order: stroke fill` outlines.
342. **JRPG / Tactical Strategy / Visual Novels**: use high-clarity humanist sans-serifs (`Plus Jakarta Sans`, `Noto Sans`, `M PLUS Rounded 1c`, `Lato`) for rapid dialogue box reading, paired with ornamental serif chapter titles (`Cinzel Decorative`, `Uncial Antiqua`, `Philosopher`).
343. **Grand Strategy / 4X / City Builders / Tycoon Sims**: treat the UI like an interactive financial and cartographic atlas—use crisp tabular grotesks (`IBM Plex Sans`, `Fira Sans`, `Work Sans`) for nested resource tooltips, paired with authoritative historical serifs (`Newsreader`, `Libre Baskerville`) for diplomacy screens and technology trees.
344. **Diegetic UI Integration**: when rendering text on in-world screens, holographic visors, parchment scrolls, or cockpit gauges, match the font's **stroke contrast and glow/bleed** to the physical medium (e.g., phosphor green CRT bloom for 1980s terminals; embossed gold foil on leather grimoires).
345. **Damage Numbers & Floating Combat Text (FCT)**: use heavy, condensed or geometric numerals (`Anton`, `Bungee`, `Chakra Petch` Bold, `Kanit` Black) with crisp dark outlines so critical hits (`9,420!`) read instantaneously in peripheral vision without blocking enemy animations.
346. **Differentiate Critical Hits vs. Normal Hits Typographically**: scale critical damage numbers `1.4x–1.75x` larger, shift weight from `600` to `900`, and add an italic slant or exclamation glyph rather than relying on color change alone.
347. **Dialogue Typewriter Reveal (`char-by-char`)**: pre-calculate line wraps *before* starting the typewriter animation so words don't suddenly jump to the next line mid-word as letters appear!
348. **Dialogue Box Line Limits**: cap RPG dialogue boxes at **2 to 3 lines maximum** (`45ch`–`55ch` per line) so players can absorb an entire speech bubble in a single glance without scrolling fatigue.
349. **Speaker Nameplates**: separate the speaker's name (`"ELDER VANE"`) from the dialogue text using a distinct nameplate tab, contrasting font weight/case (`uppercase`, `+0.08em`), and subtle color accent.
350. **Interactive Keyword Highlighting in Lore Tooltips**: highlight status effects (`[Burn]`, `[Stagger]`, `[Void Essence]`) using bold weight + subtle underline + distinct hue so players can hover/inspect nested mechanics cleanly.
351. **Button Prompts & Glyph Icons (`[E]`, `[SPACE]`, `[A]`, `[✕]`)**: design keycap badges with `1.5px` borders, `tabular-nums`/uppercase centered letters, and cap-height alignment so inline tutorials (`"Press [F] to Interact"`) never disrupt line spacing.
352. **Subtitle & Closed Caption Accessibility Standards**: offer configurable font sizes (`Small / Medium / Large / XL`), optional speaker name prefixes (`[KAI]:`), and an adjustable semi-transparent dark background box (`rgba(10, 10, 12, 0.78)`) behind dialogue subtitles.
353. **Localization Expansion Buffer (`+35%` Width Rule)**: German, Russian, French, and Spanish translations expand English UI button and skill-tree strings by 25%–40%; design all HUD containers with flexible padding rather than fixed-width clipping boxes.
354. **CJK & Global Script Readiness**: if your game ships with Japanese, Korean, or Chinese localization, choose Latin fonts whose x-height and stroke thickness harmonize with `Noto Sans CJK` or `M PLUS` so mixed English/Japanese terms (`"LV. 42 ドラゴン"`) look cohesive.
355. **Signed Distance Field (SDF / MSDF) Rendering**: when exporting fonts for Unity (TextMeshPro), Unreal Engine, Godot, or WebGL shaders, generate high-resolution **MSDF (Multi-channel Signed Distance Field)** atlases so sharp serif corners (`Cinzel`, `Instrument Serif`) don't round off into blurry blobs when scaled up.
356. **Never use thin hairlines (`Didot`, `Bodoni` Light) in 3D/VR HUDs**: chromatic aberration and lens distortion in VR headsets shred thin horizontal serifs; stick to sturdy, medium-to-bold low-contrast sans-serifs (`Plus Jakarta Sans`, `Atkinson Hyperlegible`, `Work Sans`) in VR.
357. **Loading Screen Lore Tips**: set loading screen hints in `18px`–`20px` italic serif or clean humanist sans with a generous `60ch` max-width and a subtle top divider—never cram tiny `11px` text into the corner of a loading screen.
358. **Main Menu Hierarchy**: keep main menu options (`CONTINUE`, `NEW GAME`, `LOAD`, `SETTINGS`, `QUIT`) vertically stacked with generous vertical hit-boxes (`gap: 0.75rem`), clear active-state indicators (diamond glyph `◆`, bracket `[ ]`, or weight/tracking shift), and unmistakable contrast against background key art.
