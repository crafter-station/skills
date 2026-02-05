import Link from "next/link";
import { skills } from "@/lib/skills";

export default function SkillsPage() {
  return (
    <div className="min-h-screen bg-black text-white">
      {/* Header */}
      <header className="border-b border-white/10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <Link href="/" className="flex items-center gap-2">
              <div className="w-8 h-8 bg-white rounded-md flex items-center justify-center">
                <span className="text-black font-bold text-sm">CS</span>
              </div>
              <span className="font-semibold text-lg">Skills</span>
            </Link>
            <nav className="flex items-center gap-6">
              <Link
                href="/skills"
                className="text-sm text-white hover:text-white/70 transition-colors"
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

      {/* Page Header */}
      <section className="border-b border-white/10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
          <h1 className="text-4xl font-bold mb-4">Browse skills</h1>
          <p className="text-white/60 text-lg max-w-2xl">
            Curated agent skills that work with Claude Code, Cursor, Copilot,
            and 10+ more agents.
          </p>
        </div>
      </section>

      {/* Skills Grid */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {skills.map((skill) => (
            <Link
              key={skill.slug}
              href={`/skills/${skill.slug}`}
              className="group relative overflow-hidden rounded-xl border border-white/10 bg-white/5 p-6 hover:border-white/20 hover:bg-white/10 transition-all"
            >
              <div className="absolute inset-0 bg-gradient-to-br from-white/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
              <div className="relative">
                <div className="flex items-start justify-between mb-4">
                  <div>
                    <div className="inline-flex items-center gap-2 px-2.5 py-1 rounded-full border border-emerald-500/20 bg-emerald-500/10 mb-3">
                      <span className="text-xs text-emerald-400 font-mono">
                        {skill.category}
                      </span>
                    </div>
                    <h3 className="text-xl font-bold mb-2">{skill.name}</h3>
                    <p className="text-white/60 text-sm line-clamp-2">
                      {skill.description}
                    </p>
                  </div>
                  <div className="flex-shrink-0">
                    <svg
                      className="w-5 h-5 text-white/40 group-hover:text-white/60 transition-colors"
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

                <div className="flex flex-wrap items-center gap-2">
                  {skill.compatibility.slice(0, 3).map((agent) => (
                    <span
                      key={agent}
                      className="text-xs px-2 py-1 rounded-md bg-white/5 border border-white/10 text-white/60"
                    >
                      {agent}
                    </span>
                  ))}
                  {skill.compatibility.length > 3 && (
                    <span className="text-xs px-2 py-1 rounded-md bg-white/5 border border-white/10 text-white/60">
                      +{skill.compatibility.length - 3} more
                    </span>
                  )}
                </div>
              </div>
            </Link>
          ))}
        </div>

        {/* Coming Soon Message */}
        <div className="mt-16 text-center">
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full border border-white/10 bg-white/5">
            <span className="w-2 h-2 bg-yellow-500 rounded-full animate-pulse" />
            <span className="text-sm text-white/70">
              More skills coming soon
            </span>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-white/10 mt-24">
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
