import Link from "next/link";

export default function Home() {
  return (
    <div className="min-h-screen bg-black text-white">
      {/* Header */}
      <header className="border-b border-white/10">
        <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">
          <Link href="/" className="flex items-center gap-3 group">
            <pre className="text-[10px] leading-[0.9] font-mono text-white select-none tracking-tighter">
              {`███ ██ ▄
██  █▀▀▄█
███ ██ ▀`}
            </pre>
            <span className="text-sm font-medium">skills</span>
          </Link>
          <nav className="flex items-center gap-6">
            <Link
              href="/skills"
              className="text-sm text-gray-400 hover:text-white transition-colors"
            >
              Browse
            </Link>
            <Link
              href="/combos"
              className="text-sm text-gray-400 hover:text-white transition-colors"
            >
              Combos
            </Link>
            <Link
              href="/about"
              className="text-sm text-gray-400 hover:text-white transition-colors"
            >
              About
            </Link>
            <a
              href="https://github.com/crafter-station/skills"
              target="_blank"
              rel="noopener noreferrer"
              className="text-sm text-gray-400 hover:text-white transition-colors"
            >
              GitHub
            </a>
          </nav>
        </div>
      </header>

      {/* Hero Section */}
      <section className="border-b border-white/10 relative overflow-hidden">
        <div className="max-w-7xl mx-auto px-6 py-24">
          <div className="max-w-4xl">
            {/* Terminal-style badge */}
            <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-white/5 border border-white/10 mb-8 font-mono text-xs">
              <span className="text-emerald-400">$</span>
              <span className="text-gray-400">curated_by</span>
              <span className="text-white">crafter_station</span>
            </div>

            {/* ASCII Art Title */}
            <div className="mb-8">
              <pre className="text-[clamp(20px,3.5vw,42px)] leading-[1.1] font-mono text-white select-none tracking-[-0.05em] mb-4">
                {`███████ ██   ██ ██ ██      ██      ███████
██      ██  ██  ██ ██      ██      ██
███████ █████   ██ ██      ██      ███████
     ██ ██  ██  ██ ██      ██           ██
███████ ██   ██ ██ ███████ ███████ ███████`}
              </pre>
              <h1 className="text-4xl md:text-5xl font-bold tracking-tight mb-2">
                The best agent skills,{" "}
                <span className="text-gray-400">curated</span>
              </h1>
            </div>

            <p className="text-lg md:text-xl text-gray-400 mb-8 leading-relaxed max-w-3xl">
              We test, document, and curate the best agent skills so you
              don&apos;t have to dig through{" "}
              <a
                href="https://skills.sh"
                className="text-white underline underline-offset-4 decoration-white/30 hover:decoration-white transition-colors"
                target="_blank"
                rel="noopener noreferrer"
              >
                200+ skills
              </a>
              . Only battle-tested, production-ready capabilities make the cut.
            </p>

            {/* Terminal-style CTAs */}
            <div className="flex flex-col sm:flex-row items-start gap-3">
              <Link
                href="/skills"
                className="group inline-flex items-center gap-2 px-5 py-3 bg-white text-black font-mono text-sm hover:bg-gray-100 transition-colors"
              >
                <span className="text-emerald-500">▶</span>
                <span className="font-medium">npx skills browse</span>
              </Link>
              <Link
                href="/combos"
                className="group inline-flex items-center gap-2 px-5 py-3 border border-white/20 font-mono text-sm hover:bg-white/5 transition-colors"
              >
                <span className="text-purple-400">⚡</span>
                <span>view combos</span>
              </Link>
            </div>

            {/* Quick Install Example */}
            <div className="mt-12 p-4 bg-white/5 border border-white/10 rounded font-mono text-sm">
              <div className="flex items-center gap-2 text-gray-500 mb-2">
                <span className="text-emerald-400">→</span>
                <span className="text-xs">Quick install</span>
              </div>
              <code className="text-white">
                npx skills add crafter-station/intent-layer
              </code>
            </div>
          </div>
        </div>

        {/* Terminal grid background */}
        <div className="absolute inset-0 opacity-[0.02] pointer-events-none">
          <div className="absolute inset-0" style={{
            backgroundImage: `
              linear-gradient(rgba(255,255,255,0.1) 1px, transparent 1px),
              linear-gradient(90deg, rgba(255,255,255,0.1) 1px, transparent 1px)
            `,
            backgroundSize: '20px 20px'
          }} />
        </div>
      </section>

      {/* Featured from Crafter Station */}
      <section className="border-b border-white/10">
        <div className="max-w-7xl mx-auto px-6 py-16">
          <div className="flex items-center gap-3 mb-8">
            <span className="font-mono text-emerald-400 text-sm">★</span>
            <h2 className="text-xl font-bold font-mono">
              featured_skills
            </h2>
            <div className="flex-1 h-px bg-gradient-to-r from-white/20 to-transparent" />
            <span className="font-mono text-xs text-gray-600">
              crafter_station
            </span>
          </div>

          <div className="grid gap-6">
            <Link
              href="/skills/intent-layer"
              className="group relative overflow-hidden border border-white/10 bg-white/5 p-6 hover:border-emerald-500/30 hover:bg-white/10 transition-all"
            >
              <div className="flex items-start justify-between mb-4">
                <div className="flex-1">
                  <div className="inline-flex items-center gap-2 px-2.5 py-1 bg-emerald-500/10 border border-emerald-500/20 mb-3 font-mono text-xs">
                    <span className="text-emerald-400">●</span>
                    <span className="text-emerald-400">context_engineering</span>
                  </div>
                  <h3 className="text-2xl font-bold mb-2 font-mono">
                    intent-layer
                  </h3>
                  <p className="text-gray-400 text-sm max-w-2xl leading-relaxed">
                    Set up hierarchical AGENTS.md infrastructure so agents
                    navigate codebases like senior engineers. Battle-tested
                    patterns for context structure.
                  </p>
                </div>
                <div className="flex-shrink-0 ml-4">
                  <div className="w-10 h-10 border border-white/10 bg-white/5 flex items-center justify-center group-hover:border-emerald-500/30 transition-colors">
                    <svg
                      className="w-5 h-5 text-gray-400 group-hover:text-emerald-400 transition-colors"
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
              </div>

              <div className="flex items-center gap-6 text-xs font-mono">
                <div className="flex items-center gap-2 text-gray-500">
                  <span className="text-purple-400">▸</span>
                  <span className="text-gray-400">Claude Code</span>
                  <span className="text-gray-600">•</span>
                  <span className="text-gray-400">Cursor</span>
                  <span className="text-gray-600">•</span>
                  <span className="text-gray-400">+10</span>
                </div>
                <div className="flex items-center gap-2 text-gray-500">
                  <span className="text-blue-400">↓</span>
                  <span className="text-gray-400">1.5K installs</span>
                </div>
              </div>
            </Link>
          </div>
        </div>
      </section>

      {/* Skill Combos */}
      <section className="border-b border-white/10">
        <div className="max-w-7xl mx-auto px-6 py-16">
          <div className="flex items-center gap-3 mb-8">
            <span className="font-mono text-purple-400 text-sm">⚡</span>
            <h2 className="text-xl font-bold font-mono">combo_stacks</h2>
            <div className="flex-1 h-px bg-gradient-to-r from-white/20 to-transparent" />
            <Link
              href="/combos"
              className="text-sm text-gray-400 hover:text-white transition-colors font-mono"
            >
              view_all →
            </Link>
          </div>

          <div className="grid md:grid-cols-3 gap-6">
            {/* Auth Stack */}
            <Link
              href="/combos/auth-stack"
              className="group relative overflow-hidden border border-white/10 bg-white/5 p-6 hover:border-blue-500/30 hover:bg-white/10 transition-all"
            >
              <div className="flex items-center gap-3 mb-4">
                <div className="text-3xl">🔐</div>
                <div className="font-mono text-xs text-gray-500">
                  [001]
                </div>
              </div>
              <h3 className="text-xl font-bold mb-3 font-mono">auth_stack</h3>
              <p className="text-sm text-gray-400 mb-4 leading-relaxed">
                Complete authentication setup with Clerk + best practices
              </p>
              <div className="flex items-center gap-2 font-mono text-xs text-gray-500">
                <span className="text-blue-400">▸</span>
                <span>3 skills</span>
              </div>
            </Link>

            {/* RAG Stack */}
            <Link
              href="/combos/rag-stack"
              className="group relative overflow-hidden border border-white/10 bg-white/5 p-6 hover:border-purple-500/30 hover:bg-white/10 transition-all"
            >
              <div className="flex items-center gap-3 mb-4">
                <div className="text-3xl">🧠</div>
                <div className="font-mono text-xs text-gray-500">
                  [002]
                </div>
              </div>
              <h3 className="text-xl font-bold mb-3 font-mono">rag_stack</h3>
              <p className="text-sm text-gray-400 mb-4 leading-relaxed">
                Build production RAG applications with proven patterns
              </p>
              <div className="flex items-center gap-2 font-mono text-xs text-gray-500">
                <span className="text-purple-400">▸</span>
                <span>4 skills</span>
              </div>
            </Link>

            {/* Deploy Stack */}
            <Link
              href="/combos/deploy-stack"
              className="group relative overflow-hidden border border-white/10 bg-white/5 p-6 hover:border-emerald-500/30 hover:bg-white/10 transition-all"
            >
              <div className="flex items-center gap-3 mb-4">
                <div className="text-3xl">🚀</div>
                <div className="font-mono text-xs text-gray-500">
                  [003]
                </div>
              </div>
              <h3 className="text-xl font-bold mb-3 font-mono">deploy_stack</h3>
              <p className="text-sm text-gray-400 mb-4 leading-relaxed">
                Ship to production in minutes with zero config
              </p>
              <div className="flex items-center gap-2 font-mono text-xs text-gray-500">
                <span className="text-emerald-400">▸</span>
                <span>2 skills</span>
              </div>
            </Link>
          </div>
        </div>
      </section>

      {/* Why Curated */}
      <section className="border-b border-white/10">
        <div className="max-w-7xl mx-auto px-6 py-16">
          <div className="max-w-3xl">
            <h2 className="text-2xl font-bold mb-6 font-mono">
              why_curated<span className="text-gray-600">()</span>
            </h2>
            <div className="space-y-6 text-gray-400">
              <p className="leading-relaxed">
                <a
                  href="https://skills.sh"
                  className="text-white underline underline-offset-4 decoration-white/30 hover:decoration-white transition-colors font-mono"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  skills.sh
                </a>{" "}
                is great for discovery, but with 200+ skills, it&apos;s hard to
                know which ones are actually worth your time.
              </p>
              <p className="leading-relaxed">
                We solve that by handpicking only the best skills and providing
                clear documentation on why they&apos;re good. Every skill here
                is:
              </p>
              <div className="space-y-3 border-l-2 border-white/10 pl-6 ml-2">
                <div className="flex items-start gap-3">
                  <span className="text-emerald-400 font-mono text-sm mt-0.5">
                    [✓]
                  </span>
                  <span className="leading-relaxed">
                    <strong className="text-white font-mono">
                      battle_tested
                    </strong>{" "}
                    in production codebases
                  </span>
                </div>
                <div className="flex items-start gap-3">
                  <span className="text-emerald-400 font-mono text-sm mt-0.5">
                    [✓]
                  </span>
                  <span className="leading-relaxed">
                    <strong className="text-white font-mono">
                      documented
                    </strong>{" "}
                    with clear examples
                  </span>
                </div>
                <div className="flex items-start gap-3">
                  <span className="text-emerald-400 font-mono text-sm mt-0.5">
                    [✓]
                  </span>
                  <span className="leading-relaxed">
                    <strong className="text-white font-mono">
                      maintained
                    </strong>{" "}
                    and actively supported
                  </span>
                </div>
                <div className="flex items-start gap-3">
                  <span className="text-emerald-400 font-mono text-sm mt-0.5">
                    [✓]
                  </span>
                  <span className="leading-relaxed">
                    <strong className="text-white font-mono">
                      compatible
                    </strong>{" "}
                    with 10+ agents
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="py-20">
        <div className="max-w-7xl mx-auto px-6">
          <div className="max-w-3xl mx-auto text-center">
            <div className="inline-flex items-center gap-2 mb-6 font-mono text-sm text-gray-500">
              <span className="text-emerald-400">$</span>
              <span>ready_to_start</span>
            </div>
            <h2 className="text-3xl md:text-4xl font-bold mb-4 font-mono">
              start_with_best<span className="text-gray-600">()</span>
            </h2>
            <p className="text-gray-400 mb-10 text-lg">
              No guessing, no wasted time. Just proven capabilities.
            </p>
            <Link
              href="/skills"
              className="inline-flex items-center gap-2 px-6 py-3 bg-white text-black font-mono text-sm hover:bg-gray-100 transition-colors"
            >
              <span className="text-emerald-500">▶</span>
              <span className="font-medium">browse_skills</span>
            </Link>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-white/10">
        <div className="max-w-7xl mx-auto px-6 py-10">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-6">
            <div className="flex items-center gap-3 text-sm">
              <span className="text-gray-600 font-mono">©</span>
              <span className="text-gray-400">Built by</span>
              <a
                href="https://crafterstation.com"
                className="font-mono text-white hover:text-gray-300 transition-colors"
              >
                crafter_station
              </a>
            </div>
            <div className="flex items-center gap-6 text-sm font-mono">
              <a
                href="https://github.com/crafter-station/skills"
                className="text-gray-400 hover:text-white transition-colors"
              >
                github
              </a>
              <span className="text-gray-700">•</span>
              <a
                href="https://twitter.com/crafterstation"
                className="text-gray-400 hover:text-white transition-colors"
              >
                twitter
              </a>
              <span className="text-gray-700">•</span>
              <a
                href="https://discord.gg/crafterstation"
                className="text-gray-400 hover:text-white transition-colors"
              >
                discord
              </a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
