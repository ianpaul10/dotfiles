/**
 * sound-notify: Play a macOS system sound when pi finishes a response and is
 * waiting for input. Uses `afplay` — no dependencies, works on any macOS install.
 *
 * Customize the sound by changing SOUND below to any path under
 * /System/Library/Sounds/ (Basso, Blow, Bottle, Frog, Funk, Glass, Hero,
 * Morse, Ping, Pop, Purr, Sosumi, Submarine, Tink).
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { execFile } from "node:child_process";

const SOUND = "/System/Library/Sounds/Tink.aiff";

export default function (pi: ExtensionAPI) {
	pi.on("agent_end", async () => {
		// Fire-and-forget: don't await, don't block pi, silently skip on non-macOS
		execFile("afplay", [SOUND], { timeout: 5000 }, () => {});
	});
}
