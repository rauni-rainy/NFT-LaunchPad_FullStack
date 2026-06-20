import type { Metadata } from 'next';
import { Syne, JetBrains_Mono } from 'next/font/google';
import './globals.css';
import { Providers } from './providers';

const syne = Syne({ 
  subsets: ['latin'],
  variable: '--font-syne',
});

const jetbrainsMono = JetBrains_Mono({ 
  subsets: ['latin'],
  variable: '--font-mono',
});

export const metadata: Metadata = {
  title: 'NFT Launchpad',
  description: 'Premium NFT Launchpad',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={`${syne.variable} ${jetbrainsMono.variable}`}>
      <body className="font-syne bg-void text-white antialiased">
        <Providers>
          {children}
        </Providers>
      </body>
    </html>
  );
}
