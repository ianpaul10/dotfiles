---
name: pls_invert_pyramid
description: Rewrite writing using the inverted pyramid / BLUF approach: lead with the point, cut ruthlessly, calibrate to the audience. Use when writing to a boss, stakeholder, or cross-functional peer and you want to communicate more effectively.
argument-hint: "[for: <audience>] [context: <notes>] <your writing>"
---

# Inverted Pyramid Writing Coach

Rewrite the provided writing so the most important point comes first, following the inverted pyramid / BLUF (Bottom Line Up Front) framework.

## Parsing the Input

The input in `$ARGUMENTS` may include optional markers before the writing:

- **`for: <audience>`**: The intended reader (e.g., `for: my boss`, `for: Senior Staff Engineer`, `for: Director of Product`). Use this to calibrate tone, assumed technical depth, and what counts as "relevant detail."
- **`context: <notes>`**: Situational context (e.g., `context: following up on a prod incident`, `context: asking for headcount`).
- **Everything else**: The draft writing to rewrite.

If no markers are present, treat the entire input as the draft and infer audience from tone and content.

## Rewriting Steps

Apply these three steps in order:

### 1. BLUF (Bottom Line Up Front): Lead with the conclusion

Move the primary point, recommendation, or ask to the very first sentence. The reader must know what you need from them within 10 seconds. Strip chronological narrative: deliver the destination, not the journey.

### 2. JIT (Just In Time) Context: Cut ruthlessly

Keep only what directly helps the reader make a decision or take the next step. Remove caveats, backstory, and details that don't serve the action. Test each sentence: "Does this help them say yes/no, or move forward?" If not, cut it.

### 3. Zoom-in: Depth without dumbing down

For complex content, build from shared context → one layer deeper → one more if needed (max 3 layers). Stop as soon as the reader has enough to act. Do not dumb down — zoom in.

## Audience Calibration

Adjust based on who's reading:

- **IC / peer engineer**: Technical depth OK, assume shared context, be direct
- **Staff / Principal / Architect**: Lead with tradeoffs and implications, not implementation
- **Engineering Manager / your boss**: Lead with impact and ask; implementation is supporting detail
- **Director / VP / non-eng stakeholder**: Lead with business outcome; drop jargon entirely

## Output Format

Return three sections:

**1. Audience & register**: One line confirming who you're writing for and how you've calibrated the tone (e.g., "Writing for a non-technical Director: leading with business impact, dropping implementation specifics").

**2. Rewritten version**: Clean, ready-to-send prose. No placeholders.

**3. What changed**: 3-5 bullets on the specific structural or content decisions made (e.g., "Moved the ask to sentence 1", "Cut the incident timeline - not needed for the decision", "Replaced 'idempotency' with 'safe to retry' for non-eng audience").

---

$ARGUMENTS
