import React from "react";
import { fonts } from "../lib/fonts";

interface BadgeProps {
  label: string;
  color: string;
  style?: React.CSSProperties;
}

export const Badge: React.FC<BadgeProps> = ({ label, color, style }) => {
  return (
    <span
      style={{
        fontFamily: fonts.body,
        fontSize: 14,
        fontWeight: 600,
        color,
        backgroundColor: `${color}20`,
        border: `1px solid ${color}40`,
        borderRadius: 20,
        padding: "4px 12px",
        letterSpacing: "0.05em",
        textTransform: "uppercase",
        ...style,
      }}
    >
      {label}
    </span>
  );
};
