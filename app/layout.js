import { Newsreader, Geist_Mono } from "next/font/google";
import "./globals.css";

const newsreader = Newsreader({
  variable: "--font-newsreader",
  subsets: ["latin"],
  weight: ["400", "500", "600"],
  style: ["normal", "italic"],
  display: "swap",
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata = {
  title: "CBT-I — 6-week sleep program",
  description: "Cognitive behavioral therapy for insomnia: sleep restriction, stimulus control, and tools for racing thoughts.",
};

export default function RootLayout({ children }) {
  return (
    <html lang="en" className={`${newsreader.variable} ${geistMono.variable}`}>
      <body>{children}</body>
    </html>
  );
}
