import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { CONFIG_DIR_NAME, getAgentDir } from "@earendil-works/pi-coding-agent";

interface ExtensionSettings {
  my?: {
    shellCommandPrefix?: string;
  };
}

interface CachedConfig {
  prefix: string | null;
}

/**
 * Load and merge settings from global and project settings.json files.
 * Project settings override global settings.
 * Uses Pi's SDK constants (getAgentDir, CONFIG_DIR_NAME) to support
 * rebranded distributions that may use different directory names.
 */
function loadSettings(cwd: string): ExtensionSettings {
  const globalPath = join(getAgentDir(), "settings.json");
  const projectPath = join(cwd, CONFIG_DIR_NAME, "settings.json");

  let globalSettings: ExtensionSettings = {};
  let projectSettings: ExtensionSettings = {};

  // Load global settings
  if (existsSync(globalPath)) {
    try {
      const content = readFileSync(globalPath, "utf-8");
      globalSettings = JSON.parse(content);
    } catch {
      // Silently continue with empty object if file can't be read/parsed
    }
  }

  // Load project settings
  if (existsSync(projectPath)) {
    try {
      const content = readFileSync(projectPath, "utf-8");
      projectSettings = JSON.parse(content);
    } catch {
      // Silently continue with empty object if file can't be read/parsed
    }
  }

  // Project overrides global
  return { ...globalSettings, ...projectSettings };
}

export default function (pi: ExtensionAPI) {
  // Closure variable for caching the prefix
  let cachedConfig: CachedConfig = { prefix: null };

  // Load config on session start
  pi.on("session_start", async (_event, ctx) => {
    const settings = loadSettings(ctx.cwd);
    cachedConfig = {
      prefix: settings.my?.shellCommandPrefix ?? null,
    };
  });

  // Clear cache on session shutdown (for reload)
  pi.on("session_shutdown", async () => {
    cachedConfig = { prefix: null };
  });

  // Intercept bash tool calls
  pi.on("tool_call", async (event, _ctx) => {
    // Only process bash tool calls
    if (event.toolName !== "bash") {
      return;
    }

    // Skip if no prefix configured
    if (cachedConfig.prefix === null) {
      return;
    }

    // Type assertion for bash input
    const bashInput = event.input as { command: string; timeout?: number };

    // Skip if command is empty or whitespace-only
    const trimmedCommand = bashInput.command.trim();
    if (trimmedCommand === "") {
      return;
    }

    // Prepend the prefix to the command
    bashInput.command = cachedConfig.prefix + " " + trimmedCommand;
  });
}
