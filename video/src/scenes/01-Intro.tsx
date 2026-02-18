import React from "react";
import { useCurrentFrame, useVideoConfig, spring, interpolate } from "remotion";
import { colors } from "../lib/colors";
import { fonts } from "../lib/fonts";
import { springSmooth, fadeSlideIn, typewriter } from "../lib/animations";
import { OracleLogo } from "../components/OracleLogo";
import { GlowText } from "../components/GlowText";
import { FloatingParticles } from "../components/FloatingParticles";
import { GridBackground } from "../components/GridBackground";

export const Intro: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps, width, height } = useVideoConfig();
  const isVertical = height > width;

  const logoProgress = spring({ frame, fps, config: springSmooth });
  const logoOpacity = interpolate(logoProgress, [0, 1], [0, 1]);
  const logoScale = interpolate(logoProgress, [0, 1], [0.8, 1]);

  const titleText = "oracle-world";
  const title = typewriter(titleText, frame, 25, 1.2);
  const titleOpacity = frame >= 25 ? 1 : 0;

  const showCursor =
    frame >= 25 && title.length < titleText.length;
  const cursorOpacity = showCursor ? (Math.sin(frame * 0.3) > 0 ? 1 : 0) : 0;

  const taglineProgress = spring({
    frame: frame - 70,
    fps,
    config: springSmooth,
  });
  const taglineOpacity = interpolate(taglineProgress, [0, 1], [0, 1]);
  const taglineY = interpolate(taglineProgress, [0, 1], [20, 0]);

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
          opacity: logoOpacity,
          transform: `scale(${logoScale})`,
          marginBottom: isVertical ? 50 : 30,
        }}
      >
        <OracleLogo variant="red" width={isVertical ? 300 : 250} />
      </div>

      <div
        style={{
          opacity: titleOpacity,
          display: "flex",
          alignItems: "center",
        }}
      >
        <span
          style={{
            fontFamily: fonts.mono,
            fontSize: isVertical ? 64 : 72,
            fontWeight: 700,
            color: colors.textPrimary,
          }}
        >
          {title}
        </span>
        <span
          style={{
            display: "inline-block",
            width: 4,
            height: isVertical ? 56 : 64,
            backgroundColor: colors.oracleRed,
            marginLeft: 4,
            opacity: cursorOpacity,
          }}
        />
      </div>

      <div
        style={{
          ...fadeSlideIn(frame, fps, 55),
          marginTop: isVertical ? 30 : 20,
        }}
      >
        <span
          style={{
            fontFamily: fonts.heading,
            fontSize: isVertical ? 36 : 30,
            color: colors.textSecondary,
          }}
        >
          Free, powerful server
        </span>
      </div>

      <div
        style={{
          opacity: taglineOpacity,
          transform: `translateY(${taglineY}px)`,
          marginTop: isVertical ? 24 : 16,
        }}
      >
        <GlowText
          color={colors.oracleRed}
          fontSize={isVertical ? 38 : 32}
          fontFamily={fonts.heading}
          glowRadius={20}
        >
          Always Free. Forever.
        </GlowText>
      </div>
    </div>
  );
};
