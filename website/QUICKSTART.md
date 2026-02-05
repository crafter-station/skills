# Quick Start Guide

## 🚀 Run Locally (1 minute)

```bash
cd ~/Programming/crafter-station/skills/website
bun install
bun dev
```

Open http://localhost:3000

## 📁 What You Have

### Pages Built
- `/` - Homepage with hero and featured skill
- `/skills` - Browse all skills (grid view)
- `/skills/intent-layer` - Skill detail page
- `/about` - About the project
- `/404` - Custom 404 page

### Current Content
- **1 skill**: intent-layer (context-engineering)
- **Featured**: Yes, on homepage
- **Style**: Dark Vercel/Linear aesthetic
- **Responsive**: Mobile to desktop

## ✅ Test Checklist

Before deploying:

1. **Dev Server**
   ```bash
   bun dev
   # Visit each page
   # - http://localhost:3000/
   # - http://localhost:3000/skills
   # - http://localhost:3000/skills/intent-layer
   # - http://localhost:3000/about
   ```

2. **Production Build**
   ```bash
   bun build
   bun start
   # Test on http://localhost:3000
   ```

3. **Mobile Check**
   - Open DevTools
   - Toggle device toolbar
   - Test on iPhone/Android views

4. **Lighthouse**
   - Right-click → Inspect
   - Lighthouse tab
   - Generate report
   - Should be 90+ on all metrics

## 🎨 Add More Skills

Edit `lib/skills.ts`:

```typescript
export const skills: Skill[] = [
  // ... existing intent-layer skill
  {
    slug: "your-new-skill",
    name: "your-new-skill",
    description: "What this skill does in 1-2 sentences",
    category: "category-name",
    author: "Author Name",
    repository: "https://github.com/author/repo",
    installCommand: "npx skills add author/repo@skill-name -g",
    compatibility: ["Claude Code", "Cursor", "Copilot", "..."],
    tags: ["tag1", "tag2"],
    featured: false, // Set true to show on homepage
  },
];
```

Save and the site auto-updates!

## 🚢 Deploy to Vercel

### Option 1: Vercel CLI
```bash
cd ~/Programming/crafter-station/skills/website
vercel
# Follow prompts
# Set custom domain: skills.crafter.run
```

### Option 2: GitHub + Vercel Dashboard
1. Commit and push (but you said no push yet)
2. Go to vercel.com/dashboard
3. Import from GitHub: crafter-station/skills
4. Root directory: `website`
5. Framework: Next.js
6. Deploy

### DNS Setup
In your DNS provider (wherever crafter.run is):
```
CNAME skills → cname.vercel-dns.com
```

## 📝 Before Launch

- [ ] Add 5-10 more skills to lib/skills.ts
- [ ] Test all pages work
- [ ] Generate OG images (see DEVELOPMENT.md)
- [ ] Add favicon.ico to public/
- [ ] Test mobile responsiveness
- [ ] Run Lighthouse audit
- [ ] Deploy to Vercel
- [ ] Configure skills.crafter.run DNS
- [ ] Test production site
- [ ] Prepare launch content (see LAUNCH.md)

## 🔥 Quick Wins

### Add a Logo
1. Create logo.svg in public/
2. Update header in all pages:
   ```tsx
   <Image src="/logo.svg" alt="Skills" width={32} height={32} />
   ```

### Add Analytics
1. Install Vercel Analytics:
   ```bash
   bun add @vercel/analytics
   ```
2. Add to layout.tsx:
   ```tsx
   import { Analytics } from '@vercel/analytics/react';
   // In return: <Analytics />
   ```

### Add Search
1. Install Fuse.js:
   ```bash
   bun add fuse.js
   ```
2. Create search component
3. Add to /skills page

## 🐛 Troubleshooting

**Port 3000 in use?**
```bash
bun dev -- -p 3001
```

**Build fails?**
```bash
rm -rf .next node_modules
bun install
bun build
```

**Vercel deploy fails?**
- Check vercel.json exists
- Ensure bun.lock is committed
- Verify all imports are correct

## 📚 Next Steps

1. See DEVELOPMENT.md for full roadmap
2. See LAUNCH.md for launch strategy
3. Add more skills from:
   - Your claude-dx repo
   - vercel-labs/agent-skills
   - Community favorites

## 🎯 Goals

**Week 1**: 1,000 visitors, 100 GitHub stars
**Month 1**: 5,000 visitors, 20 curated skills
**Month 3**: Partnerships with Vercel, Clerk, Anthropic

Let's ship it! 🚀
