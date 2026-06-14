# Intent evidence and spec provenance

Formal specifications must be based on the program's **intended behavior**, not merely
on the behavior the current implementation happens to exhibit. In this kit, the
informal prompt / problem statement is a first-class public specification source.

Use this checklist whenever `/formalize` writes `<program>-spec.k` claims,
loop circularities, or a `SPEC.md` note.

## 1. Allowed evidence sources

Use only public or user-provided evidence:

- the user's original prompt, issue, task description, requirements, acceptance
  criteria, examples, and follow-up clarifications;
- project docs, public API docs, comments, docstrings, names, and public tests;
- the current implementation's control/data flow, only as implementation evidence;
- proof obstacles found by `/verify`, surfaced as Findings for the next iteration.

Public/in-repo tests are **evidence, not an oracle**. They often capture intended
behavior, but in bug-fix tasks they may also encode the legacy bug or be stale
relative to the public issue. When a test-derived obligation conflicts with the
prompt/issue intent, mark it **SUSPECT**, explain the conflict in `SPEC.md` /
`FINDINGS.md`, and do not let it veto the public-intent specification by itself.

Do **not** use hidden tests, private evaluator traces, gold patches, benchmark
scores, prior-attempt pass/fail status, or any artifact that an ordinary coding
agent would not see.

## 2. Build an intent ledger before writing claims

Before choosing a claim or invariant, write a short ledger in `SPEC.md` (and mirror
critical entries as comments in the `.k` spec file):

- **Source** — `prompt`, `requirements`, `docs`, `public-test`, `name/comment`,
  `implementation`, or `proof-finding`.
- **Quoted evidence** — the smallest public excerpt that matters.
- **Semantic obligation** — the property the excerpt imposes: precondition,
  postcondition, ordering, uniqueness, preservation, error behavior, boundary case,
  invariant, or termination measure.
- **Status** — encoded in the spec, conflict finding, ambiguity to ask, or escalation.

If no external prompt or requirements are available, say so explicitly and mark the
spec as inferred from code/docs/tests only.

## 2a. Intent-first and formal round-trip adequacy

Do not start by asking "what does the candidate do?" Start by asking "what public
behavior is required?" Before accepting any candidate/legacy behavior as a formal
postcondition, write `INTENT_SPEC.md`: a concise English list of required behaviors
derived only from prompt text, docs, public tests, API names/comments, and named
default-domain conventions. It may mention the current implementation only as
"observed behavior to check later," never as an expected value by itself.

After writing the K semantics and K claims, translate every nontrivial claim,
circularity, expected value, ordering/winner rule, side condition, and frame
condition back into English in `FORMAL_SPEC_ENGLISH.md`. Then compare it against
`INTENT_SPEC.md` in `SPEC_AUDIT.md`:

- **pass** — the formal English is entailed by public intent/default-domain evidence;
- **fail** — the formal English is candidate-derived, legacy-derived, over-specific,
  under-specific, or contradicts public intent;
- **ambiguous** — public evidence is insufficient and the point must not justify
  `V2 == V1`.

A K proof whose English paraphrase fails this audit is a proof of the wrong
contract. Record the mismatch in `FINDINGS.md` and treat the run as
invalid/unresolved until the spec or code is repaired.

## 3. Extract properties from language, not just syntax

Treat words in informal specs as semantically loaded. Examples:

- **Order / winner words**: `first`, `last`, `closest`, `nearest`, `precedence`,
  `override`, `shadow`, `stable`, `in order` usually impose an ordering property.
- **Cardinality words**: `all`, `both`, `every`, `exactly one`, `at most one`,
  `deduplicate` impose collection-size or uniqueness properties.
- **Preservation words**: `keep`, `preserve`, `same as`, `backward compatible`,
  `do not change` impose frame conditions, but only over intended public behavior.
- **Boundary words**: `empty`, `missing`, `zero`, `negative`, `duplicate`, `invalid`
  impose preconditions, error behavior, or Findings.
- **Performance words**: `linear`, `constant`, `streaming`, `without copying` impose
  complexity/space obligations or termination/performance Findings.

The implementation tells you how the code works; the prompt tells you what the code is
for. Do not downgrade prompt examples to mere smoke tests when they express a general
property.

Frame conditions must be **sliced to the property that public evidence actually
names**. A statement like "preserve the well-used inheritance feature" supports the
feature explicitly named (for example, marks continue to transfer); it does not, by
itself, preserve every legacy list order, winner precedence, return type, helper
signature, or other incidental implementation detail. Each preserved sub-property
needs its own order-sensitive public evidence or named default-domain convention.

