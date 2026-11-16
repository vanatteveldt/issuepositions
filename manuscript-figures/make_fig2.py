"""Redraw Figure 8.2 (AnnoTinder interface mock-up) as greyscale vector SVG.

Units are PostScript points (1/72 in). Figure is 5 in (360 pt) wide.
Text is laid out with real font metrics (Liberation Sans, metric-compatible with Arial).
"""
from PIL import ImageFont
from xml.sax.saxutils import escape
import sys

FONTDIR = "/usr/share/fonts/truetype/liberation/"
FONTS = {
    "r": "LiberationSans-Regular.ttf",
    "b": "LiberationSans-Bold.ttf",
    "i": "LiberationSans-Italic.ttf",
}
_cache = {}


def width(text, style, size):
    key = (style, size)
    if key not in _cache:
        # measure at 100x size for precision
        _cache[key] = ImageFont.truetype(FONTDIR + FONTS[style], int(round(size * 100)))
    return _cache[key].getlength(text) / 100


def wrap(runs, size, maxw):
    """runs: list of (text, style, highlight). Returns lines: list of list of (word, style, hl)."""
    words = []
    for text, style, hl in runs:
        for w in text.split():
            words.append((w, style, hl))
    lines, cur, curw = [], [], 0.0
    for w, s, hl in words:
        ww = width(w, s, size)
        sp = width(" ", "r", size) if cur else 0
        if cur and curw + sp + ww > maxw:
            lines.append(cur)
            cur, curw = [], 0.0
            sp = 0
        cur.append((w, s, hl))
        curw += sp + ww
    if cur:
        lines.append(cur)
    return lines


def line_width(line, size):
    sp = width(" ", "r", size)
    return sum(width(w, s, size) for w, s, _ in line) + sp * (len(line) - 1)


STYLE_ATTR = {"r": "", "b": ' font-weight="bold"', "i": ' font-style="italic"'}


def text_block(out, runs, x, y, maxw, size, lead, align="left", fill="#000", hl_fill=None):
    """Render wrapped text; x is left edge (or centre if align=center). Returns y after block."""
    lines = wrap(runs, size, maxw)
    sp = width(" ", "r", size)
    for line in lines:
        lw = line_width(line, size)
        x0 = x if align == "left" else x - lw / 2
        # highlight boxes behind highlighted word runs
        cx = x0
        for idx, (w, s, hl) in enumerate(line):
            ww = width(w, s, size)
            if hl and hl_fill:
                nxt_hl = idx + 1 < len(line) and line[idx + 1][2]
                bw = ww + (sp if nxt_hl else 0)
                out.append(f'<rect x="{cx - 1.5:.2f}" y="{y - size * 0.82:.2f}" width="{bw + 3:.2f}" '
                           f'height="{size * 1.12:.2f}" rx="2" fill="{hl_fill}"/>')
            cx += ww + sp
        spans = []
        cx = x0
        for w, s, hl in line:
            spans.append(f'<tspan x="{cx:.2f}"{STYLE_ATTR[s]}>{escape(w)}</tspan>')
            cx += width(w, s, size) + sp
        out.append(f'<text y="{y:.2f}" font-size="{size}" fill="{fill}">{"".join(spans)}</text>')
        y += lead
    return y


def hamburger(out, x, y):
    for k in range(3):
        out.append(f'<rect x="{x:.2f}" y="{y + k * 3.2:.2f}" width="10" height="1.4" fill="#000"/>')


# ---------------------------------------------------------------- layout
W, PANEL_W, GAP = 360, 174, 12
PANEL_H = 322
LABEL_Y = PANEL_H + 20 + 16
H = LABEL_Y + 6
PAD = 9
STROKE = 0.75


CH = 20  # browser bar height


def star_path(cx, cy, r_out, r_in):
    import math
    pts = []
    for k in range(10):
        r = r_out if k % 2 == 0 else r_in
        a = -math.pi / 2 + k * math.pi / 5
        pts.append(f"{cx + r * math.cos(a):.2f},{cy + r * math.sin(a):.2f}")
    return "M " + " L ".join(pts) + " Z"


