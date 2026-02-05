export interface Combo {
  slug: string;
  name: string;
  emoji: string;
  description: string;
  longDescription: string;
  skills: Array<{
    slug: string;
    name: string;
    description: string;
  }>;
  compatibility: string[];
  installCommand: string;
}

export const combos: Combo[] = [
  {
    slug: "auth-stack",
    name: "The Auth Stack",
    emoji: "🔐",
    description: "Complete authentication setup with Clerk + best practices",
    longDescription:
      "These three skills work together to give you a production-ready authentication system. Start with Clerk's setup skill for the auth foundation, add web design guidelines for accessibility and UX patterns, then layer in React best practices for optimal performance.",
    skills: [
      {
        slug: "clerk-auth-setup",
        name: "clerk-auth-setup",
        description: "Bootstrap Clerk authentication in your project",
      },
      {
        slug: "web-design-guidelines",
        name: "web-design-guidelines",
        description: "Accessibility and UX patterns for auth flows",
      },
      {
        slug: "react-best-practices",
        name: "react-best-practices",
        description: "Performance optimization for auth components",
      },
    ],
    compatibility: ["claude", "cursor"],
    installCommand:
      "npx skills add clerk/clerk-auth-setup vercel-labs/web-design-guidelines vercel-labs/react-best-practices",
  },
  {
    slug: "rag-stack",
    name: "The RAG Stack",
    emoji: "🧠",
    description: "Build production RAG applications with proven patterns",
    longDescription:
      "Everything you need to build a production-grade RAG application. Pinecone for vector storage, OpenAI for embeddings, LangChain for orchestration patterns, and vector search best practices to tie it all together.",
    skills: [
      {
        slug: "pinecone-rag",
        name: "pinecone-rag",
        description: "Vector database setup and RAG patterns",
      },
      {
        slug: "openai-embeddings",
        name: "openai-embeddings",
        description: "Generate and manage text embeddings",
      },
      {
        slug: "langchain-patterns",
        name: "langchain-patterns",
        description: "RAG orchestration and chain patterns",
      },
      {
        slug: "vector-search",
        name: "vector-search",
        description: "Optimize semantic search queries",
      },
    ],
    compatibility: ["claude", "cursor", "windsurf"],
    installCommand:
      "npx skills add pinecone/rag openai/embeddings langchain/patterns vector/search",
  },
  {
    slug: "deploy-stack",
    name: "The Deploy Stack",
    emoji: "🚀",
    description: "Ship to production in minutes with zero config",
    longDescription:
      "Deploy your applications with confidence. Vercel for frontend hosting with automatic previews, and Railway for backend services and databases. Both integrate seamlessly with Git and require minimal configuration.",
    skills: [
      {
        slug: "vercel-deploy",
        name: "vercel-deploy",
        description: "Deploy Next.js apps to Vercel with automatic previews",
      },
      {
        slug: "railway-deploy",
        name: "railway-deploy",
        description: "Deploy backend services and databases to Railway",
      },
    ],
    compatibility: ["claude", "cursor", "windsurf"],
    installCommand: "npx skills add vercel/deploy railway/deploy",
  },
];

export function getCombo(slug: string): Combo | undefined {
  return combos.find((combo) => combo.slug === slug);
}
