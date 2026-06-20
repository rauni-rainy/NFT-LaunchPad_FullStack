import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { sepolia, baseSepolia } from 'viem/chains';

export const config = getDefaultConfig({
  appName: 'NFT Launchpad',
  projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || 'a4b1e5a5198a2872338f328f411b025b',
  chains: [sepolia, baseSepolia],
  ssr: true,
});
