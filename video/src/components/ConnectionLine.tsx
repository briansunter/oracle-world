import React from "react";
import { useCurrentFrame, useVideoConfig, spring, interpolate } from "remotion";
import { springSmooth } from "../lib/animations";
import { modules, type Connection } from "../lib/architecture-data";

interface ConnectionLineProps extends Connection {
  delay?: number;
}

export const ConnectionLine: React.FC<ConnectionLineProps> = ({
  from,
  to,
  color,
  delay = 0,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const fromModule = modules.find((m) => m.id === from);
  const toModule = modules.find((m) => m.id === to);

  if (!fromModule || !toModule) return null;

  const x1 = fromModule.x;
  const y1 = fromModule.y + fromModule.height / 2;
  const x2 = toModule.x;
  const y2 = toModule.y - toModule.height / 2;

  const progress = spring({
    frame: frame - delay,
    fps,
    config: springSmooth,
  });

  const lineLength = Math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2);
  const dashOffset = interpolate(progress, [0, 1], [lineLength, 0]);

  const dotCycle = ((frame - delay) % 60) / 60;
  const dotX = interpolate(dotCycle, [0, 1], [x1, x2]);
  const dotY = interpolate(dotCycle, [0, 1], [y1, y2]);
  const dotOpacity =
    progress > 0.8
      ? interpolate(Math.sin(dotCycle * Math.PI), [0, 1], [0.2, 0.8])
      : 0;

  return (
    <g>
      <line
        x1={x1}
        y1={y1}
        x2={x2}
        y2={y2}
        stroke={color}
        strokeWidth={1.5}
        strokeDasharray={lineLength}
        strokeDashoffset={dashOffset}
        opacity={0.6}
      />
      <circle cx={dotX} cy={dotY} r={4} fill={color} opacity={dotOpacity} />
    </g>
  );
};
