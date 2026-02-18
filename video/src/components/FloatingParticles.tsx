import React from "react";
import { useCurrentFrame, interpolate } from "remotion";
import { colors } from "../lib/colors";

interface FloatingParticlesProps {
  count?: number;
  color?: string;
  maxOpacity?: number;
}

export const FloatingParticles: React.FC<FloatingParticlesProps> = ({
  count = 30,
  color = colors.textMuted,
  maxOpacity = 0.3,
}) => {
  const frame = useCurrentFrame();

  const particles = React.useMemo(() => {
    return Array.from({ length: count }, (_, i) => ({
      x: (i * 137.508) % 100,
      y: (i * 73.2) % 100,
      size: 2 + (i % 4),
      speed: 0.3 + (i % 5) * 0.15,
      phase: (i * 47) % 360,
    }));
  }, [count]);

  return (
    <svg
      style={{
        position: "absolute",
        top: 0,
        left: 0,
        width: "100%",
        height: "100%",
        pointerEvents: "none",
      }}
    >
      {particles.map((p, i) => {
        const y = (p.y + frame * p.speed * 0.1) % 110 - 5;
        const x =
          p.x + Math.sin((frame * 0.02 + p.phase) * (Math.PI / 180)) * 3;
        const opacity = interpolate(
          Math.sin((frame * 0.03 + p.phase) * (Math.PI / 180)),
          [-1, 1],
          [0.05, maxOpacity],
        );
        return (
          <circle
            key={i}
            cx={`${x}%`}
            cy={`${y}%`}
            r={p.size}
            fill={color}
            opacity={opacity}
          />
        );
      })}
    </svg>
  );
};
