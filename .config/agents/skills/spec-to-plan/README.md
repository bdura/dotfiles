# Spec-to-Plan Skill

A Pi skill that converts specification conversations into comprehensive, actionable implementation plans.

## Installation

Place this skill in one of Pi's skill discovery locations:

- `~/.agents/skills/spec-to-plan/` (global - recommended)
- `~/.pi/agent/skills/spec-to-plan/` (global)
- `.pi/skills/spec-to-plan/` (project-local)
- `.agents/skills/spec-to-plan/` (project-local)

Or add to your `settings.json`:

```json
{
  "skills": [
    "/path/to/spec-to-plan"
  ]
}
```

## Usage

### Basic Usage

```
/skill:spec-to-plan
```

This analyzes the current conversation and generates a detailed implementation plan.

### Natural Language

You can also invoke it naturally:
- "Generate an implementation plan from our discussion"
- "Create a plan from this spec conversation"
- "What's the implementation plan based on what we've discussed?"
- "Convert this to an actionable plan"

### With Options

**Focus on specific areas:**
```
/skill:spec-to-plan focus:backend
/skill:spec-to-plan focus:frontend
/skill:spec-to-plan focus:api
/skill:spec-to-plan focus:testing
/skill:spec-to-plan focus:security
/skill:spec-to-plan focus:performance
/skill:spec-to-plan focus:devops
```

**Exclude sections:**
```
/skill:spec-to-plan exclude:timeline
/skill:spec-to-plan exclude:risks
/skill:spec-to-plan exclude:testing
/skill:spec-to-plan exclude:dependencies
```

**Combine options:**
```
/skill:spec-to-plan focus:backend exclude:timeline
```

## Output Structure

The generated plan includes these sections:

1. **📋 Project Overview** - High-level summary
2. **🎯 Goals & Objectives** - Success criteria
3. **📝 Requirements** - Functional and non-functional
4. **🏗️ Technical Approach** - Architecture, tech stack, design decisions
5. **🚀 Implementation Steps** - Phased, actionable tasks
6. **🔗 Dependencies** - External and internal
7. **✅ Testing Strategy** - Unit, integration, E2E
8. **⚠️ Risks & Mitigations** - Potential issues and solutions
9. **📅 Timeline & Milestones** - Estimated schedule

## Example

**Input Conversation:**
```
User: We need to build a REST API for a task management system.
User: It should support CRUD operations for tasks.
User: Use Node.js and PostgreSQL.
User: Need authentication with JWT.
```

**Output Plan:**
```markdown
# Implementation Plan: Task Management API

## 📋 Project Overview
Build a RESTful API for managing tasks with authentication.

## 🎯 Goals & Objectives
- Provide CRUD operations for tasks
- Secure API with JWT authentication
- Use Node.js and PostgreSQL

## 📝 Requirements
### Functional Requirements
- Create, read, update, delete tasks
- User authentication and authorization
- Task filtering and sorting

### Non-Functional Requirements
- Response time < 200ms for most endpoints
- 99.9% uptime

## 🏗️ Technical Approach
### Architecture
Client -> API Gateway -> Node.js Server -> PostgreSQL

### Technology Stack
- Node.js with Express
- PostgreSQL
- JWT for authentication

## 🚀 Implementation Steps
### Phase 1: Setup
- [ ] Initialize Node.js project
- [ ] Set up PostgreSQL database
- [ ] Configure project structure

### Phase 2: Authentication
- [ ] Implement JWT authentication
- [ ] Create user registration/login endpoints

### Phase 3: Task CRUD
- [ ] Create task model and migrations
- [ ] Implement task CRUD endpoints
- [ ] Add authentication middleware

### Phase 4: Testing & Deployment
- [ ] Write unit and integration tests
- [ ] Set up CI/CD pipeline
- [ ] Deploy to production

## 🔗 Dependencies
- Node.js 18+
- PostgreSQL 14+
- npm packages: express, jsonwebtoken, pg, etc.

## ✅ Testing Strategy
- Unit tests with Jest
- Integration tests with Supertest
- E2E tests with Cypress

## ⚠️ Risks & Mitigations
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Database performance | Medium | High | Add indexes, optimize queries |

## 📅 Timeline
- Phase 1: 2 days
- Phase 2: 3 days
- Phase 3: 5 days
- Phase 4: 3 days
- Total: 13 days
```

## Integration

This skill works well with:
- **Plan Mode** (`/plan`) - Execute the generated plan with progress tracking
- **Todo Tool** - Convert plan steps to todo items
- **Git Checkpoint** - Create checkpoints at milestones

## Tips

1. **Have a detailed conversation first** - The more context, the better the plan
2. **Mention constraints** - Budget, timeline, technical limitations
3. **Discuss alternatives** - Helps the skill understand your preferences
4. **Reference existing code** - Link to relevant files or systems
5. **Ask for clarification** - If the plan is missing something, ask follow-up questions

## Contributing

Feel free to customize this skill for your needs:
- Modify the template in `SKILL.md`
- Add custom sections
- Adjust the formatting
- Create project-specific versions

## License

MIT
