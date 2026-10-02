# App icon source

`app_icon.svg` is the master artwork (100×100 viewBox): an envelope holding two
gold notes, closed with the gold "funded" wax seal, on night `#1C1D24`.
Brand colors: gold `#E3AD45`, pale gold `#F1D594`, paper `#F2EEE6` / `#CFC7B8`,
ink `#1A1508`.

The `rx="CORNER"` placeholder on the clip rect is replaced per export.

| File | Export |
|---|---|
| `../app_icon.png` | 1024 px, `rx="0"`, opaque — iOS, legacy Android, About/Upgrade screens |
| `../app_icon_foreground.png` | 1024 px, `rx="0"`, `#bg` rect removed (transparent) — Android adaptive foreground |
| `../splash_logo.png` | 576 px, `rx="22.5"` (rounded tile) — Flutter splash; also resized to `android/.../drawable-*/splash_logo.png` (144/216/288/432/576) and `ios/.../LaunchImage.imageset` (144/288/432) |

Any SVG renderer works (headless Chrome/Edge screenshot with a transparent
background was used). Then run `dart run flutter_launcher_icons` — the adaptive
icon uses background `#1C1D24` and a 22% foreground inset so the envelope stays
inside every launcher mask.
