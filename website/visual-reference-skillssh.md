# Visual Style Reference: skills.sh

## 1. Core Aesthetic

**Terminal-First Developer Aesthetic**

Design philosophy: Pure black terminal environment meets modern minimalism—raw, unpolished, and developer-focused with zero decoration.

Key influences:
- **Terminal/CLI interfaces** - Pure black background, monospace typography
- **Hacker/Matrix aesthetic** - Minimalist, text-focused, command-line driven
- **Linear app** - Clean table layouts, subtle borders, organized data presentation
- **Brutalist web design** - No gradients, no shadows, stark contrast

---

## 2. Color Palette

| Color | Hex | Usage |
|-------|-----|-------|
| **Pure Black** | `#000000` | Background (dominant, 95% of screen) |
| **White** | `#FFFFFF` | Primary text, skill names, headlines |
| **Medium Gray** | `#808080` / `#999999` | Secondary text, metadata, repo paths |
| **Dark Gray** | `#1A1A1A` / `#0A0A0A` | Input backgrounds, subtle panels |
| **Border Gray** | `#333333` | Table borders, dividers (1px lines) |

**Total colors: 5** (minimal, terminal-inspired)

**Key contrasts:**
- Pure black (#000) vs Pure white (#FFF) - maximum contrast
- No mid-tones except functional grays
- Zero color accents (no blues, greens, or brand colors)

---

## 3. Typography System

### Headline Treatment
- **Font Family**: Monospace (likely "Space Mono", "JetBrains Mono", or system monospace)
- **Weight**: Regular/Medium (400-500)
- **Scale**: Large display size for "SKILLS" logo (96px+ equivalent)
- **Style**: ALL CAPS for emphasis, blocky pixel-style rendering

### Body Text
- **Primary**: Sans-serif for descriptions (likely Inter or system-ui)
- **Weight**: Regular (400) for body, Medium (500) for skill names
- **Code/Commands**: Monospace with `$` prefix for terminal commands
- **Secondary**: Gray text (#808080) for metadata/paths

### Hierarchy
1. **Giant display mono**: "SKILLS" logo
2. **Large sans body**: Hero description text
3. **Medium sans**: Skill names in table
4. **Small mono**: Repo paths, install commands
5. **Tiny sans**: Tab labels, counts

### Special Considerations
- Monospace used for brand identity, not just code
- Mix of mono (brand/commands) + sans (readability)
- No italics, no decorative fonts
- Lowercase preferred except for emphasis

---

## 4. Key Design Elements

### Layout Structure
- **Full-width black canvas** - No containers, edge-to-edge design
- **Centered content column** - ~1200px max width for text
- **Table-based leaderboard** - Clean rows with subtle borders
- **Minimal padding** - Tight spacing, information-dense

### Graphic Elements
- **Pixel-style logo** - Blocky, retro gaming aesthetic
- **Icon row** - Grayscale agent logos (GitHub, Discord, etc.)
- **Search bar** - Dark input with subtle border
- **Tabs** - Underline-style active states
- **Copy button** - Icon-only, minimal chrome

### Textures & Treatments
- **Zero gradients** - Pure flat colors only
- **Zero shadows** - No depth simulation
- **1px borders** - Hairline dividers (#333)
- **No rounded corners** - Sharp, terminal aesthetic
- **No hover effects** (likely) - Static, non-interactive feel

### Data Presentation
- **Tabular layout** - Rank | Skill Name | Repo | Installs
- **Right-aligned numbers** - Install counts with decimal precision
- **Monospace metrics** - Numbers in mono for alignment
- **Minimal column spacing** - Dense, terminal-like

---

## 5. Visual Concept

### Conceptual Bridge
The design bridges **raw terminal interfaces** with **modern web data tables**, creating a "developer-native" aesthetic that feels like reading `ls -la` output but with web polish.

### Element Relationships
- **Logo (pixel mono)** → Retro hacker vibes
- **Description (sans serif)** → Modern, readable
- **Command (mono + dark bg)** → Direct terminal reference
- **Table (structured data)** → Professional, organized
- **Icons (grayscale)** → Tool compatibility without color distraction

### Tension Points
- **Old (terminal) vs New (web)** - Resolved by keeping both pure
- **Decorative (pixel logo) vs Functional (table)** - Logo is only ornament
- **Dense (lots of data) vs Clean (minimal UI)** - Achieved through strict hierarchy

### Ideal Use Cases
- **Developer tools** - CLI utilities, APIs, SDKs
- **Data-heavy dashboards** - Leaderboards, analytics
- **Technical documentation** - When you want zero distraction
- **Hacker/maker projects** - DIY, underground, anti-corporate vibes

### What Makes It Distinctive
1. **Pure black** - Not dark gray, not near-black, PURE black
2. **No decorative elements** - Only the logo has personality
3. **Terminal DNA** - Feels like SSH'ing into a server
4. **Anti-design design** - Intentionally unpolished
5. **Monospace brand identity** - Not just for code blocks

---

## Technical Specifications

### Fonts (estimated)
```css
--font-display: "Space Mono", "JetBrains Mono", monospace;
--font-body: "Inter", -apple-system, system-ui, sans-serif;
--font-code: "SF Mono", "Consolas", monospace;
```

### Colors (exact)
```css
--black: #000000;
--white: #FFFFFF;
--gray-50: #808080;
--gray-90: #1A1A1A;
--border: #333333;
```

### Spacing (estimated)
```css
--space-xs: 8px;
--space-sm: 16px;
--space-md: 24px;
--space-lg: 48px;
--space-xl: 96px;
```

---

## Implementation Notes

**DO:**
- Use pure #000 background
- Mix monospace (brand) + sans (content)
- Keep borders to 1px max
- Use table layouts for data
- Maintain maximum contrast

**DON'T:**
- Add gradients or shadows
- Use colored accents (stay grayscale)
- Round corners
- Add decorative elements
- Use light gray on black (use white or medium gray)

**Key Differentiator from Generic Dark Mode:**
This isn't "dark mode" - it's "terminal mode". The difference is philosophical: dark mode softens edges, adds depth, uses near-black. Terminal mode is harsh, flat, pure black.
