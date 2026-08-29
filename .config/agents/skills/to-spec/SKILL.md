---
name: to-spec
description: Turn the current conversation into a spec. No interview, just synthesis of what you've already discussed.
disable-model-invocation: true
---

# Create a specification document

This skill takes the current conversation context and codebase understanding and
produces a spec. Do NOT interview the user; just synthesize what you already know.

## Process

1. If you haven't already:

   - Explore the repo to understand the current state of the codebase
   - Scan `.agent-workspace/wiki/index.md` for entries relevant to the feature
     being developed, to ground your decisions in a broader context

2. Sketch out the seams at which you're going to test the feature. Existing seams
   should be preferred to new ones. Use the highest seam possible.

3. Check with the user that these seams match their expectations. Do not write
   the spec before they do.

4. Write the spec using the template below, then publish it to
   `.agent-workspace/specs/<feature-slug>.md`.

5. Add a line for it to `.agent-workspace/specs/index.md`:

   ```markdown
   - [<feature-slug>](<feature-slug>.md) — **status.** One line on what the
     feature is and where it stands.
   ```

## Template

See the [template](references/template.md).
