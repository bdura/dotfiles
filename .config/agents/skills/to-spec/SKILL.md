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
   - Scan the agent workspace's wiki for entries relevant to the feature being
     developed, to ground your decisions in a broader context

2. Sketch out the seams at which you're going to test the feature. Existing seams
   should be preferred to new ones. Use the highest seam possible.

Check with the user that these seams match their expectations.

3. Write the spec using the template below, then publish it to the project's
   agent workspace `specs/`

4. Update `specs/index.md`

## Template

See the [template](references/template.md).
