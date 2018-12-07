

(defconst srclib (file-name-directory (expand-file-name load-file-name)))

(defun srcexec-run()  ; function to execute the current file with srcexec
  (interactive)
  (if
    (not (null (buffer-file-name)))  ; buffer file exists
    (if
      (not (buffer-modified-p))  ; buffer not modified
      (if
        (string-equal (file-name-extension buffer-file-name) "xml")  ; xml file
        (progn
          (message "Running...")  ; running
          (shell-command (concat "\"" srclib "bin/srcexec\" \"" buffer-file-name "\""))  ; execute srcexec
          (message "Load or create and save an XML file and press F8 to run Srcexec.")  ; done
        )
        (message "Please load or save an XML file.")  ; not an xml file
      )
      (message "Please save the buffer.")  ; buffer modified
    )
    (message "Please load or save a file.")  ; buffer file doesn't exist
  )
)

(global-set-key (kbd "<f8>") 'srcexec-run)  ; define f8

(message "Load or create and save an XML file and press F8 to run Srcexec.")  ; run message

