;; init.el --- -*- lexical-binding: t -*-
;; eval: (outline-hide-sublevels 4)

;;; ======Prelude======
(require 'cl-lib)
(require 'rx)
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(require 'use-package-ensure)
(setq use-package-always-ensure t
      package-enable-at-startup nil
      use-package-compute-statistics t)

;;; ======Early Packages=====
(use-package no-littering
  :config
  (no-littering-theme-backups)
  (setq custom-file (no-littering-expand-etc-file-name "custom.el")))

;;; ======General Emacs Settings======
(use-package emacs
  :custom
  (tab-always-indent 'complete)
  :config
;;;;; Disabling ugly and largely unhelpful UI features 
  (menu-bar-mode -11)
  (tool-bar-mode -1)
  (when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
;;;;; Enable some modes that give nicer, more modern behavior
    (setq pixel-scroll-precision-interpolate-mice t
	      pixel-scroll-precision-interpolate-page t)
    (pixel-scroll-precision-mode 1)   ; smooth scrolling
    (winner-mode 1)                ; better window manipulation
    (savehist-mode 1)              ; remember commands
    (column-number-mode) ; keep track of column number for the useful modeline readout
;;;;; A basic programmming mode to build off of that adds some expected things

  (add-hook 'prog-mode-hook
	    (lambda ()
	      (prettify-symbols-mode 1)
	      (electric-pair-mode 1)
	      (electric-indent-mode 1))))

;;; ======Basic Packages======
(defun layers/core/completion ()
;;;; Vertico-style IComplete
  (use-package icomplete
    :demand t
    :bind (:map icomplete-minibuffer-map
	        ("RET"    . icomplete-force-complete-and-exit)
	        ("M-RET"  . icomplete-fido-exit)
	        ("TAB"    . icomplete-force-complete)
	        ("DEL"    . icomplete-fido-backward-updir)
	        ("M-."    . embark-act) ; mostly useful in case you don't have evil mode enabled (if you do, just do {ESC g .})
	        ("<down>" . icomplete-forward-completions)
	        ("<up>"   . icomplete-backward-completions))
    :config
    ;; remove arbitrary optimization limits that make icomplete
    ;; feel old-fashioned
    (setq icomplete-delay-completions-threshold 0)
    (setq icomplete-max-delay-chars 0)
    (setq icomplete-compute-delay 0)
    (setq icomplete-show-matches-on-no-input t)
    (setq icomplete-hide-common-prefix nil)
    (setq icomplete-prospects-height 15)
    (setq icomplete-with-completion-tables t)
    (icomplete-vertical-mode 1))
  ;;;; Minibuffer completion and searching improvement packages
  (use-package marginalia
    :after icomplete
    :init
    (marginalia-mode))

  (use-package orderless
    :after icomplete
    :init
    (setq completion-styles '(orderless flex substring)
	  orderless-component-separator "-"
          orderless-matching-styles '(orderless-literal orderless-regexp)
	  completion-category-defaults nil
	  completion-category-overrides '((file (styles partial-completion))))))

(defun layers/core/usability ()
;;;; better search and completion
  (use-package consult
    :commands (consult-grep consult-ripgrep consult-man consult-theme)
    :bind (("M-g i"   . #'consult-imenu) ;; override regular imenu
           ("M-s r"   . #'consult-ripgrep)
           ("M-s f"   . #'consult-grep)
	   ("C-s"     . #'consult-line)
           ("C-x C-r" . #'consult-recent-file))
    :config
    ;; We also want to use this for in-buffer completion, which icomplete can't do alone
    (setq xref-show-xrefs-function #'consult-xref
	  xref-show-definitions-function #'consult-xref)
    (setq completion-in-region-function
	  (lambda (&rest args)
            (apply (if fido-mode
                       #'consult-completion-in-region
		     #'completion--in-region)
                   args))))
;;;; Better  popups
  (use-package which-key
    :init (which-key-mode)
    :diminish which-key-mode
    :custom
    (which-key-idle-delay 0.1)
    (which-key-idle-secondary-delay nil)
    (which-key-sort-order #'which-key-key-order-alpha)
    :config
    (which-key-enable-god-mode-support))
;;;; Better Emacs Lisp editing experience

  (use-package elisp-def
    :hook (emacs-lisp-mode . elisp-def-mode))

  (use-package highlight-defined
    :hook (emacs-lisp-mode . highlight-defined-mode))

  (use-package outline
    :bind-keymap ("C-c C-o" . outline-mode-prefix-map)
    :hook ((prog-mode . outline-minor-mode)
	   (text-mode . outline-minor-mode))
    :config
    (add-hook 'outline-minor-mode-hook (lambda ()
					 (outline-show-all))))
;;;; embark
  (use-package embark
    :commands (embark-act embark-dwim))
;;;;; Embark-Consult integration package
  (use-package embark-consult
    :hook (embark-collect-mode . consult-preview-at-point-mode)))
;;;; Core largely unopinionated evil-mode layer
(defun layers/core/editing ()
;;;;; Evil mode itself (and associated integrations)
  (use-package evil
    :custom
    (evil-want-integration t)
    (evil-want-minibuffer t)
    (evil-want-keybinding nil)
    (evil-want-C-u-scroll t)
    (evil-want-C-i-jump nil)
    (evil-undo-system 'undo-redo)
    (evil-kill-on-visual-paste nil) ;; oh thank god
    (evil-move-beyond-eol t) ;; so that it's easier to evaluate sexprs in normal mode
    :config
    (evil-mode 1)
;;;;; Custom evil mode key bindings
    ;; Override evil mode's exceptions to defaulting to normal-mode
    (evil-set-initial-state 'enlight-mode 'motion)
    (evil-set-initial-state 'minibuffer-mode 'insert))
  
  (use-package evil-collection
    :after (evil)
    :config
    (evil-collection-init))

  
  (use-package evil-cleverparens
    :after (evil)
    :hook ((lisp-mode . evil-cleverparens-mode)
           (emacs-lisp-mode . evil-cleverparens-mode))))
;;;; UI layer
(defun layers/core/ui ()
  (unless window-system
    (load-theme 'modus-vivendi))
  ;; A super-fast modeline that also won't make me wish I didn't have eyes at least
  (use-package mood-line
    :after (evil)
    :custom
    (mood-line-glyph-alist mood-line-glyphs-unicode)
    (mood-line-segment-modal-evil-state-alist 
     '((normal . ("Ⓝ" . font-lock-variable-name-face))
       (insert . ("Ⓘ" . font-lock-string-face))
       (visual . ("Ⓥ" . font-lock-keyword-face))
       (replace . ("Ⓡ" . font-lock-type-face))
       (motion . ("Ⓜ" . font-lock-constant-face))
       (operator . ("Ⓞ" . font-lock-function-name-face))
       (god . ("Ⓖ" . font-lock-function-name-face))
       (emacs . ("Ⓔ" . font-lock-builtin-face))) )
    (mood-line-format
     (mood-line-defformat
      :left
      (((mood-line-segment-modal) . "\t")
       ((or (mood-line-segment-buffer-status) " ") . " ")
       ((mood-line-segment-buffer-name) . "\t")
       ((mood-line-segment-cursor-position) . " ")
       (mood-line-segment-scroll))
      :right
      (((mood-line-segment-vc) . "\t")
       ((mood-line-segment-major-mode) . "\t")
       ((mood-line-segment-checker) . "\t"))))
    :config
    (mood-line-mode)))
;;; =====task specific layers======
;;;; general programming
(defun layers/task/coding ()
;;;;; completion at point
  (use-package corfu
    :hook (prog-mode . corfu-mode)
    :custom
    (corfu-cycle t)                
    (corfu-auto t)                 
    (corfu-quit-no-match 'separator)
    (corfu-auto-delay 0.15)
    (corfu-auto-prefix 2)
    :config
    (define-key corfu-map (kbd "RET") nil))
  (use-package corfu-terminal
    :hook corfu-mode
    :unless window-system
    :after corfu)
;;;;; lsp
  (use-package eglot
    :commands (eglot eglot-ensure)
    :preface
    (add-hook 'prog-mode-hook
	      (lambda ()
		(interactive)
		(unless (ignore-errors
                          (command-execute #'eglot-ensure))
                  (message "Info: no LSP found for this file.")))) 
    :config
    (add-hook 'eglot-managed-mode-hook
              (lambda () (add-hook 'before-save-hook 'eglot-format-buffer nil t)))
    (setq eglot-autoshutdown t
          eglot-sync-connect nil)))

;;; ====load layers====
(dolist (layer (list
		#'layers/core/completion
		#'layers/core/usability
		#'layers/core/editing
		#'layers/core/ui
		#'layers/task/coding))
  (setq start-time (current-time))
  (funcall layer)
  (message "Finished enabling layers %s in %.2f seconds" layer (float-time (time-since start-time))))
