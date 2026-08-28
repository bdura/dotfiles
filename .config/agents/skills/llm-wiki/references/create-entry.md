## Writing a wiki entry

Write an entry for a new concept.

### Page format

Every wiki page should follow this structure:

```markdown
---
summary: One to two sentences describing the page.
sources:
  - list of raw source files this page draws from, relative to the project root
tags:
  - list of short tags for easier filtering
---

# Page Title

Main content. Use clear headings and short paragraphs.

Link to related concepts using [[wiki-links]] throughout the text.
```

### Citation rules

- Every factual claim should reference its source file
- Use the markdown footnote format `[^reference]` after the claim and make the
  note link to the source
- If two sources disagree, note the contradiction explicitly
- If a claim has no source, mark it as needing verification
