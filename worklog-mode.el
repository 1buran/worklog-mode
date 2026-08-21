;;; worklog-mode.el --- Plain-text work journal -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Andrew Burdyug
;; SPDX-License-Identifier: MIT

;; Author: Andrew Burdyug
;; Version: 0.1.0
;; Keywords: outlines, notes, convenience
;; URL: https://github.com/1buran/worklog-mode
;; Package-Requires: ((emacs "28.1") (transient "0.3.0"))

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the MIT License.  See the LICENSE file.

;;; Commentary:

;; A small major mode for keeping a plain-text work journal.  It gives a
;; lightweight, org-free way to write down what you worked on, what you
;; found and what to do next, while still getting useful highlighting,
;; list handling and real syntax highlighting for embedded code blocks.

;; The format is plain text:

;;     @date 2026-08-18 12:00
;;
;;     @title Fixed the nil-panic in win.php
;;
;;     The crash happened because changeStream could be nil:
;;
;;     win.php:
;;
;;         $bulk = new \MongoDB\Driver\BulkWrite();
;;         $mongo->executeBulkWrite($bulk);
;;
;;     @next add a regression test
;;
;;     @pt A title for the paragraph below

;; Code blocks are indented by four spaces and are highlighted using the
;; major mode inferred from the extension of a filename mentioned just
;; above the block ("win.php:" above means PHP highlighting).

;;; Code:

