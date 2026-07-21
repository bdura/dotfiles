# ask-user-question - Vendorized Pi Extension

A simplified, auditable Pi extension that provides the `ask_user_question` tool for structured user interaction.

## Overview

This extension is a vendorized version of the functionality provided by `@juicesharp/rpiv-ask-user-question`. It has been simplified and streamlined for:

- **Easy auditing**: Single file (~600 lines) with no external dependencies beyond Pi's core APIs
- **Simple modification**: All logic is self-contained and easy to understand
- **Full functionality**: Supports all key features from the original

## Features

- **Multi-question dialogs** with tab navigation (Tab/Shift+Tab or ←/→)
- **Single-select questions** with 2-4 options each
- **Multi-select questions** with checkbox-style toggling (Space key)
- **Free-text fallback** via "Type something." option on every single-select question
- **Per-option descriptions** for explaining choices
- **Preview panes** for rich context (code snippets, diagrams, markdown)
- **Submit tab** to review all answers before finalizing
- **RPC fallback** for non-TUI environments (VSCode, Zed, etc.)
- **Validation** of all inputs with clear error messages

## Installation

Place the extension in Pi's extensions directory:

```bash
# Global installation (all projects)
mkdir -p ~/.pi/agent/extensions/
# The file is already at: ~/.dotfiles/.config/pi/extensions/ask-user-question.ts
# Create a symlink or copy it:
ln -s ~/.dotfiles/.config/pi/extensions/ask-user-question.ts ~/.pi/agent/extensions/ask-user-question.ts

# Or project-local
mkdir -p .pi/extensions/
ln -s ~/.dotfiles/.config/pi/extensions/ask-user-question.ts .pi/extensions/ask-user-question.ts
```

Pi will automatically discover and load it on startup.

## Usage

The model can call the `ask_user_question` tool with the following schema:

```typescript
{
  questions: [
    {
      question: "Which library should we use?",
      header: "Library",
      options: [
        {
          label: "React",
          description: "A JavaScript library for building user interfaces",
          preview: "// Code example\nfunction Component() { return <div>Hello</div>; }"
        },
        {
          label: "Vue",
          description: "The progressive JavaScript framework"
        }
      ],
      multiSelect: false  // optional, defaults to false
    }
  ]
}
```

### Schema Details

- **questions**: Array of 1-4 questions
- **question**: The full question text (should end with ?)
- **header**: Short label for tab display (max 16 chars)
- **options**: Array of 2-4 options
  - **label**: Display text (max 60 chars, 1-5 words)
  - **description**: Explanation of what this choice means
  - **preview**: Optional markdown shown when option is focused
- **multiSelect**: Boolean, allows multiple selections (default: false)

### Reserved Labels

Do NOT use these labels for options (they are reserved for runtime use):
- `Other`
- `Type something.`
- `Next →`
- `Chat about this`

## Keyboard Controls

### Single Question Mode
- **↑/↓**: Navigate options
- **Enter**: Select option or submit custom text
- **Esc**: Cancel questionnaire

### Multi-Question Mode (2+ questions)
- **Tab / →**: Next question/tab
- **Shift+Tab / ←**: Previous question/tab
- **Space**: Toggle selection (multi-select only)
- **Enter**: Select option or submit
- **Esc**: Cancel questionnaire

### Custom Text Input Mode
- **Enter**: Submit custom answer
- **Esc**: Return to options
- **Backspace**: Delete character

### Submit Tab
- **Enter**: Submit all answers (only if all questions answered)
- **Esc**: Cancel questionnaire

## Return Value

The tool returns a structured result with human-readable content and detailed machine-readable data.

## Customization

This extension is designed to be easily modified. Key areas to customize:

1. **Constants** (lines 20-23): Adjust limits for questions, options, header/label lengths
2. **Validation** (lines 56-72): Modify validation rules
3. **UI Rendering** (lines 180-380): Change colors, layout, formatting
4. **Keyboard Controls** (lines 130-200): Add or modify key bindings
5. **RPC Fallback** (lines 400-440): Customize behavior for non-TUI environments

## Differences from Original

This vendorized version differs from `@juicesharp/rpiv-ask-user-question`:

1. **No i18n support**: Uses English-only labels (simpler, easier to audit)
2. **Simplified preview rendering**: Basic text wrapping, no advanced markdown rendering
3. **Single file**: All logic in one file instead of spread across multiple modules
4. **No module pre-warming**: Simpler startup
5. **No telemetry or external dependencies**: Only depends on Pi's core APIs

## Testing

Test the extension by asking the model to use the `ask_user_question` tool.

## License

This extension is provided as-is for your personal use. It is derived from the MIT-licensed `@juicesharp/rpiv-ask-user-question` package but has been significantly simplified.
