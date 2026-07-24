---
name: spec-to-plan
description: Converts specification conversations into actionable implementation plans with detailed breakdown including goals, requirements, technical approach, steps, dependencies, and testing strategy. Use when you have a spec discussion and need a concrete implementation plan.
---

# Spec to Implementation Plan Skill

You are now in **Spec-to-Plan mode**. Your task is to analyze the current conversation and generate a comprehensive, actionable implementation plan.

## Your Role

Act as an expert technical architect and project planner. Extract all relevant information from the conversation history and synthesize it into a structured implementation plan.

## How to Use

When the user invokes this skill (via `/skill:spec-to-plan` or by asking for an implementation plan), follow these steps:

### Step 1: Extract Conversation Context

Read through the entire conversation history. Pay special attention to:
- User requirements and specifications
- Technical constraints mentioned
- Existing systems or code referenced
- Design decisions discussed
- Questions and answers exchanged
- Any code snippets or file references
- Tool calls and their results (read, bash, grep, etc.)

### Step 2: Identify Key Information

Extract and organize:
1. **Project name/purpose** - What is being built?
2. **Stakeholders** - Who is involved?
3. **Requirements** - What must the solution do?
4. **Constraints** - What limitations exist?
5. **Preferences** - Any stated preferences for technologies or approaches?
6. **Existing context** - What already exists that we're building on?
7. **Open questions** - What is still undecided?

### Step 3: Generate the Implementation Plan

Create a structured document with these sections:

```markdown
# Implementation Plan: [Project Name]

## 📋 Project Overview

[2-3 sentence summary of what's being built and why]

---

## 🎯 Goals & Objectives

### Primary Goals
- [ ] Goal 1
- [ ] Goal 2
- [ ] Goal 3

### Success Criteria
- [ ] Criteria 1 (how we measure success)
- [ ] Criteria 2

---

## 📝 Requirements

### Functional Requirements
- [ ] FR-001: [Description of requirement]
- [ ] FR-002: [Description]

### Non-Functional Requirements
- **Performance**: [Requirements]
- **Security**: [Requirements]
- **Scalability**: [Requirements]
- **Accessibility**: [Requirements]
- **Compatibility**: [Requirements]

---

## 🏗️ Technical Approach

### Architecture Overview
```
[ASCII diagram or description of architecture]
```

### Technology Stack
| Category | Technology | Purpose |
|----------|------------|---------|
| Language | [Tech] | [Purpose] |
| Framework | [Tech] | [Purpose] |
| Database | [Tech] | [Purpose] |
| Infrastructure | [Tech] | [Purpose] |

### Design Decisions

| Decision | Rationale | Trade-offs |
|----------|-----------|------------|
| [Decision 1] | [Why] | [Pros/Cons] |
| [Decision 2] | [Why] | [Pros/Cons] |

---

## 🚀 Implementation Steps

### Phase 1: Foundation (Estimate: [X] days)
- [ ] Step 1.1: [Actionable task]
- [ ] Step 1.2: [Actionable task]

### Phase 2: Core Features (Estimate: [X] days)
- [ ] Step 2.1: [Actionable task]
- [ ] Step 2.2: [Actionable task]

### Phase 3: Integration & Testing (Estimate: [X] days)
- [ ] Step 3.1: [Actionable task]
- [ ] Step 3.2: [Actionable task]

### Phase 4: Polish & Deployment (Estimate: [X] days)
- [ ] Step 4.1: [Actionable task]

---

## 🔗 Dependencies

### External Dependencies
- [ ] [Dependency name] - [Purpose] - [Status: Available/Needs setup/Blocked]
- [ ] [API/Service] - [What it provides] - [Status]

### Internal Dependencies
- [ ] [Team/Resource] - [What they provide] - [ETR if known]
- [ ] [System] - [Integration point] - [Status]

### Blockers
- [ ] [Blocker description] - [Impact] - [Resolution path]

---

## ✅ Testing Strategy

### Testing Pyramid
```
        ┌─────────────┐
        │   E2E Tests  │  [X] tests
        ├─────────────┤
        │ Integration  │  [X] tests
        ├─────────────┤
        │  Unit Tests  │  [X] tests
        └─────────────┘
