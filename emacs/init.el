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
  (ghostel-module-auto-install 'download))

(use-package claude-code-ide
  :vc (:url "https://github.com/manzaltu/claude-code-ide.el" :rev :newest)
  :bind ("C-c c" . claude-code-ide-menu)
  :custom (claude-code-ide-terminal-backend 'ghostel)
  :config (claude-code-ide-emacs-tools-setup))

;; Server for `emacsclient' ($EDITOR from ~/.zprofile) and Emacs Client.app.
(use-package server
  :ensure nil  ; built-in
  :config (unless (server-running-p) (server-start)))
