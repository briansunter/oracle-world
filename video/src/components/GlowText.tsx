import React from "react";
import { fonts } from "../lib/fonts";
import { colors } from "../lib/colors";

interface GlowTextProps {
  children: React.ReactNode;
  color?: string;
  fontSize?: number;
  fontFamily?: string;
  glowRadius?: number;
  style?: React.CSSProperties;
}

export const GlowText: React.FC<GlowTextProps> = ({
  children,
  color = colors.oracleRed,
  fontSize = 72,
  fontFamily = fonts.heading,
  glowRadius = 30,
  style,
}) => {
  return (
    <span
      style={{
        fontFamily,
        fontSize,
        fontWeight: 700,
        color,
        textShadow: `0 0 ${glowRadius}px ${color}, 0 0 ${glowRadius * 2}px ${color}40`,
        ...style,
      }}
    >
      {children}
    </span>
  );
};
