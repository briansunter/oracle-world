import { interpolate, spring } from "remotion";

export const springSmooth = { damping: 200 };

export const springSnappy = { damping: 20, stiffness: 200 };

export const springBouncy = { damping: 8 };

export const springHeavy = { damping: 15, stiffness: 80, mass: 2 };

export function fadeSlideIn(
  frame: number,
  fps: number,
  delay: number = 0,
  direction: "up" | "down" | "left" | "right" = "up",
  distance: number = 40,
) {
  const progress = spring({
    frame: frame - delay,
    fps,
    config: springSmooth,
  });

  const opacity = interpolate(progress, [0, 1], [0, 1]);

  const translateMap = {
    up: `translateY(${interpolate(progress, [0, 1], [distance, 0])}px)`,
    down: `translateY(${interpolate(progress, [0, 1], [-distance, 0])}px)`,
    left: `translateX(${interpolate(progress, [0, 1], [distance, 0])}px)`,
    right: `translateX(${interpolate(progress, [0, 1], [-distance, 0])}px)`,
  };

  return {
    opacity,
    transform: translateMap[direction],
  };
}

export function scaleIn(frame: number, fps: number, delay: number = 0) {
  const progress = spring({
    frame: frame - delay,
    fps,
    config: springSnappy,
  });

  return {
    opacity: interpolate(progress, [0, 1], [0, 1]),
    transform: `scale(${interpolate(progress, [0, 1], [0.5, 1])})`,
  };
}

export function animatedNumber(
  frame: number,
  fps: number,
  target: number,
  delay: number = 0,
  durationFrames: number = 30,
): number {
  const progress = interpolate(frame - delay, [0, durationFrames], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  return Math.round(progress * target);
}

export function stagger(index: number, delayPerItem: number = 5): number {
  return index * delayPerItem;
}

export function typewriter(
  text: string,
  frame: number,
  startFrame: number,
  charsPerFrame: number = 0.8,
): string {
  const elapsed = Math.max(0, frame - startFrame);
  const chars = Math.floor(elapsed * charsPerFrame);
  return text.substring(0, chars);
}
