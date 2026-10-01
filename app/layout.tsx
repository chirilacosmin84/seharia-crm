import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "SEHARIA · CRM Vânzări",
  description: "Prospectare, clienți și următoarele acțiuni ale echipei SEHARIA.",
  other: {
    "codex-preview": "development",
  },
  icons: {
    icon: "/favicon.svg",
    shortcut: "/favicon.svg",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ro">
      <body className="antialiased">{children}</body>
    </html>
  );
}
