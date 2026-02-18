import React from "react";
import { colors } from "../lib/colors";

export const GridBackground: React.FC = () => {
  return (
    <div
      style={{
        position: "absolute",
        top: 0,
        left: 0,
        width: "100%",
        height: "100%",
        backgroundImage: `radial-gradient(${colors.border} 1px, transparent 1px)`,
        backgroundSize: "40px 40px",
        opacity: 0.4,
        pointerEvents: "none",
      }}
    />
  );
};
