import type { Metadata } from "next";
import { GeistSans } from "geist/font/sans";
import { GeistMono } from "geist/font/mono";
import { ThemeProvider } from "@/components/theme-provider";
import "./globals.css";

export const metadata: Metadata = {
  title: "Skills — Curated agent skills for builders",
  description:
    "The best agent skills, curated by Crafter Station. Works with Claude Code, Cursor, Copilot, and 10+ more agents.",
  openGraph: {
    title: "Skills — Curated agent skills for builders",
    description:
      "The best agent skills, curated by Crafter Station. Works with Claude Code, Cursor, Copilot, and 10+ more agents.",
    url: "https://skills.crafter.run",
    siteName: "Skills",
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Skills — Curated agent skills for builders",
    description:
      "The best agent skills, curated by Crafter Station. Works with Claude Code, Cursor, Copilot, and 10+ more agents.",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body
        className={`${GeistSans.variable} ${GeistMono.variable} antialiased font-sans`}
      >
        <ThemeProvider
          attribute="class"
          defaultTheme="dark"
          enableSystem={false}
          disableTransitionOnChange
        >
          {children}
        </ThemeProvider>
      </body>
    </html>
  );
}
