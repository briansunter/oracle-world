import React from "react";
import { useCurrentFrame, useVideoConfig, spring, interpolate } from "remotion";
import { colors } from "../lib/colors";
import { fonts } from "../lib/fonts";
import { springSmooth } from "../lib/animations";

interface ModuleBoxProps {
  label: string;
  sublabel?: string;
  x: number;
  y: number;
  width: number;
  height: number;
  color: string;
  badge?: string;
  delay?: number;
}

export const ModuleBox: React.FC<ModuleBoxProps> = ({
  label,
  sublabel,
  x,
  y,
  width,
  height,
  color,
  badge,
  delay = 0,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const progress = spring({
    frame: frame - delay,
    fps,
    config: springSmooth,
  });

  const opacity = interpolate(progress, [0, 1], [0, 1]);
  const scale = interpolate(progress, [0, 1], [0.7, 1]);

  const tx = x - width / 2;
  const ty = y - height / 2;

  return (
    <g
      opacity={opacity}
      transform={`translate(${tx}, ${ty}) scale(${scale})`}
      style={{ transformOrigin: `${tx + width / 2}px ${ty + height / 2}px` }}
    >
      <rect
        width={width}
        height={height}
        rx={12}
        fill={colors.bgCard}
        stroke={color}
        strokeWidth={1.5}
        opacity={0.9}
      />
      <rect
        width={width}
        height={height}
        rx={12}
        fill="none"
        stroke={color}
        strokeWidth={1}
        opacity={0.3}
        filter="url(#glow)"
      />
      <text
        x={width / 2}
        y={sublabel ? height / 2 - 6 : height / 2 + 2}
        textAnchor="middle"
        dominantBaseline="middle"
        fill={colors.textPrimary}
        fontFamily={fonts.heading}
        fontSize={16}
        fontWeight={600}
      >
        {label}
      </text>
      {sublabel && (
        <text
          x={width / 2}
          y={height / 2 + 16}
          textAnchor="middle"
          dominantBaseline="middle"
          fill={colors.textSecondary}
          fontFamily={fonts.mono}
          fontSize={12}
        >
          {sublabel}
        </text>
      )}
      {badge && (
        <>
          <rect
            x={width - 65}
            y={-10}
            width={60}
            height={20}
            rx={10}
            fill={`${color}30`}
            stroke={color}
            strokeWidth={1}
          />
          <text
            x={width - 35}
            y={1}
            textAnchor="middle"
            dominantBaseline="middle"
            fill={color}
            fontFamily={fonts.body}
            fontSize={10}
            fontWeight={600}
          >
            {badge}
          </text>
        </>
      )}
    </g>
  );
};
