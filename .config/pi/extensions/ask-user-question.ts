/**
 * ask_user_question - Simple vendorized Pi extension
 * 
 * A structured questionnaire tool that lets the model ask users clarifying questions
 * with typed options. This is a simplified, auditable version based on the
 * functionality of @juicesharp/rpiv-ask-user-question.
 * 
 * Features:
 * - Single or multiple questions with tab navigation
 * - Single-select with free-text "Type something." fallback
 * - Multi-select support
 * - Simple, easy-to-audit codebase
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Key, matchesKey, Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";

// ============================================================================
// Configuration
// ============================================================================

const MAX_QUESTIONS = 4;
const MIN_OPTIONS = 2;
const MAX_OPTIONS = 4;
const MAX_HEADER_LENGTH = 16;
const MAX_LABEL_LENGTH = 60;

// ============================================================================
// Types
// ============================================================================

const OptionSchema = Type.Object({
  label: Type.String({
    maxLength: MAX_LABEL_LENGTH,
    description: `Display label (1-5 words, max ${MAX_LABEL_LENGTH} chars)`,
  }),
  description: Type.String({ description: "Explains what this choice means" }),
  preview: Type.Optional(Type.String({ description: "Optional markdown preview" })),
});

const QuestionSchema = Type.Object({
  question: Type.String({ description: "The question to ask, ending with ?" }),
  header: Type.String({
    maxLength: MAX_HEADER_LENGTH,
    description: `Short label (max ${MAX_HEADER_LENGTH} chars)`,
  }),
  options: Type.Array(OptionSchema, {
    minItems: MIN_OPTIONS,
    maxItems: MAX_OPTIONS,
    description: `Available choices (${MIN_OPTIONS}-${MAX_OPTIONS})`,
  }),
  multiSelect: Type.Optional(Type.Boolean({
    default: false,
    description: "Allow multiple selections",
  })),
});

const ParamsSchema = Type.Object({
  questions: Type.Array(QuestionSchema, {
    minItems: 1,
    maxItems: MAX_QUESTIONS,
    description: `Questions (1-${MAX_QUESTIONS})`,
  }),
});

// Internal types
type Option = { label: string; description: string; preview?: string };
type Question = { question: string; header: string; options: Option[]; multiSelect?: boolean };
type Params = { questions: Question[] };

const RESERVED = new Set(["Other", "Type something.", "Next →", "Chat about this"]);

// ============================================================================
// Validation
// ============================================================================

function validate(params: Params): string | null {
  if (params.questions.length === 0) return "At least one question required";
  if (params.questions.length > MAX_QUESTIONS) return `Max ${MAX_QUESTIONS} questions`;
  
  const seenQ = new Set<string>();
  for (const q of params.questions) {
    if (seenQ.has(q.question)) return "Duplicate question";
    seenQ.add(q.question);
    
    if (q.options.length < MIN_OPTIONS) return `Each question needs ${MIN_OPTIONS}+ options`;
    if (q.options.length > MAX_OPTIONS) return `Each question max ${MAX_OPTIONS} options`;
    
    const seenL = new Set<string>();
    for (const o of q.options) {
      if (RESERVED.has(o.label)) return `Reserved label: ${o.label}`;
      if (seenL.has(o.label)) return `Duplicate option label: ${o.label}`;
      seenL.add(o.label);
    }
  }
  return null;
}

// ============================================================================
// Result Building
// ============================================================================

function errorResult(msg: string): any {
  return {
    content: [{ type: "text", text: msg }],
    details: { answers: [], cancelled: true, error: "validation" },
  };
}

function successResult(result: any, params: Params): any {
  const lines: string[] = [];
  for (const a of result.answers) {
    const q = params.questions[a.qIndex];
    if (a.kind === "custom") {
      lines.push(`Q${a.qIndex + 1} (${q.header}): user wrote: ${a.value}`);
    } else if (a.kind === "multi") {
      lines.push(`Q${a.qIndex + 1} (${q.header}): selected ${a.selected.length} options: ${a.selected.join(", ")}`);
    } else {
      lines.push(`Q${a.qIndex + 1} (${q.header}): user selected: ${a.value}`);
    }
  }
  return {
    content: [{ type: "text", text: lines.join("\n") }],
    details: result,
  };
}

// ============================================================================
// UI Session
// ============================================================================

class QuestionnaireUI {
  private params: Params;
  private tui: any;
  private theme: any;
  private done: (r: any) => void;
  
  // State
  private tab = 0;                    // Current question index or submit tab
  private cursor: number[] = [];      // Option cursor per tab
  private selections: Set<string>[] = []; // Multi-select selections per tab
  private customText = "";            // Free text input
  private inputMode = false;          // In custom text input
  private inputTab = 0;               // Which question's custom input
  private answers: any[] = [];        // Collected answers
  private cached: string[] | null = null;
  
  constructor(tui: any, theme: any, params: Params, done: (r: any) => void) {
    this.tui = tui;
    this.theme = theme;
    this.params = params;
    this.done = done;
    
    this.cursor = Array(params.questions.length).fill(0);
    this.selections = Array(params.questions.length).fill(null).map(() => new Set());
    this.answers = Array(params.questions.length).fill(null);
  }
  
  private get isMulti(): boolean {
    return this.params.questions.length > 1;
  }
  
  private get isSubmit(): boolean {
    return this.tab === this.params.questions.length;
  }
  
  private get q(): Question | null {
    return this.params.questions[this.tab] ?? null;
  }
  
  private get items(): any[] {
    const q = this.q;
    if (!q) return [];
    
    const items: any[] = q.options.map((o, i) => ({
      type: "option",
      label: o.label,
      description: o.description,
      preview: o.preview,
      index: i,
    }));
    
    // Add sentinels
    if (!q.multiSelect) {
      items.push({ type: "other", label: "Type something." });
    }
    items.push({ type: "chat", label: "Chat about this" });
    if (q.multiSelect) {
      items.push({ type: "next", label: "Next →" });
    }
    
    return items;
  }
  
  private get cur(): number {
    return this.cursor[this.tab] ?? 0;
  }
  
  private set cur(v: number) {
    this.cursor[this.tab] = Math.max(0, Math.min(this.items.length - 1, v));
  }
  
  private allDone(): boolean {
    return this.answers.every((a) => a !== null);
  }
  
  private refresh(): void {
    this.cached = null;
    this.tui.requestRender();
  }
  
  private submit(cancelled: boolean): void {
    this.done({
      answers: this.answers,
      cancelled: cancelled,
    });
  }
  
  private saveAndAdvance(): void {
    if (!this.isMulti) {
      this.submit(false);
      return;
    }
    
    if (this.tab < this.params.questions.length - 1) {
      this.tab++;
    } else {
      this.tab = this.params.questions.length;
    }
    this.cur = 0;
    this.refresh();
  }
  
  private handleInput(data: string): { consume: boolean } | undefined {
    // Custom text input
    if (this.inputMode) {
      if (matchesKey(data, Key.enter)) {
        this.answers[this.inputTab] = {
          qIndex: this.inputTab,
          kind: "custom",
          value: this.customText,
        };
        this.inputMode = false;
        this.saveAndAdvance();
        return { consume: true };
      }
      if (matchesKey(data, Key.escape)) {
        this.inputMode = false;
        this.customText = "";
        this.refresh();
        return { consume: true };
      }
      if (data.length === 1) {
        this.customText += data;
        this.refresh();
        return { consume: true };
      }
      if (matchesKey(data, Key.backspace)) {
        this.customText = this.customText.slice(0, -1);
        this.refresh();
        return { consume: true };
      }
      return undefined;
    }
    
    // Tab navigation
    if (this.isMulti) {
      if (matchesKey(data, Key.tab) || matchesKey(data, Key.right)) {
        this.tab = (this.tab + 1) % (this.params.questions.length + 1);
        this.cur = 0;
        this.refresh();
        return { consume: true };
      }
      if (matchesKey(data, Key.shift("tab")) || matchesKey(data, Key.left)) {
        this.tab = (this.tab - 1 + this.params.questions.length + 1) % (this.params.questions.length + 1);
        this.cur = 0;
        this.refresh();
        return { consume: true };
      }
    }
    
    // Submit tab
    if (this.isSubmit) {
      if (matchesKey(data, Key.enter) && this.allDone()) {
        this.submit(false);
        return { consume: true };
      }
      if (matchesKey(data, Key.escape)) {
        this.submit(true);
        return { consume: true };
      }
      return undefined;
    }
    
    const q = this.q;
    const items = this.items;
    if (!q || items.length === 0) return undefined;
    
    // Navigation
    if (matchesKey(data, Key.up)) { this.cur--; this.refresh(); return { consume: true }; }
    if (matchesKey(data, Key.down)) { this.cur++; this.refresh(); return { consume: true }; }
    
    // Selection
    if (matchesKey(data, Key.enter)) {
      const item = items[this.cur];
      
      if (item.type === "option") {
        if (q.multiSelect) {
          const sel = this.selections[this.tab];
          if (sel.has(item.label)) {
            sel.delete(item.label);
          } else {
            sel.add(item.label);
          }
          this.answers[this.tab] = {
            qIndex: this.tab,
            kind: "multi",
            selected: Array.from(sel),
          };
          this.refresh();
        } else {
          this.answers[this.tab] = {
            qIndex: this.tab,
            kind: "option",
            value: item.label,
          };
          this.saveAndAdvance();
        }
        return { consume: true };
      }
      
      if (item.type === "other") {
        this.inputMode = true;
        this.inputTab = this.tab;
        this.customText = "";
        this.refresh();
        return { consume: true };
      }
      
      if (item.type === "next") {
        this.saveAndAdvance();
        return { consume: true };
      }
    }
    
    // Multi-select: space to toggle
    if (q.multiSelect && matchesKey(data, Key.space)) {
      const item = items[this.cur];
      if (item?.type === "option") {
        const sel = this.selections[this.tab];
        if (sel.has(item.label)) sel.delete(item.label);
        else sel.add(item.label);
        this.answers[this.tab] = {
          qIndex: this.tab,
          kind: "multi",
          selected: Array.from(sel),
        };
        this.refresh();
      }
      return { consume: true };
    }
    
    // Cancel
    if (matchesKey(data, Key.escape)) {
      this.submit(true);
      return { consume: true };
    }
    
    return undefined;
  }
  
  private render(width: number): string[] {
    if (this.cached) return this.cached;
    
    const lines: string[] = [];
    const w = Math.max(1, width);
    
    // Simple text wrapping
    const wrap = (text: string, indent: number = 0): void => {
      const prefix = " ".repeat(indent);
      let remaining = text;
      while (remaining.length > 0) {
        let maxLen = w - indent;
        if (remaining.length <= maxLen) {
          lines.push(prefix + remaining);
          remaining = "";
        } else {
          // Find last space within limit
          let splitAt = maxLen;
          while (splitAt > 0 && remaining[splitAt] !== " " && remaining[splitAt] !== "-") splitAt--;
          if (splitAt === 0) splitAt = maxLen;
          lines.push(prefix + remaining.slice(0, splitAt));
          remaining = remaining.slice(splitAt).trimStart();
        }
      }
    };
    
    // Border
    lines.push(this.theme.fg("accent", "─".repeat(w)));
    
    // Tab bar
    if (this.isMulti) {
      const tabs: string[] = [];
      for (let i = 0; i < this.params.questions.length; i++) {
        const active = i === this.tab;
        const done = this.answers[i] !== null;
        const lbl = this.params.questions[i].header;
        const text = ` ${done ? "✓" : "?"} ${lbl} `;
        tabs.push(active
          ? this.theme.bg("selectedBg", this.theme.fg("text", text))
          : this.theme.fg(done ? "success" : "muted", text));
      }
      const canSubmit = this.allDone();
      const submitText = " Submit ";
      tabs.push(this.tab === this.params.questions.length
        ? this.theme.bg("selectedBg", this.theme.fg("text", submitText))
        : this.theme.fg(canSubmit ? "success" : "dim", submitText));
      wrap(tabs.join(" "), 1);
      lines.push("");
    }
    
    // Question area
    const q = this.q;
    if (q) {
      wrap(q.question, 1);
      lines.push("");
      
      const items = this.items;
      const selIdx = this.cur;
      const isMulti = q.multiSelect;
      const multiSel = this.selections[this.tab];
      
      for (let i = 0; i < items.length; i++) {
        const item = items[i];
        const selected = i === selIdx;
        const isOpt = item.type === "option";
        
        // Prefix
        let prefix = "  ";
        if (isMulti && isOpt) {
          prefix = multiSel.has(item.label) ? `[${this.theme.fg("success", "x")}] ` : `[ ] `;
        } else if (selected) {
          prefix = this.theme.fg("accent", "> ");
        }
        
        // Label
        let label = item.label;
        if (isOpt) label = `${i + 1}. ${item.label}`;
        
        let color = "text";
        if (selected) color = "accent";
        if (item.type === "chat") color = "muted";
        if (item.type === "next") color = "success";
        
        wrap(prefix + this.theme.fg(color, label), 1);
        
        // Description
        if (item.description && isOpt) {
          wrap(item.description, 4);
        }
        
        // Preview (simple)
        if (item.preview && isOpt && selected) {
          lines.push("");
          wrap(this.theme.fg("muted", "Preview:"), 2);
          for (const pl of item.preview.split("\n")) {
            wrap(pl, 4);
          }
        }
        
        lines.push("");
      }
    }
    
    // Submit view
    if (this.isSubmit) {
      wrap(this.theme.fg("accent", this.theme.bold("Ready to submit")), 1);
      lines.push("");
      
      for (let i = 0; i < this.params.questions.length; i++) {
        const a = this.answers[i];
        const q = this.params.questions[i];
        
        if (a) {
          let text = `${q.header}: `;
          if (a.kind === "multi") {
            text += `Selected (${a.selected.length}): ${a.selected.join(", ")}`;
          } else if (a.kind === "custom") {
            text += `Wrote: ${a.value}`;
          } else {
            text += `Selected: ${a.value}`;
          }
          wrap(text, 2);
        } else {
          wrap(this.theme.fg("warning", `⚠ ${q.header}: Not answered`), 2);
        }
      }
      
      lines.push("");
      if (this.allDone()) {
        wrap(this.theme.fg("success", "Press Enter to submit"), 1);
      } else {
        wrap(this.theme.fg("warning", "Answer all questions first"), 1);
      }
    }
    
    // Custom input
    if (this.inputMode) {
      wrap(this.params.questions[this.inputTab].question, 1);
      lines.push("");
      wrap(this.theme.fg("muted", "Your answer:"), 1);
      lines.push(`  ${this.customText}|`);
      lines.push("");
      wrap(this.theme.fg("dim", "Enter to submit • Esc to cancel"), 1);
    }
    
    // Help
    lines.push("");
    if (this.inputMode) {
      wrap(this.theme.fg("dim", "Enter to submit • Esc to cancel"), 1);
    } else if (this.isSubmit) {
      wrap(this.theme.fg("dim", "Enter to submit • Esc to cancel"), 1);
    } else if (this.isMulti) {
      wrap(this.theme.fg("dim", "Tab/←→ navigate • ↑↓ select • Enter confirm • Space toggle • Esc cancel"), 1);
    } else {
      wrap(this.theme.fg("dim", "↑↓ navigate • Enter select • Esc cancel"), 1);
    }
    
    // Border
    lines.push(this.theme.fg("accent", "─".repeat(w)));
    
    this.cached = lines;
    return lines;
  }
  
  public get component() {
    return {
      render: (w: number) => this.render(w),
      invalidate: () => { this.cached = null; },
      handleInput: (d: string) => this.handleInput(d),
    };
  }
}

// ============================================================================
// RPC Fallback
// ============================================================================

function hasDialog(ui: any): boolean {
  return typeof ui.select === "function" && typeof ui.input === "function";
}

async function runRpc(params: Params, ui: any): Promise<any> {
  const answers: any[] = [];
  
  for (let i = 0; i < params.questions.length; i++) {
    const q = params.questions[i];
    
    if (q.multiSelect) {
      const labels = q.options.map((o) => o.label);
      const result = await ui.select(q.question, labels, { multi: true });
      if (result === null) return { answers, cancelled: true };
      answers.push({
        qIndex: i,
        kind: "multi",
        selected: Array.isArray(result) ? result : [result],
      });
    } else {
      const labels = [...q.options.map((o) => o.label), "Type something."];
      const result = await ui.select(q.question, labels);
      if (result === null) return { answers, cancelled: true };
      
      if (result === "Type something.") {
        const custom = await ui.input("Your answer:");
        if (custom === null) return { answers, cancelled: true };
        answers.push({ qIndex: i, kind: "custom", value: custom });
      } else {
        answers.push({ qIndex: i, kind: "option", value: result });
      }
    }
  }
  
  return { answers, cancelled: false };
}

// ============================================================================
// Tool Registration
// ============================================================================

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "ask_user_question",
    label: "Ask User Question",
    description: `Ask the user one or more structured questions. Use when you need concrete decisions and cannot proceed without user input.

Each question has 2-4 options with labels and descriptions. Users can type custom answers or press Esc to cancel.

For multi-select, set multiSelect: true. For rich context, use the preview field with markdown.

Do NOT author "Type something." or "Other" options yourself — they are added automatically.`,
    promptSnippet: `Ask up to ${MAX_QUESTIONS} structured questions (${MIN_OPTIONS}-${MAX_OPTIONS} options each) when requirements are ambiguous`,
    promptGuidelines: [
      `Use ask_user_question when the user's request is underspecified and you need concrete decisions.`,
      `Each question MUST have ${MIN_OPTIONS}-${MAX_OPTIONS} options with concise labels and descriptions.`,
      `Set multiSelect: true when multiple answers are valid. Use preview for visual comparisons.`,
      `Do not stack multiple ask_user_question calls — group all questions into one invocation.`,
    ],
    parameters: ParamsSchema,
    
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      // Validate
      const err = validate(params as Params);
      if (err) return errorResult(err);
      if (!ctx.hasUI) return errorResult("Error: UI not available");
      
      // RPC mode
      if (ctx.mode === "rpc" && hasDialog(ctx.ui)) {
        const result = await runRpc(params as Params, ctx.ui);
        return successResult(result, params as Params);
      }
      
      // TUI mode
      try {
        const result = await ctx.ui.custom<any>(
          (tui, theme, _kb, done) => {
            const ui = new QuestionnaireUI(tui, theme, params as Params, done);
            return ui.component;
          },
          {
            overlay: true,
            overlayOptions: {
              anchor: "bottom-center",
              width: "100%",
              maxHeight: "100%",
              margin: { left: 0, right: 0, bottom: 0 },
            },
          },
        );
        
        if (result === undefined) {
          if (hasDialog(ctx.ui)) {
            const rpcResult = await runRpc(params as Params, ctx.ui);
            return successResult(rpcResult, params as Params);
          }
          return errorResult("Error: custom UI not available");
        }
        
        return successResult(result, params as Params);
      } catch (e) {
        return errorResult(`Error: ${e}`);
      }
    },
    
    renderCall(args, theme, _ctx) {
      const qs = (args.questions as Question[]) || [];
      const count = qs.length;
      const labels = qs.map((q) => q.header).join(", ");
      let text = theme.fg("toolTitle", theme.bold("ask_user_question "));
      text += theme.fg("muted", `${count} question${count !== 1 ? "s" : ""}`);
      if (labels) text += theme.fg("dim", ` (${labels})`);
      return new Text(text, 0, 0);
    },
    
    renderResult(result, _opts, theme, _ctx) {
      const details = result.details as any;
      if (!details) {
        const t = result.content[0];
        return new Text(t?.type === "text" ? t.text : "", 0, 0);
      }
      if (details.cancelled) {
        return new Text(theme.fg("warning", "Cancelled"), 0, 0);
      }
      
      const lines = details.answers.map((a: any) => {
        const q = (result.content[0] as any)?.text?.split("\n")[a.qIndex] ?? "Q";
        const prefix = theme.fg("success", "✓ ");
        const header = theme.fg("accent", a.qIndex + 1 + ". ");
        
        if (a.kind === "custom") {
          return `${prefix}${header}${theme.fg("muted", "(wrote) ")}${a.value}`;
        }
        if (a.kind === "multi") {
          return `${prefix}${header}selected ${a.selected.length} option(s): ${a.selected.join(", ")}`;
        }
        return `${prefix}${header}${a.value}`;
      });
      
      return new Text(lines.join("\n"), 0, 0);
    },
  });
}
