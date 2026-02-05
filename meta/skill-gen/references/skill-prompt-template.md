# Claude Skill Extraction Prompt

Extract comprehensive information from this documentation to create a Claude Code skill.

## Context

Claude Code skills are modular packages that extend Claude's capabilities with specialized knowledge, workflows, and tool integrations. Think of them as "onboarding guides" for specific domains.

## Extraction Requirements

### 1. Skill Identity (CRITICAL)

- **skill_name**: Generate hyphen-case name (lowercase, hyphens only). Examples: `firecrawl-scraper`, `clerk-auth`, `resend-email`
- **description**: MUST include WHEN to use the skill. This is the primary trigger mechanism. Include:
  - What the tool does
  - Specific user scenarios that should trigger it
  - Example: "Web scraping and data extraction with Firecrawl. Use when: (1) scraping websites, (2) extracting structured data from URLs, (3) crawling multiple pages, (4) converting web content to markdown"
- **overview**: 1-2 sentences summarizing the core capability
- **triggers**: List 5-10 user phrases that should activate this skill

### 2. Workflows (REQUIRED)

Extract ALL major operations the tool supports. For each workflow:
- **name**: Clear action name (e.g., "Single Page Scrape", "Batch Crawl")
- **description**: What it accomplishes
- **steps**: Step-by-step instructions in IMPERATIVE form ("Run X", "Configure Y", NOT "You should run X")
- **code_example**: Include working code when available

### 3. API Details (if applicable)

For each endpoint extract:
- Method (GET/POST/etc.)
- Path
- All parameters with types, required status, descriptions
- Response structure

### 4. Authentication

- Method type (API Key, Bearer Token, OAuth)
- Header name
- Suggested environment variable name
- Setup instructions

### 5. Code Examples

Extract examples in ALL available languages:
- Python
- TypeScript/JavaScript
- cURL
- Other SDKs

For each example:
- Complete, runnable code (no placeholders like "YOUR_API_KEY")
- Use environment variables for secrets
- Show both simple and advanced usage

### 6. Best Practices & Gotchas

- Common patterns that work well
- Anti-patterns to avoid
- Rate limits
- Error handling approaches
- Edge cases

### 7. Progressive Disclosure Planning

If content would exceed 500 lines in SKILL.md, identify what should go into separate reference files:
- API reference details
- Advanced examples
- Schema documentation
- Troubleshooting guides

## Quality Guidelines

1. **Be comprehensive but concise** - Include enough detail for Claude to use the tool without reading original docs
2. **Use imperative form** - "Run", "Configure", "Set" (not "You should run")
3. **Prioritize practical examples** - Real code over theory
4. **Include error handling** - What can go wrong and how to handle it
5. **Note rate limits and costs** - If documented

## Output

Return structured JSON matching the provided schema. Ensure:
- `description` is under 1024 characters
- `skill_name` is under 64 characters
- All code examples are syntactically valid
- Steps are actionable and specific
