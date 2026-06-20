'use client';

import { motion } from 'framer-motion';
import React from 'react';

const rings = [
  { radius: 24,  petals: 6,  duration: 80,  dir: 1,   grad: 'grad-ring-1', opacity: 0.65 },
  { radius: 60,  petals: 8,  duration: 55,  dir: -1,  grad: 'grad-ring-2', opacity: 0.60 },
  { radius: 100, petals: 10, duration: 110, dir: 1,   grad: 'grad-ring-3', opacity: 0.50 },
  { radius: 142, petals: 12, duration: 85,  dir: -1,  grad: 'grad-ring-4', opacity: 0.45 },
  { radius: 188, petals: 14, duration: 140, dir: 1,   grad: 'grad-ring-5', opacity: 0.35 },
  { radius: 235, petals: 16, duration: 190, dir: -1,  grad: 'grad-ring-6', opacity: 0.25 },
];

const getPetalPath = (ringRadius: number, isFirstRing: boolean = false) => {
  const bandWidth = isFirstRing ? ringRadius * 0.5 : ringRadius * 0.35;
  const innerOffset = ringRadius - bandWidth;
  const width = isFirstRing ? bandWidth * 0.85 : bandWidth * 0.7;
  
  return `M 0 ${-innerOffset} 
          C ${width * 0.5} ${-innerOffset - bandWidth * 0.3}, 
            ${width * 0.6} ${-ringRadius + bandWidth * 0.2}, 
            0 ${-ringRadius} 
          C ${-width * 0.6} ${-ringRadius + bandWidth * 0.2}, 
            ${-width * 0.5} ${-innerOffset - bandWidth * 0.3}, 
            0 ${-innerOffset} Z`;
};

export default function LotusMandala() {
  return (
    <motion.svg
      viewBox="0 0 600 600"
      animate={{ scale: [1.0, 1.015, 1.0] }}
      transition={{ duration: 4, ease: "easeInOut", repeat: Infinity }}
      style={{
        filter: 'drop-shadow(0 0 50px rgba(184,160,255,0.2)) drop-shadow(0 0 20px rgba(255,208,138,0.15))',
        opacity: 0.72,
        width: '100%',
        maxWidth: '560px',
        overflow: 'visible'
      }}
    >
      <defs>
        <linearGradient id="grad-ring-1" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#FFD08A" />
          <stop offset="100%" stopColor="#FFB060" />
        </linearGradient>
        <linearGradient id="grad-ring-2" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#FFB060" />
          <stop offset="100%" stopColor="#E8A0CC" />
        </linearGradient>
        <linearGradient id="grad-ring-3" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#E8A0CC" />
          <stop offset="100%" stopColor="#D080BB" />
        </linearGradient>
        <linearGradient id="grad-ring-4" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#D080BB" />
          <stop offset="100%" stopColor="#B8A0FF" />
        </linearGradient>
        <linearGradient id="grad-ring-5" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#B8A0FF" />
          <stop offset="100%" stopColor="#9880FF" />
        </linearGradient>
        <linearGradient id="grad-ring-6" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#9880FF" />
          <stop offset="100%" stopColor="#82C4FF" />
        </linearGradient>
        <radialGradient id="center-glow" cx="50%" cy="50%" r="50%">
          <stop offset="0%" stopColor="#FFE0AA" />
          <stop offset="100%" stopColor="#FFB060" />
        </radialGradient>
      </defs>

      {rings.map((ring, ringIndex) => (
        <motion.g
          key={ringIndex}
          animate={{ rotate: [0, 360 * ring.dir] }}
          transition={{ duration: ring.duration, repeat: Infinity, ease: "linear" }}
          style={{ transformOrigin: 'center', opacity: ring.opacity }}
        >
          {Array.from({ length: ring.petals }).map((_, petalIndex) => {
            const angle = (petalIndex / ring.petals) * 360;
            return (
              <path
                key={petalIndex}
                d={getPetalPath(ring.radius, ringIndex === 0)}
                fill={`url(#${ring.grad})`}
                transform={`translate(300, 300) rotate(${angle})`}
              />
            );
          })}
        </motion.g>
      ))}

      <circle cx="300" cy="300" r="12" fill="url(#center-glow)" />
    </motion.svg>
  );
}
