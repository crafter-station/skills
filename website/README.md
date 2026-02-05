# skills.crafter.run

Curated agent skills for Claude Code, Cursor, Copilot, and 10+ more agents.

## Development

```bash
# Install dependencies
bun install

# Run dev server
bun dev

# Build for production
bun build

# Start production server
bun start
```

## Tech Stack

- **Framework**: Next.js 16 (App Router)
- **Runtime**: Bun
- **Styling**: Tailwind CSS
- **Linting**: Biome
- **Fonts**: Geist Sans & Mono

## Project Structure

```
website/
├── app/                 # Next.js App Router
│   ├── layout.tsx      # Root layout
│   ├── page.tsx        # Homepage
│   ├── skills/         # Skills pages
│   │   ├── page.tsx    # Skills list
│   │   └── [slug]/     # Skill details
│   └── about/          # About page
├── components/          # React components
├── lib/                # Utilities and data
│   └── skills.ts       # Skills data
└── public/             # Static assets
```

## Adding Skills

Edit `lib/skills.ts` to add new curated skills:

```typescript
{
  slug: "skill-name",
  name: "skill-name",
  description: "Description of what the skill does",
  category: "category-name",
  author: "Author Name",
  repository: "https://github.com/...",
  installCommand: "npx skills add ...",
  compatibility: ["Claude Code", "Cursor", "..."],
  tags: ["tag1", "tag2"],
  featured: false,
}
```

## Deploy

This site is designed to be deployed to Vercel:

```bash
vercel --prod
```

## License

MIT