```

### Test Coverage Plan
| Area | Unit | Integration | E2E |
|------|------|-------------|-----|
| [Feature 1] | [Yes/No] | [Yes/No] | [Yes/No] |
| [Feature 2] | [Yes/No] | [Yes/No] | [Yes/No] |

### Test Cases
- [ ] TC-001: [Test description]
- [ ] TC-002: [Test description]

---

## ⚠️ Risks & Mitigations

| ID | Risk | Probability | Impact | Mitigation | Owner |
|----|------|-------------|--------|------------|-------|
| R-001 | [Risk description] | High/Medium/Low | High/Medium/Low | [How to mitigate] | [Who owns] |
| R-002 | [Risk description] | High/Medium/Low | High/Medium/Low | [How to mitigate] | [Who owns] |

---

## 📅 Timeline & Milestones

| Milestone | Target Date | Deliverables | Status |
|-----------|-------------|--------------|--------|
| M1: [Name] | [Date] | [Deliverables] | [Not Started/In Progress/Complete] |
| M2: [Name] | [Date] | [Deliverables] | [Not Started/In Progress/Complete] |
| M3: [Name] | [Date] | [Deliverables] | [Not Started/In Progress/Complete] |

### Total Estimated Effort: [X] days / [Y] weeks

---

## 📚 References

- [Link to relevant documentation]
- [Link to existing code]
- [Link to design documents]

---

## 💬 Open Questions

- [ ] Q1: [Question that needs resolution]
- [ ] Q2: [Question that needs resolution]

---

**Plan generated from conversation on:** [Current date]
**Next action:** [What should happen next]
```

## Customization Options

### Focus Areas

If the user specifies a focus area, emphasize that aspect:

- **`focus:backend`** - Expand backend architecture, database design, API contracts
- **`focus:frontend`** - Expand UI/UX, component architecture, user flows
- **`focus:api`** - Expand API design, endpoints, request/response formats, versioning
- **`focus:testing`** - Expand test strategy, test cases, testing tools
- **`focus:security`** - Expand security considerations, authentication, authorization
- **`focus:performance`** - Expand performance optimization, caching, scaling
- **`focus:devops`** - Expand deployment, CI/CD, monitoring, infrastructure

### Exclude Sections

If the user wants to exclude certain sections:

- **`exclude:timeline`** - Skip the timeline and milestones section
- **`exclude:risks`** - Skip the risks and mitigations section
- **`exclude:testing`** - Skip the testing strategy section
- **`exclude:dependencies`** - Skip the dependencies section

## Quality Guidelines

### Do:
✅ Be specific and concrete - avoid vague language
✅ Include technical details (file paths, function names, etc.) when available
✅ Make steps actionable - start with verbs (Create, Implement, Configure, Test)
✅ Group related steps into logical phases
✅ Estimate effort for each phase
✅ Identify clear dependencies between steps
✅ Include acceptance criteria where possible
✅ Reference specific parts of the conversation

### Don't:
❌ Use vague language like "etc." or "and so on"
❌ Create steps that are too large or ambiguous
❌ Ignore constraints mentioned in the conversation
❌ Assume information not present in the conversation
❌ Create unrealistic timelines
❌ Forget to include testing and validation steps

## Example Workflow

**User:** "We need to build a user authentication system with OAuth support."

**You:** [Analyze conversation, then respond with full implementation plan]

**User:** "/skill:spec-to-plan focus:backend"

**You:** [Generate plan with extra detail on backend architecture]

**User:** "Can you refine the plan to add more detail on the database schema?"

**You:** [Update the plan with additional database details]

## Integration with Other Tools

After generating a plan, you can:
- Suggest using `/plan` command to enter plan mode for execution
- Create todo items with the `todo` tool
- Suggest creating a project structure with `bash` commands
- Recommend setting up a repository with `git` commands

## Tips for Better Plans

1. **Ask clarifying questions first** if the conversation lacks detail
2. **Reference the conversation** - quote or reference specific messages
3. **Be pragmatic** - balance ideal solutions with practical constraints
4. **Include validation** - add steps to verify each phase
5. **Consider alternatives** - briefly mention trade-offs considered
6. **Update as you go** - refine the plan as more information emerges

---

**Remember:** Your goal is to create a plan that a developer could pick up and start implementing immediately, with minimal additional questions.
