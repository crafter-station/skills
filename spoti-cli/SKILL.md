---
name: spoti-cli
description: |
  Create Spotify playlists using spoti-cli CLI. Use when: (1) user wants a playlist,
  (2) user says "playlist", "spotify", "music for", "songs for", (3) user describes
  a mood or activity implying music ("deep work", "chill", "workout"), (4) user asks
  for music based on their day/vault/logs. Supports vault-aware playlist generation
  by reading Obsidian daily logs to infer mood and context.
---

# spoti-cli

## Prerequisites

Check auth: `spoti-cli me --json`. If it fails:

1. Install: `bun add -g @crafter/spoti-cli`
2. Run `spoti-cli auth` — it prints the exact dashboard URL, redirect URI (`http://127.0.0.1:8888/callback`), and API checkbox (Web API) to use
3. Re-run with `spoti-cli auth --client-id <CLIENT_ID>` once you have the ID

The CLI walks the user through Spotify dashboard setup. Don't repeat the steps yourself — point them at `spoti-cli auth` and let them paste the output.

## Workflow

### 1. Parse Intent

Three modes:

- **Explicit**: user names artists/tracks → search directly
- **Mood/activity**: user describes vibe → read [mood-mapping.md](references/mood-mapping.md)
- **Vault-aware**: user says "based on my day" → read `02_Journal/daily/{YYYY-MM-DD}.md`, extract mood signals from [mood-mapping.md](references/mood-mapping.md)

### 2. Find Seeds

```bash
spoti-cli search "Radiohead" --type artist --limit 5 --json
spoti-cli search "Everything In Its Right Place" --type track --limit 3 --json
```

Extract `id` fields from results.

### 3. Get Recommendations

```bash
spoti-cli recommend --seed-artists ID1,ID2 --seed-genres ambient --energy 0.3 --valence 0.4 --limit 25 --json
```

Max 5 seeds total (artists + genres + tracks combined). Tunable attributes in [mood-mapping.md](references/mood-mapping.md).

### 4. Create Playlist

```bash
spoti-cli create "Deep Work — Mar 24" --description "Focus music" --tracks URI1,URI2,... --json
```

Name contextually: include mood + date. Vault-aware example: "Post-shipping Celebration — Mar 24".

### 5. Open in Spotify

```bash
open "spotify:playlist:{PLAYLIST_ID}" 2>/dev/null || open "https://open.spotify.com/playlist/{PLAYLIST_ID}"
```

Always open the playlist after creating it. Try Spotify desktop first (URI scheme), fall back to web if desktop isn't available.

### 6. Report

Return: playlist URL, seed logic summary, track count.

## Commands

| Command | Example |
|---------|---------|
| `search` | `spoti-cli search "query" --type track --limit 10 --json` |
| `recommend` | `spoti-cli recommend --seed-genres pop --energy 0.8 --limit 20 --json` |
| `create` | `spoti-cli create "Name" --tracks URIs --public --json` |
| `playlist list` | `spoti-cli playlist list --limit 10 --json` |
| `playlist get` | `spoti-cli playlist get ID --json` |
| `playlist add` | `spoti-cli playlist add ID --tracks URIs` |
| `me` | `spoti-cli me --json` |

All commands support `--json` for structured output.
