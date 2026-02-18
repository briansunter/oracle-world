import React from "react";
import { useCurrentFrame, useVideoConfig, spring, interpolate } from "remotion";
import { colors } from "../lib/colors";
import { fonts } from "../lib/fonts";
import { fadeSlideIn, springSmooth, springBouncy } from "../lib/animations";
import { FloatingParticles } from "../components/FloatingParticles";
import { GridBackground } from "../components/GridBackground";
import { GlowText } from "../components/GlowText";
import { OracleLogo } from "../components/OracleLogo";

export const Outro: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps, width, height } = useVideoConfig();
  const isVertical = height > width;

  const logoProgress = spring({
    frame: frame - 5,
    fps,
    config: springSmooth,
  });

  const badgeProgress = spring({
    frame: frame - 35,
    fps,
    config: springBouncy,
  });

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
      }}
    >
      <GridBackground />
      <FloatingParticles count={25} />

      <div
        style={{
          opacity: interpolate(logoProgress, [0, 1], [0, 1]),
          transform: `scale(${interpolate(logoProgress, [0, 1], [0.9, 1])})`,
          marginBottom: 20,
        }}
      >
        <OracleLogo variant="white" width={isVertical ? 320 : 180} />
      </div>

      <div style={{ ...fadeSlideIn(frame, fps, 10), marginBottom: isVertical ? 24 : 16 }}>
        <GlowText color={colors.textPrimary} fontSize={isVertical ? 80 : 56} glowRadius={15}>
          oracle-world
        </GlowText>
      </div>

      <div style={{ ...fadeSlideIn(frame, fps, 20), marginBottom: isVertical ? 48 : 32 }}>
        <span
          style={{
            fontFamily: fonts.mono,
            fontSize: isVertical ? 36 : 30,
            color: colors.textSecondary,
          }}
        >
          github.com/briansunter/oracle-world
        </span>
      </div>

      {/* Single /setup command badge with Claude Code branding */}
      <div
        style={{
          opacity: interpolate(badgeProgress, [0, 1], [0, 1]),
          transform: `scale(${interpolate(badgeProgress, [0, 1], [0.8, 1])})`,
          display: "flex",
          alignItems: "center",
          gap: isVertical ? 16 : 12,
          fontFamily: fonts.mono,
          fontSize: isVertical ? 34 : 22,
          fontWeight: 600,
          color: colors.purple,
          backgroundColor: `${colors.purple}15`,
          border: `1px solid ${colors.purple}40`,
          borderRadius: 30,
          padding: isVertical ? "20px 44px" : "14px 32px",
        }}
      >
        <span style={{ fontSize: isVertical ? 30 : 20 }}>&#10023;</span>
        Claude Code
        <span
          style={{
            color: colors.textMuted,
            fontWeight: 400,
            marginLeft: 4,
            marginRight: 4,
          }}
        >
          /
        </span>
        <span style={{ color: colors.green }}>/setup</span>
      </div>

      <div style={{ ...fadeSlideIn(frame, fps, 60), marginTop: isVertical ? 60 : 40 }}>
        <GlowText
          color={colors.oracleRed}
          fontSize={isVertical ? 44 : 28}
          fontFamily={fonts.heading}
          glowRadius={15}
        >
          Always Free. Forever.
        </GlowText>
      </div>
    </div>
  );
};
