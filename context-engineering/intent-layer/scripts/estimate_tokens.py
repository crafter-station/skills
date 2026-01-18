#!/usr/bin/env python3
"""
Estimate token count for a directory to determine Intent Node needs.

Usage:
    estimate_tokens.py <path> [--recursive]

Token estimation: ~4 chars per token (rough approximation)

Guidelines:
    <20k tokens: Usually no dedicated node needed
    20-64k tokens: Good candidate for 2-3k token node
    >64k tokens: Consider splitting into child nodes
"""

import sys
import os
from pathlib import Path

SKIP_DIRS = {
    'node_modules', '.git', 'dist', '.next', 'build', '__pycache__',
    '.venv', 'venv', 'target', '.turbo', '.cache', 'coverage'
}

SKIP_EXTENSIONS = {
    '.lock', '.png', '.jpg', '.jpeg', '.gif', '.ico', '.svg',
    '.woff', '.woff2', '.ttf', '.eot', '.mp4', '.mp3', '.pdf',
    '.zip', '.tar', '.gz', '.min.js', '.min.css'
}

CODE_EXTENSIONS = {
    '.ts', '.tsx', '.js', '.jsx', '.py', '.go', '.rs', '.java',
    '.rb', '.php', '.swift', '.kt', '.scala', '.c', '.cpp', '.h',
    '.cs', '.vue', '.svelte', '.astro', '.md', '.mdx', '.json',
    '.yaml', '.yml', '.toml', '.sql', '.graphql', '.prisma'
}


def should_skip(path: Path) -> bool:
    if path.name.startswith('.'):
        return True
    if path.name in SKIP_DIRS:
        return True
    if path.suffix.lower() in SKIP_EXTENSIONS:
        return True
    return False


def estimate_file_tokens(path: Path) -> int:
    try:
        content = path.read_text(encoding='utf-8', errors='ignore')
        return len(content) // 4
    except Exception:
        return 0


def analyze_directory(path: Path, recursive: bool = False) -> dict:
    results = {
        'total_tokens': 0,
        'file_count': 0,
        'by_extension': {},
        'largest_files': []
    }

    files = path.rglob('*') if recursive else path.glob('*')

    for file_path in files:
        if file_path.is_dir():
            if should_skip(file_path):
                continue

        if not file_path.is_file():
            continue

        if should_skip(file_path):
            continue

        if file_path.suffix.lower() not in CODE_EXTENSIONS:
            continue

        tokens = estimate_file_tokens(file_path)
        results['total_tokens'] += tokens
        results['file_count'] += 1

        ext = file_path.suffix.lower()
        results['by_extension'][ext] = results['by_extension'].get(ext, 0) + tokens

        results['largest_files'].append((tokens, str(file_path.relative_to(path))))

    results['largest_files'].sort(reverse=True)
    results['largest_files'] = results['largest_files'][:10]

    return results


def format_tokens(tokens: int) -> str:
    if tokens >= 1000000:
        return f"{tokens/1000000:.1f}M"
    if tokens >= 1000:
        return f"{tokens/1000:.1f}k"
    return str(tokens)


def get_recommendation(tokens: int) -> str:
    if tokens < 20000:
        return "No dedicated Intent Node needed (hierarchy covers this)"
    elif tokens < 64000:
        return "Good candidate for 2-3k token Intent Node"
    else:
        return "Consider splitting into child Intent Nodes"


def main():
    if len(sys.argv) < 2:
        print("Usage: estimate_tokens.py <path> [--recursive]")
        sys.exit(1)

    path = Path(sys.argv[1]).resolve()
    recursive = '--recursive' in sys.argv or '-r' in sys.argv

    if not path.exists():
        print(f"Error: Path not found: {path}")
        sys.exit(1)

    print(f"=== Token Estimate: {path.name} ===")
    print(f"Mode: {'Recursive' if recursive else 'Single directory'}")
    print()

    results = analyze_directory(path, recursive)

    print(f"Total tokens: {format_tokens(results['total_tokens'])}")
    print(f"File count: {results['file_count']}")
    print()

    print("By extension:")
    sorted_ext = sorted(results['by_extension'].items(), key=lambda x: x[1], reverse=True)
    for ext, tokens in sorted_ext[:8]:
        print(f"  {ext}: {format_tokens(tokens)}")
    print()

    print("Largest files:")
    for tokens, filepath in results['largest_files'][:5]:
        print(f"  {format_tokens(tokens)}: {filepath}")
    print()

    print(f"Recommendation: {get_recommendation(results['total_tokens'])}")


if __name__ == "__main__":
    main()
