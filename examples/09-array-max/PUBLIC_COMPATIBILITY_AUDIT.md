# Public compatibility audit — `array_max.py`

This audit covers public callsites, overrides, and changed APIs for `09-array-max`.

## Summary

- **Source repair performed in this example:** none. The `.py` file is preserved as the frozen pre-repair Claude Code output.
- **Public API changed:** none.
- **Verified public symbol(s):** `array_max`.
- **Compatibility status:** PASS / N/A for this catalog refresh.

## Public callsites and tests

- Inline `__main__` assertions or local test files, when present, are preserved.
- No public subclass/override hierarchy is present in this standalone example.
- No producer/consumer protocol or external callsite is changed by the formal artifacts.

## Artifact-only changes

Renaming the claim file to [`array-max-spec.k`](array-max-spec.k) is documentation/artifact naming
only. It does not change the program, the function signature, or runtime behavior.
