#!/usr/bin/env python3
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math
import textwrap

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "media" / "devpost"
W, H = 1500, 1000

COLORS = {
    "ink": (9, 18, 40),
    "muted": (83, 96, 120),
    "teal": (0, 154, 143),
    "mint": (36, 209, 180),
    "blue": (64, 113, 232),
    "gold": (239, 179, 74),
    "red": (222, 76, 76),
    "paper": (247, 250, 252),
    "panel": (255, 255, 255),
    "line": (211, 220, 235),
    "soft": (232, 247, 245),
    "lavender": (241, 244, 255),
    "green": (39, 174, 96),
}


def font(size, bold=False, mono=False):
    candidates = []
    if mono:
        candidates += [
            "/System/Library/Fonts/Menlo.ttc",
            "/System/Library/Fonts/Supplemental/Courier New.ttf",
        ]
    if bold:
        candidates += [
            "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
            "/System/Library/Fonts/Supplemental/Helvetica Bold.ttf",
            "/System/Library/Fonts/SFNS.ttf",
        ]
    candidates += [
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Supplemental/Helvetica.ttf",
        "/System/Library/Fonts/SFNS.ttf",
    ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, size)
        except Exception:
            pass
    return ImageFont.load_default()


F_TITLE = font(68, bold=True)
F_H1 = font(52, bold=True)
F_H2 = font(36, bold=True)
F_H3 = font(28, bold=True)
F_BODY = font(25)
F_SMALL = font(19)
F_MONO = font(22, mono=True)
F_MONO_SMALL = font(18, mono=True)


def gradient_bg(top=(246, 252, 252), bottom=(238, 243, 250)):
    img = Image.new("RGB", (W, H), top)
    px = img.load()
    for y in range(H):
        t = y / (H - 1)
        for x in range(W):
            glow = 0.04 * math.sin((x / W) * math.pi)
            tt = min(1, max(0, t + glow))
            px[x, y] = tuple(int(top[i] * (1 - tt) + bottom[i] * tt) for i in range(3))
    return img.convert("RGBA")


def rounded(draw, box, radius=26, fill=COLORS["panel"], outline=None, width=2):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def shadowed_card(img, box, radius=28, fill=COLORS["panel"], outline=(223, 230, 242)):
    x1, y1, x2, y2 = box
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((x1 + 8, y1 + 12, x2 + 8, y2 + 12), radius=radius, fill=(28, 48, 70, 28))
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    img.alpha_composite(shadow)
    draw = ImageDraw.Draw(img)
    rounded(draw, box, radius, fill, outline)
    return draw


def text(draw, xy, content, font_obj=F_BODY, fill=COLORS["ink"], width=None, spacing=8):
    x, y = xy
    if width:
        avg = max(8, font_obj.size * 0.52)
        chars = max(12, int(width / avg))
        lines = []
        for raw in str(content).split("\n"):
            lines.extend(textwrap.wrap(raw, chars) or [""])
        for line in lines:
            draw.text((x, y), line, font=font_obj, fill=fill)
            y += font_obj.size + spacing
        return y
    draw.text((x, y), content, font=font_obj, fill=fill)
    return y + font_obj.size + spacing


