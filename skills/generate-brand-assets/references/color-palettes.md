# Brand Color Palettes

Reference palettes for quick brand asset generation.

## Tech Companies

### Slack-inspired
- Primary: `#611F69` (Deep Purple)
- Accent: `#E01E5A` (Coral)
- Text: `#FFFFFF`

### Discord-inspired
- Primary: `#5865F2` (Blurple)
- Accent: `#57F287` (Green)
- Text: `#FFFFFF`

### Vercel-inspired
- Primary: `#000000` (Black)
- Accent: `#FFFFFF` (White)
- Text: `#FFFFFF`

### Stripe-inspired
- Primary: `#635BFF` (Iris Blue)
- Accent: `#D0D4FF` (Lavender)
- Text: `#FFFFFF`

## Modern Startups

### Warm & Energetic
- Primary: `#FF6B35` (Coral)
- Accent: `#FFA500` (Orange)
- Text: `#FFFFFF` or `#2D3436`

### Cool & Professional
- Primary: `#0066CC` (Cobalt)
- Accent: `#00B4D8` (Sky Blue)
- Text: `#FFFFFF`

### Vibrant & Bold
- Primary: `#7928CA` (Purple)
- Accent: `#FF0080` (Pink)
- Text: `#FFFFFF`

## Nature & Wellness

### Forest Theme
- Primary: `#2D6A4F` (Hunter Green)
- Accent: `#52B788` (Sage)
- Text: `#FFFFFF`

### Ocean Theme
- Primary: `#0077B6` (Deep Blue)
- Accent: `#00B4D8` (Aqua)
- Text: `#FFFFFF`

## Gradients

### Sunset
```
from: #FF6B6B (Red)
to: #FFA500 (Orange)
text: #FFFFFF
```

### Ocean
```
from: #0077B6 (Blue)
to: #00B4D8 (Cyan)
text: #FFFFFF
```

### Forest
```
from: #2D6A4F (Green)
to: #52B788 (Light Green)
text: #FFFFFF
```

### Twilight
```
from: #5865F2 (Blue)
to: #7928CA (Purple)
text: #FFFFFF
```

## Accessibility Tips

- Ensure contrast ratio ≥ 4.5:1 for text on background
- Test with color-blind simulators
- Avoid red/green combinations that may be hard to distinguish
- Use [Contrast Checker](https://webaim.org/resources/contrastchecker/) to validate

## Usage

Reference palette name in command:

```bash
npx generate-brand-assets \
  --name "My Project" \
  --palette slack-inspired
```

Or specify colors individually:

```bash
npx generate-brand-assets \
  --name "My Project" \
  --primary-color "#0077B6" \
  --accent-color "#00B4D8" \
  --text-color "#FFFFFF"
```
