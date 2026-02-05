import Link from "next/link";

export default function NotFound() {
  return (
    <div className="min-h-screen bg-black text-white flex items-center justify-center">
      <div className="text-center">
        <h1 className="text-6xl font-bold mb-4">404</h1>
        <p className="text-xl text-white/60 mb-8">
          This skill doesn&apos;t exist yet
        </p>
        <Link
          href="/skills"
          className="px-6 py-3 bg-white text-black rounded-lg font-medium hover:bg-white/90 transition-colors inline-block"
        >
          Browse all skills
        </Link>
      </div>
    </div>
  );
}
