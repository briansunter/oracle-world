import { loadFont as loadSpaceGrotesk } from "@remotion/google-fonts/SpaceGrotesk";
import { loadFont as loadInter } from "@remotion/google-fonts/Inter";
import { loadFont as loadJetBrainsMono } from "@remotion/google-fonts/JetBrainsMono";

const { fontFamily: spaceGrotesk } = loadSpaceGrotesk("normal", {
  weights: ["400", "500", "600", "700"],
  subsets: ["latin"],
});

const { fontFamily: inter } = loadInter("normal", {
  weights: ["400", "500", "600", "700"],
  subsets: ["latin"],
});

const { fontFamily: jetBrainsMono } = loadJetBrainsMono("normal", {
  weights: ["400", "500", "600", "700"],
  subsets: ["latin"],
});

export const fonts = {
  heading: spaceGrotesk,
  body: inter,
  mono: jetBrainsMono,
};
