# Sources — live index for `--refresh` and citations

**This is the first-class escalation path.** The three sibling primers
([`matching-logic.md`](matching-logic.md), [`k-framework.md`](k-framework.md),
[`reachability-and-circularities.md`](reachability-and-circularities.md)) are a
**fast path** — they cover the common cases (a function with a loop, a numeric
contract, an arithmetic VC) instantly and offline. They are *distillations*, not
the full theory. **When the recipe doesn't cover your case, come here and read
the primary source for that topic.** The [WHEN TO ESCALATE](#when-to-escalate)
table routes you by topic; `--refresh` re-fetches these URLs into the agent's
context for the current run.

Every citation used anywhere in `knowledge/` resolves to an entry below.

---

## matching-logic.org

An intro essay on matching logic plus footnotes linking the papers (the
matching-logic.org landing page). See also the JLAMP "Matching Logic Explained"
paper, whose footnotes route to the `fsl.cs.illinois.edu` PDFs below.

- URL: `https://matching-logic.org`
- **Fetch quirk:** the TLS certificate's subject-altname is broken
  (`ERR_TLS_CERT_ALTNAME_INVALID`). **WebFetch forces HTTPS and fails on it.**
  Use `curl -sk https://matching-logic.org` (the `-k` skips cert validation).

## Papers — `https://fsl.cs.illinois.edu/publications/<slug>.pdf`

Append `<slug>.pdf` to the base URL. These are the authoritative citations; cite
them by slug.

| Slug | Title | What it underpins |
|---|---|---|
| `rosu-2017-lmcs` | Matching Logic (LMCS 2017) | the foundational paper: patterns-as-sets, the definedness ladder, the proof system. The default citation for matching logic. |
| `chen-rosu-2019-lics` | Matching μ-Logic (LICS 2019) | adds set variables + least fixpoint `μ` (Knaster–Tarski) → induction, recursion, reachability. |
| `chen-lucanu-rosu-2020-tr` | Initial Algebra Semantics in Matching Logic (TR) | modern μ-era presentation; initial-algebra / inductive-sort semantics. |
| `rosu-stefanescu-2012-fm` | From Hoare Logic to Matching Logic Reachability (FM 2012) | reachability rules `φ ⇒ φ'` generalizing Hoare triples; one semantics for execution + proof. |
| `rosu-stefanescu-ciobaca-moore-2013-lics` | One-Path Reachability Logic (LICS 2013) | the **Circularity** rule (coinductive loop invariants) and the full proof system. |
| `chen-pena-rodrigues-rosu-trinh-2020-oopsla` | Unified fixpoint reasoning (OOPSLA 2020) | reasoning about **inductive / recursive data structures** (heap predicates, lists, trees). |
| `chen-rosu-2020-icfp` | A General Approach to Define Binders (ICFP 2020) | **binders, scoping, α-equivalence** (λ, quantifiers, local variables). |

## K framework

- Source + issues: `https://github.com/runtimeverification/k`
- **User manual** (deep K syntax reference): in-repo `docs/user_manual.md`
  (on disk this run: `/tmp/kdocs/user_manual.md`).
- **Lesson 1.22 — "Basics of Deductive Program Verification using K"**: the
  canonical worked proof (the simple-language `sum`-style example our `examples/sum-up`
  imitates). Path (under `k-distribution/k-tutorial/`, Lesson 22 by K's
  documented `1_basic` numbering): `k-distribution/k-tutorial/1_basic/22_proofs`;
  browse the full tutorial at `https://kframework.org/k-distribution/k-tutorial/`
  (on disk: `/tmp/kdocs/L22_proofs.md`).
- Project site: `https://kframework.org`
- **Full per-language semantics** also live in the K ecosystem (e.g. KEVM, the C
  semantics, Python/JS efforts) under the `runtimeverification` org — the
  roadmap target that replaces the MVP's mini-X fragment semantics.

---

## <a id="when-to-escalate"></a>WHEN TO ESCALATE

The primers are the fast path; reach for the source below when your case exceeds
them.

| Topic the recipe doesn't cover | Go to |
|---|---|
| Recursive heap predicates / linked structures (lists, trees) | `chen-pena-rodrigues-rosu-trinh-2020-oopsla` (OOPSLA'20); separation logic *as one matching-logic theory* is sketched in `rosu-2017-lmcs` (it is not the paper's headline result) |
| Binders, scoping, α-equivalence (λ, quantifiers, locals) | `chen-rosu-2020-icfp` (ICFP'20) |
| Induction / least-fixpoint `μ` reasoning, well-founded data | `chen-rosu-2019-lics` (LICS'19); inductive sorts in `chen-lucanu-rosu-2020-tr` |
| Reachability rule mechanics, the **Circularity** rule, soundness | `rosu-stefanescu-2012-fm` (FM'12) + `rosu-stefanescu-ciobaca-moore-2013-lics` (LICS'13) |
| Definedness / equality / membership / sort axioms, the proof system | `rosu-2017-lmcs` (LMCS'17) |
| Deep / unfamiliar K syntax, attributes, hooks, backends | `docs/user_manual.md` |
| A worked, end-to-end `kprove` claim to imitate | Lesson 1.22 (`22_proofs`) |
| Concurrency, or any topic none of the above clearly covers | start at `matching-logic.org` (via `curl -sk`) and follow its footnotes to the right paper |

---

## `--refresh`

`/formalize --refresh` and `/verify --refresh` re-fetch the URLs listed above —
`matching-logic.org` (via `curl -sk`), the relevant `fsl.cs.illinois.edu`
PDF(s) for the topic at hand, and the K manual / Lesson 1.22 — into the current
run's context, instead of relying only on the bundled primers. It is opt-in; the
default is the offline fast path.
