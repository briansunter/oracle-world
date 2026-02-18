import React from "react";
import { useCurrentFrame } from "remotion";
import { colors } from "../lib/colors";
import { typewriter } from "../lib/animations";

interface TerminalLineProps {
  text: string;
  startFrame: number;
  isCommand?: boolean;
  prompt?: string;
  color?: string;
  charsPerFrame?: number;
}

export const TerminalLine: React.FC<TerminalLineProps> = ({
  text,
  startFrame,
  isCommand = false,
  prompt = "$ ",
  color = colors.textSecondary,
  charsPerFrame = 0.8,
}) => {
  const frame = useCurrentFrame();

  if (frame < startFrame) return null;

  const displayText = isCommand
    ? typewriter(text, frame, startFrame, charsPerFrame)
    : text;

  const showCursor = isCommand && displayText.length < text.length;

  return (
    <div style={{ display: "flex", minHeight: "1.8em" }}>
      {isCommand && (
        <span style={{ color: colors.green, marginRight: 0 }}>{prompt}</span>
      )}
      <span style={{ color: isCommand ? colors.textPrimary : color }}>
        {displayText}
      </span>
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