def pill(draw, xy, label, fill, ink=(255, 255, 255), pad_x=18, pad_y=10):
    x, y = xy
    bbox = draw.textbbox((0, 0), label, font=F_SMALL)
    w = bbox[2] - bbox[0] + pad_x * 2
    h = bbox[3] - bbox[1] + pad_y * 2
    draw.rounded_rectangle((x, y, x + w, y + h), radius=h // 2, fill=fill)
    draw.text((x + pad_x, y + pad_y - 1), label, font=F_SMALL, fill=ink)
    return x + w


def arrow(draw, start, end, fill=COLORS["teal"], width=5):
    draw.line((start, end), fill=fill, width=width)
    sx, sy = start
    ex, ey = end
    ang = math.atan2(ey - sy, ex - sx)
    size = 16
    pts = [
        (ex, ey),
        (ex - size * math.cos(ang - 0.45), ey - size * math.sin(ang - 0.45)),
        (ex - size * math.cos(ang + 0.45), ey - size * math.sin(ang + 0.45)),
    ]
    draw.polygon(pts, fill=fill)


def header(draw, title, subtitle):
    text(draw, (78, 62), title, F_TITLE, COLORS["ink"])
    text(draw, (82, 145), subtitle, F_BODY, COLORS["muted"], width=1120)


def node_card(img, box, title, body, accent=COLORS["teal"], icon=None):
    draw = shadowed_card(img, box, radius=24)
    x1, y1, x2, y2 = box
    draw.rounded_rectangle((x1 + 24, y1 + 24, x1 + 76, y1 + 76), radius=18, fill=(*accent, 38))
    if icon:
        draw.text((x1 + 40, y1 + 37), icon, font=F_H3, fill=accent, anchor="mm")
    text(draw, (x1 + 94, y1 + 26), title, F_H3, COLORS["ink"], width=x2 - x1 - 116)
    text(draw, (x1 + 32, y1 + 96), body, F_SMALL, COLORS["muted"], width=x2 - x1 - 64, spacing=6)


def image_cover():
    img = gradient_bg((245, 252, 250), (232, 241, 250))
    draw = ImageDraw.Draw(img)
    header(draw, "AI-Fi Spiral Memory OS", "A Qwen-powered memory agent that turns outcomes into evolving behavior, corrective pressure, and self-improving system DNA.")
    cx, cy = 1060, 520
    for r, col, w in [(265, COLORS["teal"], 5), (210, COLORS["blue"], 3), (150, COLORS["gold"], 4)]:
        draw.arc((cx-r, cy-r, cx+r, cy+r), 20, 340, fill=col, width=w)
    for i in range(14):
        a = i * 0.62
        rr = 18 + i * 17
        x = cx + math.cos(a) * rr
        y = cy + math.sin(a) * rr
        draw.ellipse((x-7, y-7, x+7, y+7), fill=COLORS["teal"] if i % 3 else COLORS["gold"])
    shadowed_card(img, (110, 315, 780, 785), radius=34)
    text(draw, (155, 365), "Memory that matures", F_H1, COLORS["ink"], width=540)
    text(draw, (158, 500), "Most agents remember facts. AI-Fi remembers outcomes, then turns them into patterns, anti-patterns, and governed self-improvement.", F_BODY, COLORS["muted"], width=540)
    pill(draw, (158, 662), "Qwen Cloud", COLORS["blue"])
    pill(draw, (330, 662), "Spiral Memory", COLORS["teal"])
    pill(draw, (550, 662), "Outcome Truth", COLORS["gold"], ink=COLORS["ink"])
    return img


def image_architecture():
    img = gradient_bg()
    draw = ImageDraw.Draw(img)
    header(draw, "Architecture", "Qwen Cloud reasons over memory. Outcome labels decide whether experience becomes a pattern, anti-pattern, or system DNA candidate.")
    cards = [
        ((80, 300, 360, 500), "Event", "User action, sensor input, or external result enters the agent loop.", COLORS["blue"]),
        ((430, 300, 730, 500), "Qwen Cloud", "Reasoning layer creates reflections, repair plans, and memory labels.", COLORS["teal"]),
        ((800, 300, 1110, 500), "Spiral Memory", "Persistent traces become crystals, warnings, or pattern candidates.", COLORS["gold"]),
        ((1135, 610, 1425, 820), "Validator", "Generated modules are checked before activation.", COLORS["blue"]),
        ((760, 630, 1060, 840), "Outcome Truth", "External results update memory and authority.", COLORS["red"]),
        ((410, 630, 710, 840), "System DNA", "Only repeated positive outcomes can crystallize into durable behavior.", COLORS["teal"]),
        ((80, 630, 360, 840), "Swift + API", "Inspectable demo surface for judges.", COLORS["gold"]),
    ]
    centers = {}
    for box, title, body, color in cards:
        x1, y1, x2, y2 = box
        centers[title] = ((x1+x2)//2, (y1+y2)//2)
    # Draw flow lines first so cards remain readable.
    flow = [
        ("Event", "Qwen Cloud"),
        ("Qwen Cloud", "Spiral Memory"),
        ("Spiral Memory", "Validator"),
        ("Validator", "Outcome Truth"),
        ("Outcome Truth", "System DNA"),
        ("System DNA", "Swift + API"),
        ("Swift + API", "Event"),
    ]
    for a, b in flow:
        s, e = centers[a], centers[b]
        arrow(draw, s, e, COLORS["teal"], 4)
    for box, title, body, color in cards:
        node_card(img, box, title, body, color)
    return img


def image_loop():
    img = gradient_bg((250, 252, 255), (233, 247, 245))
    draw = ImageDraw.Draw(img)
    header(draw, "Spiral Memory Loop", "The breakthrough piece: experience is not only stored. It becomes behavioral pressure.")
    cx, cy = 750, 555
    labels = [
        ("Experience", "raw event"),
        ("Memory Crystal", "high-salience trace"),
        ("Qwen Reflection", "structured meaning"),
        ("Pattern", "positive candidate"),
        ("Anti-pattern", "repair pressure"),
        ("Outcome Label", "truth update"),
    ]
    positions = []
    for i, (title, sub) in enumerate(labels):
        a = -math.pi / 2 + i * (2 * math.pi / len(labels))
        x = cx + math.cos(a) * 430
        y = cy + math.sin(a) * 285
        positions.append((x, y))
    for i in range(len(positions)):
        arrow(draw, positions[i], positions[(i + 1) % len(positions)], COLORS["line"], 5)
    for (x, y), (title, sub) in zip(positions, labels):
        box = (int(x - 150), int(y - 68), int(x + 150), int(y + 68))
        node_card(img, box, title, sub, COLORS["teal"] if title != "Anti-pattern" else COLORS["red"])
    draw.ellipse((cx-142, cy-142, cx+142, cy+142), fill=(255,255,255,225), outline=COLORS["line"], width=3)
    text(draw, (cx-98, cy-58), "remember", F_H3, COLORS["ink"])
    text(draw, (cx-86, cy-20), "reason", F_H3, COLORS["teal"])
    text(draw, (cx-58, cy+18), "adapt", F_H3, COLORS["gold"])
    return img


def image_qwen():
    img = gradient_bg((244, 249, 255), (238, 252, 250))
    draw = ImageDraw.Draw(img)
    header(draw, "Qwen Cloud Integration", "The backend calls Qwen through Alibaba Cloud's OpenAI-compatible API and falls back safely for offline judging.")
    shadowed_card(img, (85, 260, 690, 835), radius=28)
    text(draw, (130, 315), "Backend health", F_H2, COLORS["ink"])
    code = '{\n  \"ok\": true,\n  \"message\": \"spiral_memory_backend_live\",\n  \"llm\": {\n    \"provider\": \"qwen_cloud\",\n    \"enabled\": true,\n    \"model\": \"qwen3.5-flash\"\n  }\n}'
    text(draw, (130, 390), code, F_MONO, COLORS["ink"], spacing=7)
    shadowed_card(img, (785, 260, 1415, 835), radius=28)
    text(draw, (830, 315), "Code path", F_H2, COLORS["ink"])
    code2 = "backend/qwen-cloud-client.cjs\n\nDASHSCOPE_API_KEY=...\nAIFI_QWEN_MODEL=qwen3.5-flash\nAIFI_QWEN_CHAT_URL=https://dashscope-us.aliyuncs.com/compatible-mode/v1/chat/completions"
    text(draw, (830, 390), code2, F_MONO_SMALL, COLORS["ink"], width=510, spacing=9)
    pill(draw, (830, 700), "Verified qwen_cloud", COLORS["green"])
    return img


def image_antipattern():
    img = gradient_bg((252, 249, 247), (240, 247, 252))
    draw = ImageDraw.Draw(img)
    header(draw, "Failure Becomes Repair Pressure", "AI-Fi does not hide negative outcomes. It turns them into anti-pattern memory that changes future behavior.")
    boxes = [
        ((100, 310, 410, 530), "Negative event", "The agent repeats a mistake or receives a bad outcome.", COLORS["red"]),
        ((470, 310, 800, 530), "Anti-pattern", "Spiral memory labels the trigger and stores a repair trace.", COLORS["gold"]),
        ((860, 310, 1215, 530), "Corrective pressure", "Future behavior gets slower, stricter, or more careful.", COLORS["teal"]),
        ((555, 635, 990, 825), "Updated behavior", "The system changes future behavior without pretending the failure succeeded.", COLORS["blue"]),
    ]
    centers = []
    for box, title, body, color in boxes:
        x1, y1, x2, y2 = box
        centers.append(((x1+x2)//2, (y1+y2)//2))
    # Lines are drawn below cards to keep every label readable.
    arrow(draw, centers[0], centers[1], COLORS["red"], 5)
    arrow(draw, centers[1], centers[2], COLORS["gold"], 5)
    arrow(draw, centers[2], centers[3], COLORS["teal"], 5)
    arrow(draw, centers[3], centers[0], COLORS["blue"], 4)
    for box, title, body, color in boxes:
        node_card(img, box, title, body, color)
    shadowed_card(img, (95, 860, 1240, 940), radius=20)
    text(draw, (130, 882), "Example pressure:", F_H3, COLORS["ink"])
    text(draw, (425, 884), "slow_down | repair_trust | avoid_repeat_trigger", F_MONO, COLORS["muted"])
    return img


def image_governance():
    img = gradient_bg()
    draw = ImageDraw.Draw(img)
    header(draw, "Self-Improvement With Guardrails", "Qwen can propose. The validator, canary stage, and outcome labels decide what survives.")
    steps = [
        ("Proposal", "Qwen suggests a memory action or module."),
        ("Finance boundary", "Forbidden capabilities are blocked."),
        ("Validator", "Permissions and shape are checked."),
        ("Canary", "Runs in test stage only."),
        ("Outcome truth", "Positive labels expand; negative labels roll back."),
    ]
    x = 90
    centers = []
    for i, (title, body) in enumerate(steps):
        box = (x + i * 280, 360, x + i * 280 + 235, 610)
        x1, y1, x2, y2 = box
        centers.append(((x1+x2)//2, (y1+y2)//2))
    for i in range(len(centers) - 1):
        arrow(draw, centers[i], centers[i+1], COLORS["teal"], 4)
    for i, (title, body) in enumerate(steps):
        box = (x + i * 280, 360, x + i * 280 + 235, 610)
        node_card(img, box, title, body, [COLORS["blue"], COLORS["red"], COLORS["teal"], COLORS["gold"], COLORS["green"]][i])
    shadowed_card(img, (260, 730, 1240, 875), radius=24)
    next_y = text(draw, (305, 765), "Rule: generated modules never get direct authority just because they sound smart.", F_H3, COLORS["ink"], width=900, spacing=4)
    text(draw, (305, next_y + 8), "They earn authority through validation and outcome labels.", F_BODY, COLORS["muted"])
    return img


def image_video_storyboard():
    img = gradient_bg((250, 252, 249), (239, 245, 253))
    draw = ImageDraw.Draw(img)
    header(draw, "3-Minute Demo Story", "A simple recording path: problem, memory, Qwen, anti-pattern, governance, deployment proof.")
    rows = [
        ("0:00", "Hook", "Most agents remember facts. AI-Fi remembers outcomes."),
        ("0:25", "State", "Show health endpoint and memory state."),
        ("0:55", "Event", "Trigger a negative experience."),
        ("1:25", "Qwen", "Generate a spiral memory event with Qwen Cloud."),
        ("1:55", "Govern", "Show module validation and rollback safety."),
        ("2:25", "Proof", "Show repo, architecture, and Alibaba deployment proof."),
    ]
    y = 275
    for t, title, body in rows:
        shadowed_card(img, (95, y, 1405, y + 92), radius=20)
        pill(draw, (130, y + 25), t, COLORS["blue"])
        text(draw, (260, y + 23), title, F_H3, COLORS["ink"])
        text(draw, (460, y + 25), body, F_BODY, COLORS["muted"], width=810)
        y += 105
    return img


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    images = [
        ("01-cover.png", image_cover()),
        ("02-architecture.png", image_architecture()),
        ("03-spiral-memory-loop.png", image_loop()),
        ("04-qwen-cloud-integration.png", image_qwen()),
        ("05-antipattern-repair.png", image_antipattern()),
        ("06-governed-self-improvement.png", image_governance()),
        ("07-video-storyboard.png", image_video_storyboard()),
    ]
    for name, img in images:
        path = OUT / name
        img.convert("RGB").save(path, "PNG", optimize=True)
        print(path)

    thumb_w, thumb_h = 500, 333
    label_h = 42
    sheet = Image.new("RGB", (thumb_w * 3, (thumb_h + label_h) * 3), (244, 248, 252))
    sheet_draw = ImageDraw.Draw(sheet)
    for idx, (name, img) in enumerate(images):
        col = idx % 3
        row = idx // 3
        x = col * thumb_w
        y = row * (thumb_h + label_h)
        sheet_draw.text((x + 12, y + 10), name, font=F_SMALL, fill=COLORS["ink"])
        thumb = img.convert("RGB").resize((thumb_w, thumb_h), Image.LANCZOS)
        sheet.paste(thumb, (x, y + label_h))
    contact_path = OUT / "00-contact-sheet.png"
    sheet.save(contact_path, "PNG", optimize=True)
    print(contact_path)


if __name__ == "__main__":
    main()
