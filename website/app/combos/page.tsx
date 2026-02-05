import Link from "next/link";
import { combos } from "@/lib/combos";

export default function CombosPage() {
  return (
    <div className="min-h-screen bg-black text-white">
      {/* Header */}
      <header className="border-b border-white/10">
        <div className="max-w-7xl mx-auto px-6 h-14 flex items-center justify-between">
          <Link
            href="/"
            className="flex items-center gap-2 text-sm font-medium"
          >
            <div className="w-5 h-5 bg-white flex items-center justify-center text-[9px] font-mono font-bold text-black">
              CS
            </div>
            <span>Skills</span>
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
              className="text-sm text-white transition-colors"
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

      {/* Hero */}
      <section className="border-b border-white/10">
        <div className="max-w-7xl mx-auto px-6 py-20">
          <div className="max-w-3xl">
            <h1 className="text-5xl font-bold tracking-tight mb-6">
              Skill Combos
            </h1>
            <p className="text-lg text-gray-400 leading-relaxed">
              Pre-configured skill combinations that work together perfectly.
              Install multiple skills at once with a single command.
            </p>
          </div>
        </div>
      </section>

      {/* Combos Grid */}
      <section className="py-16">
        <div className="max-w-7xl mx-auto px-6">
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {combos.map((combo) => (
              <Link
                key={combo.slug}
                href={`/combos/${combo.slug}`}
                className="group relative overflow-hidden rounded-xl border border-white/10 bg-white/5 p-8 hover:border-white/20 hover:bg-white/10 transition-all"
              >
                <div className="text-5xl mb-4">{combo.emoji}</div>
                <h2 className="text-2xl font-bold mb-3">{combo.name}</h2>
                <p className="text-gray-400 mb-6">{combo.description}</p>
                <div className="flex items-center justify-between text-sm">
                  <span className="text-gray-500">
                    {combo.skills.length} skills
                  </span>
                  <svg
                    className="w-5 h-5 text-gray-400 group-hover:text-white transition-colors"
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
              </Link>
            ))}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="border-t border-white/10 py-16">
        <div className="max-w-7xl mx-auto px-6 text-center">
          <h2 className="text-2xl font-bold mb-4">
            Don't see what you need?
          </h2>
          <p className="text-gray-400 mb-8">
            Browse all curated skills or suggest a new combo.
          </p>
          <div className="flex items-center justify-center gap-4">
            <Link
              href="/skills"
              className="inline-flex px-6 py-3 bg-white text-black rounded-lg font-medium hover:bg-white/90 transition-colors"
            >
              Browse all skills
            </Link>
            <a
              href="https://github.com/crafter-station/skills/issues/new"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex px-6 py-3 border border-white/10 rounded-lg font-medium hover:bg-white/5 transition-colors"
            >
              Suggest a combo
            </a>
          </div>
        </div>
      </section>
    </div>
  );
}
