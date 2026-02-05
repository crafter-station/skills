import Link from "next/link";

export default function AboutPage() {
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
                className="text-sm text-white/70 hover:text-white transition-colors"
              >
                Browse
              </Link>
              <Link
                href="/about"
                className="text-sm text-white hover:text-white/70 transition-colors"
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

      {/* Content */}
      <section className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-24">
        <h1 className="text-5xl font-bold mb-8">About Skills</h1>

        <div className="space-y-8 text-lg text-white/70">
          <p>
            Skills is a curated directory of the best agent skills for modern AI
            coding tools. We handpick, test, and document skills that actually
            work.
          </p>

          <div className="pt-8 border-t border-white/10">
            <h2 className="text-3xl font-bold text-white mb-4">
              Why we built this
            </h2>
            <p>
              The{" "}
              <a
                href="https://skills.sh"
                className="text-white/90 hover:text-white transition-colors underline underline-offset-4"
              >
                skills.sh leaderboard
              </a>{" "}
              is great for discovery, but it&apos;s hard to know which skills
              are actually worth installing. We&apos;re solving that by curating
              only the best skills and providing clear documentation.
            </p>
          </div>

          <div className="pt-8 border-t border-white/10">
            <h2 className="text-3xl font-bold text-white mb-4">
              What makes a skill &quot;curated&quot;?
            </h2>
            <ul className="space-y-3 ml-6">
              <li className="flex items-start gap-3">
                <span className="text-emerald-400 mt-1">✓</span>
                <span>
                  <strong className="text-white">Battle-tested</strong> - Used
                  in production codebases
                </span>
              </li>
              <li className="flex items-start gap-3">
                <span className="text-emerald-400 mt-1">✓</span>
                <span>
                  <strong className="text-white">Well-documented</strong> -
                  Clear examples and use cases
                </span>
              </li>
              <li className="flex items-start gap-3">
                <span className="text-emerald-400 mt-1">✓</span>
                <span>
                  <strong className="text-white">Wide compatibility</strong> -
                  Works with Claude Code, Cursor, Copilot, and more
                </span>
              </li>
              <li className="flex items-start gap-3">
                <span className="text-emerald-400 mt-1">✓</span>
                <span>
                  <strong className="text-white">Actively maintained</strong> -
                  Updated and supported
                </span>
              </li>
            </ul>
          </div>

          <div className="pt-8 border-t border-white/10">
            <h2 className="text-3xl font-bold text-white mb-4">Who we are</h2>
            <p>
              Skills is built by{" "}
              <a
                href="https://crafterstation.com"
                className="text-white/90 hover:text-white transition-colors underline underline-offset-4"
              >
                Crafter Station
              </a>
              , a non-profit building Peru&apos;s tech ecosystem. We create
              tools, run hackathons, and support builders worldwide.
            </p>
          </div>

          <div className="pt-8 border-t border-white/10">
            <h2 className="text-3xl font-bold text-white mb-4">Get involved</h2>
            <p className="mb-6">
              We&apos;re always looking for more skills to curate. If
              you&apos;ve built a great agent skill, we&apos;d love to feature
              it.
            </p>
            <div className="flex flex-wrap gap-4">
              <a
                href="https://github.com/crafter-station/skills/issues/new"
                className="px-6 py-3 bg-white text-black rounded-lg font-medium hover:bg-white/90 transition-colors inline-block"
              >
                Submit a skill
              </a>
              <a
                href="https://github.com/crafter-station/skills"
                className="px-6 py-3 border border-white/10 rounded-lg font-medium hover:bg-white/5 transition-colors inline-block"
              >
                View on GitHub
              </a>
            </div>
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
