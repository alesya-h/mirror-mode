(make-variable-buffer-local 'mirror-window-id)
(make-variable-buffer-local 'mirror-point)
(make-variable-buffer-local 'mirror-change-start)
(make-variable-buffer-local 'mirror-change-end)
(make-variable-buffer-local 'mirror-key-buffer)


(defun mirror-get-window-id ()
  (replace-regexp-in-string "\n" "" (shell-command-to-string "xdotool selectwindow")))

(defun just-call (cmd &rest args)
  (apply #'call-process (append (list cmd nil nil nil) args)))

(defun xdotool (args)
  (apply #'just-call (cons "xdotool" args)))

(defun mirror-key (&rest args)
  (xdotool `("key" "--window" ,mirror-window-id ,@args)))

(defun mirror-type (&rest args)
  (xdotool `("type" "--window" ,mirror-window-id ,@args)))


(defun mirror-point-row (point)
  (count-lines 1 (1+ point)))

(defun mirror-point-col (point)
  (save-excursion
    (goto-char point)
    (beginning-of-line)
    (- point (point))))

(defun mirror-home (&optional select)
  (setq mirror-point-row 0)
  (setq mirror-point-col 0)
  (if select
      (mirror-key "Shift+Ctrl+Home")
      (mirror-key "Ctrl+Home")))


(defun mirror-line-begin ()
  (mirror-key "Home"))

(defun mirror-end (&optional select)
  (if select
      (mirror-key "Shift+Ctrl+End")
      (mirror-key "Ctrl+End")))

(defun mirror-move-vertical (n &optional select)
  (cond ((= n 0) nil)
        ((> n 0) (apply #'mirror-key (make-list n (if select "Shift+Down" "Down"))))
        ((< n 0) (apply #'mirror-key (make-list (abs n) (if select "Shift+Up" "Up")))))
  (setq mirror-point-row (+ mirror-point-row n)))

(defun mirror-move-horizontal (n &optional select)
  (cond ((= n 0) nil)
        ((> n 0) (apply #'mirror-key (make-list n (if select "Shift+Right" "Right"))))
        ((< n 0) (apply #'mirror-key (make-list (abs n) (if select "Shift+Left" "Left")))))
  (setq mirror-point-col (+ mirror-point-col n)))

(defun mirror-move-to (point &optional select)
  (mirror-home select)
  (let ((row (1- (mirror-point-row point)))
        (col (mirror-point-col point)))
    (if (= mirror-point-row row)
        (mirror-move-horizontal (- mirror-point-col col))
      (progn (mirror-line-begin)
             (mirror-move-vertical (- mirror-point-row row))
             (mirror-move-horizontal col)))))

(defun mirror-get-clipboard ()
  (with-temp-buffer
    (clipboard-yank)
    (buffer-string)))
  
(defun mirror-select (start end)
  (mirror-move-to start)
  (mirror-move-to end t))

(defun mirror-set-clipboard (str)
  (x-set-selection 'CLIPBOARD str))


(defun mirror-do-paste ()
  (mirror-key "Ctrl+v"))

(defun mirror-paste (text)
  (mirror-set-clipboard text)
  (mirror-do-paste))

(defun mirror-sync ()
  (interactive)
  ;; (mirror-home)
  ;; (mirror-end t)
  ;; (mirror-type (buffer-substring-no-properties (point-min) (point-max)))
  (let (old-clipboard (mirror-get-clipboard))
    (mirror-set-clipboard (buffer-substring-no-properties (point-min) (point-max)))
    (mirror-key "Ctrl+a" "Ctrl+v")
    ;; (mirror-set-clipboard old-clipboard)
    )
  ;; (mirror-home)
  ;; (mirror-move-to (point))
  )
  
(defun mirror-coord ()
  (list (mirror-point-row (point)) (mirror-point-col (point))))


(defun mirror-before-change (start end)
  (setq mirror-change-start start
        mirror-change-end end))

(defun mirror-after-change (start end old-len)
  (mirror-select mirror-change-start mirror-change-end)
  (mirror-type (buffer-substring-no-properties start end))
  
  )


(setq mirror-mode-map nil)
(define-minor-mode mirror-mode "mirrors buffer to (google docs) window" nil "Mirror" mirror-mode-map
  (cond
   ;; Enable mode
   (mirror-mode
    (setq mirror-window-id (mirror-get-window-id))
    (run-at-time 1 1 'mirror-sync)
    ;; (mirror-sync)
    ;; (add-to-list 'before-change-functions 'mirror-before-change)
    ;; (add-to-list 'after-change-functions 'mirror-after-change)
    )
   ;; Disable mode
   (t
    (setq before-change-functions (delete 'mirror-before-change before-change-functions))
    (setq after-change-functions(delete 'mirror-after-change after-change-functions))
    )))


(provide 'mirror)
