import React from "react";
import { useCurrentFrame, useVideoConfig } from "remotion";
import { colors } from "../lib/colors";
import { fonts } from "../lib/fonts";
import { fadeSlideIn, stagger } from "../lib/animations";
import { SpecCard } from "../components/SpecCard";
import { FloatingParticles } from "../components/FloatingParticles";
import { GridBackground } from "../components/GridBackground";

const specs = [
  { value: 4, unit: "OCPU", label: "ARM Compute", color: colors.green },
  { value: 24, unit: "GB", label: "Memory", color: colors.cyan },
  { value: 200, unit: "GB", label: "Block Storage", color: colors.blue },
  { value: 50, unit: "GB", label: "MySQL Database", color: colors.purple },
  { value: 10, unit: "TB", label: "Outbound Data", color: colors.amber },
  { value: 20, unit: "GB", label: "Object Storage", color: colors.pink },
];

export const WhatYouGet: React.FC = () => {
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
      <FloatingParticles count={20} />

      <div style={{ ...fadeSlideIn(frame, fps, 0), marginBottom: isVertical ? 40 : 50 }}>
        <span
          style={{
            fontFamily: fonts.heading,
            fontSize: isVertical ? 64 : 48,
            fontWeight: 700,
            color: colors.textPrimary,
            textAlign: "center",
          }}
        >
          What You Get &mdash;{" "}
          <span style={{ color: colors.green }}>Always Free</span>
        </span>
      </div>

      <div
        style={{
          display: "grid",
          gridTemplateColumns: isVertical ? "repeat(2, 1fr)" : "repeat(3, 280px)",
          gap: isVertical ? 30 : 24,
          width: isVertical ? "100%" : undefined,
          maxWidth: isVertical ? 950 : undefined,
        }}
      >
        {specs.map((spec, i) => (
          <SpecCard
            key={spec.label}
            value={spec.value}
            unit={spec.unit}
            label={spec.label}
            color={spec.color}
            delay={stagger(i, 8) + 15}
          />
        ))}
      </div>
    </div>
  );
};
