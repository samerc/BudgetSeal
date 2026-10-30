"""Play Store screenshots: each raw screen (test/store/screenshots.dart) in a
phone on the brand background, with a headline and one line above it.

    python tool/store/frame.py

Reads build/store/raw/*.png, writes docs/store_assets/screenshots/*.png
(1080 x 1920, what Play shows best for phones).
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "build/store/raw"
OUT = ROOT / "docs/store_assets/screenshots"
FONTS = ROOT / "assets/fonts"
NUNITO = ROOT / "tool/store/fonts"

W, H = 1080, 1920
# The app's own colors (lib/shared/theme): its background, ink, the gold
# of the Ready to assign card, and the deep gold of its section titles.
BG = (247, 245, 241)
INK = (26, 21, 8)
GOLD = (227, 173, 69)
DEEP = (138, 94, 15)
SUB = (107, 100, 87)
# The dark-mode shot sits on the app's dark background instead.
NIGHT = (28, 29, 36)
PAPER = (242, 238, 230)
NIGHT_SUB = (170, 165, 155)

# name -> (headline, gold words in it, line under it)
CAPTIONS = {
    "01_home": ("Give every dollar a job", "every dollar",
                "See what's ready to assign at a glance"),
    "02_budget": ("Envelopes that fill up", "fill up",
                  "Fund each one and earn the seal when it's done"),
    "03_activity": ("Every penny in one place", "one place",
                    "Search, filter and edit in a tap"),
    "04_envelope": ("Save for what matters", "what matters",
                    "Goals that grow a little every month"),
    "05_reports": ("Reports that make sense", "make sense",
                   "Where your money went, month by month"),
    "06_forecast": ("Safe to spend, till payday", "till payday",
                    "Bills coming up are already counted"),
    "07_bills": ("Never miss a bill", "Never miss",
                 "Subscriptions and bills, all lined up"),
    "08_calendar": ("Your month at a glance", "at a glance",
                    "Every day's spending on one calendar"),
    "09_add": ("Add it in seconds", "in seconds",
               "Amount first, with a calculator built in"),
    "10_splitter": ("Split the bill", "Split",
                    "Scan the receipt, share it out, settle up"),
    "11_home_dark": ("Easy on the eyes", "Easy",
                     "A dark mode made for late-night budgeting"),
}


def font(name, size):
    return ImageFont.truetype(str(name), size)


def background(dark, card_top):
    img = Image.new("RGB", (W, H), NIGHT if dark else BG)
    # A gold card behind the phone, like the app's Ready to assign card.
    ImageDraw.Draw(img).rounded_rectangle(
        (48, card_top, W - 48, H + 200), 56,
        fill=(47, 42, 30) if dark else GOLD)
    return img


def draw_headline(draw, text, gold, y, dark):
    f = font(FONTS / "BricolageGrotesque-ExtraBold.ttf", 92)
    # Wrap to two lines at most, splitting near the middle.
    words = text.split()
    lines = [text]
    if draw.textlength(text, font=f) > W - 140:
        best = min(range(1, len(words)),
                   key=lambda i: abs(len(" ".join(words[:i])) - len(text) / 2))
        lines = [" ".join(words[:best]), " ".join(words[best:])]
    gold_start = text.lower().find(gold.lower())
    gold_end = gold_start + len(gold)
    pos = 0
    for line in lines:
        start = text.find(line, pos)
        pos = start + len(line)
        x = (W - draw.textlength(line, font=f)) / 2
        # Word by word, so the gold words take the accent color.
        offset = 0
        for i, word in enumerate(line.split(" ")):
            idx = line.find(word, offset)
            offset = idx + len(word)
            at = start + idx
            accent = gold_start <= at < gold_end
            color = (GOLD if accent else PAPER) if dark else (
                DEEP if accent else INK)
            piece = word + (" " if i < len(line.split(" ")) - 1 else "")
            draw.text((x, y), piece, font=f, fill=color)
            x += draw.textlength(piece, font=f)
        y += 104
    return y


def status_bar(shot, dark):
    """A phone's status bar in the screen's empty top inset (66 px)."""
    d = ImageDraw.Draw(shot)
    ink = PAPER if dark else INK
    d.text((70, 12), "9:41", font=font(NUNITO / "NunitoSans-700.ttf", 36),
           fill=ink)
    x = shot.width - 70
    # Battery.
    d.rounded_rectangle((x - 50, 22, x, 46), 6, outline=ink, width=3)
    d.rounded_rectangle((x - 45, 27, x - 12, 41), 3, fill=ink)
    d.rectangle((x + 2, 30, x + 5, 38), fill=ink)
    # Signal bars.
    for i in range(4):
        h = 8 + i * 5
        d.rectangle((x - 120 + i * 11, 46 - h, x - 113 + i * 11, 46), fill=ink)
    return shot


def phone(shot):
    """The screen with rounded corners in a thin dark bezel."""
    sw = 820
    scale = sw / shot.width
    screen = shot.resize((sw, int(shot.height * scale)), Image.LANCZOS)
    r = 64
    bezel = 14
    pw, ph = sw + bezel * 2, screen.height + bezel * 2
    body = Image.new("RGBA", (pw, ph), (0, 0, 0, 0))
    ImageDraw.Draw(body).rounded_rectangle(
        (0, 0, pw - 1, ph - 1), r + bezel, fill=INK + (255,),
        outline=(60, 55, 45, 255), width=3)
    mask = Image.new("L", screen.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, screen.width - 1, screen.height - 1), r, fill=255)
    body.paste(screen, (bezel, bezel), mask)
    # Camera hole.
    cx = pw // 2
    ImageDraw.Draw(body).ellipse((cx - 13, bezel + 18, cx + 13, bezel + 44),
                                 fill=(10, 10, 12, 255))
    return body


def frame(name, shot):
    head, gold, sub = CAPTIONS[name]
    dark = name.endswith("_dark")
    # Measure first: the gold card starts partway down the phone.
    y = draw_headline(ImageDraw.Draw(Image.new("RGB", (W, H))),
                      head, gold, 110, dark)
    top = y + 120
    img = background(dark, top + 260)
    draw = ImageDraw.Draw(img)
    draw_headline(draw, head, gold, 110, dark)
    f = font(NUNITO / "NunitoSans-600.ttf", 44)
    draw.text(((W - draw.textlength(sub, font=f)) / 2, y + 18), sub,
              font=f, fill=NIGHT_SUB if dark else SUB)
    body = phone(status_bar(shot, dark))
    # Shadow, then the phone; it runs off the bottom edge.
    shadow = Image.new("L", (W, H), 0)
    x = (W - body.width) // 2
    ImageDraw.Draw(shadow).rounded_rectangle(
        (x + 10, top + 30, x + body.width - 10, top + body.height), 80, fill=150)
    shadow = shadow.filter(ImageFilter.GaussianBlur(40))
    img.paste(Image.new("RGB", (W, H), (60, 40, 5)), mask=shadow)
    img.paste(body, (x, top), body)
    return img


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for path in sorted(RAW.glob("*.png")):
        if path.stem not in CAPTIONS:
            continue
        frame(path.stem, Image.open(path).convert("RGB")).save(
            OUT / f"{path.stem}.png", optimize=True)
        print("framed", path.stem)
    store_icon()
    feature_graphic()


def store_icon():
    """Play's 512 px icon: the app icon, full square (Play rounds it)."""
    Image.open(ROOT / "assets/icon/app_icon.png").convert("RGB").resize(
        (512, 512), Image.LANCZOS).save(ROOT / "docs/store_assets/icon_512.png")


