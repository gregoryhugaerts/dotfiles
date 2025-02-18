;;; init.el --- emacs initialisation -*- lexical-binding: t; -*-
;;; Code:
;;; Don't collect garbage during init
(setq gc-cons-threshold-original gc-cons-threshold)
(setq gc-cons-threshold most-positive-fixnum)
(run-with-timer 5 0 (lambda ()
                      (setq gc-cons-threshold gc-cons-threshold-original)
                      (message "Restored GC cons threshold")))
;;; Package Management
;;;; set up use-package
(use-package package
  :custom
  (package-native-compile t)
  (package-install-upgrade-built-in t)
  (package-quickstart t)
  :config
  (setq package-enable-at-startup nil)
  (add-to-list 'package-archives
               '("melpa" . "https://melpa.org/packages/")))

(use-package use-package
  :custom
  (use-package-always-ensure t)
  (use-package-enable-imenu-support t)
  (use-package-compute-statistics t)
  (warning-minimum-level :emergency))

(use-package diminish)

(unless (package-installed-p 'vc-use-package)
  (package-vc-install "https://github.com/slotThe/vc-use-package"))
(require 'vc-use-package)
;;; Early Packages and functions
;;;; load secrets
(load (concat user-emacs-directory "personal.el") :no-error-if-file-is-missing)
;;;; no-littering
;; keep user directory clean
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file :no-error-if-file-is-missing)
(use-package no-littering
  :config
  (no-littering-theme-backups)
  (let ((dir (no-littering-expand-var-file-name "lock-files/")))
    (make-directory dir t)
    (setq lock-file-name-transforms `((".*" ,dir t)))))
;;; General settings
(use-package emacs
  :defer nil
  :init
  (defun crm-indicator (args)
    (cons (format "[CRM%s] %s"
                  (replace-regexp-in-string
                   "\\`\\[.*?]\\*\\|\\[.*?]\\*\\'" ""
                   crm-separator)
                  (car args))
          (cdr args)))
  (advice-add #'completing-read-multiple :filter-args #'crm-indicator)
  :config
  (setq tab-always-indent 'complete
	use-short-answers t
	read-extended-command-predicate #'command-completion-default-include-p
	load-prefer-newer t
	inhibit-startup-screen t
	inhibit-startup-echo-area-message t
	initial-major-mode 'fundamental-mode
	project-vc-extra-root-markers '(".dir-locals.el"))
  (setq browse-url-secondary-browser-function 'browse-url-xdg-open)
  (add-hook 'after-init-hook (lambda ()
			       (savehist-mode 1)))
  (add-hook 'prog-mode-hook (lambda ()
			      (electric-pair-local-mode 1)
			      (prettify-symbols-mode 1))))

(use-package recentf
  :ensure nil
  :after no-littering
  :hook (after-init . recentf-mode)
  :custom
  (recentf-auto-cleanup 'never)
  :config
  (add-to-list 'recentf-exclude
               (recentf-expand-file-name no-littering-var-directory))
  (add-to-list 'recentf-exclude
               (recentf-expand-file-name no-littering-etc-directory)))

(use-package dired
  :ensure nil
  :hook (dired-mode . dired-hide-details-mode)
  :commands (dired dired-jump)
  :config
  (setq dired-dwim-target t
	dired-kill-when-opening-new-dired-buffer t))
;;; Emacs Completion
;;;; Vertico
(use-package vertico
  :config
  (vertico-mode))
;;;; Minibuffer completion and searching improvement packages
(use-package marginalia
  :config (marginalia-mode))

(use-package orderless
  :custom
  ;; Configure a custom style dispatcher (see the Consult wiki)
  ;; (orderless-style-dispatchers '(+orderless-consult-dispatch orderless-affix-dispatch))
  ;; (orderless-component-separator #'orderless-escapable-split-on-space)
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))

;;; Usability
;;;; consult.el - Consulting completing-read
(use-package consult
  :commands (consult-completion-in-region)
  :bind (("C-x b"   . consult-buffer)
	 ("C-c M-x" . consult-mode-command)
	 ("M-y" . consult-yank-pop)
	 ("M-g g" . consult-goto-line)
         ("M-g M-g" . consult-goto-line)
         ("M-g o" . consult-outline)
	 ("C-x C-r" . consult-recent-file)
	 ("M-g i"   . #'consult-imenu) ;; override regular imenu
         ("M-s r"   . #'consult-ripgrep)
         ("M-s f"   . #'consult-grep)
	 ("M-s l"   . consult-line)
	 ("C-s" . #'consult-line))
  :config
  (setq consult-narrow-key "<")
  :init
  (setq xref-show-xrefs-function #'consult-xref
	xref-show-definitions-function #'consult-xref)
  (unless  window-system
    (setq completion-in-region-function #'consult-completion-in-region)))
;;;; which-key
(use-package which-key
  :custom
  (which-key-sort-order #'which-key-key-order-alpha)
  :config
  (which-key-mode)
  (with-eval-after-load 'god-mode
    (which-key-enable-god-mode-support)))
;;;; embark
(use-package embark
  :commands (embark-act embark-dwim)
  :bind (("M-." . embark-act)
	 ("C-h B" . embark-bindings)
	 :map embark-general-map
	 ("G" . embark-internet-search)
	 ("O" . embark-default-action-in-other-window))
  :config
;;;;; Use `which-key' to display possible actions instead of a separate buffer
  (defun embark-which-key-indicator ()
    "An embark indicator that displays keymaps using which-key.
The which-key help message will show the type and value of the
current target followed by an ellipsis if there are further
targets."
    (lambda (&optional keymap targets prefix)
      (if (null keymap)
          (which-key--hide-popup-ignore-command)
        (which-key--show-keymap
         (if (eq (plist-get (car targets) :type) 'embark-become)
             "Become"
           (format "Act on %s '%s'%s"
                   (plist-get (car targets) :type)
                   (embark--truncate-target (plist-get (car targets) :target))
                   (if (cdr targets) "…" "")))
         (if prefix
             (pcase (lookup-key keymap prefix 'accept-default)
               ((and (pred keymapp) km) km)
               (_ (key-binding prefix 'accept-default)))
           keymap)
         nil nil t (lambda (binding)
                     (not (string-suffix-p "-argument" (cdr binding))))))))

  (setq embark-indicators
        '(embark-which-key-indicator
          embark-highlight-indicator
          embark-isearch-highlight-indicator))

  (defun embark-hide-which-key-indicator (fn &rest args)
    "Hide the which-key indicator immediately when using the completing-read prompter."
    (which-key--hide-popup-ignore-command)
    (let ((embark-indicators
           (remq #'embark-which-key-indicator embark-indicators)))
      (apply fn args)))

  (advice-add #'embark-completing-read-prompter
              :around #'embark-hide-which-key-indicator)
;;;;; Add useful Hyperbole-style actions to Embark
;;;;;; Search DuckDuckGo for the given term
  (defun embark-internet-search (term)
    (interactive "sSearch Term: ")
    (browse-url
     (format "https://duckduckgo.com/search?q=%s" term)))
;;;;;; Run default action in another Emacs window
  (defun embark-default-action-in-other-window ()
    "Run the default embark action in another window."
    (interactive))

  (cl-defun run-default-action-in-other-window
      (&rest rest &key run type &allow-other-keys)
    (let ((default-action (embark--default-action type)))
      (split-window-below) ; or your preferred way to split
      (funcall run :action default-action :type type rest)))

  (setf (alist-get 'embark-default-action-in-other-window
		   embark-around-action-hooks)
	'(run-default-action-in-other-window))
;;;;;;; GNU Hyperbole-style execute textual representation of keyboard macro
  (defun embark-kmacro-target ()
    "Target a textual kmacro in braces."
    (save-excursion
      (let ((beg (progn (skip-chars-backward "^{}\n") (point)))
	    (end (progn (skip-chars-forward "^{}\n") (point))))
	(when (and (eq (char-before beg) ?{) (eq (char-after end) ?}))
	  `(kmacro ,(buffer-substring-no-properties beg end)
		   . (,(1- beg) . ,(1+ end)))))))

  (add-to-list 'embark-target-finders 'embark-kmacro-target)

  (defun embark-kmacro-run (arg kmacro)
    (interactive "p\nsKmacro: ")
    (kmacro-call-macro arg t nil (kbd kmacro)))

  (defun embark-kmacro-name (kmacro name)
    (interactive "sKmacro: \nSName: ")
    (let ((last-kbd-macro (kbd kmacro)))
      (kmacro-name-last-macro name)))

  (defvar-keymap embark-kmacro-map
    :doc "Actions on kmacros."
    :parent embark-general-map
    "RET" #'embark-kmacro-run
    "n" #'embark-kmacro-name)

  (add-to-list 'embark-keymap-alist '(kmacro . embark-kmacro-map))
  
;;;;;;; better help
  (with-eval-after-load 'shell
    (define-key shell-mode-map [remap display-local-help] #'man))
  (with-eval-after-load 'sh-script
    (define-key sh-mode-map [remap display-local-help] #'man))
  (with-eval-after-load 'esh-mode
    (define-key eshell-mode-map [remap display-local-help] #'man))
  )

;;;;;; Embark-Consult integration package
(use-package embark-consult
  :after emabark
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(use-package wgrep
  :defer t
  :custom
  (wgrep-auto-save-buffer t)
  (wgrep-enable-key "i"))

;;;;;; link hint
(use-package link-hint
  :bind
  ("C-c l o" . link-hint-open-link)
  ("C-c l c" . link-hint-copy-link)
  ("M-." . link-hint-open-link-at-point)
  :config
  (setq link-hint-action-fallback-commands
	(list :open (lambda ()
                      (condition-case _
                          (progn
                            (embark-act)
                            t)
			(error
			 nil))))))
;;; UI
;;;; theme
(use-package modus-themes
  :init
  (load-theme 'modus-vivendi-tinted :no-confirm))

;;;; mode line
(use-package mood-line
  :init
  (add-hook 'after-init-hook (lambda () (mood-line-mode)))
  :custom
  (mood-line-glyph-
   alist mood-line-glyphs-unicode))

;;; Coding
;;;; general
;;;;; folding
(use-package treesit-fold
  :hook (prog-mode . treesit-fold-mode))
;;;;; git
(use-package magit
  :commands (magit magit-status))
;;;;; corfu
(use-package corfu
  :hook (prog-mode)
  ;; TAB-and-Go customizations
  :custom
  (corfu-cycle t)           ;; Enable cycling for `corfu-next/previous'
  (corfu-auto t)
  (corfu-preselect 'prompt) ;; Always preselect the prompt
  ;; Use TAB for cycling, default is `corfu-complete'.
  :bind
  (:map corfu-map
        ("TAB" . corfu-next)
        ([tab] . corfu-next)
        ("S-TAB" . corfu-previous)
        ([backtab] . corfu-previous)))
(use-package corfu-terminal
  :after corfu
  :unless window-system
  :config
  (corfu-terminal-mode 1))
;;;;; eglot - LSP client
(use-package eglot
  :commands (eglot eglot-ensure)
  :preface
  (add-hook 'prog-mode-hook (lambda ()
			      (interactive)
			      (ignore-errors (command-execute #'eglot-ensure))))
  :config
  (add-hook 'eglot-managed-mode-hook
	    (lambda () (add-hook 'before-save-hook 'eglot-format-buffer nil t)))
  (setq eglot-autoshutdown t
	eglot-sync-connect nil))
;;;;; TempEl - Simple templates for Emacs
(use-package tempel
  :bind (("M-+" . tempel-complete)
         ("M-*" . tempel-insert))
  :init
  ;; Setup completion at point
  (defun tempel-setup-capf ()
    (setq-local completion-at-point-functions
                (cons #'tempel-expand
                      completion-at-point-functions)))

  (add-hook 'conf-mode-hook 'tempel-setup-capf)
  (add-hook 'org-mode-hook 'tempel-setup-capf)
  (add-hook 'prog-mode-hook 'tempel-setup-capf)
  (add-hook 'text-mode-hook 'tempel-setup-capf))
(use-package tempel-collection
  :after tempel)

(use-package eglot-tempel
  :after tempel
  :config
  (eglot-tempel-mode 1))
;;;;; treesit-auto - automatic grammar installation
(use-package treesit-auto
  :custom
  (treesit-auto-install t)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))
;;;;; Cape - Completion At Point Extensions
(use-package cape
  :bind ("C-c p" . cape-prefix-map)
  :init
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-elisp-block)
  (add-hook 'completion-at-point-functions #'cape-keyword))

;;;;; devdocs
(use-package devdocs
  :bind ("C-h D" . devdocs-lookup)
  :commands (devdocs-lookup devdocs-install))
;;;; rust
(use-package rust-mode
  :defer t
  :init
  (setq rust-mode-treesitter-derive t))

(use-package rustic
  :mode "\\.rs\\'"
  :after rust-mode
  :config
  (setq rustic-lsp-client 'eglot))
;;;; python
;;;;; docstring
(use-package python-insert-docstring
  :commands (python-insert-docstring-with-google-style-at-point))
;;;;; direnv
(use-package envrc
  :if (executable-find "direnv")
  :hook (after-init . envrc-global-mode))
;;; Notes
;;;; Denote
(use-package denote
  :after org
  :commands (denote denote-link-after-creating denote-region denote-silo denote-open-or-create)
  :init
  (require 'denote-org-dblock)
  (denote-rename-buffer-mode 1)
  :config
  (if (equal system-configuration "aarch64-unknown-linux-android")
      (setq denote-directory "~/storage/shared/Documents/kb")
    (setq denote-directory "~/KnowledgeBase"))
  :hook
  (dired-mode . denote-dired-mode)
  :custom
  (denote-known-keywords '())
  (denote-infer-keywords t)
  (denote-prompts-with-history-as-completion t)
  (denote-prompts '(title keywords))
  (denote-backlinks-show-context t)
  (denote-journal-extras-title-format 'day-date-month-year)
  :custom-face
  (denote-faces-link ((t (:slant italic)))))

;; Denote extensions

(use-package consult-notes
  :commands (consult-notes consult-notes-search-in-all-notes)
  :config
  (consult-notes-denote-mode)
  (consult-notes-org-headings-mode))

(use-package denote-explore
  :after denote
  :defer t)

(use-package citar-denote
  :after (citar denote)
  :defer t
  :custom
  (citar-open-always-create-notes t)
  (citar-denote-subdir "bib")
  :init
  (citar-denote-mode))

;;;; bibtex
(use-package bibtex
  :defer t
  :custom
  (bibtex-dialect 'BibTeX)
  (bibtex-user-optional-fields
   '(("keywords" "Keywords to describe the entry" "")
     ("file" "Link to a document file." "" )))
  (bibtex-align-at-equal-sign t)
  :config
  (if (equal system-configuration "aarch64-unknown-linux-android")
      (setq bibtex-files '("~/storage/shared/Documents/bibtex/bibtex.bib"))
    (setq bibtex-files '("~/bibtex/bibtex.bib"))))

(use-package biblio
  :commands (biblio-lookup))
(use-package biblio-gbooks
  :after biblio)

(use-package citar
  :hook
  (org-mode . citar-capf-setup)
  :commands (citar-open org-cite-insert)
  :custom
  (citar-bibliography bibtex-files)
  :config
  (setq citar-at-point-function 'embark-act)
  (setq org-cite-global-bibliography bibtex-files
	org-cite-insert-processor 'citar
	org-cite-follow-processor 'citar
	org-cite-activate-processor 'citar))

(use-package citar-embark
  :after citar embark
  :no-require
  :diminish citar-embark-mode
  :config (citar-embark-mode))


;;;; org mode
(use-package org
  :ensure nil
  :commands (org-mode org-capture org-agenda)
  :bind
  (("C-c a" . org-agenda)
   ("C-c c" . org-capture))
  :config
  (add-hook 'org-mode-hook (lambda ()
			     (visual-line-mode 1)))
  (when (equal system-configuration "aarch64-unknown-linux-android")
    (setq org-directory "~/storage/shared/Documents/org"))
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((plantuml . t)))

  (defun my/org-agenda-entry-get-repeat ()
    "Get the repeater of the current entry with 'org-get-repeat'."
    (when-let ((marker (org-get-at-bol 'org-marker))
               (buffer (marker-buffer marker))
               (pos (marker-position marker)))
      (with-current-buffer buffer
	(goto-char pos)
	(org-get-repeat))))

  (defun my/org-agenda-update-repeated-entry()
    "Update the scheduled leader to repeater for current entry.

e.g., Replace 'Scheduled:' to 'Rept .+1d:'."
    (save-excursion
      (when-let ((org-repeat (my/org-agenda-entry-get-repeat))
		 (rept-str (format "Rep %4s: " org-repeat))
		 (scheduled-leader (car org-agenda-scheduled-leaders)))
	(when (search-backward scheduled-leader (pos-bol) t)
          (delete-forward-char (length scheduled-leader))
          (insert-and-inherit rept-str)))))

  (defun my/org-agenda-update-repeated-entries ()
    "Update the scheduled leader to repeater for all entries."
    (save-excursion
      (goto-char (point-min))
      (while (text-property-search-forward 'type "scheduled" t)
	(my/org-agenda-update-repeated-entry))))

  (add-hook 'org-agenda-finalize-hook #'my/org-agenda-update-repeated-entries)

  (setq org-plantuml-exec-mode 'plantuml
	org-plantuml-args '("-headless"))
  (setq org-return-follows-link t
	org-export-exclude-tags '("person" "private")
	org-export-with-broken-links nil
	org-export-use-babel t
	org-confirm-babel-evaluate nil
	org-export-with-section-numbers 1
	org-export-allow-bind-keywords t
	org-log-done 'time
	org-use-speed-commands t
	org-yank-adjusted-subtrees t
	org-hide-emphasis-markers t
	org-log-into-drawer t
	org-default-notes-file (concat org-directory "/inbox.org")
	org-agenda-skip-scheduled-if-done t
	org-agenda-skip-deadline-if-done t
	org-agenda-skip-timestamp-if-done t
	org-agenda-span 'day
	org-refile-targets '((nil :maxlevel . 3)
			     (org-agenda-files :maxlevel . 3))
	org-stuck-projects '("+LEVEL=2/-DONE" ("NEXT" "WAIT") nil "")
	org-ellipsis "  "
	org-startup-indented t
	org-M-RET-may-split-line '((default . nil))
	org-image-actual-width (list 300)
	org-attach-id-dir "assets/"
	org-pretty-entities t
	org-fontify-done-headline t
	org-deadline-warning-days 7
	org-fontify-quote-and-verse-blocks t
	org-tags-column 0
	org-global-properties '(("Effort_ALL" . "0:05 0:15 0:30 0:45 1:00 2:00 3:00"))
	org-auto-align-tags nil
	org-startup-folded t
	org-special-ctrl-a/e t
	org-insert-heading-respect-content nil
	org-agenda-tags-column 0
	calendar-location-name "Oostende"
	calendar-latutude 51.2
	calendar-longitude 2.9
	org-columns-default-format-for-agenda "%4Effort(Estimated Effort){:} %TODO %25ITEM(Task) %3PRIORITY %TAGS")
  (setq org-tag-alist
	'(;; Places
          ("@home" . ?h)
          ("@work" . ?w)

          ;; Devices
          ("@computer" . ?c)
          ("@phone" . ?p)

          ;; Activities
          ("@programming" . ?P)
          ("@email" . ?e)
          ("@calls" . ?a)
          ("@shop" . ?s)))
  (defun my/org-agenda-recent-open-loops ()
    (interactive)
    (let ((org-agenda-start-with-log-mode t)
          (org-agenda-use-time-grid nil))
      (org-agenda-list nil (org-read-date nil nil "-2d") 4)
      (beginend-org-agenda-mode-goto-beginning)))
  (defun my/org-agenda-longer-open-loops ()
    (interactive)
    (let ((org-agenda-start-with-log-mode t)
          (org-agenda-use-time-grid nil))
      (org-agenda-list nil (org-read-date nil nil "-14d") 28)
      (beginend-org-agenda-mode-goto-beginning)))

  (setq org-agenda-files (list org-directory)))
;;;; org-nice-html
(use-package nice-org-html
  :hook (org-mode . nice-org-html-mode)
  :after org
  :config
  (setq org-publish-project-alist
	`(("Knowledge Base"
	   :base-directory ,(concat org-directory "/../kb")
	   :auto-sitemap t
	   :exclude "person.org"
	   :base-extension "org"
	   :with-tags nil
	   :publishing-directory ,(concat org-directory "/../export")
	   :publishing-function nice-org-html-publish-to-html)))
  (setq nice-org-html-theme-alist
        '((light . modus-operandi-tinted)
          (dark  . modus-vivendi-tinted)))
  (setq nice-org-html-default-mode 'dark)
  (setq nice-org-html-options '(:layout "compact" :collapsing t))
  (setq nice-org-html-headline-bullets nil))
;;;; org modern
(use-package org-modern
  :after org
  :commands (org-modern-mode global-org-modern-mode)
  :custom
  (org-modern-star 'replace)
  :config
  (global-org-modern-mode))
;;;; org-gtd
(use-package org-gtd
  :after org
  :bind
  (("C-c a" . org-gtd-engage)
   ("C-c c" . org-gtd-capture)
   :map org-gtd-clarify-map
   ("C-c c" . org-gtd-organize))
  :commands (org-gtd-engage org-gtd-capture)
  :custom
  (org-gtd-directory org-directory)
  :init
  (with-eval-after-load 'org-gtd-capture
    (add-to-list 'org-gtd-capture-templates '("n" "Permanent note" plain
					      (file denote-last-path)
					      #'denote-org-capture
					      :no-save t
					      :immediate-finish nil
					      :kill-buffer t
					      :jump-to-captured t))

    (add-to-list 'org-gtd-capture-templates '("a" "Application" entry (file+headline "solicitaties.org" "Applications")
					      "* %\1 - %\2%^{COMPANY}p%^{JOBTITLE}p%^{LINK}p\n:PROPERTIES:\n:DATE: %u\n:END:\n%?") :append))
  :config
  (setq org-edna-use-inheritance t)
  (org-edna-mode)
  (org-gtd-mode 1)
  (setq org-gtd-organize-hooks '(org-set-tags-command org-set-effort org-gtd-set-area-of-focus)))
;;;; org-contacts
(use-package org-contacts
  :after org
  :custom
  (org-contacts-files `(,(concat org-directory "/person.org")))
  :commands (org-contacts)
  :init
  (with-eval-after-load 'org-gtd-capture
    (add-to-list 'org-gtd-capture-templates '("p" "person" entry (file "person.org")
					      "* %(org-contacts-template-name)%^{COMPANY}p%^{JOBTITLE}p\n:PROPERTIES:\n:EMAIL: %(org-contacts-template-email)\n:END:")))) 
;;; Information gathering
;;;; Elfeed - rss reader
(use-package elfeed
  :commands (elfeed elfeed-update))
(use-package elfeed-protocol
  :disable t
  :after elfeed
  :custom
  ((elfeed-use-curl t)
   (elfeed-curl-extra-arguments '("--insecure"))
   (elfeed-protocol-fever-update-unread-only t)
   (elfeed-protocol-fever-fetch-category-as-tag t)
   (elfeed-protocol-enabled-protocols '(fever))
   (elfeed-protocol-feeds
    `((,my/elfeed-url
       :api-url ,my/elfeed-api-url
       :password ,my/elfeed-password))))
  :config
  (elfeed-set-timeout 36000)
  (elfeed-protocol-enable))
;;;; NotMuch - email reader
(use-package notmuch
  :commands (notmuch notmuch-search notmuch-poll)
  :custom
  ((notmuch-archive-tags '("-inbox" "-unread" "+archive"))
   (notmuch-tagging-keys
    '(("a" notmuch-archive-tags "Archive")
      ("u" notmuch-show-mark-read-tags "Mark read")
      ("f"
       ("+flagged")
       "Flag")
      ("s"
       ("+spam" "-inbox" "-unread")
       "Mark as spam")
      ("d"
       ("+trash" "-unread" "-inbox")
       "Delete")))))

(use-package notmuch-transient
  :after notmuch)

(use-package ol-notmuch
  :defer t
  :after org)

;;; Transients
;;;; disproject - transient for project.el
(use-package disproject
  ;; Replace `project-prefix-map' with `disproject-dispatch'.
  :bind ( :map ctl-x-map
          ("p" . disproject-dispatch)))
;;;; own transients
(use-package transient
  :bind ("C-c o" . my/general-transient)
  :config
  (transient-define-prefix my/general-transient ()
    [["Apps"
      ("a" "agenda" org-gtd-engage)
      ("c" "capture" org-gtd-capture)
      ("r" "rss" elfeed)
      ("e" "email" notmuch)]
     ["KB"
      ("f" "find note" consult-denote-find)
      ("i" "insert link" denote-link-or-create :if-mode org-mode)
      ("j" "journal" denote-journal-extras-new-or-existing-entry)
      ("g" "grep KB" consult-denote-grep)]
     ["Misc"
      ("m" "context aware" context-transient :if (lambda () (context-transient--run-hook-collect-results 'context-transient-hook)))
      ("m" "consult mode" consult-mode-command :if-not (lambda () (context-transient--run-hook-collect-results 'context-transient-hook)))
      ("." "embark" embark-act)
      ("'" "embark(dwim)" embark-dwim)]]))
;;; context transients
(use-package context-transient
  :bind ("M-o" . context-transient)
  :config
  (context-transient-define my/denote-transient
			    :doc "transient for denote"
			    :context (string= "./" denote-directory)
			    :menu
			    [["links"
			      ("l" "links" denote-find-link)
			      ("b" "backlinks" denote-find-backlink)
			      ("B" "backlinks buffer" denote-backlinks)]
			     ["files"
			      ("f" "file" consult-denote-find)
			      ("i" "insert link" denote-link-or-create)
			      ("j" "journal" denote-journal-extras-new-or-existing-entry)]])
  (context-transient-define my/org-agenda-transient
			    :doc "Transient fo org-agenda mode"
			    :mode 'org-agenda-mode
			    :menu
			    [["place"
			      ("c" "clarify" org-gtd-clarify-agenda-item)
			      ("a" "area" org-gtd-area-of-focus-set-on-agenda-item)]
			     ["time"
			      ("e" "effort" org-agenda-set-effort)
			      ("s" "schedule" org-agenda-schedule)
			      ("d" "deadline" org-agenda-deadline)]
			     ["misc"
			      ("S" "save all" org-save-all-org-buffers)]]))
;;; utility
;;;; consult-omni
(use-package consult-omni
  :defer t
  :vc (:fetcher github :repo "armindarvish/consult-omni")
    :after consult
  :custom
   ;; General settings that apply to all sources
  (consult-omni-show-preview t) ;;; show previews
  (consult-omni-preview-key "C-o") ;;; set the preview key to C-o
  :config
  ;; Load Sources Core code
  (require 'consult-omni-sources)
  ;; Load Embark Actions
  (require 'consult-omni-embark)
  (consult-omni-sources-load-modules))
;;;; org-capture-ref
(use-package persid
  :defer t
  :vc (:fetcher github :repo "rougier/persid/"))
(use-package org-capture-ref
  :defer t
  :vc (:fetcher github :repo "yantar92/org-capture-ref")
  :config
  (org-capture-ref-set-capture-template))
;;;; beginend - better begin and end buffer
(use-package beginend
  :diminish beginend-global-mode
  :config
  (beginend-global-mode))
;;;; try - try emacs packages without permanently installing them
(use-package try
  :after package
  :commands try)
;;;; crux - various utility functions
(use-package crux
  :bind (("C-a" . crux-move-beginning-of-line)
	 ("C-e" . crux-move-end-of-line)
	 ("C-k" . crux-smart-kill-line))
  :defer t)
;;;; shrface - better shr rendering
(use-package shrface
  :commands (shrface-mode)
  :hook (eww-mode)
  :config
  (setq shrface-href-versatile t)
  (add-hook 'outline-view-change-hook 'shrface-outline-visibility-changed)
  (with-eval-after-load 'eww
    (define-key eww-mode-map (kbd "<tab>") 'shrface-outline-cycle)
    (define-key eww-mode-map (kbd "TAB") 'shrface-outline-cycle)
    (define-key eww-mode-map (kbd "S-<tab>")
		'shrface-outline-cycle-buffer)
    (define-key eww-mode-map (kbd "S-TAB") 'shrface-outline-cycle-buffer)
    (define-key eww-mode-map (kbd "C-t") 'shrface-toggle-bullets)
    (define-key eww-mode-map (kbd "C-j") 'shrface-next-headline)
    (define-key eww-mode-map (kbd "C-k") 'shrface-previous-headline)
    (define-key eww-mode-map (kbd "M-l") 'shrface-links-consult)
    (define-key eww-mode-map (kbd "M-h") 'shrface-headline-consult)))

(use-package shr-tag-pre-highlight
  :ensure t
  :after shr
  :config
  (add-to-list 'shr-external-rendering-functions '(pre . shrface-shr-tag-pre-highlight))
  (defun shrface-shr-tag-pre-highlight (pre)
    "Highlighting code in PRE."
    (let* ((shr-folding-mode 'none)
           (shr-current-font 'default)
           (code (with-temp-buffer
                   (shr-generic pre)
                   ;; (indent-rigidly (point-min) (point-max) 2)
                   (buffer-string)))
           (lang (or (shr-tag-pre-highlight-guess-language-attr pre)
                     (let ((sym (language-detection-string code)))
                       (and sym (symbol-name sym)))))
           (mode (and lang
                      (shr-tag-pre-highlight--get-lang-mode lang))))
      (shr-ensure-newline)
      (shr-ensure-newline)
      (setq start (point))
      (insert
       (propertize (concat "#+BEGIN_SRC " lang "\n") 'face 'org-block-begin-line)
       (or (and (fboundp mode)
                (with-demoted-errors "Error while fontifying: %S"
                  (shr-tag-pre-highlight-fontify code mode)))
           code)
       (propertize "#+END_SRC" 'face 'org-block-end-line ))
      (shr-ensure-newline)
      (setq end (point))
      (shr-ensure-newline)
      (insert "\n"))))
;;;; orgmdb - watchlist manager and OMDb API client
(use-package orgmdb
  :commands (orgmdb-act)
  :config
  (setq orgmdb-omdb-apikey my/omdb-api-key))
;;;; eat - better terminal emulator
(use-package eat
  :commands (eat eat-project)
  :config
  (eat-eshell-mode t))
;; random functions
(defun unpackaged/org-fix-blank-lines (&optional prefix)
  "Ensure that blank lines exist between headings and between headings and their contents.
With prefix, operate on whole buffer. Ensures that blank lines
exist after each headings's drawers."
  (interactive "P")
  (org-map-entries (lambda ()
		     (org-with-wide-buffer
		      ;; `org-map-entries' narrows the buffer, which prevents us from seeing
		      ;; newlines before the current heading, so we do this part widened.
		      (while (not (looking-back "\n\n" nil))
			;; Insert blank lines before heading.
			(insert "\n")))
		     (let ((end (org-entry-end-position)))
		       ;; Insert blank lines before entry content
		       (forward-line)
		       (while (and (org-at-planning-p)
				   (< (point) (point-max)))
			 ;; Skip planning lines
			 (forward-line))
		       (while (re-search-forward org-drawer-regexp end t)
			 ;; Skip drawers. You might think that `org-at-drawer-p' would suffice, but
			 ;; for some reason it doesn't work correctly when operating on hidden text.
			 ;; This works, taken from `org-agenda-get-some-entry-text'.
			 (re-search-forward "^[ \t]*:END:.*\n?" end t)
			 (goto-char (match-end 0)))
		       (unless (or (= (point) (point-max))
				   (org-at-heading-p)
				   (looking-at-p "\n"))
			 (insert "\n"))))
		   t (if prefix
			 nil
		       'tree)))
