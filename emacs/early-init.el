;;; early-init.el -*- lexical-binding: t; -*-

;; Defer GC during startup; restore a sane threshold afterwards.
(setq gc-cons-threshold most-positive-fixnum)
(add-hook 'emacs-startup-hook
          (lambda () (setq gc-cons-threshold (* 16 1024 1024))))

;; Frame/UI: prevent, rather than create-then-disable.
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(width . 120) default-frame-alist)
(push '(height . 40) default-frame-alist)
;; Font for every frame (editor and the ghostel terminal alike). MesloLGS NF is
;; the powerlevel10k Nerd Font, installed system-wide (see README), so the zsh
;; prompt renders inside Emacs too.
(push '(font . "MesloLGS NF-13") default-frame-alist)
(setq frame-inhibit-implied-resize t)
(setq frame-resize-pixelwise t)
(setq inhibit-startup-screen t)

;; Quiet async native-compilation warnings.
(setq native-comp-async-report-warnings-errors 'silent)
