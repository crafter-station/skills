export interface Skill {
  slug: string;
  name: string;
  description: string;
  category: string;
  author: string;
  repository: string;
  installCommand: string;
  compatibility: string[];
  tags: string[];
  featured: boolean;
  readme?: string;
}

export const skills: Skill[] = [
  {
    slug: "intent-layer",
    name: "intent-layer",
    description:
      "Set up hierarchical AGENTS.md infrastructure so agents navigate codebases like senior engineers. Battle-tested patterns for context structure.",
    category: "context-engineering",
    author: "Railly Hugo",
    repository: "https://github.com/crafter-station/skills",
    installCommand:
      "npx skills add crafter-station/skills --skill intent-layer -g",
    compatibility: [
      "Claude Code",
      "Cursor",
      "Copilot",
      "Windsurf",
      "Zed",
      "+10 more",
    ],
    tags: ["agents", "context", "AGENTS.md", "CLAUDE.md", "codebase"],
    featured: true,
  },
];

export function getSkill(slug: string): Skill | undefined {
  return skills.find((skill) => skill.slug === slug);
}

export function getFeaturedSkills(): Skill[] {
  return skills.filter((skill) => skill.featured);
}

export function getSkillsByCategory(category: string): Skill[] {
  return skills.filter((skill) => skill.category === category);
}