(require 'transient)

(defgroup worklog nil
  "Plain-text work journal."
  :group 'text
  :prefix "worklog-")


;;; Options

(defvar worklog-directory)

(defun worklog--refresh-auto-mode-alist ()
  "Rebuild the directory-based `auto-mode-alist' entry from `worklog-directory'."
  (let ((result '()))
    (dolist (entry auto-mode-alist)
      (unless (and (consp entry)
                   (eq (cdr entry) 'worklog-mode)
                   (string-match-p "/" (car entry)))
        (push entry result)))
    (setq auto-mode-alist (nreverse result)))
  (add-to-list 'auto-mode-alist
               (cons (concat (regexp-quote (file-name-as-directory
                                            (expand-file-name worklog-directory)))
                             "[^/]*\\.txt\\'")
                     'worklog-mode)))

(defun worklog--set-directory (sym val)
  "Set `worklog-directory' (SYM) to VAL and refresh `auto-mode-alist'."
  (set-default sym val)
  (worklog--refresh-auto-mode-alist))

(defcustom worklog-directory "~/worklogs"
  "Directory where worklog files are stored, one per project."
  :type 'directory
  :group 'worklog
  :set #'worklog--set-directory)

(defcustom worklog-fill-column 90
  "Column used for automatic word wrapping in `worklog-mode'."
  :type 'integer
  :group 'worklog)

(defcustom worklog-checkmark "✅"
  "Checkmark character toggled by `worklog-toggle-checkmark'."
  :type 'string
  :group 'worklog)

(defcustom worklog-insert-menu-key "C-c C-c"
  "Key binding for `worklog-insert-menu' in `worklog-mode-map'."
  :type 'string
  :group 'worklog)

(defcustom worklog-return-key "RET"
  "Key binding for `worklog-return' in `worklog-mode-map'."
  :type 'string
  :group 'worklog)

(defcustom worklog-toggle-checkmark-key "C-c d"
  "Key binding for `worklog-toggle-checkmark' in `worklog-mode-map'."
  :type 'string
  :group 'worklog)


;;; Faces

(defface worklog-next-face
  '((t :weight bold))
  "Face for the text of @next lines in `worklog-mode'."
  :group 'worklog)

(defcustom worklog-next-color "seagreen1"
  "Foreground color for @next text.
Applied to `worklog-next-face'."
  :type 'color
  :group 'worklog
  :set (lambda (sym val)
         (set-default sym val)
         (set-face-foreground 'worklog-next-face val)))

(defface worklog-paragraph-title-face
  '((t :weight bold))
  "Face for the text of @pt paragraph-title lines in `worklog-mode'."
  :group 'worklog)

(defcustom worklog-pt-color "plum"
  "Foreground color for @pt paragraph-title text.
Applied to `worklog-paragraph-title-face'."
  :type 'color
  :group 'worklog
  :set (lambda (sym val)
         (set-default sym val)
         (set-face-foreground 'worklog-paragraph-title-face val)))

(defface worklog-tag-face
  '((t :foreground "slategray"))
  "Face for the @date/@title/@next/@pt tags in `worklog-mode'."
  :group 'worklog)

(defface worklog-english-face
  '((t))
  "Face for English words and code identifiers in `worklog-mode'."
  :group 'worklog)

(defcustom worklog-english-color "skyblue1"
  "Foreground color for English words and code identifiers.
Applied to `worklog-english-face'."
  :type 'color
  :group 'worklog
  :set (lambda (sym val)
         (set-default sym val)
         (set-face-foreground 'worklog-english-face val)))

(defface worklog-subheading-face
  '((((type tty)) :weight bold :inverse-video t)
    (t :weight bold :height 1.3))
  "Face for the text of @title subheadings in `worklog-mode'."
  :group 'worklog)

(defcustom worklog-title-color "mediumpurple1"
  "Foreground color for @title subheadings.
Applied to `worklog-subheading-face'."
  :type 'color
  :group 'worklog
  :set (lambda (sym val)
         (set-default sym val)
         (set-face-foreground 'worklog-subheading-face val)))

(defface worklog-list-header-face
  '((t :weight bold))
  "Face for list-header lines (ending with `:') in `worklog-mode'."
  :group 'worklog)

(defface worklog-checkmark-face
  '((t :weight bold :foreground "green1"))
  "Face for the checkmark inserted by `worklog-toggle-checkmark'."
  :group 'worklog)


;;; Font-lock helpers

(defun worklog-list-header-matcher (limit)
  "Font-lock matcher for a list-header line ending with `:'.
A line ending with `:' counts as a list header only if the following
line starts with `-', a digit, or `.'."
  (let (found)
    (while (and (not found)
                (re-search-forward "^\\(.*:\\)$" limit t))
      (if (save-match-data
            (save-excursion
              (goto-char (match-end 0))
              (forward-line 1)
              (and (not (eobp))
                   (looking-at "[-0-9.]"))))
          (setq found t)
        (goto-char (match-end 0))))
    found))

(defvar jit-lock-start)

(defun worklog-extend-after-change (_start _end _old-len)
  "Extend the jit-lock after-change region to include the previous line.
This re-highlights a list-header line when its following list-item line
is edited."
  (let ((prev (save-excursion
                (goto-char jit-lock-start)
                (line-beginning-position 0))))
    (when (< prev jit-lock-start)
      (setq jit-lock-start prev))))

(defun worklog-code-line-p ()
  "Return non-nil if point is on an indented (code) line.
Used as a `fill-nobreak-predicate' so auto-fill skips code blocks."
  (save-excursion
    (beginning-of-line)
    (looking-at "    ")))

(defun worklog-adaptive-fill-function ()
  "Return the fill prefix for a list item, indenting under its text.
Returns nil for non-list lines so they fill normally."
  (save-excursion
    (beginning-of-line)
    (cond
     ;; bullet: - , * , +
     ((looking-at "[ \t]*[-+*][ \t]+")
      (replace-regexp-in-string "[^ \t]" " " (match-string 0)))
     ;; numbered: 1. or 1)
     ((looking-at "[ \t]*[0-9]+[.)][ \t]+")
      (replace-regexp-in-string "[^ \t]" " " (match-string 0)))
     (t nil))))

(defun worklog-next-item-marker ()
  "Return the marker for the next list item, or nil.
Works both on the item's marker line and on its indented continuation
lines: it walks up through indented lines to find the marker."
  (save-excursion
    (beginning-of-line)
    ;; Walk up through indented (continuation) lines.
    (while (and (not (bobp))
                (looking-at "[ \t]+"))
      (forward-line -1))
    (cond
     ;; numbered: N. or N)
     ((looking-at "[ \t]*\\([0-9]+\\)\\([.)]\\)[ \t]")
      (format "%s%s " (1+ (string-to-number (match-string 1))) (match-string 2)))
     ;; bullet: - * +
     ((looking-at "[ \t]*\\([-+*]\\)[ \t]")
      (format "%s " (match-string 1)))
     (t nil))))

(defun worklog-return ()
  "Start the next list item with a blank line before it, or a newline.
If point is at the end of a list-item line, insert a blank line followed
by the next item's marker; otherwise call `newline'."
  (interactive)
  (let ((marker (and (eolp) (worklog-next-item-marker))))
    (if marker
        (insert "\n\n" marker)
      (newline))))

(defun worklog-toggle-checkmark ()
  "Toggle a checkmark at the start of the current line's content.
The checkmark goes after a list marker (`-', `1.', `2)' ...) or at the
very beginning of a non-list line."
  (interactive)
  (beginning-of-line)
  (when (looking-at "\\([0-9]+[.)][ \t]+\\|[-+*][ \t]+\\)")
    (goto-char (match-end 1)))
  (if (looking-at (regexp-quote worklog-checkmark))
      (progn
        (delete-char (length worklog-checkmark))
        (when (looking-at "[ \t]")
          (delete-char 1)))
    (insert worklog-checkmark " ")))


;;; Embedded code blocks

(defconst worklog-code-keywords
  '("abstract" "and" "array" "as" "break" "callable" "case" "catch"
    "class" "clone" "const" "continue" "declare" "default" "die" "do"
    "echo" "else" "elseif" "empty" "enddeclare" "endfor" "endforeach"
    "endif" "endswitch" "endwhile" "enum" "exit" "extends" "final"
    "finally" "fn" "for" "foreach" "function" "global" "goto" "if"
    "implements" "include" "include_once" "instanceof" "insteadof"
    "interface" "isset" "list" "match" "namespace" "new" "or" "print"
    "private" "protected" "public" "readonly" "require" "require_once"
    "return" "static" "switch" "throw" "trait" "try" "unset" "use"
    "var" "while" "xor" "yield" "true" "false" "null" "TRUE" "FALSE" "NULL")
  "Keywords highlighted inside worklog code blocks.")

(defconst worklog-code-token-regexp
  (concat
   "\\('[^']*'\\)"                              ; 1 single-quoted string
   "\\|\\(\\\"[^\\\"]*\\\"\\)"                  ; 2 double-quoted string
   "\\|\\(//.*\\)"                              ; 3 // comment
   "\\|\\(#.*\\)"                               ; 4 # comment
   "\\|\\(\\$[A-Za-z_][A-Za-z0-9_]*\\)"         ; 5 variable
   "\\|\\([0-9]+\\)"                            ; 6 number
   "\\|\\b\\(" (mapconcat #'identity worklog-code-keywords "\\|") "\\)\\b" ; 7 keyword
   "\\|\\([A-Za-z_][A-Za-z0-9_]*\\)[[:blank:]]*(") ; 8 function call
  "Regexp matching a single code token in a worklog code block.")

(defcustom worklog-lang-modes
  '(("el" . emacs-lisp-mode)
    ("elisp" . emacs-lisp-mode)
    ("lisp" . lisp-mode)
    ("cl" . lisp-mode)
    ("php" . php-mode)
    ("go" . go-mode)
    ("sh" . sh-mode)
    ("bash" . sh-mode)
    ("zsh" . sh-mode)
    ("ksh" . sh-mode)
    ("shell" . sh-mode)
    ("py" . python-mode)
    ("python" . python-mode)
    ("js" . js2-mode)
    ("jsx" . js2-mode)
    ("javascript" . js2-mode)
    ("rb" . ruby-mode)
    ("rs" . rust-mode)
    ("c" . c-mode)
    ("h" . c-mode)
    ("cpp" . c++-mode)
    ("cc" . c++-mode)
    ("cxx" . c++-mode)
    ("hpp" . c++-mode)
    ("java" . java-mode)
    ("kt" . kotlin-mode)
    ("css" . css-mode)
    ("scss" . scss-mode)
    ("sass" . sass-mode)
    ("html" . html-mode)
    ("htm" . html-mode)
    ("xml" . nxml-mode)
    ("json" . json-mode)
    ("yaml" . yaml-mode)
    ("yml" . yaml-mode)
    ("toml" . conf-toml-mode)
    ("ini" . conf-mode)
    ("md" . markdown-mode)
    ("markdown" . markdown-mode)
    ("sql" . sql-mode)
    ("lua" . lua-mode)
    ("pl" . cperl-mode)
    ("pm" . cperl-mode)
    ("dockerfile" . dockerfile-mode)
    ("make" . makefile-mode)
    ("mk" . makefile-mode)
    ("tex" . latex-mode)
    ("proto" . protobuf-mode)
    ("graphql" . graphql-mode)
    ("hcl" . hcl-mode)
    ("tf" . terraform-mode)
    ("tfvars" . terraform-mode)
    ("vue" . vue-mode))
  "Alist mapping language/extension names to major modes for code blocks.

Each element is (NAME . MODE), where NAME is the extension or language
label written after the filename colon.  You may add or override entries;
new entries take precedence over the built-in ones."
  :type '(alist :key-type string :value-type function)
  :group 'worklog)

(defun worklog-lang-mode (lang)
  "Return the major-mode symbol for LANG (a file extension or language name).
Returns nil for an empty string.  Falls back to the symbol `LANG-mode' for
unknown names."
  (let ((l (downcase (or lang ""))))
    (or (cdr (assoc l worklog-lang-modes))
        (and (not (string-empty-p l))
             (intern (concat l "-mode"))))))

(defun worklog-fontify-code-block-natively (lang start end)
  "Fontify the code between START and END using LANG's major mode.
Copies `face' text properties from a temporary buffer running the
language's major mode back into the current buffer.  Falls back to
`font-lock-constant-face' when the language mode is unavailable."
  (when (< start end)
    (let ((mode (worklog-lang-mode lang)))
      (remove-text-properties start end '(face nil))
      (if (and mode (fboundp mode))
          (let ((string (buffer-substring-no-properties start end))
                (target (current-buffer)))
            (with-current-buffer (get-buffer-create " *worklog-code-fontification*")
              (let ((inhibit-modification-hooks nil))
                (erase-buffer)
                (insert string)
                (unless (eq major-mode mode)
                  (funcall mode))
                (font-lock-ensure)
                (let ((pos (point-min))
                      (max (point-max)))
                  (while (< pos max)
                    (let ((next (or (next-single-property-change pos 'face) max)))
                      (let ((face (get-text-property pos 'face)))
                        (when face
                          (put-text-property (+ start (1- pos)) (+ start (1- next))
                                             'face face target)))
                      (setq pos next)))))))
        (add-text-properties start end '(face font-lock-constant-face)))
      (add-text-properties start end '(fontified t))
      t)))

(defun worklog-fontify-file-code (limit)
  "Fontify the next indented code block before LIMIT whose preceding
line (possibly separated by blank lines) ends with a filename followed
by a colon.  The language is inferred from the file's extension."
  (when (re-search-forward "\\([[:alnum:]_./-]+\\.\\([[:alnum:]]+\\)\\):[ \t]*$" limit t)
    (let ((file-start (match-beginning 0))
          (ext (match-string 2)))
      (forward-line 1)
      ;; Skip blank lines between the filename line and the code block.
      (while (and (not (eobp)) (looking-at "[ \t]*$"))
        (forward-line 1))
      (let ((block-start (point)))
        (while (and (not (eobp)) (looking-at "    "))
          (forward-line 1))
        (let ((block-end (point)))
          (when (< block-start block-end)
            (worklog-fontify-code-block-natively ext block-start block-end))
          (add-text-properties file-start block-end '(fontified t font-lock-multiline t))
          (set-match-data (list file-start block-end))
          t)))))


;;; Tag insertion

(defun worklog-insert-tag (tag)
  "Insert TAG on a line of its own at point."
  (unless (bolp)
    (end-of-line)
    (newline))
  (insert tag))

(defun worklog-insert-date ()
  "Insert an @date tag with the current timestamp."
  (interactive)
  (worklog-insert-tag (format "@date %s" (format-time-string "%Y-%m-%d %H:%M"))))

(defun worklog-insert-title ()
  "Insert an @title tag."
  (interactive)
  (worklog-insert-tag "@title "))

(defun worklog-insert-next ()
  "Insert an @next tag."
  (interactive)
  (worklog-insert-tag "@next "))

(defun worklog-insert-paragraph-title ()
  "Insert an @pt paragraph-title tag."
  (interactive)
  (worklog-insert-tag "@pt "))

(transient-define-prefix worklog-insert-menu ()
  "Insert a worklog tag or toggle a checkmark."
  ["Insert tag"
   ("d" "date"  worklog-insert-date)
   ("t" "title" worklog-insert-title)
   ("n" "next"  worklog-insert-next)
   ("p" "pt"    worklog-insert-paragraph-title)]
  ["Mark"
   ("c" "checkmark" worklog-toggle-checkmark)])


;;; Font-lock keywords

(defconst worklog-english-regexp
  "[A-Za-z][A-Za-z0-9_]*\\(?:[./-][A-Za-z0-9_]+\\)*\\(?:([A-Za-z0-9_,.]*)\\)?"
  "Regexp matching English words and code identifiers in `worklog-mode'.")

(defconst worklog-highlight-preset-numbers "[0-9]+"
  "Preset regexp matching numbers.")
(defconst worklog-highlight-preset-todos "TODO\\|FIXME\\|HACK"
  "Preset regexp matching TODO/FIXME/HACK markers.")

(defvar worklog-highlight-english t)
(defvar worklog-highlight-rules nil)

(defvar worklog-font-lock-keywords-base
  `(("^\\(@date\\b\\)[[:blank:]]*\\(.*\\)$"  (1 'worklog-tag-face t) (2 'outline-1 t)) ; @date entry
    ("^\\(@title\\b\\)[[:blank:]]*\\(.*\\)$" (1 'worklog-tag-face t) (2 'worklog-subheading-face t)) ; @title heading
    ("^ *- "                    0 'font-lock-keyword-face    t)
    ("^ *[0-9]+\\."             0 'font-lock-keyword-face    t)
    ("^    .*"                  0 'font-lock-constant-face   t) ; code block base
    ("^    "
     (,worklog-code-token-regexp nil nil
      (1 'font-lock-string-face t t)
      (2 'font-lock-string-face t t)
      (3 'font-lock-comment-face t t)
      (4 'font-lock-comment-face t t)
      (5 'font-lock-variable-name-face t t)
      (6 'font-lock-constant-face t t)
      (7 'font-lock-keyword-face t t)
      (8 'font-lock-function-name-face t t)))
    ("https?://[^[:space:]]+"   0 'link                      t)
    ("^\\(@next\\b\\)[[:blank:]]*\\(.*\\)$"  (1 'worklog-tag-face t) (2 'worklog-next-face t)) ; next-step line
    ("^\\(@pt\\b\\)[[:blank:]]*\\(.*\\)$"  (1 'worklog-tag-face t) (2 'worklog-paragraph-title-face t)) ; paragraph title
    (worklog-fontify-file-code) ; indented blocks after "file.ext:" (native language fontification)
    (worklog-list-header-matcher (1 'worklog-list-header-face t)) ; list header
    (,worklog-checkmark 0 'worklog-checkmark-face t)) ; checkmark
  "Base font-lock rules for `worklog-mode', excluding configurable highlights.")

(defvar worklog-font-lock-keywords nil
  "Font-lock rules for `worklog-mode', rebuilt from the highlight options.")

(defun worklog--face-for-color (color)
  "Return a face whose foreground is COLOR, creating it if needed."
  (let ((face (intern (format "worklog-highlight-%s-face"
                              (replace-regexp-in-string "[^[:alnum:]]" "" (downcase color))))))
    (unless (facep face)
      (make-empty-face face)
      (set-face-foreground face color))
    face))

(defun worklog--rebuild-keywords ()
  "Rebuild `worklog-font-lock-keywords' from the highlight options."
  (let ((dynamic '()))
    (when worklog-highlight-english
      (push `(,worklog-english-regexp 0 'worklog-english-face t) dynamic))
    (dolist (rule worklog-highlight-rules)
      (when (and (consp rule) (stringp (car rule)) (stringp (cdr rule)))
        (push `(,(car rule) 0 ',(worklog--face-for-color (cdr rule)) t) dynamic)))
    (setq worklog-font-lock-keywords
          (append (nreverse dynamic) worklog-font-lock-keywords-base))))

(defun worklog--set-highlight (sym val)
  "Set SYM to VAL and rebuild the font-lock keywords."
  (set-default sym val)
  (worklog--rebuild-keywords))

(defcustom worklog-highlight-english t
  "When non-nil, highlight English words and code identifiers.
The color is controlled by `worklog-english-color'."
  :type 'boolean
  :group 'worklog
  :set #'worklog--set-highlight)

(defcustom worklog-highlight-rules nil
  "Alist of (REGEXP . COLOR) highlighting rules for `worklog-mode'.
Each entry highlights text matching REGEXP with COLOR.
Set to nil to disable extra highlighting."
  :type '(repeat (cons regexp color))
  :group 'worklog
  :set #'worklog--set-highlight)

(worklog--rebuild-keywords)


;;; Mode

;;;###autoload
(define-derived-mode worklog-mode text-mode "Worklog"
  "Major mode for plain-text work log files."
  (setq-local font-lock-defaults '(worklog-font-lock-keywords))
  (add-hook 'jit-lock-after-change-extend-region-functions
            #'worklog-extend-after-change nil t)
  (define-key worklog-mode-map (kbd worklog-insert-menu-key) #'worklog-insert-menu)
  (define-key worklog-mode-map (kbd worklog-return-key) #'worklog-return)
  (define-key worklog-mode-map (kbd worklog-toggle-checkmark-key) #'worklog-toggle-checkmark)
  (setq-local fill-column worklog-fill-column)
  (setq-local paragraph-start
              "\f\\|[ \t]*$\\|^[ \t]*[-+*][ \t]+\\|^[ \t]*[0-9]+[.)][ \t]+")
  (setq-local adaptive-fill-function #'worklog-adaptive-fill-function)
  (make-local-variable 'fill-nobreak-predicate)
  (add-to-list 'fill-nobreak-predicate #'worklog-code-line-p)
  (auto-fill-mode 1))

;;;###autoload
(add-to-list 'auto-mode-alist '("worklog\\.txt\\'" . worklog-mode))

;; Directory-based entry is built from `worklog-directory' at load time.
(worklog--refresh-auto-mode-alist)


;;; Project worklog

(defun worklog-project-name ()
  "Return the current project name, or nil.
Derived from the ~/projects/<name> layout, falling back to Projectile."
  (let ((dir (expand-file-name (or (buffer-file-name) default-directory))))
    (or (and (string-match "/projects/\\([^/]+\\)" dir)
             (match-string 1 dir))
        (and (fboundp 'projectile-project-name)
             (let ((n (projectile-project-name)))
               (unless (or (null n) (equal n "-")) n))))))

;;;###autoload
(defun worklog-open ()
  "Open (or create) the worklog file for the current project."
  (interactive)
  (let ((name (worklog-project-name)))
    (unless name
      (user-error "Cannot determine the project name"))
    (let ((file (expand-file-name (concat name ".txt")
                                  (expand-file-name worklog-directory))))
      (make-directory (file-name-directory file) t)
      (find-file file)
      (unless (derived-mode-p 'worklog-mode)
        (worklog-mode)))))

(provide 'worklog-mode)
;;; worklog-mode.el ends here
