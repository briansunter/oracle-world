import React from "react";
import { useCurrentFrame, useVideoConfig, interpolate, spring } from "remotion";
import { colors } from "../lib/colors";
import { fonts } from "../lib/fonts";
import { animatedNumber, springSmooth } from "../lib/animations";

interface SpecCardProps {
  value: number;
  unit: string;
  label: string;
  color: string;
  delay?: number;
  suffix?: string;
}

export const SpecCard: React.FC<SpecCardProps> = ({
  value,
  unit,
  label,
  color,
  delay = 0,
  suffix = "",
}) => {
  const frame = useCurrentFrame();
  const { fps, width, height } = useVideoConfig();
  const isVertical = height > width;

  const progress = spring({
    frame: frame - delay,
    fps,
    config: springSmooth,
  });

  const opacity = interpolate(progress, [0, 1], [0, 1]);
  const scale = interpolate(progress, [0, 1], [0.8, 1]);
  const displayValue = animatedNumber(frame, fps, value, delay, 20);

  return (
    <div
      style={{
        opacity,
        transform: `scale(${scale})`,
        backgroundColor: colors.bgCard,
        border: `1px solid ${color}40`,
        borderRadius: isVertical ? 20 : 16,
        padding: isVertical ? "40px 28px" : "32px 24px",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        gap: isVertical ? 12 : 8,
        minWidth: isVertical ? 0 : 240,
      }}
    >
      <div
        style={{
          fontFamily: fonts.heading,
          fontSize: isVertical ? 72 : 56,
          fontWeight: 700,
          color,
          textShadow: `0 0 20px ${color}60`,
          lineHeight: 1,
        }}
      >
        {displayValue}
        <span style={{ fontSize: isVertical ? 36 : 28, marginLeft: 4 }}>{unit}</span>
        {suffix}
      </div>
      <div
        style={{
          fontFamily: fonts.body,
          fontSize: isVertical ? 24 : 18,
          color: colors.textSecondary,
          textTransform: "uppercase",
          letterSpacing: "0.1em",
        }}
      >
        {label}
      </div>
    </div>
  );
};
