import React from "react";
import { Composition } from "remotion";
import { LaunchVideo } from "./LaunchVideo";

export const Root: React.FC = () => {
  return (
    <>
      <Composition
        id="LaunchVideo"
        component={LaunchVideo}
        durationInFrames={1500}
        fps={30}
        width={1920}
        height={1080}
      />
      <Composition
        id="LaunchVideoVertical"
        component={LaunchVideo}
        durationInFrames={1500}
        fps={30}
        width={1080}
        height={1920}
      />
    </>
  );
};
