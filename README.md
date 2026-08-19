# worklog-mode

A plain-text work journal for Emacs.

`worklog-mode` is a small major mode for keeping a daily work journal in a
single plain-text file per project. It gives lightweight, org-free note taking
with rich highlighting, list handling and real syntax highlighting for embedded
code snippets — without pulling in `org-mode` or `markdown-mode`.

The journal stays perfectly readable as raw text: no markup noise, just prose,
tags, lists and indented code blocks.

## Why

- `org-mode` is powerful but heavyweight; `markdown` syntax (`#`, ```` ``` ````)
  gets in the way of plain prose.
- A worklog is mostly a stream of thoughts with occasional lists and code. It
  should look clean in *any* editor, not just Emacs.

## Features

- **Tags** — `@date`, `@title`, `@next` and `@pt` (paragraph title) headings,
  each with its own face.
- **Lists** — numbered and bulleted lists with blank-line separation and
  auto-numbering: press `RET` at the end of an item to start the next one.
- **Checkmarks** — toggle `✅` on an item with `C-c d`.
- **Syntax highlighting** — indent a code block by four spaces after a line
  ending in `filename.ext:` and it is highlighted with the matching major mode
  (`win.php:` → PHP, `main.go:` → Go, `script.sh:` → shell, …).
- **Word wrap** — auto-fill at 90 columns (configurable), leaving code blocks
  untouched.
- **Per-project journals** — `worklog-open` (`C-c w`) opens or creates the
  journal for the current project.

## Installation

With `use-package` and `straight.el`:

```elisp
(use-package worklog-mode
  :straight (worklog-mode :type git :host github :repo "1buran/worklog-mode")
  :bind ("C-c w" . worklog-open)
  :custom
  (worklog-directory "~/worklogs"))
```

Files under `worklog-directory` (as well as files named `worklog.txt`) open in
`worklog-mode` automatically.

## Configuration

| Option                        | Default     | Description                                  |
| ----------------------------- | ----------- | -------------------------------------------- |
| `worklog-directory`           | `"~/worklogs"` | Directory where journals are stored (one file per project) |
| `worklog-fill-column`         | `90`        | Column used for automatic word wrapping      |
| `worklog-checkmark`           | `"✅"`       | Checkmark character                          |
| `worklog-insert-menu-key`     | `"C-c C-c"` | Key for the insert-tag menu                  |
| `worklog-return-key`          | `"RET"`     | Key for starting the next list item          |
| `worklog-toggle-checkmark-key`| `"C-c d"`   | Key for toggling a checkmark                 |
| `worklog-pt-color`            | `"plum"`    | Foreground color of `@pt` paragraph titles   |

Highlighting colors are exposed as faces and customizable with
`M-x customize-face`:

`worklog-next-face`, `worklog-tag-face`, `worklog-english-face`,
`worklog-subheading-face`, `worklog-paragraph-title-face`, `worklog-list-header-face`,
`worklog-checkmark-face`.

The extension-to-mode mapping for code blocks is `worklog-lang-modes`
(`M-x customize-variable`). Add or override entries, e.g. to highlight
`.js` blocks with `web-mode`:

```elisp
(add-to-list 'worklog-lang-modes '("js" . web-mode))
```

## Usage

Write plain text. A few conventions make it shine:

```text
@date 2026-08-18 12:00

@title Fixed the nil-panic in win.php

The crash happened because changeStream could be nil after the retry
loop. The fix is to return an error instead of dereferencing it.

win.php:

    $bulk = new \MongoDB\Driver\BulkWrite();
    $mongo->executeBulkWrite($bulk);

Things to check later:

1. add a regression test
2. grep for other os.Exit(1) calls in the library code

@next open a follow-up for the remaining call sites
```

Key bindings inside a worklog buffer:

| Key         | Command                    |
| ----------- | -------------------------- |
| `RET`       | `worklog-return` — next list item (auto-numbered) |
| `C-c C-c`   | `worklog-insert-menu` — insert `@date`/`@title`/`@next`/`@pt` or a checkmark |
| `C-c d`     | `worklog-toggle-checkmark` |
| `C-c w`     | `worklog-open` — open the current project's journal (global) |

## Screenshot

Coming soon (generated with [vhs](https://github.com/charmbracelet/vhs)).

## License

[MIT](LICENSE)