def feature_graphic():
    """Play's 1024 x 500 banner: name and line left, the app right."""
    fw, fh = 1024, 500
    img = Image.new("RGB", (fw, fh), BG)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((600, 70, fw + 60, fh + 60), 48, fill=GOLD)
    icon = Image.open(ROOT / "assets/icon/app_icon.png").convert("RGB").resize(
        (120, 120), Image.LANCZOS)
    mask = Image.new("L", icon.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, 119, 119), 28, fill=255)
    img.paste(icon, (64, 92), mask)
    d.text((64, 232), "BudgetSeal",
           font=font(FONTS / "BricolageGrotesque-ExtraBold.ttf", 76), fill=INK)
    d.text((66, 330), "Give every dollar a job",
           font=font(FONTS / "BricolageGrotesque-Bold.ttf", 40), fill=DEEP)
    d.text((66, 392), "Envelope budgeting · offline · private",
           font=font(NUNITO / "NunitoSans-600.ttf", 28), fill=SUB)
    shot = status_bar(Image.open(RAW / "01_home.png").convert("RGB"), False)
    body = phone(shot).resize((330, int(phone(shot).height * 330 / 848)),
                              Image.LANCZOS)
    img.paste(body, (650, 40), body)
    img.save(ROOT / "docs/store_assets/feature_graphic.png", optimize=True)


if __name__ == "__main__":
    main()
