;;; init.el -*- lexical-binding: t; -*-
;;
;; Bootstrap rules:
;; - `(require 'package)' is needed: with zero installed packages Emacs 30 skips
;;   loading package.el at startup, so `package-archives' would be void.
;; - Auto-installing native modules (ghostel) must be non-interactive, or a y/n
;;   prompt fires mid-init and use-package flattens it to "Cannot load X".
;; Fresh-machine test after touching bootstrap: mv ~/.emacs.d/elpa{,.bak}, relaunch,
;; expect an error-free startup with everything self-installed.

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)

;; Keep Customize's generated code out of version-controlled files.
(setq custom-file (locate-user-emacs-file "custom.el"))
(load custom-file :no-error-if-file-is-missing)

;; Core editor settings (built-in, no package behind them).
(use-package emacs
  :custom
  ;; Files: no backup (~), auto-save (#file#), or lock (.#file) clutter.
  (make-backup-files nil)
  (auto-save-default nil)
  (create-lockfiles nil)

  ;; macOS keyboard: right ⌘ acts as Control.
  (ns-right-command-modifier 'control)

  ;; Identity (commit messages, mail headers).
  (user-full-name "Max Brieiev")
  ;; (user-mail-address "max.brieiev@gmail.com")

  ;; Editing.
  (indent-tabs-mode nil)
  (truncate-lines t)
  (auto-hscroll-mode 'current-line)
  (mouse-yank-at-point t)
  (next-screen-context-lines 7)
  (show-paren-context-when-offscreen 'child-frame)
  (scroll-preserve-screen-position t)

  ;; UI.
  (initial-scratch-message nil)
  (ring-bell-function 'ignore)
  (blink-cursor-mode nil)
  (column-number-mode t)
  (mode-line-compact 'long)
  (context-menu-mode t)
  (what-cursor-show-names t)
  (highlight-nonselected-windows t)  ; keep the region visible in other windows

  ;; Minibuffer & help.
  (enable-recursive-minibuffers t)
  (minibuffer-prompt-properties '(read-only t cursor-intangible t face minibuffer-prompt))
  (read-extended-command-predicate #'command-completion-default-include-p)  ; M-x: hide inapplicable commands
  (tab-always-indent 'complete)              ; TAB indents, then completes (corfu)
  (text-mode-ispell-word-completion nil)     ; no dictionary words in completion
  (help-window-select t)
  (help-enable-variable-value-editing t)
  (debugger-stack-frame-as-list t)

  ;; Version control: Git only (skips probing for RCS/SVN/Hg/... per file).
  (vc-handled-backends '(Git))

  :config
  ;; Glyph fallback. Emacs picks fallback fonts itself, not via the macOS
  ;; cascade: MesloLGS NF lacks technical symbols like ⎘, and Emacs chose STIX
  ;; Two Math for them. (Emoji need nothing: Apple Color Emoji is picked anyway.)
  (set-fontset-font t 'symbol "Apple Symbols" nil 'prepend)

  ;; Unbind suspend-frame (useless in a GUI) and transpose-chars.
  (keymap-unset global-map "C-z" t)
  (keymap-unset global-map "C-t" t)

  ;; Enable disabled-by-default commands.
  (put 'narrow-to-region 'disabled nil)
  (put 'narrow-to-page 'disabled nil)
  (put 'help-fns-edit-variable 'disabled nil)

  ;; Keep the cursor out of the minibuffer prompt (pairs with
  ;; `minibuffer-prompt-properties' above).
  (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)

  ;; Prompt indicator for `completing-read-multiple' (built into Emacs 31).
  (when (< emacs-major-version 31)
    (advice-add #'completing-read-multiple :filter-args
                (lambda (args)
                  (cons (format "[CRM%s] %s"
                                (string-replace "[ \t]*" "" crm-separator)
                                (car args))
                        (cdr args))))))

;; Built-in features with their own settings.
(use-package dired
  :custom
  (dired-kill-when-opening-new-dired-buffer t)
  (dired-listing-switches "-Alh"))  ; BSD ls: no --group-directories-first

(use-package isearch
  :custom
  (isearch-lazy-count t)
  (isearch-wrap-pause 'no))

(use-package autorevert
  :custom
  (global-auto-revert-mode t)
  (global-auto-revert-non-file-buffers t)  ; Dired too
  (auto-revert-avoid-polling t)            ; kqueue notifications only
  (auto-revert-verbose nil))

(use-package pixel-scroll
  :custom
  (pixel-scroll-precision-mode t)  ; smooth trackpad scrolling
  (pixel-scroll-precision-interpolate-page t)
  (pixel-scroll-precision-interpolation-total-time 0.3)
  :config
  ;; Page scrolling that glides (so the eye follows the text) and keeps
  ;; `next-screen-context-lines' of overlap, which the stock
  ;; `pixel-scroll-interpolate-down/up' don't.
  (defun my/pixel-scroll-page (dir)
    "Glide one page in DIR (+1 down, -1 up), keeping some context."
    (pixel-scroll-precision-interpolate
     (* (- dir)
        (- (window-text-height nil t)
           (* next-screen-context-lines (default-line-height))))
     nil 1))
  (defun my/pixel-scroll-page-down ()
    (interactive)
    (my/pixel-scroll-page 1))
  (defun my/pixel-scroll-page-up ()
    (interactive)
    (my/pixel-scroll-page -1))
  ;; Let `scroll-preserve-screen-position' treat them as scroll commands.
  (put 'my/pixel-scroll-page-down 'scroll-command t)
  (put 'my/pixel-scroll-page-up 'scroll-command t)
  :bind (:map pixel-scroll-precision-mode-map
              ([remap scroll-up-command]   . my/pixel-scroll-page-down)
              ([remap scroll-down-command] . my/pixel-scroll-page-up)))
(use-package savehist     :custom (savehist-mode t))
(use-package recentf      :custom (recentf-mode t))
(use-package repeat       :custom (repeat-mode t))

;; Completion stack: vertico (minibuffer UI) + orderless (matching) +
;; marginalia (annotations) + consult (commands) + embark (actions) +
;; corfu/cape (in-buffer completion).

(use-package vertico
  :ensure t
  :custom
  (vertico-count 12)
  (vertico-cycle t)
  (vertico-quick1 "nthueoa")  ; Dvorak home row
  (vertico-quick2 "id")
  :bind (:map vertico-map
              ("M-q" . vertico-quick-insert)
              ("C-q" . vertico-quick-exit))
  :init (vertico-mode))

;; Ido-like directory editing: RET descends, DEL deletes whole components,
;; and typing ~/ or // anywhere in a path tidies the shadowed prefix.
(use-package vertico-directory
  :ensure nil  ; ships with vertico
  :after vertico
  :bind (:map vertico-map
              ("RET"   . vertico-directory-enter)
              ("DEL"   . vertico-directory-delete-char)
              ("M-DEL" . vertico-directory-delete-word))
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))

;; Space-separated patterns in any order. The default affix dispatchers
;; replace the 2024 config's hand-written ones: suffix/prefix ! = not,
;; = literal, ^ literal-prefix, ~ flex, , initialism, & annotation, % char-fold.
(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))  ; basic = fallback for odd tables/TRAMP
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))  ; /u/l/b paths

(use-package marginalia
  :ensure t
  :bind (:map minibuffer-local-map ("M-A" . marginalia-cycle))
  :init (marginalia-mode))

(use-package consult
  :ensure t
  :bind (([remap switch-to-buffer] . consult-buffer)
         ([remap switch-to-buffer-other-window] . consult-buffer-other-window)
         ([remap project-switch-to-buffer] . consult-project-buffer)
         ([remap bookmark-jump] . consult-bookmark)
         ([remap goto-line] . consult-goto-line)  ; the 2024 remap had a `go-to-line' typo
         ([remap yank-pop] . consult-yank-pop)
         ([remap imenu] . consult-imenu)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-thing-at-point)
         ("M-s r" . consult-ripgrep)
         ("M-#" . consult-register-load)
         ("M-'" . consult-register-store)
         ("C-M-#" . consult-register)
         ("C-c h" . consult-history)
         ("C-c m" . consult-mode-command))
  :custom
  (consult-narrow-key "C-+")
  ;; Select xref results in the minibuffer with preview.
  (xref-show-xrefs-function #'consult-xref)
  (xref-show-definitions-function #'consult-xref)
  :config
  ;; Use orderless to compile patterns for external grep/find/ripgrep, so
  ;; async searches match like everything else and need no -- splitting.
  (defun my/consult--orderless-regexp-compiler (input type &rest _config)
    (setq input (orderless-pattern-compiler input))
    (cons (mapcar (lambda (r) (consult--convert-regexp r type)) input)
          (lambda (str) (orderless--highlight input t str))))
  (setq consult--regexp-compiler #'my/consult--orderless-regexp-compiler)
  (setq consult-async-split-style nil)

  ;; Register preview via consult.
  (setq register-preview-delay 0
        register-preview-function #'consult-register-format)
  (advice-add #'register-preview :override #'consult-register-window)

  ;; consult-line with the symbol at point on M-s L; M-n fetches it on M-s l.
  (consult-customize consult-line
                     :add-history (seq-some #'thing-at-point '(region symbol)))
  (defalias 'consult-line-thing-at-point 'consult-line)
  (consult-customize consult-line-thing-at-point
                     :initial (thing-at-point 'symbol)))

(use-package embark
  :ensure t
  ;; C-; instead of the 2024 M-., which is reserved for xref-find-definitions.
  :bind (("C-." . embark-act)
         ("C-;" . embark-dwim)
         ("C-h B" . embark-bindings))
  :custom (prefix-help-command #'embark-prefix-help-command))

(use-package embark-consult
  :ensure t
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(use-package corfu
  :ensure t
  :custom
  (corfu-auto t)
  (corfu-cycle t)
  (corfu-quick1 "nthueoa")
  (corfu-quick2 "id")
  :bind (:map corfu-map
              ("M-q" . corfu-quick-complete)
              ("C-q" . corfu-quick-exit))
  :init
  (global-corfu-mode)
  (corfu-history-mode)    ; sort by recency (persisted via savehist)
  (corfu-popupinfo-mode)  ; docs popup next to the candidate (ex corfu-doc)
  :config
  (add-to-list 'savehist-additional-variables 'corfu-history))

;; Extra completion-at-point backends (also under C-c p on demand).
(use-package cape
  :ensure t
  :bind ("C-c p" . cape-prefix-map)
  :init
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file))

;; Theme: modus tinted (warm paper / dark), following the macOS appearance via
;; the emacs-plus `ns-system-appearance' hook.
(use-package modus-themes
  :ensure t
  :demand t  ; :bind would otherwise defer loading, and the theme with it
  :custom
  (modus-themes-to-toggle '(modus-operandi-tinted modus-vivendi-tinted))
  (modus-themes-headings '((1 . (rainbow background 1.1))
                           (2 . (rainbow background 1.05))
                           (t . (rainbow))))
  (modus-themes-common-palette-overrides
   '((cursor fg-main)                       ; tinted's red cursor is too loud
     (comment fg-dim)                       ; grey comments, not brick red
     (fg-region unspecified)                ; keep syntax colours inside the region
     (border-mode-line-active unspecified)  ; "3d"-ish flat mode-line
     (border-mode-line-inactive unspecified)))
  :bind ("<f5>" . modus-themes-toggle)
  :init
  (defun my/modus-themes-follow-system (appearance)
    "Load the modus theme matching macOS APPEARANCE (`light' or `dark')."
    (modus-themes-load-theme
     (if (eq appearance 'dark) 'modus-vivendi-tinted 'modus-operandi-tinted)))
  :config
  (if (boundp 'ns-system-appearance)
      (progn
        (add-hook 'ns-system-appearance-change-functions
                  #'my/modus-themes-follow-system)
        (my/modus-themes-follow-system ns-system-appearance))
    (modus-themes-load-theme 'modus-operandi-tinted)))

;; macOS GUI apps don't inherit the shell environment. `-l' = login shell,
;; which reads ~/.zprofile (brew shellenv, ~/.local/bin → claude) but not ~/.zshrc.
(use-package exec-path-from-shell
  :ensure t
  :if (eq window-system 'ns)
  :custom (exec-path-from-shell-arguments '("-l"))
  :config (exec-path-from-shell-initialize))

(use-package ghostel
  :ensure t
  :custom
  ;; Non-interactive on a pristine machine: fetch the prebuilt native module
  ;; instead of prompting (default is 'ask).
  (ghostel-module-auto-install 'download)
  ;; No-break spaces are layout in a terminal, not text — don't underline them.
  :hook (ghostel-mode . (lambda () (setq-local nobreak-char-display nil))))

(use-package claude-code-ide
  :vc (:url "https://github.com/manzaltu/claude-code-ide.el" :rev :newest)
  :bind ("C-c c" . claude-code-ide-menu)
  :custom (claude-code-ide-terminal-backend 'ghostel)
  :config (claude-code-ide-emacs-tools-setup))

;; Server for `emacsclient' ($EDITOR from ~/.zprofile) and Emacs Client.app.
(use-package server
  :ensure nil  ; built-in
  :config (unless (server-running-p) (server-start)))
