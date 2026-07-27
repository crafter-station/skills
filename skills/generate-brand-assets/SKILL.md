---
name: generate-brand-assets
version: 1.0.0
description: |
  Generate OG images and favicon based on project branding. Use when: (1) user needs
  social media preview images for their project, (2) user wants to generate a favicon,
  (3) user is setting up branding assets for a website or app, (4) user has brand colors
  and wants professional-looking Open Graph images. Automatically generates correctly
  sized images optimized for social platforms (Twitter, LinkedIn, Facebook) and favicon
  formats.
---

# generate-brand-assets

Generate branded OG (Open Graph) images and favicons for your project based on brand colors and identity.

## Prerequisites

Check if you have the necessary tools:

```bash
node --version  # Node.js 16+
```

The skill uses built-in image generation capabilities. No additional dependencies required beyond Node.js.

## What It Generates

- **OG Images**: 1200×630px preview images for social media sharing (Twitter, LinkedIn, Facebook)
- **Favicon**: Multiple formats (16×16, 32×32, 64×64, 192×192, 512×512) and iOS touch icons
- **Manifest Icons**: Web app manifest-compatible icons
- **Optimized**: WebP, PNG, and ICO formats for maximum compatibility

## Workflow

### 1. Identify Brand Colors

Ask the user for their brand colors. Typical palette includes:
- Primary color (hex: `#RRGGBB`)
- Accent color (optional)
- Text color (typically `#000000` or `#FFFFFF` for contrast)
- Background patterns (optional)

### 2. Gather Project Details

Collect information for the OG images:
- Project name
- Tagline or description (1-2 lines)
- Logo path or text-based logo preference

### 3. Generate Assets

Command structure:

```bash
npx generate-brand-assets \
  --name "Your Project Name" \
  --tagline "Brief project description" \
  --primary-color "#3B82F6" \
  --accent-color "#1E40AF" \
  --output-dir ./public/brand-assets
```

### 4. Customization Options

| Option | Example | Purpose |
|--------|---------|---------|
| `--name` | "My Project" | Project name for OG images |
| `--tagline` | "Build faster" | Subtitle/description on images |
| `--primary-color` | "#3B82F6" | Main brand color |
| `--accent-color` | "#1E40AF" | Secondary brand color |
| `--text-color` | "#FFFFFF" | Text contrast color |
| `--logo-path` | "./logo.png" | Custom logo file |
| `--pattern` | "dots" \| "grid" | Background pattern style |
| `--output-dir` | "./public" | Where to save generated assets |
| `--format` | "png,webp,ico" | Image formats to generate |

### 5. Integration

**For Next.js/React projects:**

```jsx
// next.config.js or next-seo.config.js
{
  openGraph: {
    images: [
      {
        url: '/brand-assets/og-image.png',
        width: 1200,
        height: 630,
      }
    ]
  },
  icons: {
    icon: '/brand-assets/favicon.ico',
    apple: '/brand-assets/apple-touch-icon.png'
  }
}
```

**For HTML projects:**

```html
<!-- index.html -->
<meta property="og:image" content="/brand-assets/og-image.png" />
<meta property="og:image:width" content="1200" />
<meta property="og:image:height" content="630" />
<link rel="icon" href="/brand-assets/favicon.ico" />
<link rel="apple-touch-icon" href="/brand-assets/apple-touch-icon.png" />
```

### 6. Verification

Test generated images:

```bash
# Check file sizes and formats
ls -lh ./public/brand-assets/

# Preview in browser
open ./public/brand-assets/og-image.png
```

Test social preview:
- Use [Twitter Card Validator](https://cards-dev.twitter.com/validator)
- Use [Facebook Sharing Debugger](https://developers.facebook.com/tools/debug/sharing)
- Use [LinkedIn Post Inspector](https://www.linkedin.com/post-inspector/)

### 7. Report Results

Provide the user with:
- List of generated files with dimensions
- Output directory path
- Integration instructions for their framework
- Preview links if hosting is set up

## Common Patterns

### Gradient Backgrounds

```bash
npx generate-brand-assets \
  --name "My App" \
  --gradient "from-#3B82F6 to-#1E40AF" \
  --text-color "#FFFFFF"
```

### Dark Mode Support

Generate both light and dark variants:

```bash
# Light version
npx generate-brand-assets --theme light --primary-color "#3B82F6"

# Dark version
npx generate-brand-assets --theme dark --primary-color "#60A5FA"
```

### Multiple Locale Variants

For multi-language projects:

```bash
npx generate-brand-assets \
  --name "My Project" \
  --locale es \
  --tagline "Construir más rápido"
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Colors look wrong | Verify hex format is exactly `#RRGGBB` (6 chars) |
| Text not readable | Ensure sufficient contrast; `text-color` should differ from background by >50% brightness |
| Images too large | Use `--optimize` flag to reduce file size (trades some quality) |
| Favicon not showing | Clear browser cache and hard-refresh (Cmd+Shift+R / Ctrl+Shift+F5) |
| Output directory error | Ensure output directory exists or use `--create-dirs` flag |

## Next Steps

After generating assets:
1. Commit generated files to version control
2. Update social media preview URLs in deployment
3. Test social sharing on each platform (links may cache old images)
4. Monitor OG image performance in analytics
