import Link from "next/link";

export default function Home() {
  return (
    <div className="min-h-screen bg-black text-white">
      {/* Header */}
      <header className="border-b border-white/10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 bg-white rounded-md flex items-center justify-center">
                <span className="text-black font-bold text-sm">CS</span>
              </div>
              <span className="font-semibold text-lg">Skills</span>
            </div>
            <nav className="flex items-center gap-6">
              <Link
                href="/skills"
                className="text-sm text-white/70 hover:text-white transition-colors"
              >
                Browse
              </Link>
              <Link
                href="/about"
                className="text-sm text-white/70 hover:text-white transition-colors"
              >
                About
              </Link>
              <a
                href="https://github.com/crafter-station/skills"
                target="_blank"
                rel="noopener noreferrer"
                className="text-sm text-white/70 hover:text-white transition-colors"
              >
                GitHub
              </a>
            </nav>
          </div>
        </div>
      </header>

      {/* Hero */}
      <section className="relative">
        <div className="absolute inset-0 bg-gradient-to-b from-white/5 to-transparent pointer-events-none" />
        <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-32 text-center">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-white/10 bg-white/5 mb-8">
            <span className="w-2 h-2 bg-green-500 rounded-full animate-pulse" />
            <span className="text-sm text-white/70">
              1 curated skill • More coming soon
            </span>
          </div>
          <h1 className="text-5xl sm:text-6xl lg:text-7xl font-bold tracking-tight mb-6">
            Agent skills,{" "}
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-white to-white/60">
              curated
            </span>
          </h1>
          <p className="text-xl text-white/60 max-w-2xl mx-auto mb-12">
            The best agent skills for Claude Code, Cursor, Copilot, and 10+ more
            agents. Built by{" "}
            <a
              href="https://crafterstation.com"
              className="text-white/90 hover:text-white transition-colors underline underline-offset-4"
            >
              Crafter Station
            </a>
            .
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <Link
              href="/skills"
              className="px-6 py-3 bg-white text-black rounded-lg font-medium hover:bg-white/90 transition-colors"
            >
              Browse skills
            </Link>
            <a
              href="https://github.com/crafter-station/skills"
              className="px-6 py-3 border border-white/10 rounded-lg font-medium hover:bg-white/5 transition-colors"
            >
              View on GitHub
            </a>
          </div>
        </div>
      </section>

      {/* Featured Skill */}
      <section className="border-t border-white/10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-24">
          <div className="flex items-center gap-3 mb-12">
            <h2 className="text-3xl font-bold">Featured skill</h2>
            <div className="h-px flex-1 bg-gradient-to-r from-white/20 to-transparent" />
          </div>

          <Link
            href="/skills/intent-layer"
            className="block group relative overflow-hidden rounded-2xl border border-white/10 bg-white/5 p-8 hover:border-white/20 hover:bg-white/10 transition-all"
          >
            <div className="absolute inset-0 bg-gradient-to-br from-white/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
            <div className="relative">
              <div className="flex items-start justify-between mb-6">
                <div>
                  <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-emerald-500/20 bg-emerald-500/10 mb-4">
                    <span className="text-sm text-emerald-400 font-mono">
                      context-engineering
                    </span>
                  </div>
                  <h3 className="text-2xl font-bold mb-3">intent-layer</h3>
                  <p className="text-white/60 text-lg max-w-2xl">
                    Set up hierarchical AGENTS.md infrastructure so agents
                    navigate codebases like senior engineers. Battle-tested
                    patterns for context structure.
                  </p>
                </div>
                <div className="flex-shrink-0">
                  <svg
                    className="w-6 h-6 text-white/40 group-hover:text-white/60 transition-colors"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M9 5l7 7-7 7"
                    />
                  </svg>
                </div>
              </div>

              <div className="flex flex-wrap items-center gap-3 mb-6">
                <span className="text-sm text-white/40">Works with</span>
                <div className="flex items-center gap-2">
                  <span className="text-xs px-2 py-1 rounded-md bg-white/5 border border-white/10 text-white/60">
                    Claude Code
                  </span>
                  <span className="text-xs px-2 py-1 rounded-md bg-white/5 border border-white/10 text-white/60">
                    Cursor
                  </span>
                  <span className="text-xs px-2 py-1 rounded-md bg-white/5 border border-white/10 text-white/60">
                    Copilot
                  </span>
                  <span className="text-xs px-2 py-1 rounded-md bg-white/5 border border-white/10 text-white/60">
                    +10 more
                  </span>
                </div>
              </div>

              <div className="pt-6 border-t border-white/10">
                <div className="font-mono text-sm text-white/40 mb-2">
                  Install command
                </div>
                <code className="block p-4 rounded-lg bg-black/40 border border-white/10 font-mono text-sm text-white/80 overflow-x-auto">
                  npx skills add crafter-station/skills --skill intent-layer -g
                </code>
              </div>
            </div>
          </Link>
        </div>
      </section>

      {/* Coming Soon */}
      <section className="border-t border-white/10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-24">
          <div className="text-center">
            <h2 className="text-3xl font-bold mb-4">More coming soon</h2>
            <p className="text-white/60 mb-8 max-w-2xl mx-auto">
              We&apos;re curating the best agent skills from Crafter Station and
              beyond. Stay tuned for more.
            </p>
            <a
              href="https://github.com/crafter-station/skills"
              className="inline-flex items-center gap-2 text-white/70 hover:text-white transition-colors"
            >
              <span>Follow on GitHub for updates</span>
              <svg
                className="w-4 h-4"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M9 5l7 7-7 7"
                />
              </svg>
            </a>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-white/10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
            <div className="flex items-center gap-2 text-white/40 text-sm">
              <span>Built by</span>
              <a
                href="https://crafterstation.com"
                className="text-white/70 hover:text-white transition-colors font-medium"
              >
                Crafter Station
              </a>
            </div>
            <div className="flex items-center gap-6">
              <a
                href="https://github.com/crafter-station/skills"
                className="text-white/40 hover:text-white transition-colors text-sm"
              >
                GitHub
              </a>
              <a
                href="https://twitter.com/crafterstation"
                className="text-white/40 hover:text-white transition-colors text-sm"
              >
                Twitter
              </a>
              <a
                href="https://discord.gg/crafterstation"
                className="text-white/40 hover:text-white transition-colors text-sm"
              >
                Discord
              </a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
