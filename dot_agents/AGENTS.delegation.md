# Delegation and Review Mechanics

Applies when you start workers or reviewers. When to delegate, which model to pick and when a review is required are in `AGENTS.md`.

## Starting agents
- Start each one as a named interactive agent in a visible pane (`herdr agent start`, then `herdr agent prompt`), not headless. Check it is running after you prompt it, and say which pane it is in.
- Workers run in Claude Code, not on sol: `claude --dangerously-skip-permissions --model <sonnet|opus> --effort high`.
- Reviewers run at medium effort. Use sol in pi while its quota lasts, without global steering: `--no-context-files --no-skills --no-extensions --no-prompt-templates --no-mcp`. When sol is out, use Opus: `claude --dangerously-skip-permissions --model opus --effort medium`. For a really risky review, use Fable.
- Give parallel workers disjoint scopes, and assign shared identifiers (ADR numbers, migration versions, ports) up front.

## Briefs
- A brief is self-contained: read-only rules, repo and branch, exact files, output path, required format.
- Reviewer briefs ask for findings by severity with `file:line`, a concrete failure scenario and the smallest fix, without nits, and for a reply holding only the report path.
- Behavior-change briefs list the edge cases: restart and reload mid-operation, failure of each external call, empty, missing and unknown values, old and new versions side by side.

## Re-check rounds
- Re-checks go to the same reviewer with the new head: verify the earlier findings and report only regressions and blockers.
- Stop when only minor findings remain, and after two rounds at most, whatever is left. Then fix it yourself and merge, or merge and open a follow-up issue.