Executable snippets, reference implementations, or workaround code embedded in the
prompt are first-class intent evidence. If they traverse, merge, or select values in a
particular order, encode that order as an `intent-derived` claim unless another public
source explicitly overrides it. A sentence may carry both negative and positive
information: for example, "actual behavior uses MRO so X wins, but only one element is
present" is negative evidence about completeness while still positively identifying the
winner/precedence `X`.

## 4. Audit code-derived conditions against human intent

Most useful bug signals appear when a precondition, postcondition, invariant,
ordering rule, frame condition, or side condition extracted from the program looks
**weird** relative to the user's prompt, issue, informal spec, examples, docs, or
API names.

Use this rule before accepting any nontrivial condition in the formal spec:

1. Label the condition's provenance: `intent-derived`, `default-domain-assumption`,
   `implementation-derived`, `proof-required`, or `ambiguous`.
2. If a condition is implementation-derived or proof-required, require independent
   public justification from the prompt/docs/tests/API names **unless** it is a
   default, most-common domain assumption.
3. Default assumptions are allowed, but name them explicitly. Examples: integer
   arithmetic is exact unless overflow is in scope; Python inheritance uses normal
   `cls.__mro__`; a function named `closest` usually chooses the nearest/most-specific
   candidate; sorted output is ascending unless stated otherwise; a partial-correctness
   proof does not prove termination unless requested.
4. If the implementation-derived condition conflicts with public intent, or merely
   makes the spec awkward in a way the prompt does not justify, write a Finding rather
   than silently baking it into the spec.
5. A set/membership public assertion does **not** establish a list-order compatibility
   obligation. Derive list/order precedence only from an order-sensitive assertion,
   prompt reference code, docs/API names such as `first`/`closest`, or a named
   default-domain convention.
6. For any ordered K claim, the expected ordered result must cite a non-candidate
   source. If the only reason for `[a,b]` instead of `[b,a]` is "the current patch
   returns it," classify the order as `implementation-derived`/`ambiguous` and do not
   use it to justify no code change.
7. If both the intent and the default domain convention are unclear, mark the point as
   underspecified and ask an UltimatePowers-style clarification question.

Compatibility audits are also intent evidence. If a candidate changes a public
function/method signature, return type, virtual dispatch call, producer/consumer
shape, or storage format, search public callsites and subclass/override definitions.
For virtual dispatch such as `self.method(new_keyword=...)`, every public override
must accept the new call or the caller must preserve backward-compatible dispatch.
Record this in `PUBLIC_COMPATIBILITY_AUDIT.md`; an unhandled public callsite or
override is a Finding even if the formal unit proof closes.

The goal is not to reject all implementation facts. The implementation still tells you
which variables, states, and transitions the proof must model. The point is that
implementation facts are **not automatically the desired semantics**.

## 5. Resolve conflicts honestly

When prompt-derived intent and implementation behavior disagree:

1. Prefer the public intent as the candidate specification.
2. Treat the implementation behavior as an observed behavior to check against it.
3. If the code violates the intent, write a Finding with `input → observed vs expected`.
4. If the code-derived spec condition is weird, stronger, weaker, or differently
   ordered than the human requirement, question it unless it is supported by public
   intent evidence or by an explicit default-domain assumption.
5. If the intent is genuinely ambiguous, record the ambiguity and ask an
   UltimatePowers-style clarification question; do not silently choose the legacy
   behavior because it is easier to prove.
6. Never preserve a legacy behavior as an invariant just because it is currently in
   the code. It must have independent public intent evidence or be a named default
   domain convention. Public evidence for one behavior (for example, completeness or
   transfer) does not automatically preserve a stronger legacy sub-behavior (for
   example, list order or same-name winner precedence). Over-preserved sub-behaviors
   are legacy-derived unless separately justified.
7. Block a `V2 == V1` / no-change conclusion if any ordering, precedence, winner, or
   proof side-condition claim is implementation-derived, code-derived, or
   legacy-derived without public-intent/default-domain support. Such a claim is a
   Finding or ambiguity, not a proof that the candidate is correct.

## 6. Encode provenance in artifacts

Every nontrivial claim/circularity should be traceable:

```k
// SPEC-PROVENANCE:
// - from_prompt: "<quote>" => <semantic obligation>
// - from_docs_or_tests: "<quote>" => <supporting obligation>
// - from_code: <implementation fact used for the semantics/proof>
// - conflicts: <observed implementation mismatch, if any; also in FINDINGS.md>
claim ...
```

`SPEC.md` should explain the same obligations in plain English for readers who never
open the `.k` files. `FINDINGS.md` should record unresolved conflicts, missing
preconditions, and proof-derived feedback for the next code-generation pass.
