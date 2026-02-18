import React from "react";
import { colors } from "../lib/colors";
import { fonts } from "../lib/fonts";

interface OracleLogoProps {
  variant?: "red" | "white";
  width?: number;
  style?: React.CSSProperties;
}

export const OracleLogo: React.FC<OracleLogoProps> = ({
  variant = "red",
  width = 200,
  style,
}) => {
  const isRed = variant === "red";
  const aspectRatio = 340 / 520;

  return (
    <svg
      viewBox="0 0 520 340"
      width={width}
      height={width * aspectRatio}
      style={style}
    >
      {/* Cloud shape */}
      <path
        d={[
          "M 78 288",
          "C 32 288, 6 258, 6 224",
          "C 6 192, 28 168, 60 160",
          "C 52 108, 88 66, 148 62",
          "C 188 59, 220 78, 242 106",
          "C 262 58, 316 38, 368 56",
          "C 418 73, 448 120, 444 164",
          "C 480 170, 514 200, 514 232",
          "C 514 264, 484 288, 444 288",
          "Z",
        ].join(" ")}
        fill={isRed ? colors.oracleRed : "none"}
        stroke={isRed ? "none" : "rgba(255,255,255,0.3)"}
        strokeWidth={isRed ? 0 : 3}
      />
      {/* ORACLE text */}
      <text
        x="260"
        y="228"
        textAnchor="middle"
        dominantBaseline="middle"
        fill="#FFFFFF"
        fontFamily={fonts.heading}
        fontSize="68"
        fontWeight="700"
        letterSpacing="8"
      >
        ORACLE
      </text>
    </svg>
  );
};
