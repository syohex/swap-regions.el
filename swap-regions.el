;;; swap-regions.el --- Swap current region and previous region  -*- lexical-binding: t; -*-

;; Copyright (C) 2016  Chunyang Xu

;; Author: Chunyang Xu <xuchunyang56@gmail.com>
;; URL: https://github.com/xuchunyang/swap-regions.el
;; Keywords: convenience
;; Version: 0.01

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; If you install this package with Emacs's packaging system, no setup is
;; needed. However, if you want to install it manually, you have to set the
;; `load-path` correctly and load it.
;;
;; To exchange current (active) region and previous region, call M-x
;; swap-regions, if you think it is worth, you can assign a key to it,
;; use e.g.:
;;
;; (define-key global-map "\C-c\C-t" #'swap-regions)
;;
;; Tips: these two regions don't need to belong to the same buffer.


;;; Code:

(defvar swap-regions-last-region nil)
(defvar swap-regions-this-region nil)
(defvar swap-regions-current-buffer nil)

;;;###autoload
(defun swap-regions-track-region ()
  (setq swap-regions-last-region
        (cons (current-buffer)
              (cons (region-beginning) (region-end)))))

;;;###autoload
(add-hook 'deactivate-mark-hook #'swap-regions-track-region)

;;;###autoload
(defun swap-regions-track-buffer ()
  (cond ((not (buffer-live-p swap-regions-current-buffer))
         (setq swap-regions-current-buffer (current-buffer)))
        ((eq swap-regions-current-buffer (current-buffer)))
        (t
         (with-current-buffer swap-regions-current-buffer
           (when (region-active-p)
             (swap-regions-track-region)))
         (setq swap-regions-current-buffer (current-buffer)))))

;;;###autoload
(add-hook 'activate-mark-hook #'swap-regions-track-buffer)

;;;###autoload
(defun swap-regions (beg end &optional arg)
  "Swap the current region and the last region.

Prefixed with one \\[universal-argument], replace the current
region with the last region.

Prefixed with two \\[universal-argument]'s, replace the last
region with the current region."
  (interactive "*r\np")
  (unless swap-regions-last-region
    (user-error "Need previous region"))
  (if (region-active-p)
      (setq swap-regions-this-region
            (cons (current-buffer)
                  (cons beg end)))
    (user-error "Need active region"))
  (let* ((last-buf (car swap-regions-last-region))
         (last-pos (cdr swap-regions-last-region))
         (last-text (with-current-buffer last-buf
                      (buffer-substring (car last-pos) (cdr last-pos))))
         (this-buf (car swap-regions-this-region))
         (this-pos (cdr swap-regions-this-region))
         (this-text (buffer-substring beg end)))
    (cond
     ((= arg 4)
      (delete-region beg end)
      (swap-regions-insert last-text))
     ((= arg 16)
      (with-current-buffer last-buf
        (goto-char (car last-pos))
        (delete-region (car last-pos) (cdr last-pos))
        (swap-regions-insert this-text)))
     (t
      (if (eq last-buf this-buf)
          ;; Maybe use `transpose-regions' instead?
          (transpose-subr-1 last-pos this-pos)
        (let ((this-text (buffer-substring (car this-pos) (cdr this-pos)))
              (last-text (with-current-buffer last-buf
                           (buffer-substring (car last-pos) (cdr last-pos)))))
          (delete-region (car this-pos) (cdr this-pos))
          (insert last-text)
          (with-current-buffer last-buf
            (delete-region (car last-pos) (cdr last-pos))
            (insert this-text))))))))

(defun swap-regions-insert (text)
  (if (require 'pulse nil 'no-error)
      (let ((p0 (point))
            (p1 (progn (insert text) (point))))
        (pulse-momentary-highlight-region p0 p1))
    (insert text)))

;; For `unload-feature'
(defun swap-regions-unload-function ()
  (remove-hook 'activate-mark-hook #'swap-regions-track-buffer)
  (remove-hook 'deactivate-mark-hook #'swap-regions-track-region)
  nil)

(provide 'swap-regions)
;;; swap-regions.el ends here
