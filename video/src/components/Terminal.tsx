import React from "react";
import { colors } from "../lib/colors";
import { fonts } from "../lib/fonts";

interface TerminalProps {
  children: React.ReactNode;
  title?: string;
  style?: React.CSSProperties;
}

export const Terminal: React.FC<TerminalProps> = ({
  children,
  title = "terminal",
  style,
}) => {
  return (
    <div
      style={{
        backgroundColor: "#0D1117",
        border: `1px solid ${colors.border}`,
        borderRadius: 12,
        overflow: "hidden",
        width: "100%",
        maxWidth: 1000,
        boxShadow: "0 20px 60px rgba(0,0,0,0.5)",
        ...style,
      }}
    >
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
            fontSize: 13,
            color: colors.textMuted,
            marginLeft: 8,
          }}
        >
          {title}
        </span>
      </div>
      <div
        style={{
          padding: "20px 24px",
          fontFamily: fonts.mono,
          fontSize: 16,
          lineHeight: 1.8,
        }}
      >
        {children}
      </div>
    </div>
  );
};
