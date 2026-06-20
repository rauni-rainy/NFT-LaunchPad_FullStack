import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        syne: ['var(--font-syne)'],
        mono: ['var(--font-mono)'],
      },
      colors: {
        void: '#070708',
        surface: '#0E0E10',
        accent: '#B8A0FF',
      },
      spacing: {
        '20': '80px',
        '30': '120px',
      },
    },
  },
  plugins: [],
};
export default config;
