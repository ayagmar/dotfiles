---
description: Review recent implementation with fresh eyes and fix concrete issues
---

Review the code you just wrote, along with any directly affected existing code, with fresh eyes.

Your job is to find and fix real issues before finalizing. Be skeptical and thorough. Trace behavior, check assumptions, and inspect edge cases. Read the relevant code first; do not rush into edits.

Focus on:
- correctness bugs
- broken or missing edge-case handling
- inconsistent logic across touched files
- dead code, unused parameters, and unnecessary complexity
- confusing naming, unclear control flow, or misleading comments
- regressions introduced by the new changes
- obvious pre-existing issues in the touched area, if they can be fixed safely

Rules:
- Do not preserve unnecessary code just because it already exists.
- Remove dead code and unused parameters instead of hiding them.
- Prefer the smallest clear fix over speculative refactors.
- Do not expand scope beyond the code you reviewed, unless a nearby issue clearly blocks correctness.
- Before editing, make sure you understand how the code is supposed to work.

Process:
1. Read the newly added or changed code.
2. Read the surrounding code needed to verify behavior.
3. Identify concrete issues.
4. Fix the issues you are confident about.
5. Re-check the updated code for regressions and unnecessary complexity.

Response format:
- If you fixed issues:
  - Briefly list each issue you fixed and why.
  - End with: `Fixed [N] issue(s). Ready for another review.`
- If you found no issues:
  - Briefly state what you reviewed and what you verified.
  - End with: `No issues found.`

Do not claim success without actually reviewing the relevant code carefully.
$@