def browser_frame(out, x0):
    """Phone/browser frame with a dark Chrome-style address bar; content goes below y=CH."""
    W_, H_ = PANEL_W, PANEL_H + CH
    out.append(f'<g transform="translate({x0},0)">')
    out.append(f'<rect x="{STROKE/2}" y="{STROKE/2}" width="{W_ - STROKE}" height="{H_ - STROKE}" '
               f'rx="6" fill="#fff"/>')
    # dark bar with rounded top corners
    out.append(f'<path d="M 0 {CH} V 6 Q 0 0 6 0 H {W_ - 6} Q {W_} 0 {W_} 6 V {CH} Z" fill="#404040"/>')
    wl0 = 'stroke="#fff" fill="none" stroke-linecap="round" stroke-linejoin="round"'
    wl = wl0 + ' stroke-width="1.1"'
    c = CH / 2
    # back / forward arrows
    out.append(f'<path d="M 13 {c} H 6 M 9 {c - 3} L 6 {c} L 9 {c + 3}" {wl}/>')
    out.append(f'<path d="M 18 {c} H 25 M 22 {c - 3} L 25 {c} L 22 {c + 3}" {wl}/>')
    # reload: open circle with arrow head
    out.append(f'<path d="M 37.2 {c - 2} A 3.6 3.6 0 1 0 37.6 {c + 1.2}" {wl}/>')
    out.append(f'<path d="M 37.6 {c - 4.6} L 37.4 {c - 1.8} L 34.7 {c - 2.3}" {wl}/>')
    # address field: padlock + blurred (redacted) URL
    px0, px1 = 44, W_ - 36
    out.append(f'<rect x="{px0}" y="{c - 6}" width="{px1 - px0}" height="12" rx="6" fill="#fff"/>')
    out.append(f'<rect x="{px0 + 5}" y="{c - 0.6}" width="5" height="4" rx="0.6" fill="#000"/>')
    out.append(f'<path d="M {px0 + 6.1} {c - 0.6} V {c - 2.2} A 1.4 1.4 0 0 1 {px0 + 8.9} {c - 2.2} V {c - 0.6}" '
               f'stroke="#000" stroke-width="0.8" fill="none"/>')
    out.append(f'<rect x="{px0 + 14}" y="{c - 2}" width="{px1 - px0 - 20}" height="4" rx="2" fill="#bfbfbf"/>')
    # star, tab switcher, kebab menu
    out.append(f'<path d="{star_path(W_ - 28, c + 0.3, 3.8, 1.6)}" {wl0} stroke-width="0.9"/>')
    out.append(f'<rect x="{W_ - 20}" y="{c - 3.5}" width="7" height="7" rx="1" {wl0} stroke-width="0.9"/>')
    for k in (-3, 0, 3):
        out.append(f'<circle cx="{W_ - 6}" cy="{c + k}" r="0.9" fill="#fff"/>')
    # outer frame stroke last so it sits on top of the bar
    out.append(f'<rect x="{STROKE/2}" y="{STROKE/2}" width="{W_ - STROKE}" height="{H_ - STROKE}" '
               f'rx="6" fill="none" stroke="#000" stroke-width="{STROKE}"/>')
    out.append('</g>')


out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}pt" height="{H}pt" viewBox="0 0 {W} {H}" '
       f'font-family="Liberation Sans, Arial, Helvetica, sans-serif">',
       f'<rect width="{W}" height="{H}" fill="#fff"/>']

# ------------------------------------------------------------- panel (a)
ax = 0
browser_frame(out, ax)
out.append(f'<g transform="translate({ax},{CH})">')
# top bar: back arrow + menu
out.append(f'<path d="M {PAD + 6} 9 L {PAD} 14 L {PAD + 6} 19 Z" fill="#000"/>')
hamburger(out, PANEL_W - PAD - 10, 10.5)
out.append(f'<line x1="0" y1="26" x2="{PANEL_W}" y2="26" stroke="#000" stroke-width="0.5"/>')
# title
y = text_block(out, [("Position Coding on Work & Income", "b", False)], PANEL_W / 2, 48,
               PANEL_W - 2 * PAD - 20, 13, 15.5, align="center")
y += 6
body = [
    ("On the following screens you will each time see three sentences with a marked actor. "
     "The central question is what the actor’s position is on Work & Income. "
     "To determine this, choose between the two dimensions explained below: is the actor in favor of", "r", False),
    ("“more Social security and poverty reduction”,", "i", False),
    ("or rather", "r", False),
    ("“more Tax cuts & Entrepreneurs”?", "i", False),
    ("If the actor is explicitly against “Social security and poverty reduction”, choose", "r", False),
    ("“Tax cuts & Entrepreneurs”,", "i", False),
    ("and vice versa.", "r", False),
]
y = text_block(out, body, PAD, y, PANEL_W - 2 * PAD, 8.5, 11.5)
y += 5
y = text_block(out, [("You may interpret this broadly: it’s about the general political direction, "
                      "not the exact wording.", "r", False)], PAD, y, PANEL_W - 2 * PAD, 8.5, 11.5)
