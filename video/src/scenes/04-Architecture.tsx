import React from "react";
import {
  useCurrentFrame,
  useVideoConfig,
  spring,
  interpolate,
} from "remotion";
import { colors } from "../lib/colors";
import { fonts } from "../lib/fonts";
import { fadeSlideIn, springSmooth } from "../lib/animations";
import { FloatingParticles } from "../components/FloatingParticles";
import { GridBackground } from "../components/GridBackground";

// --- Helpers ---

function hexToRgba(hex: string, alpha: number): string {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return `rgba(${r},${g},${b},${alpha})`;
}

// --- Sub-components ---

const Region: React.FC<{
  x: number;
  y: number;
  w: number;
  h: number;
  color: string;
  label: string;
  dashed?: boolean;
  badge?: string;
  delay: number;
  frame: number;
  fps: number;
  fontSize?: number;
}> = ({ x, y, w, h, color, label, dashed, badge, delay, frame, fps, fontSize = 12 }) => {
  const progress = spring({
    frame: frame - delay,
    fps,
    config: springSmooth,
  });
  const opacity = interpolate(progress, [0, 1], [0, 1]);
  const badgeW = fontSize * 6;
  const badgeH = fontSize * 1.8;

  return (
    <g opacity={opacity}>
      <rect
        x={x}
        y={y}
        width={w}
        height={h}
        rx={14}
        fill={hexToRgba(color, 0.04)}
        stroke={color}
        strokeWidth={dashed ? 1 : 1.5}
        strokeDasharray={dashed ? "8 4" : undefined}
        strokeOpacity={0.5}
      />
      <text
        x={x + 14}
        y={y + fontSize * 1.7}
        fill={color}
        fontFamily={fonts.mono}
        fontSize={fontSize}
        fontWeight={500}
        opacity={0.85}
      >
        {label}
      </text>
      {badge && (
        <>
          <rect
            x={x + w - badgeW - 10}
            y={y + 6}
            width={badgeW}
            height={badgeH}
            rx={badgeH / 2}
            fill={hexToRgba(color, 0.15)}
            stroke={color}
            strokeWidth={0.8}
            strokeOpacity={0.5}
          />
          <text
            x={x + w - badgeW / 2 - 10}
            y={y + 6 + badgeH * 0.72}
            textAnchor="middle"
            fill={color}
            fontFamily={fonts.body}
            fontSize={fontSize * 0.85}
            fontWeight={600}
          >
            Optional
          </text>
        </>
      )}
    </g>
  );
};

const Box: React.FC<{
  cx: number;
  cy: number;
  w: number;
  h: number;
  color: string;
  label: string;
  sublabel: string;
  badge?: string;
  delay: number;
  frame: number;
  fps: number;
  labelSize?: number;
  subSize?: number;
}> = ({ cx, cy, w, h, color, label, sublabel, badge, delay, frame, fps, labelSize = 15, subSize = 11 }) => {
  const progress = spring({
    frame: frame - delay,
    fps,
    config: springSmooth,
  });
  const opacity = interpolate(progress, [0, 1], [0, 1]);
  const scale = interpolate(progress, [0, 1], [0.9, 1]);
  const badgeW = subSize * 5.5;
  const badgeH = subSize * 1.7;

  return (
    <g
      opacity={opacity}
      transform={`translate(${cx}, ${cy}) scale(${scale}) translate(${-cx}, ${-cy})`}
    >
      <rect
        x={cx - w / 2}
        y={cy - h / 2}
        width={w}
        height={h}
        rx={10}
        fill={colors.bgCard}
        stroke={color}
        strokeWidth={1.5}
      />
      <text
        x={cx}
        y={cy - labelSize * 0.5}
        textAnchor="middle"
        dominantBaseline="middle"
        fill={colors.textPrimary}
        fontFamily={fonts.heading}
        fontSize={labelSize}
        fontWeight={600}
      >
        {label}
      </text>
      <text
        x={cx}
        y={cy + labelSize * 0.9}
        textAnchor="middle"
        dominantBaseline="middle"
        fill={colors.textSecondary}
        fontFamily={fonts.mono}
        fontSize={subSize}
      >
        {sublabel}
      </text>
      {badge && (
        <>
          <rect
            x={cx + w / 2 - badgeW - 4}
            y={cy - h / 2 - badgeH / 2}
            width={badgeW}
            height={badgeH}
            rx={badgeH / 2}
            fill={hexToRgba(color, 0.2)}
            stroke={color}
            strokeWidth={0.8}
            strokeOpacity={0.6}
          />
          <text
            x={cx + w / 2 - badgeW / 2 - 4}
            y={cy - h / 2 + badgeH * 0.2}
            textAnchor="middle"
            fill={color}
            fontFamily={fonts.body}
            fontSize={subSize * 0.85}
            fontWeight={600}
          >
            Optional
          </text>
        </>
      )}
    </g>
  );
};

