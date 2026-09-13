# WIP — `fix/docx-angle-bracket-stripping`

Working notes for this branch. **Not intended to be merged** — delete this file before opening any PR from it.

## What's on the branch

| commit | what |
|---|---|
| `38a42f7` | test: add the docx phenomena the next two commits fix |
| `380a534` | fix: do not apply the angle-bracket convention to every text node — **fork-only for now** |
| `a8cee62` | fix: let a break with no type reach `pmf:break` and become `<lb/>` |

Tests: 112 XQSuite tests, 0 failures, 0 errors, with the four new tests running.

## Bug 1 — angle brackets (commit `380a534`)

`pmf:combine` in `content/ext-docx.xql` runs

```xquery
case text() return
    if (matches($node, '^(.*?)<.*>(.*)$')) then
        replace($node, '^(.*?)<.*>(.*)$', '$1$2')
    else
        $node
```

over **every** text node in the converted document, so any docx text containing an angle-bracket pair loses the span between the first `<` and the last `>`. The conversion reports success; the characters are simply gone.

This is not a stray line — it implements a documented convention. `docx.odd` describes the producing half: a run whose *character style* is `tei:persName` contributes its bracketed content as `@ref`, and a run styled `tei:<element>` with `<a=b;c=d>` contributes an attribute list; `tei:code` and `tei:tag` are exempted immediately above the stripping. The changelog names the convention as of v3.0.1.

**The defect is scope, not intent.** The convention is opt-in via a character style; the post-processing is applied unconditionally. Anyone whose source text legitimately contains angle brackets — outside `tei:code`/`tei:tag`, and without having opted in — loses it silently.

Our case: FRUS annotation sheets write `<n>` for an en dash and `<m>` for an em dash in ordinary unstyled runs. **4,891 such tokens across the delivered corpus** (one chapter alone has 811). Because `.*` is greedy, the loss runs from the first `<` on a line to the last `>`:

```
before: 'Title of Volume: Foreign Relations, 19811984'
after : 'Title of Volume: Foreign Relations, 1981<n>1988, Volume XXXVI, Trade; Monetary Policy; …'

before: '… Electronic Telegrams, D8300120076.'
after : '… Electronic Telegrams, D830012<n>0076.'
```

That one chapter recovers **811 codes and 46,013 characters** with the stripping removed.

**Why this commit is fork-only.** Simply deleting the stripping breaks the documented convention for everyone using it. The right upstream change is for the producing models to mark what they encoded — so post-processing strips only the runs that opted in — and that needs the maintainers, since `docx.odd` ships outside this library. Deleting it is correct *for us* and wrong as a patch to send.

**Proposed upstream route:** open an issue describing the over-broad scope with the evidence above, and send bug 2 as a standalone PR.

## Bug 2 — breaks with no type (commit `a8cee62`)

`pmf:break` in `content/tei-functions.xql` declared `$type as xs:string`, so an ODD `<model behaviour="break"/>` with no `type` parameter could not bind and the generated transform emitted `()`. A plain `<w:br/>` was dropped entirely.

Word writes page breaks as `<w:br w:type="page"/>`, which bind fine, so only line breaks were affected. One-character fix (`xs:string?`), self-contained, no convention attached — **PR-ready**.

## How this was localized

Stage by stage rather than by guessing, checking the text at each hand-off:

1. `xmldb:store` of the .docx — clean
2. after `compression:unzip` — clean
3. what `docx:process` hands the transform — clean
4. after `$pm-config:tei-transform` — gone

Then inside the transform: `pmf:text` is a passthrough, `pmf:apply-children` delegates, `docx:normalize-ranges` preserves text — leaving `pmf:finish` → `pmf:create-divisions` → `pmf:combine`.

## Notes for whoever picks this up

- `content/ext-docx.xql` is **CRLF**. Edit it as bytes; a normalizing editor turns a 5-line change into a whole-file diff.
- Build with `ant xar`.
- Install into a running container with `xst`, using `--force` when a version is already present. Doing it by hand is a trap: `repo:install-and-deploy-from-db` returns `result="ok"` and installs nothing when the package name is already registered.

## Open questions

- [ ] Issue or PR first for bug 1? (leaning: issue with the evidence, let the maintainers pick the marking mechanism)
- [ ] Split bug 2 onto its own branch off `master` for the PR, so it carries none of this?
- [ ] Does anything else in the lib assume the unconditional stripping?