a_text_end = y
# continue button
btn_y = PANEL_H - 34
out.append(f'<line x1="0" y1="{btn_y - 8}" x2="{PANEL_W}" y2="{btn_y - 8}" stroke="#000" stroke-width="0.5"/>')
out.append(f'<rect x="{PAD}" y="{btn_y}" width="{PANEL_W - 2 * PAD}" height="22" rx="2.5" fill="#404040"/>')
out.append(f'<text x="{PANEL_W / 2}" y="{btn_y + 14.5}" font-size="9.5" fill="#fff" text-anchor="middle">Continue</text>')
out.append('</g>')

# ------------------------------------------------------------- panel (b)
bx = PANEL_W + GAP
browser_frame(out, bx)
out.append(f'<g transform="translate({bx},{CH})">')
# nav: |< 2 >|  progress bar  menu
out.append(f'<rect x="{PAD}" y="9" width="1.6" height="10" fill="#000"/>')
out.append(f'<path d="M {PAD + 8.5} 9 L {PAD + 2.4} 14 L {PAD + 8.5} 19 Z" fill="#000"/>')
out.append(f'<text x="{PAD + 15}" y="17.2" font-size="8.5" font-weight="bold" text-anchor="middle">2</text>')
out.append(f'<path d="M {PAD + 21} 9 L {PAD + 27} 14 L {PAD + 21} 19 Z" fill="#000"/>')
out.append(f'<rect x="{PAD + 27.6}" y="9" width="1.6" height="10" fill="#000"/>')
pb_x, pb_w = PAD + 35, PANEL_W - PAD - 35 - PAD - 16
out.append(f'<rect x="{pb_x}" y="11.5" width="{pb_w}" height="5" rx="1.5" fill="#bfbfbf"/>')
out.append(f'<rect x="{pb_x}" y="9.5" width="4" height="9" rx="1" fill="#fff" stroke="#000" stroke-width="0.6"/>')
hamburger(out, PANEL_W - PAD - 10, 10.5)
out.append(f'<line x1="0" y1="26" x2="{PANEL_W}" y2="26" stroke="#000" stroke-width="0.5"/>')
# sentence with highlighted actor
sent = [
    ("“No clear choices”", "r", False),
    ("GroenLinks-PvdA leader Timmermans", "b", True),
    ("criticizes the lack of clear choices by NSC. He therefore misses clarity on raising the minimum wage.",
     "r", False),
]
text_block(out, sent, PAD + 2, 80, PANEL_W - 2 * PAD - 4, 10, 14.5, hl_fill="#bfbfbf")
# question band
band_y = PANEL_H - 118
out.append(f'<path d="M 0 {band_y} H {PANEL_W} V {PANEL_H - 6} Q {PANEL_W} {PANEL_H} {PANEL_W - 6} {PANEL_H} '
           f'H 6 Q 0 {PANEL_H} 0 {PANEL_H - 6} Z" fill="#262626"/>')
qy = text_block(out, [("What is the position of the mentioned actor on Work & Income?", "b", False)],
                PANEL_W / 2, band_y + 17, PANEL_W - 2 * PAD, 9, 12, align="center", fill="#fff")
# three answer buttons
BP = 5
bw = (PANEL_W - 2 * BP - 2 * 4) / 3
btn_top, btn_h = qy + 2, PANEL_H - 8 - (qy + 2)
labels = ["Social security and poverty reduction", "None/ Other Neutral", "Tax reduction & Entrepreneurs"]
for k, lab in enumerate(labels):
    x = BP + k * (bw + 4)
    out.append(f'<rect x="{x:.2f}" y="{btn_top:.2f}" width="{bw:.2f}" height="{btn_h:.2f}" rx="2.5" fill="#cccccc"/>')
    lines = wrap([(lab, "r", False)], 8, bw - 3)
    lead = 9.6
    ty = btn_top + btn_h / 2 - (len(lines) - 1) * lead / 2 + 3
    text_block(out, [(lab, "r", False)], x + bw / 2, ty, bw - 3, 8, lead, align="center")
out.append('</g>')

# ------------------------------------------------------------- panel labels
out.append(f'<text x="{PANEL_W / 2}" y="{LABEL_Y}" font-size="9.5" text-anchor="middle">(a)</text>')
out.append(f'<text x="{bx + PANEL_W / 2}" y="{LABEL_Y}" font-size="9.5" text-anchor="middle">(b)</text>')
out.append('</svg>')

open(sys.argv[1], "w").write("\n".join(out))
from PIL import ImageFont as _F
print("Entrepreneurs@8pt=%.1f bw=%.1f" % (width("Entrepreneurs","r",8), bw))
print("panel (a) text ends at y=%.1f, continue-button separator at y=%.1f" % (a_text_end, btn_y - 8))
