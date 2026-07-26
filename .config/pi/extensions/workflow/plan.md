# Implementation Plan: Workflow Extension Refactor

## Overview

This document outlines the refactoring of the workflow extension to introduce a cleaner abstraction hierarchy:

- **Engine** (future): Orchestrates multiple tasks in succession
- **Task**: Runs a complete workflow for a single task (NEW main abstraction)
- **Step/State**: Individual phases within a workflow

The first iteration focuses on **single-task execution** with a simplified UI, while preserving the existing multi-task engine as dead code for potential future use.

---

## Design Decisions

### 1. Task Abstraction

- **Purpose**: Encapsulate single-task workflow execution with its own mutable state
- **Instance fields**: `loopCounts`, `budgetUsed`, `pendingFeedback`, `currentState`, `cachedDiff`, `handoffNote`
- **Public interface**: `run(): Promise<TaskResult>`
- **Benefits**:
  - Clean separation from multi-task orchestration (Engine)
  - Enables future parallelism
  - Simplifies code by reducing parameter threading

### 2. TaskResult Interface

```typescript
interface TaskResult {
  success: boolean;
  finalState: string;
  error?: WorkflowAbort;
  usage: UsageTotals;
  handoffNote: string;
  steeringNotes: string;
}
```

### 3. CLI Tools State

- **Approach**: Extend `deterministicGate` to accept `DeterministicGateSpec | DeterministicGateSpec[]`
- **Behavior**: Runs commands sequentially, stops at first failure
- **Feedback**: Returns only the first failing command's output
- **Rationale**: Avoids special state type; keeps framework generic

### 4. Entry Point

- **Current**: `index.ts` → `engine.runWorkflow()` → loops over tasks
- **New**: `index.ts` → `new Task(...).run()` directly
- **engine.ts**: Kept as dead code for now

### 5. UI Simplification

- **Header**: `⚙ Workflow — {taskTitle}` (removed "task X/N" counter)
- **Focus**: Single task progress only
- **Retained**: State, loops, budget, gate status, activity stream

### 6. Diff Computation

- **Strategy**: Lazy computation with caching
- **Trigger**: On first access by a non-implementer state
- **Storage**: `cachedDiff` instance field in Task

### 7. WorkflowRunner Usage

- **Relationship**: Task uses WorkflowRunner internally
- **Responsibility split**:
  - Task: State machine orchestration, loop/budget management
  - WorkflowRunner: Agent session lifecycle, verdict enforcement, event streaming

---

## File Changes

### New Files

#### `framework/task.ts`

**Purpose**: Main abstraction for single-task workflow execution

**Structure**:

```typescript
class Task {
  // Mutable state
  private loopCounts = new Map<string, number>();
  private budgetUsed = 0;
  private pendingFeedback?: string;
  private currentState: string;
  private cachedDiff?: string;
  private handoffNote = "";
  private runner: WorkflowRunner;

  constructor(
    private spec: TaskSpec,
    private def: WorkflowDefinition,
    private deps: {
      cwd: string;
      baselineRef: string;
      steeringNotes: string;
      modelRuntime: ModelRuntime;
      ui: WorkflowUI;
      signal: AbortSignal;
      agentDir: string;
      ctx: ExtensionCommandContext;
    }
  ) {}

  async run(): Promise<TaskResult> {}
  private async getDiff(): Promise<string> {}
  private buildRunContext(): RunContext {}
}
```

**Methods**:

- `run()`: Main state machine loop
  - Iterates through states until terminal
  - Manages loop counts, budget, feedback routing
  - Handles escalation (budget/loop caps)
  - Returns TaskResult with success/failure info
- `getDiff()`: Lazy diff computation with caching
- `buildRunContext()`: Constructs RunContext for gate evaluation

**Dependencies**:

- Uses `WorkflowRunner` for agent execution
- Uses `handoff.computeDiff` for git diff
- Uses `handoff.extractBlock` for HANDOFF/STEERING_NOTES parsing

---

### Modified Files

#### `framework/gates.ts`

**Change**: Extend `deterministicGate` to accept array of specs

