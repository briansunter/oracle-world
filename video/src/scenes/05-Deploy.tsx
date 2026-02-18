import React from "react";
import {
  useCurrentFrame,
  useVideoConfig,
  spring,
  interpolate,
} from "remotion";
import { colors } from "../lib/colors";
import { fonts } from "../lib/fonts";
import { fadeSlideIn, springSmooth, typewriter } from "../lib/animations";
import { FloatingParticles } from "../components/FloatingParticles";
import { GridBackground } from "../components/GridBackground";

// --- Claude Code styled terminal ---

const ClaudeCodeLine: React.FC<{
  text: string;
  startFrame: number;
  type: "command" | "output" | "success" | "heading" | "value" | "blank";
  color?: string;
}> = ({ text, startFrame, type, color }) => {
  const frame = useCurrentFrame();

  if (frame < startFrame) return null;

  const isTyped = type === "command";
  const displayText = isTyped
    ? typewriter(text, frame, startFrame, 1.2)
    : text;

  const showCursor = isTyped && displayText.length < text.length;

  const textColor =
    color ??
    (type === "success"
      ? colors.green
      : type === "heading"
        ? colors.textSecondary
        : type === "value"
          ? colors.amber
          : type === "command"
            ? colors.textPrimary
            : colors.textSecondary);

  return (
    <div style={{ display: "flex", minHeight: "1.7em", alignItems: "center" }}>
      {type === "command" && (
        <span
          style={{
            color: colors.purple,
            marginRight: 8,
            fontWeight: 700,
            fontSize: 17,
          }}
        >
          &gt;
        </span>
      )}
      <span style={{ color: textColor }}>{displayText}</span>
      {showCursor && (
        <span
          style={{
            display: "inline-block",
            width: 8,
            height: "1em",
            backgroundColor: colors.textPrimary,
            marginLeft: 2,
            opacity: Math.sin(frame * 0.3) > 0 ? 1 : 0,
          }}
        />
      )}
    </div>
  );
};

const lines: {
  text: string;
  startFrame: number;
  type: "command" | "output" | "success" | "heading" | "value" | "blank";
  color?: string;
}[] = [
  { text: "/setup", startFrame: 20, type: "command" },
  { text: "", startFrame: 38, type: "blank" },
  {
    text: "\u2713 Detected OCI config (~/.oci/config)",
    startFrame: 42,
    type: "success",
  },
  {
    text: "\u2713 Generated .env with state encryption passphrase",
    startFrame: 55,
    type: "success",
  },
  {
    text: "\u2713 Created oci-prod.auto.tfvars from template",
    startFrame: 68,
    type: "success",
  },
  { text: "", startFrame: 78, type: "blank" },
  {
    text: "Initializing providers...",
    startFrame: 82,
    type: "output",
    color: colors.textMuted,
  },
  {
    text: "\u2713 terraform init complete",
    startFrame: 100,
    type: "success",
  },
  { text: "", startFrame: 108, type: "blank" },
  {
    text: "Planning infrastructure...",
    startFrame: 112,
    type: "output",
    color: colors.textMuted,
  },
  {
    text: "Plan: 23 to add, 0 to change, 0 to destroy.",
    startFrame: 130,
    type: "output",
    color: colors.cyan,
  },
  { text: "", startFrame: 138, type: "blank" },
  {
    text: "Applying...",
    startFrame: 142,
    type: "output",
    color: colors.textMuted,
  },
  {
    text: "\u2713 Apply complete! 23 resources created.",
    startFrame: 168,
    type: "success",
  },
  { text: "", startFrame: 176, type: "blank" },
  { text: "Outputs:", startFrame: 180, type: "heading" },
  {
    text: "  instance_ip   = 140.238.xxx.xxx",
    startFrame: 190,
    type: "value",
  },
];

export const Deploy: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps, width, height } = useVideoConfig();
  const isVertical = height > width;

  const badgeProgress = spring({
    frame: frame - 5,
    fps,
    config: springSmooth,
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
        padding: isVertical ? 40 : 80,
      }}
    >
      <GridBackground />
      <FloatingParticles count={10} maxOpacity={0.1} />

      <div style={{ ...fadeSlideIn(frame, fps, 0), marginBottom: 40 }}>
        <span
          style={{
            fontFamily: fonts.heading,
            fontSize: isVertical ? 56 : 40,
            fontWeight: 700,
            color: colors.textPrimary,
          }}
        >
          One Command to Production
        </span>
      </div>

      {/* Claude Code badge */}
      <div
        style={{
          ...fadeSlideIn(frame, fps, 3),
          marginBottom: 30,
          display: "flex",
          alignItems: "center",
          gap: 10,
        }}
      >
        <div
          style={{
            opacity: interpolate(badgeProgress, [0, 1], [0, 1]),
            transform: `scale(${interpolate(badgeProgress, [0, 1], [0.8, 1])})`,
            fontFamily: fonts.mono,
            fontSize: isVertical ? 24 : 16,
            fontWeight: 600,
            color: colors.purple,
            backgroundColor: `${colors.purple}15`,
            border: `1px solid ${colors.purple}40`,
            borderRadius: 20,
            padding: "8px 20px",
            display: "flex",
            alignItems: "center",
            gap: 8,
          }}
        >
          <span style={{ fontSize: isVertical ? 26 : 18 }}>&#10023;</span>
          Claude Code
        </div>
      </div>

      {/* Claude Code terminal */}
      <div style={fadeSlideIn(frame, fps, 5)}>
        <div
          style={{
            backgroundColor: "#0D1117",
            border: `1px solid ${colors.border}`,
            borderRadius: 12,
            overflow: "hidden",
            width: "100%",
            maxWidth: isVertical ? "95%" : 1000,
            boxShadow: `0 20px 60px rgba(0,0,0,0.5), 0 0 40px ${colors.purple}10`,
          }}
        >
          {/* Title bar */}
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 8,
              padding: "12px 16px",
              backgroundColor: "#161B22",
              borderBottom: `1px solid ${colors.border}`,
            }}
          >
            <div
              style={{
                width: 12,
                height: 12,
                borderRadius: "50%",
                backgroundColor: "#FF5F56",
              }}
            />
            <div
              style={{
                width: 12,
                height: 12,
                borderRadius: "50%",
                backgroundColor: "#FFBD2E",
              }}
            />
            <div
              style={{
                width: 12,
                height: 12,
                borderRadius: "50%",
                backgroundColor: "#27C93F",
              }}
            />
            <span
              style={{
                fontFamily: fonts.mono,
                fontSize: isVertical ? 20 : 13,
                color: colors.textMuted,
                marginLeft: 8,
              }}
            >
              claude ~/oracle-world
            </span>
          </div>

          {/* Content */}
          <div
            style={{
              padding: isVertical ? "32px 36px" : "20px 24px",
              fontFamily: fonts.mono,
              fontSize: isVertical ? 26 : 15,
              lineHeight: 1.7,
            }}
          >
            {lines.map((line, i) => (
              <ClaudeCodeLine
                key={i}
                text={line.text}
                startFrame={line.startFrame}
                type={line.type}
                color={line.color}
              />
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};
