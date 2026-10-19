import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Anjun Control Tower",
  description: "Gestão operacional de entregas, frota e indicadores logísticos.",
  icons: { icon: "/favicon.svg", shortcut: "/favicon.svg" },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="pt-BR"><body>{children}</body></html>;
}
