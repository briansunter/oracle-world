import React from "react";
import { useCurrentFrame, useVideoConfig, spring, interpolate } from "remotion";
import { colors } from "../lib/colors";
import { fonts } from "../lib/fonts";
import { fadeSlideIn, springSmooth, stagger } from "../lib/animations";
import { FloatingParticles } from "../components/FloatingParticles";
import { GridBackground } from "../components/GridBackground";

const features = [
  { icon: "\uD83D\uDD10", label: "State Encryption", color: colors.oracleRed },
  { icon: "\uD83D\uDEE1\uFE0F", label: "SSH Hardening", color: colors.blue },
  { icon: "\u26A1", label: "Idle Protection", color: colors.amber },
  { icon: "\uD83D\uDCE6", label: "Modular Design", color: colors.purple },
  { icon: "\uD83D\uDCB0", label: "Budget Alerts", color: colors.green },
  { icon: "\uD83D\uDD04", label: "Auto Updates", color: colors.cyan },
  { icon: "\uD83C\uDF10", label: "Public IP", color: colors.oracleRed },
  { icon: "\uD83D\uDDC4\uFE0F", label: "Block Storage", color: colors.blue },
];

export const Features: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps, width, height } = useVideoConfig();
  const isVertical = height > width;

  return (
    <div
      style={{
        width: "100%",
        height: "100%",
        backgroundColor: colors.bg,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        position: "relative",
        overflow: "hidden",
        padding: isVertical ? 40 : 80,
      }}
    >
      <GridBackground />
      <FloatingParticles count={15} />

      <div style={{ ...fadeSlideIn(frame, fps, 0), marginBottom: isVertical ? 40 : 50 }}>
        <span
          style={{
            fontFamily: fonts.heading,
            fontSize: isVertical ? 64 : 48,
            fontWeight: 700,
            color: colors.textPrimary,
          }}
        >
          Production-Ready Features
        </span>
      </div>

      <div
        style={{
          display: "grid",
          gridTemplateColumns: isVertical ? "repeat(2, 1fr)" : "repeat(4, 1fr)",
          gap: isVertical ? 20 : 24,
          width: "100%",
          maxWidth: isVertical ? 950 : 1200,
        }}
      >
        {features.map((feature, i) => {
          const delay = stagger(i, 6) + 15;
          const progress = spring({
            frame: frame - delay,
            fps,
            config: springSmooth,
          });
          const opacity = interpolate(progress, [0, 1], [0, 1]);
          const y = interpolate(progress, [0, 1], [30, 0]);

          return (
            <div
              key={feature.label}
              style={{
                opacity,
                transform: `translateY(${y}px)`,
                backgroundColor: colors.bgCard,
                border: `1px solid ${feature.color}30`,
                borderRadius: 16,
                padding: isVertical ? "36px 20px" : "28px 20px",
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                gap: 12,
              }}
            >
              <span style={{ fontSize: isVertical ? 48 : 36 }}>{feature.icon}</span>
              <span
                style={{
                  fontFamily: fonts.body,
                  fontSize: isVertical ? 26 : 18,
                  fontWeight: 600,
                  color: colors.textPrimary,
                  textAlign: "center",
                }}
              >
                {feature.label}
              </span>
            </div>
          );
        })}
      </div>
    </div>
  );
};
