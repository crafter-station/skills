import Link from "next/link";
import { notFound } from "next/navigation";
import { getCombo, combos } from "@/lib/combos";

export async function generateStaticParams() {
  return combos.map((combo) => ({
    slug: combo.slug,
  }));
}

export default async function ComboPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const combo = getCombo(slug);

  if (!combo) {
    notFound();
  }

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

      {/* Back Link */}
      <div className="border-b border-white/10">
        <div className="max-w-7xl mx-auto px-6 py-4">
          <Link
            href="/combos"
            className="inline-flex items-center gap-2 text-sm text-gray-400 hover:text-white transition-colors"
          >
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
                d="M15 19l-7-7 7-7"
              />
            </svg>
            Back to Combos
          </Link>
        </div>
      </div>

      {/* Hero */}
      <section className="border-b border-white/10">
        <div className="max-w-7xl mx-auto px-6 py-16">
          <div className="max-w-3xl">
            <div className="text-6xl mb-6">{combo.emoji}</div>
            <h1 className="text-5xl font-bold tracking-tight mb-6">
              {combo.name}
            </h1>
            <p className="text-xl text-gray-400 mb-8">{combo.description}</p>

            {/* Compatibility */}
            <div className="flex items-center gap-4 mb-8">
              <span className="text-sm text-gray-500">Works with</span>
              <div className="flex items-center gap-3">
                {combo.compatibility.includes("claude") && (
                  <span className="text-sm text-gray-400">Claude Code</span>
                )}
                {combo.compatibility.includes("cursor") && (
                  <>
                    <span className="text-gray-600">•</span>
                    <span className="text-sm text-gray-400">Cursor</span>
                  </>
                )}
                {combo.compatibility.includes("windsurf") && (
                  <>
                    <span className="text-gray-600">•</span>
                    <span className="text-sm text-gray-400">Windsurf</span>
                  </>
                )}
              </div>
            </div>

            {/* Install Command */}
            <div className="bg-white/5 border border-white/10 rounded-lg p-4">
              <div className="flex items-start justify-between gap-4">
                <div className="flex-1 min-w-0">
                  <div className="text-xs text-gray-500 mb-2 font-mono">
                    Install all {combo.skills.length} skills
                  </div>
                  <code className="text-sm text-white font-mono break-all">
                    {combo.installCommand}
                  </code>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Why This Combo */}
      <section className="border-b border-white/10">
        <div className="max-w-7xl mx-auto px-6 py-16">
          <div className="max-w-3xl">
            <h2 className="text-2xl font-bold mb-4">Why this combo?</h2>
            <p className="text-gray-400">{combo.longDescription}</p>
          </div>
        </div>
      </section>

      {/* Included Skills */}
      <section className="py-16">
        <div className="max-w-7xl mx-auto px-6">
          <div className="max-w-3xl">
            <h2 className="text-2xl font-bold mb-8">
              Included skills ({combo.skills.length})
            </h2>
            <div className="space-y-4">
              {combo.skills.map((skill, index) => (
                <div
                  key={skill.slug}
                  className="border border-white/10 rounded-lg p-6 bg-white/5"
                >
                  <div className="flex items-start gap-4">
                    <div className="flex-shrink-0 w-8 h-8 rounded-full bg-white/10 flex items-center justify-center text-sm font-bold">
                      {index + 1}
                    </div>
                    <div className="flex-1 min-w-0">
                      <h3 className="text-lg font-bold mb-2 font-mono">
                        {skill.name}
                      </h3>
                      <p className="text-gray-400 text-sm">
                        {skill.description}
                      </p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="border-t border-white/10 py-16">
        <div className="max-w-7xl mx-auto px-6 text-center">
          <h2 className="text-2xl font-bold mb-4">Ready to get started?</h2>
          <p className="text-gray-400 mb-8">
            Copy the install command above and run it in your project.
          </p>
          <div className="flex items-center justify-center gap-4">
            <Link
              href="/combos"
              className="inline-flex px-6 py-3 bg-white text-black rounded-lg font-medium hover:bg-white/90 transition-colors"
            >
              View all combos
            </Link>
            <Link
              href="/skills"
              className="inline-flex px-6 py-3 border border-white/10 rounded-lg font-medium hover:bg-white/5 transition-colors"
            >
              Browse individual skills
            </Link>
          </div>
        </div>
      </section>
    </div>
  );
}
