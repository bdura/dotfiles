/**
 * Exit Handler Extension
 * 
 * Deterministically interprets the command "exit" as a signal to shut down Pi.
 * This provides a guaranteed way to exit Pi by typing "exit" at the prompt.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("input", async (event, ctx) => {
    // Only handle interactive input (not RPC or extension-injected messages)
    if (event.source !== "interactive") {
      return { action: "continue" };
    }

    // Check if the input is exactly "exit" (case-insensitive)
    const trimmedInput = event.text.trim();
    if (trimmedInput.toLowerCase() === "exit") {
      // Show exit message
      ctx.ui.notify("Goodbye!", "info");
      
      // Trigger graceful shutdown
      ctx.shutdown();
      
      // Mark as handled so Pi doesn't process it as a regular command
      return { action: "handled" };
    }

    // Continue with normal processing for all other input
    return { action: "continue" };
  });
}
