# Mood Mapping Reference

## Mood → Spotify Parameters

| Mood/Activity | Seed Genres | Energy | Valence | Tempo | Other |
|---------------|-------------|--------|---------|-------|-------|
| Deep work / Focus | ambient, electronic, classical | 0.3 | 0.3 | 90-120 | instrumentalness: 0.8 |
| Coding sprint | electronic, techno, house | 0.7 | 0.5 | 120-140 | instrumentalness: 0.6 |
| Morning energy | pop, indie-pop, dance | 0.8 | 0.8 | 110-130 | - |
| Chill / Relax | lo-fi, ambient, jazz | 0.2 | 0.5 | 70-100 | acousticness: 0.7 |
| Workout / Gym | edm, hip-hop, drum-and-bass | 0.9 | 0.7 | 130-160 | - |
| Celebration / Shipped | pop, dance, funk | 0.9 | 0.9 | 120-140 | popularity: 70+ |
| Late night | ambient, trip-hop, downtempo | 0.2 | 0.3 | 60-90 | acousticness: 0.5 |
| Sad / Reflective | singer-songwriter, indie, classical | 0.3 | 0.2 | 60-100 | acousticness: 0.6 |
| Creative brainstorm | jazz, experimental, art-rock | 0.5 | 0.5 | 90-120 | - |
| Road trip | rock, indie, country | 0.7 | 0.8 | 100-130 | - |

## Tunable Attributes

All 0.0-1.0 unless noted:

| Flag | What it controls |
|------|-----------------|
| `--energy` | Intensity (0.8 = energetic) |
| `--danceability` | Dance suitability |
| `--valence` | Positiveness (0.1 = sad, 0.9 = happy) |
| `--tempo` | BPM (120 = moderate) |
| `--popularity` | 0-100, mainstream factor |
| `--acousticness` | Acoustic vs electronic |
| `--instrumentalness` | Vocals vs instrumental |

## Available Genres

acoustic, ambient, art-rock, classical, country, dance, downtempo,
drum-and-bass, edm, electronic, experimental, folk, funk, hip-hop,
house, indie, indie-pop, jazz, lo-fi, metal, pop, r-n-b, reggaeton,
rock, singer-songwriter, soul, techno, trip-hop, world-music

## Vault Context Signals

When extracting mood from `02_Journal/daily/{today}.md`:

| Signal | Maps To |
|--------|---------|
| Many completed tasks | Celebration |
| "tired", "drained" | Chill / Late night |
| "energized", "pumped" | Morning energy / Workout |
| "frustrated", "stuck" | Sad / Reflective |
| "shipped", "launched" | Celebration |
| Coding/technical work | Deep work / Coding sprint |
| Meetings/social | Creative brainstorm |
| Late timestamp (>22:00) | Late night |
| Morning timestamp (<10:00) | Morning energy |
