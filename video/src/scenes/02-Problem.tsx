import React from "react";
import { useCurrentFrame, useVideoConfig, spring, interpolate } from "remotion";
import { colors } from "../lib/colors";
import { fonts } from "../lib/fonts";
import { springBouncy, fadeSlideIn, stagger } from "../lib/animations";
import { FloatingParticles } from "../components/FloatingParticles";
import { GridBackground } from "../components/GridBackground";
import { GlowText } from "../components/GlowText";

const providers = [
  { name: "Hetzner", price: "$20/mo", detail: "4 vCPU \u2022 16 GB" },
  { name: "AWS EC2", price: "$98/mo", detail: "4 vCPU \u2022 16 GB" },
  { name: "DigitalOcean", price: "$126/mo", detail: "4 vCPU \u2022 16 GB" },
];

export const Problem: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps, width, height } = useVideoConfig();
  const isVertical = height > width;

  const strikeProgress = interpolate(frame, [50, 65], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  const zeroProgress = spring({
    frame: frame - 80,
    fps,
    config: springBouncy,
  });
  const zeroScale = interpolate(zeroProgress, [0, 1], [0.3, 1]);
  const zeroOpacity = interpolate(zeroProgress, [0, 1], [0, 1]);

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
      <FloatingParticles count={15} />

      <div style={fadeSlideIn(frame, fps, 0)}>
        <span
          style={{
            fontFamily: fonts.heading,
            fontSize: isVertical ? 56 : 40,
            color: colors.textSecondary,
            letterSpacing: "0.05em",
          }}
        >
          What cloud costs look like
        </span>
      </div>

      <div
        style={{
          display: "flex",
          flexDirection: isVertical ? "column" : "row",
          gap: isVertical ? 60 : 32,
          marginTop: isVertical ? 80 : 50,
          marginBottom: isVertical ? 80 : 60,
          position: "relative",
        }}
      >
        {providers.map((p, i) => {
          const itemStyle = fadeSlideIn(frame, fps, stagger(i, 8) + 10);
          return (
            <div
              key={p.name}
              style={{
                ...itemStyle,
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                gap: 12,
                position: "relative",
              }}
            >
              <span
                style={{
                  fontFamily: fonts.body,
                  fontSize: isVertical ? 44 : 20,
                  color: colors.textMuted,
                }}
              >
                {p.name}
              </span>
              <span
                style={{
                  fontFamily: fonts.mono,
                  fontSize: isVertical ? 28 : 13,
                  color: colors.textMuted,
                  opacity: 0.7,
                }}
              >
                {p.detail}
              </span>
              <span
                style={{
                  fontFamily: fonts.heading,
                  fontSize: isVertical ? 76 : 42,
                  fontWeight: 700,
                  color: colors.textSecondary,
                  position: "relative",
                }}
              >
                {p.price}
                <div
                  style={{
                    position: "absolute",
                    left: -8,
                    top: "50%",
                    width: `${strikeProgress * 110}%`,
                    height: 3,
                    backgroundColor: colors.oracleRed,
                    transform: "translateY(-50%) rotate(-5deg)",
                  }}
                />
              </span>
            </div>
          );
        })}
      </div>

      <div
        style={{
          opacity: zeroOpacity,
          transform: `scale(${zeroScale})`,
        }}
      >
        <GlowText
          color={colors.green}
          fontSize={isVertical ? 160 : 120}
          fontFamily={fonts.heading}
          glowRadius={40}
        >
          $0
        </GlowText>
        <div style={{ textAlign: "center", marginTop: 8 }}>
          <span
            style={{
              fontFamily: fonts.body,
              fontSize: isVertical ? 34 : 24,
              color: colors.textSecondary,
            }}
          >
            /month with Oracle Cloud Free Tier
          </span>
        </div>
      </div>
    </div>
  );
};
