;;; emacs --- A grouping of all of my dotfiles whatnots

;;; Commentary:
;; This is largely stolen from http://www.aaronbedra.com/emacs.d/

;;; Code:
;; My name and email address (this email address might change per-system).
(setq user-full-name "Drew Hays")
(setq user-mail-address "drewshays@gmail.com")

;; Require some common-lispy things
(eval-when-compile (require 'cl))

;; Initialize MELPA and Marmalade
(load "package")
(package-initialize)
(add-to-list 'package-archives
             '("marmalade" . "http://marmalade-repo.org/packages/"))
(add-to-list 'package-archives
             '("melpa" . "http://melpa.milkbox.net/packages/") t)
(setq package-archive-enable-alist '(("melpa" deft magit)))

;; A list of all of the packages that I want to have installed by default.
(defvar dru89/packages '(auto-complete
                         autopair
                         coffee-mode
                         dash
                         deft
                         epl
                         f
                         flx
                         flx-ido
                         flycheck
                         gist
                         go-mode
                         graphviz-dot-mode
                         htmlize
                         let-alist
                         magit
                         markdown-mode
                         marmalade
                         monokai-theme
                         multi-term
                         neotree
                         org
                         paredit
                         pkg-info
                         powerline
                         projectile
                         rich-minority
                         s
                         scss-mode
                         smart-mode-line
                         smart-mode-line-powerline-theme
                         smex
                         writegood-mode
                         yaml-mode)
  "Default packages.")

;; Return nil if there exists a package taht is not installed.
;; Return true otherwise.
(defun dru89/packages-installed-p ()
  "Return nil if there exists a package that is not installed.
If all of the packages were installed, return true."
  (loop for pkg in dru89/packages
        when (not (package-installed-p pkg)) do (return nil)
        finally (return t)))

;; Install all the packages
(unless (dru89/packages-installed-p)
  (message "%s" "Refreshing packages database...")
  (package-refresh-contents)
  (dolist (pkg dru89/packages)
    (when (not (package-installed-p pkg))
      (package-install pkg))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Start-up options

;; Turn off the splash screen.  Clear the scratch message. Make it "org-mode".
(setq inhibit-splash-screen t
      initial-scratch-message nil
      initial-major-mode 'org-mode)

;; Turn off the scrollbar, toolbar, and menu bar.
(scroll-bar-mode -1)
(tool-bar-mode -1)
(menu-bar-mode -1)

;; Typing when the mark is active should overwrite the marked region.
;; Fixing common highlighting keystrokes.
;; Emacs clipboard, be friends with the system clipboard
(delete-selection-mode t)
(transient-mark-mode t)
(setq x-select-enable-clipboard t)

;; Small tweak to the frame's title and startup size/position
(when window-system
  (setq frame-title-format '(buffer-file-name "%f" ("%b")))
  (set-frame-size (selected-frame) 180 49))


;; This shows when a file actuall ends by putting empty line markers on the left-hand side
(setq-default indicate-empty-lines t)
(when (not indicate-empty-lines)
  (toggle-inidicate-empty-lines))

;; Always set the tab-width to 4.  Never, ever, ever, ever, ever use spaces.
;; Turn on automatic indentation mode, and hard-wrap at 120 columns
(setq tab-width 4
      indent-tabs-mode nil)
(electric-indent-mode 1)
(setq-default fill-column 120)
(add-hook 'text-mode-hook 'turn-on-auto-fill)

;; Goodbye, backup files!
(setq make-backup-files nil)

;; Helpful function will create directories before find-file
(defadvice find-file (before make-directory-maybe (filename &optional wildcards) activate)
  "Create the parent directory if it doesn't exist when visiting a file."
  (unless (file-exists-p filename)
    (let ((dirname (file-name-directory filename)))
      (unless (file-exists-p dirname)
	(make-directory dirname t)))))

;; Type "y" and "n" (instead of "yes" and "no").
(defalias 'yes-or-no-p 'y-or-n-p)

;; Some nice keybindings and stuff
(global-set-key (kbd "RET") 'newline-and-indent)
(global-set-key (kbd "C-;") 'comment-or-uncomment-region)
(global-set-key (kbd "M-/") 'hippe-expand)
(global-set-key (kbd "C-+") 'text-scale-increase)
(global-set-key (kbd "C--") 'text-scale-decrease)
(global-set-key (kbd "C-c C-k") 'compile)
(global-set-key (kbd "C-x g") 'magit-status)

;; Make keystrokes echo faster, don't use dialog boxes, and use visual bells.
(setq echo-keystrokes 0.1
      use-dialog-box nil
      visible-bell t) ; I'm so going to regret that.

;; Always always always highlight parens.
(show-paren-mode t)

;; Always put a newline at the end of the file
(setq-default require-final-newline t)
;; Set a scrolloff buffer of 5
(setq scroll-margin 5)

;; Enable projectile (Like CtrlP, uses C-c p f)
(projectile-global-mode)

;; Always follow symlinks
(setq vc-follow-symlinks t)

;; Turn on line numbers (and put a space between the columns)
(global-linum-mode t)
(setq linum-format "%4d \u2502 ")
(setq column-number-mode t)

;; Install things from the vendor directory, because not everything is in MELPA
(defvar dru89/vendor-dir (expand-file-name "vendor" user-emacs-directory))
(add-to-list 'load-path dru89/vendor-dir)

(dolist (project (directory-files dru89/vendor-dir t "\\w+"))
  (when (file-directory-p project)
    (add-to-list 'load-path project)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ORG MODE STUFF

;; Add the INPROGRESS keyword to tasks, make it blue.  Enable flyspell- and writegood-mode
;; when org-mode is active
(setq org-log-done t
      org-todo-keywords '((sequence "TODO" "INPROGRESS" "DONE"))
      org-todo-keyword-faces '(("INPROGRESS" . (:foreground "blue" :weight bold))))
(add-hook 'org-mode-hook
          (lambda ()
            (flyspell-mode)))
(add-hook 'org-mode-hook
          (lambda ()
            (writegood-mode)))

;; Make org-agenda easily accessible (C-c a). Add some org files to it
;; (personal.org and work.org).  My hope is that I'll use this for planning my next day.
;; If a todo item is already scheduled or has a deadline, don't show it in the global
;; list.
(defvar dropbox-org-dir  (file-name-as-directory "~/Dropbox/org"))
(global-set-key (kbd "C-c a") 'org-agenda)
(setq org-agenda-start-on-weekday 0
      org-agenda-show-log t
      org-agenda-todo-ignore-scheduled t
      org-agenda-todo-ignore-deadlines t)
(load-library "find-lisp")
(setq org-agenda-files (find-lisp-find-files dropbox-org-dir "\.org$"))
(setq org-agenda-custom-commands
      `(;; match the tasks that are incomplete and unscheduled
	("u" "[u]nscheduled tasks" tags "-SCHEDULED={.+}/!+TODO|+INPROGRESS")
	))
(defun daily-journal ()
  (interactive)
  (let ((journal-location-name (file-name-as-directory "journal"))
	(daily-journal-name (format-time-string "%Y-%m-%d"))
	(journal-month-name (file-name-as-directory (format-time-string "%B")))
	(journal-year-name (file-name-as-directory (format-time-string "%Y"))))
    (find-file (concat dropbox-org-dir journal-location-name journal-year-name journal-month-name daily-journal-name ".org"))))

;; Set up some stuff for tracking habits, too.  That's pretty cool.
(require 'org)
(require 'org-install)
(require 'org-habit)
(add-to-list 'org-modules "org-habit")
(setq org-habit-graph-column 80
      org-habit-show-habits-only-for-today nil)

;; Apparently I could rewrite this entire file an org file and have it still compiled
;; and run as my initialization file.  This might be nice for documentation later.
;; It will definitely be nice for graphviz-like stuff, though.
(require 'ob)
(org-babel-do-load-languages
 'org-babel-load-languages
 '((sh . t)
   (ditaa . t)
   (plantuml . t)
   (dot . t)
   (ruby . t)))

(add-to-list 'org-src-lang-modes (quote ("dot" . graphviz-dot)))
(add-to-list 'org-src-lang-modes (quote ("plantuml" . fundamental)))
(add-to-list 'org-babel-tangle-lang-exts '("clojure" . "clj"))

(defvar org-babel-default-header-args:clojure
  '((:results . "silent") (:tangle . "yes")))

(defun org-babel-execute:clojure (body params)
  (lisp-eval-string body)
  "Done!")

(provide 'ob-clojure)

(setq org-src-fontify-natively t
      org-confirm-babel-evaluate nil)

(add-hook 'org-babel-after-execute-hook (lambda ()
                                          (condition-case nil
                                              (org-display-inline-images)
                                            (error nil)))
          'append)

;; something, something, org-abbrev ..
;; https://github.com/abedra/emacs.d/blob/eca039ad6f8403d693ce5088f5f921d36712a267/abedra.org#org-abbrev
;; On second glance, this looks like a nice way to do abbrevations and expansions.
(add-hook 'org-mode-hook (lambda () (abbrev-mode 1)))

(define-skeleton skel-org-block-elisp
  "Insert an emacs-lisp block"
  ""
  "#+begin_src emacs-lisp\n"
  _ - \n
  "#+end_src\n")

(define-abbrev org-mode-abbrev-table "selisp" "" 'skel-org-block-elisp)

(define-skeleton skel-header-block
  ;; TODO: REMOVE HARDLINK TO CSS FILE
  "Creates a default header"
  ""
  "#+TITLE: " str "\n"
  "#+AUTHOR: Drew Hays\n"
  "#+EMAIL: drewshays@gmail.com\n"
  "#+OPTIONS: toc:3 num:nil\n"
  "#+STYLE: <link rel=\"stylesheet\" type=\"text/css\" href=\"http://cse3521.artifice.cc/css/worg.css\" />\n")

(define-abbrev org-mode-abbrev-table "sheader" "" 'skel-header-block)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UTILITIES

;; Set a path to ditaa (http://ditaa.sourceforge.net/)
(setq org-ditaa-jar-path "~/.emacs.d/vendor/ditaa0_9.jar")

;; Set a path to plantuml (http://plantuml.sourceforge.net/)
(setq org-plantuml-jar-path "~.emacs.d/vendor/plantuml.jar")

;; Turn on deft mode for random note taking
(setq deft-directory "~/Dropbox/deft")
(setq deft-use-filename-as-title t)
(setq deft-extension "org")
(setq deft-text-mode 'org-mode)

;; Turn on smex (M-x history and searching)
(setq smex-save-file (expand-file-name ".smex-items" user-emacs-directory))
(smex-initialize)
(global-set-key (kbd "M-x") 'smex)
(global-set-key (kbd "M-x") 'smex-major-mode-commands)

;; Turning on Ido
(ido-mode t)
(setq ido-enable-flex-matching t
      ido-use-virtual-buffers t)

;; Turn on column numbers
(setq column-number-mode t)

;; Get rid of the temporary files
(setq backup-directory-alist `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms `((".*" ,temporary-file-directory t)))

;; Automatically create pairs for braces (e.g. (), [], {}).
;; TODO: I might eventually turn this off.
(require 'autopair)

;; Things for lispy files
(setq lisp-modes '(lisp-mode
                   emacs-lisp-mode
                   common-lisp-mode
                   scheme-mode
                   clojure-mode))

(defvar lisp-power-map (make-keymap))
(define-minor-mode lisp-power-mode "Fix keybindings; add power."
  :lighter " (power)"
  :keymap lisp-power-map
  (paredit-mode t))
(define-key lisp-power-map [delete] 'paredit-forward-delete)
(define-key lisp-power-map [backspace] 'paredit-backward-delete)

(defun dru89/engage-lisp-power ()
  "Turn on lisp-power-mode."
  (lisp-power-mode t))

(dolist (mode lisp-modes)
  (add-hook (intern (format "%s-hook" mode))
            #'dru89/engage-lisp-power))

(setq inferior-lisp-program "clisp")
(setq scheme-program-name "racket")

;; Turn on autocomplete
(require 'auto-complete-config)
(ac-config-default)

;; Indentation and buffer cleaup. (Re-indent, untabify, and clean-up whitespace.)
(defun untabify-buffer ()
  "Untabify the current buffer."
  (interactive)
  (untabify (point-min) (point-max)))

(defun indent-buffer ()
  "Indent the current buffer."
  (interactive)
  (indent-region (point-min) (point-max)))

(defun cleanup-buffer (trim-whitespace)
  "Clean up buffer by indenting, untabifying, and deleting trailing whitespace.
TRIM-WHITESPACE: boolean value representing whether or not to trim whitespace"
  (interactive
   (list (yes-or-no-p "Trim whitespace? ")))
  (indent-buffer)
  (untabify-buffer)
  (if trim-whitespace (delete-trailing-whitespace)))

(defun cleanup-region (beg end)
  "Remove tmux artifacts from region.
BEG: The beginning of the region
END: The end of the region"
  (interactive "r")
  (dolist (re '("\\\\|\·*\n" "\W*│\·*"))
    (replace-regexp re "" nil beg end)))

;; flymake configuration.
(add-hook 'after-init-hook #'global-flycheck-mode)
(add-hook 'scss-mode-hook 'flycheck-mode)
(add-hook 'coffee-mode-hook (lambda ()
                              (setq flycheck-coffeelintrc "~/.coffeelint.json")))

;; flyspell configuration. Turn off the welcome flag, specify spell check location.
(setq flyspell-issue-welcome-flag nil)
(if (eq system-type 'darwin)
    (setq-default ispell-program-name "/usr/local/bin/aspell")
  (setq-default ispell-program-name "/usr/bin/aspell"))
(setq-default ispell-list-command "list")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SPECIFIC LANGUAGE HOOKS

;;;;;;;;;;;;;;
;; ORG MODE
(add-hook 'org-mode-hook
	  (lambda ()
	    (electric-indent-mode -1)))

;;;;;;;;;;;;;;
;; WEB MODE
(add-to-list 'auto-mode-alist '("\\.hbs$" . web-mode))
(add-to-list 'auto-mode-alist '("\\.erb$" . web-mode))

;;;;;;;;;;;;;;
;; RUBY MODE
;; Turn on autopair with ruby and add some extra file types.
(add-hook 'ruby-mode-hook
          (lambda ()
            (autopair-mode)))

(add-to-list 'auto-mode-alist '("\\.rake$" . ruby-mode))
(add-to-list 'auto-mode-alist '("\\.gemspec$" . ruby-mode))
(add-to-list 'auto-mode-alist '("\\.ru$" . ruby-mode))
(add-to-list 'auto-mode-alist '("Rakefile" . ruby-mode))
(add-to-list 'auto-mode-alist '("Gemfile" . ruby-mode))
(add-to-list 'auto-mode-alist '("Capfile" . ruby-mode))
(add-to-list 'auto-mode-alist '("Vagrantfile" . ruby-mode))

;;;;;;;;;;;;;;
;; YAML MODE
;; Add some file types to YAML mode.
(add-to-list 'auto-mode-alist '("\\.yml$" . yaml-mode))
(add-to-list 'auto-mode-alist '("\\.yaml$" . yaml-mode))

;;;;;;;;;;;;;;
;; SCSS MODE
;; Never ever compile SCSS files right after save.
(setq scss-compile-at-save nil)

;;;;;;;;;;;;;;
;; COFFEESCRIPT MODE
;; Set default indent level to 4 spaces
(defun coffee-custom ()
  "Correctly hook up CoffeeScript files."
  (make-local-variable 'tab-width)
  (set 'tab-width 4))
(add-hook 'coffee-mode-hook 'coffee-custom)

;;;;;;;;;;;;;;
;; JAVASCRIPT MODE
;; Set default indent level to 4 spaces)
(defun js-custom ()
  "Correctly hook up JavaScript files."
  (setq js-indent-level 4))
(add-hook 'js-mode-hook 'js-custom)

;;;;;;;;;;;;;;
;; MARKDOWN MODE
;; Setup some markdown extensions, use pandoc to generate HTML previews
;; Add a custom CSS file.
(add-to-list 'auto-mode-alist '("\\.md$" . markdown-mode))
(add-to-list 'auto-mode-alist '("\\.mdown$" . markdown-mode))
(add-hook 'markdown-mode-hook
          (lambda ()
            (visual-line-mode t)
            (writegood-mode t)
            (flyspell-mode t)))
(setq markdown-command "pandoc --smart -f markdown -t html")
(setq markdown-css-path (expand-file-name "markdown.css" dru89/vendor-dir))

;;;;;;;;;;;;;;
;; DOTFILE EXTRAS
;; Set up some common file names for my dotfiles, since my ~/dotfiles doesn't
;; hide the files before installation.
(add-to-list 'auto-mode-alist '("zshrc$" . sh-mode))
(add-to-list 'auto-mode-alist '("emacs$" . emacs-lisp-mode))

;;;;;;;;;;;;;;
;; THEMES
;; Always load the monokai theme.
(load-theme 'monokai t)

;; Setting up a nice mode-line
(setq sml/theme 'dark)
(sml/setup)
