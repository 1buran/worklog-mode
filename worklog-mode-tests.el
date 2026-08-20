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

(provide 'worklog-mode-tests)
;;; worklog-mode-tests.el ends here
