import React from "react";
import { TransitionSeries, linearTiming } from "@remotion/transitions";
import { fade } from "@remotion/transitions/fade";
import { slide } from "@remotion/transitions/slide";
import { Intro } from "./scenes/01-Intro";
import { Problem } from "./scenes/02-Problem";
import { WhatYouGet } from "./scenes/03-WhatYouGet";
import { Architecture } from "./scenes/04-Architecture";
import { Deploy } from "./scenes/05-Deploy";
import { Features } from "./scenes/06-Features";
import { Outro } from "./scenes/07-Outro";

// 6 transitions x 15 frames = 90 frames of overlap
// Total sequence frames = 1590, output = 1590 - 90 = 1500
const T = 15;

export const LaunchVideo: React.FC = () => {
  return (
    <TransitionSeries>
      {/* Scene 1: Intro — logo reveal, typewriter title, tagline */}
      <TransitionSeries.Sequence durationInFrames={165}>
        <Intro />
      </TransitionSeries.Sequence>

      <TransitionSeries.Transition
        presentation={fade()}
        timing={linearTiming({ durationInFrames: T })}
      />

      {/* Scene 2: Problem — cloud costs struck through, $0 reveal */}
      <TransitionSeries.Sequence durationInFrames={195}>
        <Problem />
      </TransitionSeries.Sequence>

      <TransitionSeries.Transition
        presentation={slide({ direction: "from-right" })}
        timing={linearTiming({ durationInFrames: T })}
      />

      {/* Scene 3: What You Get — 3x2 spec card grid */}
      <TransitionSeries.Sequence durationInFrames={285}>
        <WhatYouGet />
      </TransitionSeries.Sequence>

      <TransitionSeries.Transition
        presentation={fade()}
        timing={linearTiming({ durationInFrames: T })}
      />

      {/* Scene 4: Architecture — animated SVG network diagram */}
      <TransitionSeries.Sequence durationInFrames={315}>
        <Architecture />
      </TransitionSeries.Sequence>

      <TransitionSeries.Transition
        presentation={slide({ direction: "from-right" })}
        timing={linearTiming({ durationInFrames: T })}
      />

      {/* Scene 5: Deploy — terminal with typed commands */}
      <TransitionSeries.Sequence durationInFrames={255}>
        <Deploy />
      </TransitionSeries.Sequence>

      <TransitionSeries.Transition
        presentation={fade()}
        timing={linearTiming({ durationInFrames: T })}
      />

      {/* Scene 6: Features — 4x2 feature grid */}
      <TransitionSeries.Sequence durationInFrames={195}>
        <Features />
      </TransitionSeries.Sequence>

      <TransitionSeries.Transition
        presentation={fade()}
        timing={linearTiming({ durationInFrames: T })}
      />

      {/* Scene 7: Outro — CTA, GitHub link, command badges */}
      <TransitionSeries.Sequence durationInFrames={180}>
        <Outro />
      </TransitionSeries.Sequence>
    </TransitionSeries>
  );
};
