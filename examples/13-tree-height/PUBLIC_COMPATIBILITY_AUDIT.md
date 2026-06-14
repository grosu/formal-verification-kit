# Public compatibility audit — `tree_height.py`

This audit covers public callsites, overrides, and changed APIs for `13-tree-height`.

## Summary

- **Source repair performed in this example:** none. The `.py` file is preserved as the frozen pre-repair Claude Code output.
- **Public API changed:** none.
- **Verified public symbol(s):** `max2`, `tree_height`.
- **Compatibility status:** PASS / N/A for this catalog refresh.

## Public callsites and tests

- Inline `__main__` assertions or local test files, when present, are preserved.
- No public subclass/override hierarchy is present in this standalone example.
- No producer/consumer protocol or external callsite is changed by the formal artifacts.

## Artifact-only changes

Renaming the claim file to [`tree-height-spec.k`](tree-height-spec.k) is documentation/artifact naming
only. It does not change the program, the function signature, or runtime behavior.
