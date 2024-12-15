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
;;; Early Packages and functions
;;;; load secrets
(load (concat user-emacs-directory "personal.el") :no-error-if-file-is-missing)
;;;; use-package-vc
(when (< emacs-major-version 30)
  (unless (package-installed-p 'vc-use-package)
    (package-vc-install "https://github.com/slotThe/vc-use-package"))
  (require 'vc-use-package))
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
  :config
  (setq tab-always-indent 'complete
	use-short-answers t
	load-prefer-newer t
	inhibit-startup-screen t
	inhibit-startup-echo-area-message t
	initial-major-mode 'fundamental-mode)
  (setq browse-url-secondary-browser-function 'browse-url-xdg-open)
  (add-hook 'after-init-hook (lambda ()
			       (savehist-mode 1)))
  (add-hook 'prog-mode-hook (lambda ()
			      (electric-pair-local-mode 1)
			      (prettify-symbols-mode 1))))

(use-package recentf
  :ensure nil
  :after no-littering
  :custom
  (recentf-auto-cleanup 'never)
  :config
  (add-to-list 'recentf-exclude
               (recentf-expand-file-name no-littering-var-directory))
  (add-to-list 'recentf-exclude
               (recentf-expand-file-name no-littering-etc-directory))
  (recentf-mode))

(use-package dired
  :ensure nil
  :hook (dired-mode . dired-hide-details-mode)
  :commands (dired dired-jump)
  :config
  (setq dired-dwim-target t
	dired-kill-when-opening-new-dired-buffer t))
;;; Emacs Completion
;;;; Vertico-style IComplete
(use-package icomplete
  :ensure nil
  :demand t
  :bind (:map icomplete-minibuffer-map
	      ("RET"    . icomplete-force-complete-and-exit)
	      ("M-RET"  . icomplete-fido-exit)
    	      ("TAB"    . icomplete-force-complete)
	      ("DEL"    . icomplete-fido-backward-updir)
	      ("M-."    . embark-act)
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
  :hook (after-init . marginalia-mode))

(use-package orderless
  :after icomplete
  :init
  (setq completion-styles '(orderless flex substring)
	orderless-component-separator "-"
        orderless-matching-styles '(orderless-literal orderless-regexp)
	completion-category-defaults nil
	completion-category-overrides '((file (styles partial-completion)))))

;;; Usability
;;;; consult.el - Consulting completing-read
(use-package consult
  :commands (consult-completion-in-region)
  :bind (("C-x b"   . consult-buffer)
	 ("C-c M-x" . consult-mode-command)
	 ("C-x p b" . consult-project-buffer)
	 ("M-y" . consult-yank-pop)
	 ("M-g g" . consult-goto-line)
         ("M-g M-g" . consult-goto-line)
         ("M-g o" . consult-outline)
	 ("C-x C-r" . consult-recent-file)
	 ("M-g i"   . #'consult-imenu) ;; override regular imenu
         ("M-s r"   . #'consult-ripgrep)
         ("M-s f"   . #'consult-grep)
	 ("M-s l"   . consult-line))
  :config
  (setq consult-narrow-key "<")
  :init
  (setq xref-show-xrefs-function #'consult-xref
	xref-show-definitions-function #'consult-xref)
  (unless  window-system
    (setq completion-in-region-function #'consult-completion-in-region)))
;;;; God Mode — no more RSI
(use-package god-mode
  :bind
  ("C-z" . god-local-mode))
;;;; which-key
(use-package which-key
  :hook (after-init)
  :custom
  (which-key-sort-order #'which-key-key-order-alpha)
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
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(use-package wgrep
  :defer t
  :custom
  (wgrep-auto-save-buffer t)
  (wgrep-enable-key "i"))
;;; UI
;;;; theme
(use-package modus-themes
  :init
  (load-theme 'modus-vivendi-tinted :no-confirm))
;;;; mode line
(use-package mood-line
  :custom
  (mood-line-glyph-alist mood-line-glyphs-unicode)
  :config
  (mood-line-mode))
;;;; Disable ugly and unhelpful UI features
(menu-bar-mode -1)
(tool-bar-mode -1)
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode))
;;; Coding
;;;; general
;;;;; combobulate
(use-package combobulate
  :vc (combobulate :url "https://github.com/mickeynp/combobulate")
  :custom
  (combobulate-key-prefix "C-c m")
  :commands (combobulate-mode))
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
  (treesit-auto-install 'prompt)
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
;;;; python
;;;;; docstring
(use-package python-insert-docstring
  :commands (python-insert-docstring-with-google-style-at-point))
;;;;; direnv
(use-package envrc
  :if (executable-find "direnv")
  :hook (after-init . envrc-global-mode))
;;; Notes
;;;; org mode
(use-package org
  :commands (org-mode org-capture org-agenda)
  :bind
  (("C-c a" . org-agenda)
   ("C-c c" . org-capture))
  :config
  (when (equal system-configuration "aarch64-unknown-linux-android")
    (setq org-directory "~/storage/shared/Documents/org"))
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((plantuml . t)))

  (setq org-plantuml-exec-mode 'plantuml
	org-plantuml-args '("-headless" "-checkmetadata"))
  (setq org-return-follows-link t
	org-export-exclude-tags '("person" "private")
	org-export-with-broken-links nil
	org-export-use-babel t
	org-confirm-babel-evaluate nil
	org-export-with-section-numbers 1
	org-use-speed-commands t
	org-yank-adjusted-subtrees t
	org-hide-emphasis-markers t
	org-agenda-skip-scheduled-if-done t
	org-agenda-skip-deadline-if-done t
	org-agenda-skip-timestamp-if-done t
	org-refile-targets '((nil :maxlevel . 3)
			     (org-agenda-files :maxlevel . 3))
	org-ellipsis "  "
	org-startup-indented t
	org-image-actual-width (list 300)
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
  
  (setq org-agenda-files (list org-directory)))
;;;; org-nice-html
(use-package nice-org-html
  :hook (org-mode . nice-org-html-mode)
  :after org
  :config
  (setq org-publish-project-alist
	`(("Knowledge Base"
	   :base-directory ,(concat org-directory "/Knowledge base")
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
  (setq nice-org-html-headline-bullets nil))
;;;; org modern
(use-package org-modern
  :after org
  :custom
  (org-modern-star 'replace)
  :config
  (global-org-modern-mode))
;;;; org-node for notes
(use-package org-node
  :after org
  :config
  (org-node-cache-mode)
  (org-node-backlink-mode)
  (org-node-complete-at-point-mode)
  (add-hook 'org-open-at-point-functions
            #'org-node-try-visit-ref-node)
  (setq org-node-alter-candidates t
	org-node-ask-directory (concat org-directory "/Knowledge base")
	org-node-extra-id-dirs (list (concat org-directory "/Knowledge base"))))
;;;; org-gtd
(use-package org-gtd
  :after org
  :commands (org-gtd-transient org-gtd-engage org-gtd-capture)
  :bind (("C-c d" . org-gtd-transient)
	 ("C-c a" . org-gtd-engage)
	 ("C-c c" . org-gtd-capture))
  :init
  (with-eval-after-load 'org-gtd-capture
    (add-to-list 'org-gtd-capture-templates '("p" "person" entry (file "Knowledge base/person.org")
					      "* %^{name}%^{EMAIL}p%^{COMPANY}p%^{JOBTITLE}p\n:PROPERTIES:\n:ID: %(org-id-new)\n:END:" :kill-buffer t :after-finalize (lambda () (run-hooks 'org-node-creation-hook))) :append)
    (add-to-list 'org-gtd-capture-templates '("a" "Application" entry (file+headline "solicitaties.org" "Active Applications")
					      "* %\1 - %\2%^{COMPANY}p%^{JOBTITLE}p%^{LINK}p\n:PROPERTIES:\n:DATE: %t\n:END:\n%?") :append))
  :config
  (define-key org-gtd-clarify-map (kbd "C-c c") #'org-gtd-organize)
  (defun my/get-person-link ()
    (let* ((input (completing-read "Node: " #'org-node-collection () () "person > " 'org-node-hist))
	   (node (gethash input org-node--candidate<>node))
	   (id (if node (org-node-get-id node) (org-id-new)))
	   (link-desc (or (when (not org-node-alter-candidates) input)
			  (and node (seq-find (##string-search % input)
                                              (org-node-get-aliases node)))
			  (and node (org-node-get-title node))
			  input)))
      (org-link-make-string (concat "id:" id) link-desc)))
  (setq org-gtd-delegate-read-func #'my/get-person-link)
  (defun my/org-agenda-recent-open-loops ()
    (interactive)
    (with-org-gtd-context
	(let ((org-agenda-start-with-log-mode t)
              (org-agenda-use-time-grid nil))
	  (org-agenda-list nil (org-read-date nil nil "-2d") 4)
	  (beginend-org-agenda-mode-goto-beginning))))
  (defun my/org-agenda-longer-open-loops ()
    (interactive)
    (with-org-gtd-context
	(let ((org-agenda-start-with-log-mode t)
              (org-agenda-use-time-grid nil))
	  (org-agenda-list nil (org-read-date nil nil "-14d") 28)
	  (beginend-org-agenda-mode-goto-beginning))))
  (defun my/gtd-projects ()
    (interactive)
    (with-org-gtd-context
	(org-tags-view nil org-gtd-project-headings)
	(beginend-org-agenda-mode-goto-beginning)))
  (setq org-gtd-directory org-directory)
  (org-gtd-mode)
  (add-hook 'org-gtd-organize-hooks 'org-gtd-set-area-of-focus)
  (add-hook 'org-gtd-organize-hooks (lambda ()
				      (interactive)
				      (unless (org-gtd-organize-type-member-p '(trash knowledge quick-action)))
				      (org-set-effort)))
  (transient-define-prefix org-gtd-transient ()
    [["capture"
      ("c" "capture" org-gtd-capture)]
     ["process"
      ("p" "process inbox" org-gtd-process-inbox)
      ("C" "clarify item" org-gtd-clarify-item :if (lambda () (member major-mode '(org-mode org-agenda-mode))))]
     ["engage"
      ("e" "engage" org-gtd-engage)
      ("E" "engage by context" org-gtd-engage-grouped-by-context)
      ("n" "next actions" org-gtd-show-all-next)]]
    [["review"
      ("a" "area" org-gtd-review-area-of-focus)
      ("s" "stuck projects" org-gtd-review-stuck-projects)
      ("a" "archive completed" org-gtd-archive-completed-items)]]))
;;; Information gathering
;;;; Elfeed - rss reader
(use-package elfeed
  :commands (elfeed elfeed-update))
(use-package elfeed-protocol
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

;;;; readel
(use-package readel
  :commands (readel-annotations-buffer-render readel-annotations-insert-from-bm)
  :vc (readel :url https://github.com/EFLS/readel))
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
    ("a" "agenda" org-agenda)
    ("c" "capture" org-gtd-capture)
    ("r" "rss" elfeed)
    ("m" "email" notmuch)]
   ["KB"
    ("f" "find node" org-node-find)
    ("i" "insert link" org-node-insert-link :if-mode org-mode)
    ("g" "grep KB" org-node-grep)]
   ["Misc"
    ("." "embark" embark-act)
    ("'" "embark(dwim)" embark-dwim)]]))
;;; utility
(use-package beginend
  :config
  (beginend-global-mode))
(use-package try
  :commands try)
;;; override functions
(defun org-html--reference (datum info &optional named-only)
  "Return an appropriate reference for DATUM.

DATUM is an element or a `target' type object.  INFO is the
current export state, as a plist.

When NAMED-ONLY is non-nil and DATUM has no NAME keyword, return
nil.  This doesn't apply to headlines, inline tasks, radio
targets and targets."
  (let* ((type (org-element-type datum))
	 (custom-id (and (memq type '(headline inlinetask))
			 (org-element-property :ID datum)))
	 (user-label
	  (or
	   (when custom-id
	   (concat "ID-" custom-id))
	   (and (memq type '(radio-target target))
		(org-element-property :value datum))
	   (org-element-property :name datum)
	   (when-let* ((id (org-element-property :ID datum)))
	     (concat org-html--id-attr-prefix id)))))

    (cond
     ((and user-label
	   (or (plist-get info :html-prefer-user-labels)
	       ;; Used CUSTOM_ID property unconditionally.
	       custom-id))
      user-label)
     ((and named-only
	   (not (memq type '(headline inlinetask radio-target target)))
	   (not user-label))
      nil)
     (t
      (org-export-get-reference datum info)))))
