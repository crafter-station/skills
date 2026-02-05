import Link from "next/link";
import { notFound } from "next/navigation";
import { getSkill, skills } from "@/lib/skills";

export async function generateStaticParams() {
  return skills.map((skill) => ({
    slug: skill.slug,
  }));
}

export default async function SkillDetailPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const skill = getSkill(slug);

  if (!skill) {
    notFound();
  }

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

      {/* Breadcrumb */}
      <div className="border-b border-white/10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center gap-2 text-sm text-white/60">
            <Link href="/skills" className="hover:text-white transition-colors">
              Skills
            </Link>
            <span>/</span>
            <span className="text-white">{skill.name}</span>
          </div>
        </div>
      </div>

      {/* Skill Header */}
      <section className="border-b border-white/10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-emerald-500/20 bg-emerald-500/10 mb-6">
            <span className="text-sm text-emerald-400 font-mono">
              {skill.category}
            </span>
          </div>
          <h1 className="text-5xl font-bold mb-6">{skill.name}</h1>
          <p className="text-xl text-white/60 max-w-3xl mb-8">
            {skill.description}
          </p>

          {/* Compatibility Badges */}
          <div className="flex flex-wrap items-center gap-3 mb-8">
            <span className="text-sm text-white/40">Works with</span>
            {skill.compatibility.map((agent) => (
              <span
                key={agent}
                className="text-sm px-3 py-1.5 rounded-md bg-white/5 border border-white/10 text-white/70"
              >
                {agent}
              </span>
            ))}
          </div>

          {/* Install Command */}
          <div className="bg-black/40 border border-white/10 rounded-xl p-6">
            <div className="mb-3">
              <span className="font-mono text-sm text-white/40">
                Install command
              </span>
            </div>
            <code className="block font-mono text-sm text-white/90 break-all select-all">
              {skill.installCommand}
            </code>
          </div>
        </div>
      </section>

      {/* README Section */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
        <div className="prose prose-invert max-w-none">
          <h2 className="text-3xl font-bold mb-6">About this skill</h2>
          <div className="bg-white/5 border border-white/10 rounded-xl p-8">
            <p className="text-white/60">
              This skill helps you set up hierarchical AGENTS.md files in your
              codebase so agents can navigate like senior engineers. It includes
              templates, examples, and scripts to analyze your project structure
              and generate appropriate context files.
            </p>
            <div className="mt-8 pt-8 border-t border-white/10">
              <h3 className="text-xl font-bold mb-4">Key features</h3>
              <ul className="space-y-2 text-white/60">
                <li>Hierarchical AGENTS.md file structure</li>
                <li>Automatic project structure analysis</li>
                <li>Token estimation for context budgets</li>
                <li>Multiple templates for different project types</li>
                <li>State detection for development phases</li>
              </ul>
            </div>
            <div className="mt-8 pt-8 border-t border-white/10">
              <a
                href={`${skill.repository}/tree/main/context-engineering/intent-layer`}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 text-white/70 hover:text-white transition-colors"
              >
                <span>View full documentation on GitHub</span>
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
        </div>
      </section>

      {/* Author Section */}
      <section className="border-t border-white/10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 bg-white/10 rounded-full flex items-center justify-center">
              <span className="text-lg font-bold">{skill.author[0]}</span>
            </div>
            <div>
              <div className="text-sm text-white/40">Created by</div>
              <div className="font-medium">{skill.author}</div>
            </div>
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
