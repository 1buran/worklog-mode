# Repository Guidelines

Contributor guide for `worklog-mode`, a small Emacs major mode for keeping a
plain-text work journal with rich highlighting, list handling, checkmarks and
native syntax highlighting for embedded code blocks.

## Agent-Specific Instructions

- Do not commit or push until the maintainer has reviewed the changes and approved them.
- Before presenting changes, byte-compile the package from the repo root and make sure it is warning-free, then remove the generated `worklog-mode.elc` (it is ignored by `.gitignore`).
- Verify the package loads cleanly with no user configuration.
- Run the smoke test to confirm highlighting, list handling and code-block fontification still work.

## Project Structure

- `worklog-mode.el` — the whole package in a single file.
- `README.md` — documentation and configuration reference.
- `LICENSE` — MIT.
- `.gitignore` — ignores `*.elc` and generated autoload files.
- `AGENTS.md` — this file.

## Build, Test, and Development Commands

```sh
# byte-compile (must be warning-free)
emacs -Q --batch -f batch-byte-compile worklog-mode.el

# load check (must exit cleanly)
emacs -Q --batch -l worklog-mode.el

# smoke test: fontify a tiny worklog covering tags, lists and a code block
emacs -Q --batch -l worklog-mode.el --eval \
  '(with-temp-buffer (worklog-mode) (insert "@date 2026-01-01 12:00\n\n@title T\n\nwin.php:\n\n    $x = new Foo();\n\n- item\n") (font-lock-fontify-buffer))'
```

## Coding Style & Naming Conventions

- Emacs Lisp with `lexical-binding: t`.
- Every public function, variable and face is prefixed with `worklog-` and has a `checkdoc`-clean docstring.
- User-facing options are `defcustom`s under the `worklog` customize group; highlight colors are `defface`s.
- Keep the font-lock rules narrow: the mode targets small plain-text buffers, but avoid needlessly broad regexps that would slow down refontification.

## Testing Guidelines

- There is no ERT suite yet. Changes are verified with the byte-compile, load check and the batch smoke test above.
- When adding behavior, extend the smoke test to cover the new construct (a new tag, list handling, code-block language inference, fill behavior, and so on).

## Commit & Pull Request Guidelines

- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/#specification): `type: description`, lowercase and imperative.
- Keep the commit subject within 50 characters.
- Wrap the commit body at 72 characters: hard-wrap every line at a word boundary, so no body line is longer than 72 characters.
- Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `style`, `perf`.
