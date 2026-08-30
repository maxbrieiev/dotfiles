;;; init.el -*- lexical-binding: t; -*-
;;
;; Bootstrap rules:
;; - `(require 'package)' is needed: with zero installed packages Emacs does not
;;   load package.el at startup, so `package-archives' would be void.
;; - Auto-installing native modules (ghostel) must be non-interactive, or a y/n
;;   prompt fires mid-init and use-package flattens it to "Cannot load X".
;; Fresh-machine test after touching bootstrap: mv ~/.emacs.d/elpa{,.bak}, relaunch,
;; expect an error-free startup with everything self-installed. Two warnings are
;; normal on that first start only: embark's "embark-consult should be installed"
;; (compiling embark-consult during its install loads consult before
;; embark-consult itself) and ghostel's "native module not found" (the download
;; it triggers is asynchronous).

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)

;; Keep Customize's generated code out of version-controlled files.
(setq custom-file (locate-user-emacs-file "custom.el"))
(load custom-file :no-error-if-file-is-missing)

;; Core editor settings (built-in, no package behind them).
(use-package emacs
  :ensure nil
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
  (tab-always-indent 'complete)              ; TAB indents, then completes
  (text-mode-ispell-word-completion nil)     ; no dictionary words in completion
  (help-window-select t)
  (help-enable-variable-value-editing t)
  (debugger-stack-frame-as-list t)

  ;; Version control: Git only (skips probing for RCS/SVN/Hg/... per file).
  (vc-handled-backends '(Git))
  (vc-follow-symlinks t)  ; visit the real file behind symlinked files, don't ask

  :config
  ;; macOS keyboard: the "Dev Dvorak" layout defines a QWERTY command plane
  ;; (⌘-shortcuts sit at QWERTY positions system-wide), but the NS port
  ;; ignores that plane and derives super keys from the base Dvorak plane,
  ;; so e.g. ⌘C arrives as s-j. Translate each super key through the
  ;; layout's own base→⌘-plane table so ⌘ shortcuts land on the same
  ;; physical keys as in every other app. Unmodified typing is untouched.
  ;; The aligned strings are generated from the installed layout by
  ;;   swift .claude/skills/dotfiles/scripts/mac-layout-table.swift "Dev Dvorak"
  (when (featurep 'ns)
    (let ((dvorak "oeudi'qjkx;,.pfy&[{}=(#+`*)]@rg?clnh-tswzbv/OEUDI\"QJKX:<>PFY12346597%80^RG!CLNH_TSWZBV")
          (qwerty "sdfhgzxcvbqweryt123465=97-80]ou[iplj'k;,/n.`SDFHGZXCVBQWERYT!@#$^%(&_*)}OU{IPLJ\"K:<?N>"))
      (dotimes (i (length dvorak))
        (dolist (mods '((super) (super shift)))
          (define-key key-translation-map
                      (vector (event-convert-list (append mods (list (aref dvorak i)))))
                      (vector (event-convert-list (append mods (list (aref qwerty i))))))))))

  ;; Glyph fallback. Emacs picks fallback fonts itself, not via the macOS
  ;; cascade: MesloLGS NF lacks technical symbols like ⎘, and Emacs chose STIX
  ;; Two Math for them. (Emoji need nothing: Apple Color Emoji is picked anyway.)
  (set-fontset-font t 'symbol "Apple Symbols" nil 'prepend)

  ;; Unbind suspend-frame (useless in a GUI).
  (keymap-unset global-map "C-z" t)

  ;; Emacs has no built-in command to visit the init file.
  (defun my/visit-init-file ()
    "Visit the init file Emacs loaded at startup (`user-init-file').
Follows symlinks."
    (interactive)
    (find-file (file-truename user-init-file)))
  (keymap-global-set "C-c i" #'my/visit-init-file)

  ;; Enable disabled-by-default commands.
  (put 'narrow-to-region 'disabled nil)
  (put 'narrow-to-page 'disabled nil)
  (put 'help-fns-edit-variable 'disabled nil)

  ;; Keep the cursor out of the minibuffer prompt (pairs with
  ;; `minibuffer-prompt-properties' above).
  (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode))

;; C-t is my personal prefix: everything of my own lives under it (transient
;; menus now, maybe modal editing later). It replaces transpose-chars, which is
;; not missed, and sits on the Dvorak home row. Modes that bind C-t themselves
;; (dired's image-dired prefix, ghostel terminals) are told below to yield it,
;; so C-t <key> means the same thing in every buffer.
(defvar-keymap my/prefix-map
  :doc "Personal commands, on C-t."
  :prefix t)
(keymap-global-set "C-t" 'my/prefix-map)

;; Built-in features with their own settings (`:ensure nil' marks a built-in).
(use-package dired
  :ensure nil
  :bind (:map dired-mode-map ("C-t" . my/prefix-map))  ; not image-dired's prefix
  :custom
  (dired-kill-when-opening-new-dired-buffer t)
  (dired-listing-switches "-Alh"))  ; BSD ls: no --group-directories-first

(use-package isearch
  :ensure nil
  :custom
  (isearch-lazy-count t)
  (isearch-wrap-pause 'no))

(use-package autorevert
  :ensure nil
  :custom
  (global-auto-revert-mode t)
  (global-auto-revert-non-file-buffers t)  ; Dired too
  (auto-revert-avoid-polling t)            ; kqueue notifications only
  (auto-revert-verbose nil))

(use-package pixel-scroll
  :ensure nil
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
(use-package which-key    :ensure nil :custom (which-key-mode t))
(use-package savehist     :ensure nil :custom (savehist-mode t))
(use-package recentf      :ensure nil :custom (recentf-mode t))
(use-package repeat       :ensure nil :custom (repeat-mode t))

;; Completion stack: vertico (the one candidate-picking UI, for minibuffer
;; prompts and, via consult, for in-buffer completion) + orderless (matching)
;; + marginalia (annotations) + consult (commands) + embark (actions) + cape
;; (extra in-buffer backends). Nothing pops up unasked; the only automatic
;; element is Emacs's completion preview below.

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

;; Space-separated patterns in any order. Default affix dispatchers:
;; suffix/prefix ! = not, = literal, ^ literal-prefix, ~ flex, , initialism,
;; & annotation, % char-fold.
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
  ;; In-buffer completion (TAB, C-M-i, also inside M-:) picks its candidates
  ;; in the minibuffer, so vertico is the one candidate UI. TAB with a single
  ;; candidate just inserts it.
  :init (setq completion-in-region-function #'consult-completion-in-region)
  :bind (([remap switch-to-buffer] . consult-buffer)
         ([remap switch-to-buffer-other-window] . consult-buffer-other-window)
         ([remap project-switch-to-buffer] . consult-project-buffer)
         ([remap bookmark-jump] . consult-bookmark)
         ([remap goto-line] . consult-goto-line)
         ([remap yank-pop] . consult-yank-pop)
         ([remap imenu] . consult-imenu)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-thing-at-point)
         ("M-s r" . consult-ripgrep)
         ("M-#" . consult-register-load)
         ("M-'" . consult-register-store)
         ("C-M-#" . consult-register)
         ("M-g f" . consult-flymake)
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
  ;; C-; rather than M-., which stays with xref-find-definitions.
  :bind (("C-." . embark-act)
         ("C-;" . embark-dwim)
         ("C-h B" . embark-bindings))
  :custom (prefix-help-command #'embark-prefix-help-command))

(use-package embark-consult
  :ensure t
  :after (embark consult)
  :demand t  ; a :hook alone defers it forever, and embark warns it's missing
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;; The one automatic element while editing: Emacs's inline preview of the
;; first candidate (ghost text after three characters of a symbol). TAB
;; accepts it, M-n / M-p cycle, M-i lists all candidates (in the minibuffer,
;; like TAB); typing on ignores it.
(use-package completion-preview
  :ensure nil
  :custom (global-completion-preview-mode t)
  :bind (:map completion-preview-active-mode-map
              ("M-n" . completion-preview-next-candidate)
              ("M-p" . completion-preview-prev-candidate)))

;; Extra completion-at-point backends (also under C-c p on demand).
(use-package cape
  :ensure t
  :bind ("C-c p" . cape-prefix-map)
  :init
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file))

;; Git porcelain. Magit sets its own global keys: C-x g status,
;; C-x M-g dispatch (any magit command), C-c M-g file dispatch.
(use-package magit
  :ensure t
  :custom
  (magit-diff-refine-hunk t)
  (magit-save-repository-buffers 'dontask))

;; Changed lines in the fringe (VS Code's gutter), live and Magit-aware.
;; C-x v [ / ] jump between hunks, C-x v * shows the old text inline.
(use-package diff-hl
  :ensure t
  :hook ((magit-pre-refresh . diff-hl-magit-pre-refresh)
         (magit-post-refresh . diff-hl-magit-post-refresh)
         (dired-mode . diff-hl-dired-mode))
  :custom
  (diff-hl-draw-borders nil)            ; solid bars
  :init
  (global-diff-hl-mode)
  (diff-hl-flydiff-mode)      ; update while editing, not only on save
  (global-diff-hl-show-hunk-mouse-mode)) ; click a fringe mark to see the old text

;; Language support: Emacs 31's built-in tree-sitter modes + eglot.
;; `treesit-enabled-modes' is the switch: without it the `*-ts-mode-maybe'
;; dispatchers fall back to a plain mode (or `fundamental-mode') when the
;; grammar is missing. With it, the ts-mode runs and compiles its grammar on
;; first use, non-interactively (same doctrine as the ghostel module: a fresh
;; machine must start without prompts).
(use-package treesit
  :ensure nil
  :custom
  (treesit-enabled-modes '(typescript-ts-mode tsx-ts-mode))
  (treesit-auto-install-grammar 'always)
  (treesit-font-lock-level 4))

(use-package typescript-ts-mode
  :ensure nil
  :mode ("\\.[mc]ts\\'" . typescript-ts-mode)
  :custom (typescript-ts-mode-indent-offset 2))

;; TypeScript's language server is the native (Go) compiler itself, `tsc --lsp',
;; available since TypeScript 7. A vp/oxc project (elarion) type-checks with the
;; same engine via tsgolint and deliberately carries no `typescript' dependency,
;; so the server comes from a global `npm i -g typescript' — unless the project
;; has its own tsc 7+, which then wins.
(use-package eglot
  :ensure nil
  :hook ((typescript-ts-mode tsx-ts-mode) . eglot-ensure)
  :custom
  (eglot-autoshutdown t)                    ; stop the server with its last buffer
  (eglot-events-buffer-config '(:size 0))   ; no per-server JSON-RPC log
  :bind (:map eglot-mode-map
              ("C-c l r" . eglot-rename)
              ("C-c l a" . eglot-code-actions)
              ("C-c l o" . eglot-code-action-organize-imports)
              ("C-c l f" . eglot-format)
              ("C-c l d" . eldoc-doc-buffer)
              ("M-n" . flymake-goto-next-error)
              ("M-p" . flymake-goto-prev-error))
  :config
  (defun my/tsc-lsp-p (tsc)
    "Non-nil if TSC is a TypeScript 7+ binary (the ones that speak LSP)."
    (and tsc (file-executable-p tsc)
         (let ((v (with-temp-buffer
                    (ignore-errors (call-process tsc nil t nil "--version"))
                    (buffer-string))))
           (and (string-match "Version \\([0-9]+\\)" v)
                (>= (string-to-number (match-string 1 v)) 7)))))
  (defun my/eglot-tsc-contact (&rest _)
    "Contact for eglot: the project's tsc if it is 7+, else the global one."
    (let* ((root (and-let* ((pr (project-current))) (project-root pr)))
           (local (and root (expand-file-name "node_modules/.bin/tsc" root)))
           (tsc (if (my/tsc-lsp-p local) local (executable-find "tsc"))))
      (list tsc "--lsp" "--stdio")))
  (add-to-list 'eglot-server-programs
               '(((typescript-ts-mode :language-id "typescript")
                  (tsx-ts-mode :language-id "typescriptreact"))
                 . my/eglot-tsc-contact))
  ;; tsc registers `workspace/didChangeConfiguration' dynamically; eglot has no
  ;; handler for that and warns on every connection. Accept it silently.
  (cl-defmethod eglot-register-capability
    (_server (_method (eql workspace/didChangeConfiguration)) _id &rest _)
    nil))

;; Format on save with oxfmt (the vp toolchain's formatter), in the modes it
;; owns and only where a project-local or global oxfmt exists. The config is the
;; project root's vite.config.ts (its `fmt' block), as `vp fmt' itself reads it.
;; TODO oxlint diagnostics: eglot runs one server per buffer, so `oxlint --lsp'
;; can't ride alongside tsc; a flymake backend is the likely route.
(use-package apheleia
  :ensure t
  :hook ((typescript-ts-mode tsx-ts-mode) . my/apheleia-mode-if-oxfmt)
  :config
  (defun my/oxfmt-config-args ()
    "--config for the project root's vite.config.ts, when there is one."
    (and-let* ((pr (project-current))
               (cfg (expand-file-name "vite.config.ts" (project-root pr)))
               ((file-exists-p cfg)))
      (list "--config" cfg)))
  (defun my/apheleia-mode-if-oxfmt ()
    (when (or (executable-find "oxfmt")
              (locate-dominating-file default-directory "node_modules/.bin/oxfmt"))
      (apheleia-mode)))
  (push '(oxfmt . (npx "oxfmt" "--stdin-filepath" filepath (my/oxfmt-config-args)))
        apheleia-formatters)
  (setf (alist-get 'typescript-ts-mode apheleia-mode-alist) 'oxfmt
        (alist-get 'tsx-ts-mode apheleia-mode-alist) 'oxfmt))

;; Theme: modus tinted (warm paper / dark), following the macOS appearance via
;; the emacs-plus `ns-system-appearance' hook. The themes ship with Emacs in
;; etc/themes, where `require' does not look; `require-theme' loads them.
(use-package modus-themes
  :ensure nil
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
  (require-theme 'modus-themes)
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
  :hook (ghostel-mode . (lambda () (setq-local nobreak-char-display nil)))
  :config
  ;; Let C-t reach Emacs (my prefix) instead of the program, on top of the
  ;; default exceptions (C-c, C-x, ...); the :set rebuilds the keymap. A
  ;; literal C-t still goes through with C-c C-q (`ghostel-send-next-key').
  (customize-set-variable 'ghostel-keymap-exceptions
                          (cons "C-t" ghostel-keymap-exceptions))
  ;; Trackpad scrolling in fullscreen TUIs (Claude Code, vim, less…). On the
  ;; alternate screen ghostel forwards every wheel event to the program as
  ;; one full button-4/5 tick and ignores the event's pixel delta; a macOS
  ;; trackpad emits dozens of small-delta events per gesture, so a light
  ;; nudge scrolled pages. Do what Ghostty itself does: accumulate the
  ;; pixel travel and emit one tick per line height. Off the alternate
  ;; screen the original per-event path is kept (it falls through to
  ;; `pixel-scroll-precision-mode', which already scrolls by pixels).
  (defvar-local my/ghostel-wheel-accum 0.0
    "Signed pixels of wheel travel not yet forwarded as a tick (up > 0).")
  (defun my/ghostel-forward-scroll-by-lines (orig event button)
    "Around `ghostel--forward-scroll-event': one BUTTON tick per line of travel."
    (let ((delta (and (consp event) (nth 4 event) (cdr (nth 4 event)))))
      (if (not (and delta (ghostel-alt-screen-p)))
          (funcall orig event button)
        (let ((sign (if (eq button 4) 1 -1))
              (line (float (default-line-height)))
              (sent t))
          ;; A direction change drops leftover travel from the old one.
          (when (< (* my/ghostel-wheel-accum sign) 0)
            (setq my/ghostel-wheel-accum 0.0))
          (setq my/ghostel-wheel-accum (+ my/ghostel-wheel-accum (* sign (abs delta))))
          (while (and sent (>= (abs my/ghostel-wheel-accum) line))
            (setq sent (funcall orig event button))
            (setq my/ghostel-wheel-accum (- my/ghostel-wheel-accum (* sign line))))
          ;; nil only if the program refused a tick: then ghostel re-dispatches
          ;; the event to the normal Emacs scroll handler.
          sent))))
  (advice-add 'ghostel--forward-scroll-event :around #'my/ghostel-forward-scroll-by-lines))

(use-package claude-code-ide
  :vc (:url "https://github.com/manzaltu/claude-code-ide.el" :rev :newest)
  :bind (:map my/prefix-map ("c" . claude-code-ide-menu))
  :custom (claude-code-ide-terminal-backend 'ghostel)
  :config (claude-code-ide-emacs-tools-setup))

;; Server for `emacsclient' ($EDITOR from ~/.zprofile) and Emacs Client.app.
(use-package server
  :ensure nil  ; built-in
  :config (unless (server-running-p) (server-start)))
