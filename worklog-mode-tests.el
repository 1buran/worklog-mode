;;; worklog-mode-tests.el --- Tests for worklog-mode -*- lexical-binding: t; -*-

;;; Commentary:
;; ERT tests covering fontification and formatting behavior of
;; `worklog-mode'.

;;; Code:

(require 'ert)
(require 'worklog-mode)

(defun worklog-test-face-of (text substring)
  "Return the face at the first occurrence of SUBSTRING in fontified TEXT."
  (with-temp-buffer
    (worklog-mode)
    (insert text)
    (font-lock-ensure)
    (goto-char (point-min))
    (and (search-forward substring nil t)
         (get-text-property (match-beginning 0) 'face))))

;;; Tags

(ert-deftest worklog-test-tag-date ()
  (should (eq (worklog-test-face-of "@date 2026-08-19 12:00\n" "@date")
              'worklog-tag-face)))

(ert-deftest worklog-test-tag-title ()
  (should (eq (worklog-test-face-of "@title Fixed the nil-panic\n" "@title")
              'worklog-tag-face))
  (should (eq (worklog-test-face-of "@title Fixed the nil-panic\n" "Fixed the nil-panic")
              'worklog-subheading-face)))

(ert-deftest worklog-test-tag-next ()
  (should (eq (worklog-test-face-of "@next add a regression test\n" "@next")
              'worklog-tag-face))
  (should (eq (worklog-test-face-of "@next add a regression test\n" "add a regression test")
              'worklog-next-face)))

(ert-deftest worklog-test-tag-pt ()
  (should (eq (worklog-test-face-of "@pt Paragraph title\n" "@pt")
              'worklog-tag-face))
  (should (eq (worklog-test-face-of "@pt Paragraph title\n" "Paragraph title")
              'worklog-paragraph-title-face)))

;;; English words and URLs

(ert-deftest worklog-test-english-word ()
  (should (eq (worklog-test-face-of "see the variable\n" "variable")
              'worklog-english-face)))

(ert-deftest worklog-test-url ()
  (should (eq (worklog-test-face-of "see https://example.com/x\n" "https://example.com/x")
              'link)))

;;; Lists

(ert-deftest worklog-test-bullet ()
  (should (eq (worklog-test-face-of "- item\n" "-")
              'font-lock-keyword-face)))

(ert-deftest worklog-test-numbered-item ()
  (should (eq (worklog-test-face-of "1. item\n" "1.")
              'font-lock-keyword-face)))

(ert-deftest worklog-test-list-header ()
  (should (eq (worklog-test-face-of "Header:\n- item\n" "Header")
              'worklog-list-header-face)))

;;; Code blocks (native fontification)

(ert-deftest worklog-test-code-block-elisp ()
  (should (eq (worklog-test-face-of "script.el:\n\n    (defun foo () t)\n" "defun")
              'font-lock-keyword-face)))

;;; Language inference

(ert-deftest worklog-test-lang-mode ()
  (should (eq (worklog-lang-mode "el") 'emacs-lisp-mode))
  (should (eq (worklog-lang-mode "go") 'go-mode))
  (should (eq (worklog-lang-mode "md") 'markdown-mode))
  (should-not (worklog-lang-mode "")))

;;; List auto-numbering

(ert-deftest worklog-test-return-numbered ()
  (with-temp-buffer
    (worklog-mode)
    (insert "1. first item")
    (end-of-line)
    (worklog-return)
    (should (string= (buffer-string) "1. first item\n\n2. "))))

(ert-deftest worklog-test-return-bullet ()
  (with-temp-buffer
    (worklog-mode)
    (insert "- first item")
    (end-of-line)
    (worklog-return)
    (should (string= (buffer-string) "- first item\n\n- "))))

;;; Checkmark toggle

(ert-deftest worklog-test-toggle-checkmark ()
  (with-temp-buffer
    (worklog-mode)
    (insert "1. item")
    (beginning-of-line)
    (worklog-toggle-checkmark)
    (should (string= (buffer-string) "1. ✅ item"))
    (worklog-toggle-checkmark)
    (should (string= (buffer-string) "1. item"))))

;;; Fill helpers

(ert-deftest worklog-test-code-line-p ()
  (with-temp-buffer
    (insert "    code\n")
    (goto-char (point-min))
    (should (worklog-code-line-p)))
  (with-temp-buffer
    (insert "not code\n")
    (goto-char (point-min))
    (should-not (worklog-code-line-p))))

(ert-deftest worklog-test-adaptive-fill ()
  (with-temp-buffer
    (insert "- item")
    (goto-char (point-min))
    (should (string= (worklog-adaptive-fill-function) "  ")))
  (with-temp-buffer
    (insert "10. item")
    (goto-char (point-min))
    (should (string= (worklog-adaptive-fill-function) "    ")))
  (with-temp-buffer
    (insert "plain text")
    (goto-char (point-min))
    (should-not (worklog-adaptive-fill-function))))

;;; List marker and return

(ert-deftest worklog-test-next-item-marker ()
  (with-temp-buffer
    (insert "1. item")
    (end-of-line)
    (should (string= (worklog-next-item-marker) "2. ")))
  (with-temp-buffer
    (insert "- item")
    (end-of-line)
    (should (string= (worklog-next-item-marker) "- ")))
  (with-temp-buffer
    (insert "1. first item\n   continuation")
    (end-of-line)
    (should (string= (worklog-next-item-marker) "2. "))))

(ert-deftest worklog-test-return-plain ()
  (with-temp-buffer
    (worklog-mode)
    (insert "plain text")
    (end-of-line)
    (worklog-return)
    (should (string= (buffer-string) "plain text\n"))))

;;; Checkmark on bullets and plain lines

(ert-deftest worklog-test-toggle-checkmark-bullet ()
  (with-temp-buffer
    (worklog-mode)
    (insert "- item")
    (beginning-of-line)
    (worklog-toggle-checkmark)
    (should (string= (buffer-string) "- ✅ item"))
    (worklog-toggle-checkmark)
    (should (string= (buffer-string) "- item"))))

(ert-deftest worklog-test-toggle-checkmark-plain ()
  (with-temp-buffer
    (worklog-mode)
    (insert "item")
    (beginning-of-line)
    (worklog-toggle-checkmark)
    (should (string= (buffer-string) "✅ item"))
    (worklog-toggle-checkmark)
    (should (string= (buffer-string) "item"))))

;;; Language inference

(ert-deftest worklog-test-lang-mode-more ()
  (should (eq (worklog-lang-mode "sh") 'sh-mode))
  (should (eq (worklog-lang-mode "yml") 'yaml-mode))
  (should (eq (worklog-lang-mode "php") 'php-mode))
  (should (eq (worklog-lang-mode "zzz") 'zzz-mode))) ; fallback to LANG-mode

;;; Generic code-token highlighting

(ert-deftest worklog-test-code-token ()
  (should (eq (worklog-test-face-of "    function foo($x)\n" "function")
              'font-lock-keyword-face))
  (should (eq (worklog-test-face-of "    function foo($x)\n" "foo")
              'font-lock-function-name-face))
  (should (eq (worklog-test-face-of "    $x = 42;\n" "$x")
              'font-lock-variable-name-face))
  (should (eq (worklog-test-face-of "    $x = 42;\n" "42")
              'font-lock-constant-face))
  (should (eq (worklog-test-face-of "    // comment\n" "// comment")
              'font-lock-comment-face)))

;;; Tag insertion

(ert-deftest worklog-test-insert-tags ()
  (with-temp-buffer (worklog-mode) (worklog-insert-title)
    (should (string= (buffer-string) "@title ")))
  (with-temp-buffer (worklog-mode) (worklog-insert-next)
    (should (string= (buffer-string) "@next ")))
  (with-temp-buffer (worklog-mode) (worklog-insert-paragraph-title)
    (should (string= (buffer-string) "@pt "))))

(ert-deftest worklog-test-insert-date ()
  (with-temp-buffer
    (worklog-mode)
    (worklog-insert-date)
    (should (string-match-p "^@date [0-9-]+ [0-9:]+$" (buffer-string)))))

(ert-deftest worklog-test-insert-tag-mid-line ()
  (with-temp-buffer
    (worklog-mode)
    (insert "some text")
    (goto-char (+ (point-min) 4))
    (worklog-insert-title)
    (should (string= (buffer-string) "some text\n@title "))))

;;; Color options

(ert-deftest worklog-test-color-defaults ()
  (should (string= (face-foreground 'worklog-paragraph-title-face) "plum"))
  (should (string= (face-foreground 'worklog-subheading-face) "mediumpurple1"))
  (should (string= (face-foreground 'worklog-next-face) "seagreen1"))
  (should (string= (face-foreground 'worklog-english-face) "skyblue1")))

(ert-deftest worklog-test-color-option ()
  (let ((old (face-foreground 'worklog-paragraph-title-face)))
    (unwind-protect
        (progn
          (customize-set-variable 'worklog-pt-color "tomato")
          (should (string= (face-foreground 'worklog-paragraph-title-face)
                           "tomato")))
      (customize-set-variable 'worklog-pt-color old))))

;;; Project detection and open

(ert-deftest worklog-test-project-name ()
  (let ((default-directory "/tmp/projects/my-project/"))
    (should (string= (worklog-project-name) "my-project"))))

(ert-deftest worklog-test-open ()
  (let ((dir (make-temp-file "worklog-open-test" t)))
    (unwind-protect
        (let ((worklog-directory dir)
              (default-directory "/tmp/projects/my-project/"))
          (worklog-open)
          (should (derived-mode-p 'worklog-mode))
          (should (string= (buffer-file-name)
                           (expand-file-name "my-project.txt" dir))))
      (delete-directory dir t))))

;;; auto-mode-alist

(defun worklog-test-mode-for-path (path)
  "Return the `auto-mode-alist' mode matching PATH, or nil."
  (catch 'found
    (dolist (entry auto-mode-alist)
      (when (and (consp entry) (stringp (car entry))
                 (string-match-p (car entry) path))
        (throw 'found (cdr entry))))
    nil))

(ert-deftest worklog-test-auto-mode-alist-entry ()
  (should (eq (worklog-test-mode-for-path
               (expand-file-name "~/worklogs/foo.txt"))
              'worklog-mode))
  (should-not (eq (worklog-test-mode-for-path "/tmp/other/foo.txt")
                  'worklog-mode)))

(ert-deftest worklog-test-auto-mode-alist-rebuild ()
  (let ((old worklog-directory))
    (unwind-protect
        (progn
          (customize-set-variable 'worklog-directory "/tmp/wl-test")
          (should (eq (worklog-test-mode-for-path "/tmp/wl-test/bar.txt")
                      'worklog-mode)))
      (customize-set-variable 'worklog-directory old))))

;;; Configurable highlighting

(ert-deftest worklog-test-highlight-english-off ()
  (let ((old worklog-highlight-english))
    (unwind-protect
        (progn
          (customize-set-variable 'worklog-highlight-english nil)
          (should-not (worklog-test-face-of "the variable\n" "variable")))
      (customize-set-variable 'worklog-highlight-english old))))

(ert-deftest worklog-test-highlight-rules ()
  (let ((old worklog-highlight-rules))
    (unwind-protect
        (progn
          (customize-set-variable 'worklog-highlight-rules '(("[0-9]+" . "red")))
          (let ((face (worklog-test-face-of "see 42 and 123\n" "42")))
            (should face)
            (should (string= (face-foreground face) "red"))))
      (customize-set-variable 'worklog-highlight-rules old))))

(ert-deftest worklog-test-highlight-multiple-rules ()
  (let ((old worklog-highlight-rules))
    (unwind-protect
        (progn
          (customize-set-variable
           'worklog-highlight-rules
           '(("[0-9]+" . "red")
             ("TODO\\|FIXME" . "orange")))
          (should (string= (face-foreground
                            (worklog-test-face-of "see 42\n" "42"))
                           "red"))
          (should (string= (face-foreground
                            (worklog-test-face-of "TODO fix\n" "TODO"))
                           "orange")))
      (customize-set-variable 'worklog-highlight-rules old))))

(ert-deftest worklog-test-highlight-face-spec ()
  (let ((old worklog-highlight-rules))
    (unwind-protect
        (progn
          (customize-set-variable
           'worklog-highlight-rules
           '(("\\bWARNING\\b" . (:foreground "yellow" :weight bold))
             ("\\bERROR\\b" . font-lock-warning-face)))
          (let ((warn (worklog-test-face-of "WARNING disk\n" "WARNING")))
            (should warn)
            (should (string= (face-foreground warn) "yellow"))
            (should (eq (face-attribute warn :weight) 'bold)))
          (should (eq (worklog-test-face-of "ERROR x\n" "ERROR")
                      'font-lock-warning-face)))
      (customize-set-variable 'worklog-highlight-rules old))))

(ert-deftest worklog-test-highlight-case-fold ()
  (let ((old-rules worklog-highlight-rules)
        (old-fold worklog-highlight-case-fold))
    (unwind-protect
        (progn
          (customize-set-variable 'worklog-highlight-rules '(("TODO\\|FIXME" . "orange")))
          (customize-set-variable 'worklog-highlight-case-fold t)
          (let ((face (worklog-test-face-of "todo\n" "todo")))
            (should face)
            (should (string= (face-foreground face) "orange"))))
      (customize-set-variable 'worklog-highlight-case-fold old-fold)
      (customize-set-variable 'worklog-highlight-rules old-rules))))

(ert-deftest worklog-test-highlight-precedence ()
  "A custom rule must win over the English-word fallback."
  (let ((old worklog-highlight-rules))
    (unwind-protect
        (progn
          (customize-set-variable 'worklog-highlight-rules '(("\\bWARNING\\b" . "orange")))
          (should (string= (face-foreground
                            (worklog-test-face-of "WARNING\n" "WARNING"))
                           "orange")))
      (customize-set-variable 'worklog-highlight-rules old))))

(provide 'worklog-mode-tests)
;;; worklog-mode-tests.el ends here
