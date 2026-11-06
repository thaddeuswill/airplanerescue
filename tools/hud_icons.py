# Writes the HUD icon set to textures/hud/*.svg: one dark tile with a brass edge, a glyph on top.
# Godot imports the SVGs directly. Run from the project root, then import.
import os

INK, CREAM, BRASS, MUSTARD, RED = "#1E1B17", "#EEE6CF", "#C8B99A", "#D9A62E", "#A8261F"
LINE = f'fill="none" stroke="{CREAM}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"'
GOLD = f'fill="{MUSTARD}" stroke="{INK}" stroke-width="3" stroke-linejoin="round"'

GLYPHS = {
    "wallet": f'<rect x="26" y="40" width="76" height="52" rx="8" {LINE}/><path d="M26 54h76"  {LINE}/><rect x="74" y="60" width="28" height="18" rx="5" {GOLD}/>',
    "clipboard": f'<rect x="34" y="32" width="60" height="70" rx="6" {LINE}/><rect x="50" y="24" width="28" height="16" rx="4" {GOLD}/><path d="M46 58h36M46 72h36M46 86h22" {LINE}/>',
    "logbook": f'<path d="M34 30h52a8 8 0 0 1 8 8v60H42a8 8 0 0 1-8-8z" {LINE}/><path d="M34 90a8 8 0 0 1 8-8h52" {LINE}/><path d="M56 30v30l10-8 10 8V30" {GOLD}/>',
    "inspect": f'<circle cx="56" cy="56" r="26" {LINE}/><path d="M76 76l24 24" {LINE}/><path d="M48 52a10 10 0 0 1 10-8" fill="none" stroke="{MUSTARD}" stroke-width="6" stroke-linecap="round"/>',
    "wrench": f'<path d="M92 30a22 22 0 0 0-28 28L32 90a9 9 0 0 0 13 13l32-32a22 22 0 0 0 28-28L90 58 76 52l-6-14z" {GOLD}/>',
    "shop": f'<path d="M30 58v42h68V58" {LINE}/><path d="M26 58l8-28h60l8 28z" {GOLD}/><rect x="54" y="72" width="20" height="28" {LINE}/>',
    "radio": f'<rect x="26" y="44" width="76" height="54" rx="8" {LINE}/><path d="M44 44l40-18" {LINE}/><rect x="60" y="56" width="32" height="14" {GOLD}/><circle cx="44" cy="71" r="10" {LINE}/><circle cx="67" cy="85" r="4" fill="{CREAM}"/><circle cx="85" cy="85" r="4" fill="{CREAM}"/>',
    "map": f'<path d="M28 40l24-10 24 10 24-10v58l-24 10-24-10-24 10z" {LINE}/><path d="M52 30v58M76 40v58" {LINE}/><circle cx="64" cy="58" r="8" fill="{RED}" stroke="{INK}" stroke-width="3"/>',
    "toolbox": f'<rect x="26" y="52" width="76" height="46" rx="6" {GOLD}/><path d="M48 52V40a6 6 0 0 1 6-6h20a6 6 0 0 1 6 6v12" {LINE}/><path d="M26 70h76" stroke="{INK}" stroke-width="5"/><rect x="56" y="64" width="16" height="12" fill="{CREAM}" stroke="{INK}" stroke-width="3"/>',
    "parts": f'<path d="M64 26l36 18v40L64 102 28 84V44z" {LINE}/><path d="M28 44l36 18 36-18M64 62v40" {LINE}/><path d="M46 35l36 18" stroke="{MUSTARD}" stroke-width="7"/>',
    "saved": f'<path d="M34 66l20 20 40-46" fill="none" stroke="{MUSTARD}" stroke-width="12" stroke-linecap="round" stroke-linejoin="round"/>',
    "question": f'<circle cx="64" cy="64" r="36" {LINE}/><path d="M52 54a12 12 0 1 1 18 11c-4 3-6 5-6 10" fill="none" stroke="{MUSTARD}" stroke-width="8" stroke-linecap="round"/><circle cx="64" cy="87" r="5" fill="{MUSTARD}"/>',
    "runup": f'<path d="M64 64C50 56 44 38 50 26c8-6 18 0 20 10 2 8-2 20-6 28zM64 64c14 8 20 26 14 38-8 6-18 0-20-10-2-8 2-20 6-28z" {GOLD}/><circle cx="64" cy="64" r="9" fill="{RED}" stroke="{INK}" stroke-width="3"/>',
    "sign": f'<path d="M34 94l6-20 48-48 14 14-48 48z" {GOLD}/><path d="M28 104h72" {LINE}/>',
    "fuel": f'<path d="M36 44l14-14h42v72H36z" {GOLD}/><path d="M44 30h22" {LINE}/><path d="M50 60l26 26M76 60L50 86" stroke="{INK}" stroke-width="6" stroke-linecap="round"/>',
    "hangar": f'<path d="M22 98V76a42 42 0 0 1 84 0v22z" {LINE}/><path d="M46 98V74h36v24" {LINE}/><path d="M64 88V56m-10 10l10-10 10 10" fill="none" stroke="{MUSTARD}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>',
    "fly": f'<path d="M64 24c4 0 6 6 6 14v16l32 18v10l-32-10v18l10 8v6l-16-5-16 5v-6l10-8V72L26 82V72l32-18V38c0-8 2-14 6-14z" {GOLD} transform="rotate(30 64 64)"/>',
}

os.makedirs("textures/hud", exist_ok=True)
for name, glyph in GLYPHS.items():
    with open(f"textures/hud/{name}.svg", "w", encoding="utf-8") as f:
        f.write(f'<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">'
                f'<rect x="4" y="4" width="120" height="120" rx="20" fill="{INK}" fill-opacity="0.9" stroke="{BRASS}" stroke-width="4"/>{glyph}</svg>')
print(len(GLYPHS), "icons")
