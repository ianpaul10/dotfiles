---
name: ipr-walkthrough
description: Write a reviewer's walkthrough of a PR (or local branch) as a markdown guide with clickable `path:line` references. Use when asked to walk someone through a PR, branch, or diff range.
---

# PR walkthrough

Write a guide that lets a reviewer read this change in the right order, understand what each part does, and know exactly what to scrutinize. The reader has the code open next to your guide and will jump to every reference you give.

## Gather context first

Work only from the repository; do not push, commit, or change any files other than the output file.

1. Read the commit list and `git diff --stat` for the range you were given.
2. Read the full diff (`git diff <merge_base>..HEAD`). For large diffs, go file by file.
3. Open the surrounding code for anything non-obvious: callers, the types it implements, tests that pin the behavior.
4. If the branch is one layer of a stack (the base is not the trunk), note what the parent layer provides and keep this guide to this layer's diff.

## Write the guide

Use this structure. Skip a section only when it would be empty.

```markdown
# <Short title>: PR review guide

<1-3 sentences: what this change does and why.>

## At a glance

- **Branch:** `<branch>` ← `<base>`, N commits, +X/-Y
- **Risk:** low | medium | high, with one line of why
- **Suggested order:** the order to read areas in, e.g. tests-as-spec first, then implementation

## <Area 1 name>

**Files:** `path/a.ts`, `path/a.test.ts`

**What it does:** a few sentences or bullets.

**Walkthrough:**
1. `path/a.ts:12-40`: `functionName` does X.
2. `path/a.ts:55`: why this branch exists.

**Scrutinize:**
- [ ] `path/a.ts:61` Is this regex correct for inputs like ...?
- [ ] **Key assumption** `path/b.ts:8`: ... Confirm on ...

---

## <Area 2 name>
...

## Testing and rollout

- What tests cover, and what they don't.
- Flags, migrations, deploy order, cross-repo dependencies.
- How to tophat it.
```

## Rules

- **Every claim about code gets a reference** in the exact form `` `repo/relative/path.ext:LINE` `` or `` `repo/relative/path.ext:START-END` ``. Paths are always relative to the repository root, never to a subdirectory, never absolute. Use post-change line numbers from HEAD. Deleted code: say so and reference the file without a line.
- Put the reference at the **start** of walkthrough steps and scrutinize items so the reader can jump without searching.
- Group by concern (behavior, data flow, layer), not by file order. Small PRs may have a single area.
- Scrutinize items are concrete questions a reviewer can answer by reading the referenced code: correctness, edge cases, dead code, naming, performance, security, missing tests. No generic advice.
- Call out dead code, commented-out code, debug leftovers, TODOs, and anything that looks unintentionally included.
- Plain, direct sentences. No filler, no praise, no restating the diff line by line.
