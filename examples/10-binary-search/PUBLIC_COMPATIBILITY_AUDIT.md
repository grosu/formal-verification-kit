# Public compatibility audit — `binary_search.py`

This audit covers public callsites, overrides, and changed APIs for `10-binary-search`.

## Summary

- **Source repair performed in this example:** none. The `.py` file is preserved as the frozen pre-repair Claude Code output.
- **Public API changed:** none.
- **Verified public symbol(s):** `binary_search`.
- **Compatibility status:** PASS / N/A for this catalog refresh.

## Public callsites and tests

- Inline `__main__` assertions or local test files, when present, are preserved.
- No public subclass/override hierarchy is present in this standalone example.
- No producer/consumer protocol or external callsite is changed by the formal artifacts.

## Artifact-only changes

Renaming the claim file to [`binary-search-spec.k`](binary-search-spec.k) is documentation/artifact naming
only. It does not change the program, the function signature, or runtime behavior.