const Arrow: React.FC<{
  points: [number, number][];
  color: string;
  delay: number;
  frame: number;
  fps: number;
}> = ({ points, color, delay, frame, fps }) => {
  const progress = spring({
    frame: frame - delay,
    fps,
    config: springSmooth,
  });

  let totalLen = 0;
  const segments: number[] = [];
  for (let i = 1; i < points.length; i++) {
    const dx = points[i][0] - points[i - 1][0];
    const dy = points[i][1] - points[i - 1][1];
    const seg = Math.sqrt(dx * dx + dy * dy);
    segments.push(seg);
    totalLen += seg;
  }
  const dashOffset = interpolate(progress, [0, 1], [totalLen, 0]);

  const last = points[points.length - 1];
  const prev = points[points.length - 2];
  const angle = Math.atan2(last[1] - prev[1], last[0] - prev[0]);
  const sz = 7;
  const headOpacity = interpolate(progress, [0.7, 1], [0, 0.8], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const al = {
    x: last[0] - sz * Math.cos(angle - Math.PI / 7),
    y: last[1] - sz * Math.sin(angle - Math.PI / 7),
  };
  const ar = {
    x: last[0] - sz * Math.cos(angle + Math.PI / 7),
    y: last[1] - sz * Math.sin(angle + Math.PI / 7),
  };

  const dotCycle = ((frame - delay) % 50) / 50;
  let dotDist = dotCycle * totalLen;
  let dotX = points[0][0];
  let dotY = points[0][1];
  for (let i = 0; i < segments.length; i++) {
    if (dotDist <= segments[i]) {
      const t = dotDist / segments[i];
      dotX = points[i][0] + t * (points[i + 1][0] - points[i][0]);
      dotY = points[i][1] + t * (points[i + 1][1] - points[i][1]);
      break;
    }
    dotDist -= segments[i];
  }
  const dotOpacity =
    progress > 0.9
      ? interpolate(Math.sin(dotCycle * Math.PI), [0, 1], [0.05, 0.5])
      : 0;

  const pathD = points.map((p, i) => (i === 0 ? `M${p[0]},${p[1]}` : `L${p[0]},${p[1]}`)).join(" ");

  return (
    <g>
      <path
        d={pathD}
        fill="none"
        stroke={color}
        strokeWidth={1.8}
        strokeDasharray={totalLen}
        strokeDashoffset={dashOffset}
        opacity={0.55}
      />
      <polygon
        points={`${last[0]},${last[1]} ${al.x},${al.y} ${ar.x},${ar.y}`}
        fill={color}
        opacity={headOpacity}
      />
      <circle cx={dotX} cy={dotY} r={3} fill={color} opacity={dotOpacity} />
    </g>
  );
};

// --- Landscape diagram ---

const LandscapeDiagram: React.FC<{ frame: number; fps: number }> = ({ frame, fps }) => {
  const inetProgress = spring({ frame: frame - 10, fps, config: springSmooth });
  const inetOpacity = interpolate(inetProgress, [0, 1], [0, 1]);

  const VCN = { x: 155, y: 20, w: 1290, h: 470 };
  const PUB = { x: 185, y: 65, w: 620, h: 400 };
  const PRIV = { x: 835, y: 65, w: 580, h: 400 };

  return (
    <svg width={1920} height={800} viewBox="0 0 1600 530" style={{ marginTop: 40 }}>
      {/* Internet icon */}
      <g opacity={inetOpacity}>
        <circle cx={60} cy={260} r={28} fill="none" stroke={colors.textSecondary} strokeWidth={1.2} />
        <ellipse cx={60} cy={260} rx={28} ry={15} fill="none" stroke={colors.textSecondary} strokeWidth={0.7} opacity={0.4} />
        <line x1={60} y1={232} x2={60} y2={288} stroke={colors.textSecondary} strokeWidth={0.7} opacity={0.4} />
        <text x={60} y={306} textAnchor="middle" fill={colors.textSecondary} fontFamily={fonts.body} fontSize={12}>Internet</text>
      </g>

      <Region x={VCN.x} y={VCN.y} w={VCN.w} h={VCN.h} color={colors.blue} label="VCN  10.0.0.0/16" delay={5} frame={frame} fps={fps} />
      <Region x={PUB.x} y={PUB.y} w={PUB.w} h={PUB.h} color={colors.cyan} label="Public Subnet  10.0.1.0/24" dashed delay={10} frame={frame} fps={fps} />
      <Region x={PRIV.x} y={PRIV.y} w={PRIV.w} h={PRIV.h} color={colors.purple} label="Private Subnet  10.0.2.0/24" badge="Optional" dashed delay={12} frame={frame} fps={fps} />

      <Box cx={420} cy={240} w={220} h={70} color={colors.green} label="ARM Compute" sublabel="A1.Flex | 4 OCPU | 24 GB" delay={18} frame={frame} fps={fps} />
      <Box cx={420} cy={380} w={190} h={65} color={colors.green} label="Block Storage" sublabel="150 GB | /data" delay={24} frame={frame} fps={fps} />
      <Box cx={1125} cy={240} w={220} h={70} color={colors.purple} label="MySQL HeatWave" sublabel="50 GB | Always Free" delay={30} frame={frame} fps={fps} />
      <Box cx={1125} cy={380} w={220} h={65} color={colors.pink} label="Object Storage" sublabel="S3-Compatible | 20 GB" badge="Optional" delay={36} frame={frame} fps={fps} />

      {/* Internet -> Compute */}
      <Arrow points={[[92, 260], [310, 240]]} color={colors.textSecondary} delay={42} frame={frame} fps={fps} />
      {/* Compute -> Block Storage */}
      <Arrow points={[[420, 275], [420, 348]]} color={colors.green} delay={48} frame={frame} fps={fps} />
      {/* Compute -> MySQL */}
      <Arrow points={[[530, 240], [1015, 240]]} color={colors.purple} delay={52} frame={frame} fps={fps} />
      {/* Compute -> Object Storage */}
      <Arrow points={[[530, 260], [850, 260], [850, 380], [1015, 380]]} color={colors.pink} delay={56} frame={frame} fps={fps} />
    </svg>
  );
};

// --- Vertical diagram (top-to-bottom flow) ---

const VerticalDiagram: React.FC<{ frame: number; fps: number }> = ({ frame, fps }) => {
  const inetProgress = spring({ frame: frame - 10, fps, config: springSmooth });
  const inetOpacity = interpolate(inetProgress, [0, 1], [0, 1]);

  // Vertical layout: centered column, resources stacked top-to-bottom
  // viewBox: 700 wide x 1200 tall
  const VCN = { x: 30, y: 100, w: 640, h: 1060 };
  const PUB = { x: 50, y: 145, w: 600, h: 530 };
  const PRIV = { x: 50, y: 700, w: 600, h: 440 };

  const cx = 350; // center x
  const bw = 320; // box width
  const bh = 100; // box height
  const ls = 22;  // label size
  const ss = 16;  // sublabel size
  const rs = 18;  // region label size

  return (
    <svg
      width="100%"
      viewBox="0 0 700 1200"
      preserveAspectRatio="xMidYMid meet"
      style={{ maxHeight: 1600, padding: "0 20px" }}
    >
      {/* Internet icon */}
      <g opacity={inetOpacity}>
        <circle cx={cx} cy={40} r={32} fill="none" stroke={colors.textSecondary} strokeWidth={1.5} />
        <ellipse cx={cx} cy={40} rx={32} ry={17} fill="none" stroke={colors.textSecondary} strokeWidth={0.8} opacity={0.4} />
        <line x1={cx} y1={8} x2={cx} y2={72} stroke={colors.textSecondary} strokeWidth={0.8} opacity={0.4} />
        <text x={cx} y={90} textAnchor="middle" fill={colors.textSecondary} fontFamily={fonts.body} fontSize={16}>Internet</text>
      </g>

      <Region x={VCN.x} y={VCN.y} w={VCN.w} h={VCN.h} color={colors.blue} label="VCN  10.0.0.0/16" delay={5} frame={frame} fps={fps} fontSize={rs} />
      <Region x={PUB.x} y={PUB.y} w={PUB.w} h={PUB.h} color={colors.cyan} label="Public Subnet  10.0.1.0/24" dashed delay={10} frame={frame} fps={fps} fontSize={rs} />
      <Region x={PRIV.x} y={PRIV.y} w={PRIV.w} h={PRIV.h} color={colors.purple} label="Private Subnet  10.0.2.0/24" badge="Optional" dashed delay={12} frame={frame} fps={fps} fontSize={rs} />

      {/* Compute */}
      <Box cx={cx} cy={270} w={bw} h={bh} color={colors.green} label="ARM Compute" sublabel="A1.Flex | 4 OCPU | 24 GB" delay={18} frame={frame} fps={fps} labelSize={ls} subSize={ss} />

      {/* Block Storage */}
      <Box cx={cx} cy={430} w={bw} h={bh} color={colors.green} label="Block Storage" sublabel="150 GB | /data" delay={24} frame={frame} fps={fps} labelSize={ls} subSize={ss} />

      {/* MySQL */}
      <Box cx={cx} cy={810} w={bw} h={bh} color={colors.purple} label="MySQL HeatWave" sublabel="50 GB | Always Free" delay={30} frame={frame} fps={fps} labelSize={ls} subSize={ss} />

      {/* Object Storage */}
      <Box cx={cx} cy={980} w={bw} h={bh} color={colors.pink} label="Object Storage" sublabel="S3-Compatible | 20 GB" badge="Optional" delay={36} frame={frame} fps={fps} labelSize={ls} subSize={ss} />

      {/* Arrows — vertical flow */}
      {/* Internet -> Compute */}
      <Arrow points={[[cx, 95], [cx, 220]]} color={colors.textSecondary} delay={42} frame={frame} fps={fps} />
      {/* Compute -> Block Storage */}
      <Arrow points={[[cx, 320], [cx, 380]]} color={colors.green} delay={48} frame={frame} fps={fps} />
      {/* Compute -> MySQL (down through subnet boundary) */}
      <Arrow points={[[cx + 60, 320], [cx + 60, 760]]} color={colors.purple} delay={52} frame={frame} fps={fps} />
      {/* Compute -> Object Storage (down, offset) */}
      <Arrow points={[[cx - 60, 320], [cx - 60, 690], [cx - 60, 930]]} color={colors.pink} delay={56} frame={frame} fps={fps} />
    </svg>
  );
};

// --- Main scene ---

export const Architecture: React.FC = () => {
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
        justifyContent: isVertical ? "flex-start" : "center",
        position: "relative",
        overflow: "hidden",
      }}
    >
      <GridBackground />
      <FloatingParticles count={12} maxOpacity={0.1} />

      {/* Title */}
      <div
        style={{
          ...fadeSlideIn(frame, fps, 0),
          marginTop: isVertical ? 80 : 0,
          position: isVertical ? "relative" : "absolute",
          top: isVertical ? undefined : 28,
          left: 0,
          right: 0,
          textAlign: "center",
          marginBottom: isVertical ? 10 : 0,
        }}
      >
        <span
          style={{
            fontFamily: fonts.heading,
            fontSize: isVertical ? 52 : 40,
            fontWeight: 700,
            color: colors.textPrimary,
          }}
        >
          Architecture
        </span>
      </div>

      {isVertical ? (
        <VerticalDiagram frame={frame} fps={fps} />
      ) : (
        <LandscapeDiagram frame={frame} fps={fps} />
      )}
    </div>
  );
};