```typescript
function deterministicGate(
  spec: DeterministicGateSpec | DeterministicGateSpec[]
): Gate {
  return async (ctx: RunContext): Promise<GateResult> => {
    const specs = Array.isArray(spec) ? spec : [spec];
    for (const s of specs) {
      const r = await runCommand(s.command, {
        cwd: ctx.cwd,
        signal: ctx.signal,
        timeoutMs: s.timeoutMs,
      });
      if (r.exitCode !== 0) {
        const output = [r.stdout, r.stderr].filter(Boolean).join("\n").trim();
        return {
          pass: false,
          label: `${s.name}: failed (exit ${r.exitCode})`,
          feedback: `The \`${s.name}\` check failed (\`${s.command}\`, exit code ${r.exitCode}).\nFix the issues below, then finish.\n\n${output || "(no output captured)"}`,
          structured: { exitCode: r.exitCode },
        };
      }
    }
    return { pass: true, label: "all cli checks passed" };
  };
}
```

**Impact**:

- Simplifies workflow definitions (e.g., `ruff, ty, pytest` as single state)
- Maintains backward compatibility (single spec still works)

---

#### `framework/ui.ts`

**Changes**:

1. Remove task counter from widget header
2. Simplify constructor to not require task count

**Modified `render()`**:

```typescript
private render() {
  const lines = [
    `⚙ Workflow — ${this.taskTitle}`,
    `  state: ${this.state}   loops: ${this.loopInfo || "-"}   budget: ${this.budget || "-"}   gate: ${this.lastGate || "-"}`,
    ...this.activity.map((a) => `    ${a}`),
  ];
  this.ctx.ui.setWidget(WIDGET_KEY, lines);
  this.ctx.ui.setStatus(STATUS_KEY, `workflow · ${this.state}`);
}
```

**Modified `setTask()`**:

```typescript
setTask(title: string) {
  this.taskTitle = title;
  this.activity = [];
  this.lastGate = "";
  this.render();
}
```

**Removed**: `taskIndex`, `taskCount` fields and related methods

---

#### `index.ts`

**Changes**: Direct Task execution instead of engine-based flow

**New command handler**:

```typescript
pi.registerCommand("workflow", {
  description: "Run the deterministic multi-agent workflow: /workflow <plan-path>",
  handler: async (args, ctx) => {
    const planPath = resolvePlanPath(args.trim(), ctx.cwd);
    if (!planPath) {
      ctx.ui.notify("Usage: /workflow <path-to-plan.md>", "warning");
      return;
    }

    const controller = new AbortController();
    activeController = controller;
    const ui = new WorkflowUI(pi, ctx);

    try {
      if (!modelRuntime) modelRuntime = await ModelRuntime.create();

      const roles = discoverRoles(AGENTS_DIR);
      const def = buildPythonWorkflow(roles);
      assertRolesPresent(roles, [def.implementerRole, ...def.states.map((s) => s.role).filter(Boolean)]);

      await assertCleanTree(ctx.cwd, controller.signal);
      const baselineRef = await getBaselineRef(ctx.cwd, controller.signal);
      const tasks = parsePlan(planPath);
      
      // For now: only run the first task
      const taskSpec = tasks[0];
      ui.setTask(taskSpec.title);
      ui.milestone({ kind: "start", task: taskSpec.title, text: `Starting task: ${taskSpec.title}` });

      const task = new Task(taskSpec, def, {
        cwd: ctx.cwd,
        baselineRef,
        steeringNotes: "",
        modelRuntime,
        ui,
        signal: controller.signal,
        agentDir: getAgentDir(),
        ctx,
      });

      const result = await task.run();
      
      if (result.success) {
        ui.milestone({ kind: "end", task: taskSpec.title, text: "Task completed successfully" });
        ui.notify("Workflow completed.", "info");
      } else {
        ui.milestone({ kind: "end", task: taskSpec.title, text: `Task failed: ${result.error?.message}` });
        ui.notify(`Workflow failed: ${result.error?.message ?? 'Unknown error'}`, "error");
      }
    } catch (err) {
      if (err instanceof WorkflowAbort) {
        ui.notify(`Workflow stopped (${err.kind}): ${err.message}`, err.kind === "user" ? "warning" : "error");
      } else {
        ui.notify(`Workflow error: ${(err as Error).message}`, "error");
      }
    } finally {
      ui.clear();
      activeController = undefined;
    }
  },
});
```

**Impact**:

- Single-task execution only
- Cleaner separation of concerns
- Returns TaskResult for explicit success/failure handling

---

#### `framework/runner.ts`

**No structural changes needed** — Task will use it internally.

**Minor addition**: Add documentation for `unsub` pattern (already done).

---

### Unchanged Files

- `framework/types.ts` — Core contracts remain valid
- `framework/engine.ts` — Kept as dead code
- `framework/handoff.ts` — No changes needed
- `framework/plan-parser.ts` — No changes needed
- `framework/exec.ts` — No changes needed
- `framework/agents.ts` — No changes needed
- `workflows/python.ts` — No changes needed (but can be simplified later with array gates)
- `agents/*.md` — No changes needed

---

## Implementation Order

### Phase 1: Foundation (Task Class)

1. Create `framework/task.ts` with:
   - Class structure and constructor
   - Instance fields for mutable state
   - `getDiff()` with lazy caching
   - `buildRunContext()` helper
2. Implement `run()` method skeleton with state machine loop
3. Wire up WorkflowRunner internally

### Phase 2: Integration

4. Modify `index.ts` to use Task directly
5. Update `framework/ui.ts` to remove task counter
6. Ensure WorkflowRunner is properly instantiated by Task

### Phase 3: CLI Tools Enhancement

7. Extend `deterministicGate` in `framework/gates.ts` to accept array
8. Update `workflows/python.ts` to use array gate for CLI checks (optional, can be done later)

### Phase 4: Testing

9. Test single-task workflow end-to-end
10. Verify loop-back behavior (gate failure → implementer)
11. Verify verdict enforcement (submit_verdict requirement)
12. Verify escalation paths (budget/loop caps)

---

## Migration Notes

### Backward Compatibility

- **None**: This is a breaking change for the workflow command
- The old multi-task behavior is not supported in this iteration
- `engine.ts` is preserved but unused

### Future Work

1. **Multi-task support**: Restore engine.ts to orchestrate multiple Task instances
2. **Parallel execution**: Leverage Task abstraction for concurrent task runs
3. **Workflow configuration**: Externalize CLI tool commands per project
4. **Resume support**: Add persistence layer for interrupted workflows

---

## Testing Strategy

### Unit Tests (future)

- `Task.run()` with mock WorkflowRunner
- `deterministicGate` with array input
- Loop cap and budget enforcement

### Manual Testing

1. Create a plan with 1 task
2. Run `/workflow plan.md`
3. Verify:
   - Implementer runs
   - CLI gates execute sequentially
   - First failure stops execution
   - Feedback delivered to implementer
   - Loop-back works
   - Verdict enforcement works
   - UI shows correct state

### Edge Cases

- Empty plan (should error)
- Plan with no tasks (should error)
- All CLI checks pass
- CLI check timeout
- User abort during execution
- Verdict role never calls submit_verdict

---

## Rollback Plan

If issues arise:

1. Revert `index.ts` to use `engine.runWorkflow()`
2. Keep `framework/task.ts` as experimental
3. No changes to existing files are breaking (except index.ts)
