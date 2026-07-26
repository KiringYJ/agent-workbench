# TeX and LaTeX

Use this module for `.tex`, `.cls`, `.sty`, `.bib`, local TEXMF, and document-build work. Apply the rigorous research module to mathematical and scholarly content, and apply the rules below to the source and rendered artifact.

## Preserve the Document Contract

- Read the project guide, root document, local class/package files, bibliography configuration, build scripts, formatter settings, and CI workflow before editing.
- Preserve the existing engine, document class, bibliography backend, package stack, macro conventions, and output layout unless the task explicitly changes them.
- Treat mathematical notation, hypotheses, theorem boundaries, labels, citations, counters, and cross-reference semantics as behavior, not cosmetic text.
- Reuse documented macros and environments. Do not add a package or define a wrapper when an existing project primitive expresses the same concept.

## Source Editing

- Keep source changes narrow and reviewable; avoid unrelated reflow or formatter churn.
- Do not manually edit generated artifacts such as `.aux`, `.bbl`, `.bcf`, `.blg`, `.fdb_latexmk`, `.fls`, `.log`, `.out`, `.synctex.gz`, or generated PDFs unless the project explicitly treats one as source.
- Use semantic environments: theorem-like environments for mathematical statements, `equation` or structured AMS environments for numbered mathematics, and unnumbered displays only when no number or reference is needed.
- Number and label only objects that are referenced or structurally important. Follow the project’s label and cross-reference conventions.
- Keep notation stable. Define every new symbol before use, give maps a source and target, and verify theorem hypotheses where invoked.
- Preserve exact citation keys and bibliography fields. Do not invent a key or silently change a source claim to fit an available citation.
- In prose, prefer precise native English and visible logical structure over formulaic transitions, defensive repetition, or one-use terminology.

## Classes, Packages, and Bibliographies

- For `.cls` and `.sty` changes, check option handling, load order, engine compatibility, moving arguments, counters, theorem definitions, and public macro compatibility.
- Use documented package interfaces instead of patching internals when a supported interface exists.
- Keep class-level layout policy separate from reusable package features.
- Match the project’s existing bibliography toolchain, whether biber/BibLaTeX or BibTeX. Do not mix backends without an explicit migration.

## Build and Render Verification

Use the project-documented root file and build command. If none is documented, infer the smallest safe command from `latexmkrc`, `Makefile`, CI, editor configuration, and the root document, and state the assumption.

After a source change:

1. Run the relevant formatter or source check when configured.
2. Compile far enough to refresh cross-references, citations, indices, glossaries, and generated tables.
3. Inspect the log for TeX errors, undefined control sequences, missing files, undefined references or citations, and new material layout warnings.
4. Inspect the rendered PDF when the change can affect typography, page breaks, equations, floats, tables, fonts, or hyperlinks.
5. Re-run after bibliography, index, glossary, class, package, or counter changes when the toolchain requires multiple passes.

Do not claim success from a zero exit code alone when the log or rendered document still shows a material defect. Report the engine, root file, commands, log status, render check, and any warnings that remain.
