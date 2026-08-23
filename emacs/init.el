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

(setopt
 ;; No backup (~), auto-save (#file#), or lock (.#file) files.
 make-backup-files nil
 auto-save-default nil
 create-lockfiles nil

 mac-right-command-modifier 'control)

;; Keep Customize's generated code out of version-controlled files.
(setq custom-file (locate-user-emacs-file "custom.el"))
(load custom-file :no-error-if-file-is-missing)

;; Theme: modus tinted (warm paper / dark), following the macOS appearance via
;; the emacs-plus `ns-system-appearance' hook.
(use-package modus-themes
  :ensure t
  :demand t  ; :bind would otherwise defer loading, and the theme with it
  :custom
  (modus-themes-bold-constructs t)
  (modus-themes-to-toggle '(modus-operandi-tinted modus-vivendi-tinted))
  (modus-themes-headings '((1 . (rainbow background 1.3))
                           (2 . (rainbow background 1.15))
                           (t . (rainbow))))
  (modus-themes-common-palette-overrides
   '((cursor fg-main)                      ; tinted's red cursor is too loud
     (bg-hl-line bg-ochre)                  ; warm sand, sits in the paper tone
     (bg-region bg-sage)                    ; earthy selection, distinct from hl-line
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

;; Glyph fallback (fontset needs the window system, so not early-init).
;; Emacs picks fallback fonts itself, not via the macOS cascade: MesloLGS NF
;; lacks technical symbols like ⎘, and Emacs chose STIX Two Math for them.
;; (Emoji need nothing: Apple Color Emoji is picked anyway)
(set-fontset-font t 'symbol "Apple Symbols" nil 'prepend)

;; macOS GUI apps don't inherit the shell environment. `-l' = login shell,
;; which reads ~/.zprofile (brew shellenv, ~/.local/bin → claude) but not ~/.zshrc.
(use-package exec-path-from-shell
  :ensure t
  :if (memq window-system '(ns mac))
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
