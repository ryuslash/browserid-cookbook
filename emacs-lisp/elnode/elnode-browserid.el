(require 'elnode)
(require 'esxml)
(require 'json)
(require 'url)

(defun persona-index-handler (httpcon)
  (elnode-http-start httpcon 200 '("Content-Type" . "text/html"))
  (elnode-http-return httpcon
    (concat
     "<!DOCTYPE html>\n"
     (esxml-to-xml
      '(html ((lang . "en"))
             (head ()
                   (meta ((charset . "utf-8")))
                   (title () "elnode persona example")
                   (script ((src . "https://login.persona.org/include.js")) "")
                   (script ((src . "/login.js")) ""))
             (body ()
                   (form ((id . "login-form")
                          (method . "POST")
                          (action . "/status"))
                         (input ((id . "assertion-field")
                                 (type . "hidden")
                                 (name . "assertion")
                                 (value . ""))))
                   (p ()
                      (a ((href . "javascript:login()")) "Login"))))))))

(defun persona-verify-credentials (audience assertion)
  (let ((url-request-extra-headers '(("Content-Type" . "application/json")))
        (url-request-data (json-encode `(("assertion" . ,assertion)
                                         ("audience" . ,audience))))
        (url-request-method "POST")
        result)
    (with-current-buffer
        (url-retrieve-synchronously "https://verifier.login.persona.org/verify")
      (goto-char (point-min))
      (search-forward "\n\n")
      (setq result (json-read))
      (kill-buffer))
    result))

(defun persona-status-handler (httpcon)
  (when (equal "POST" (elnode-http-method httpcon))
    (elnode-http-start httpcon 200 '("Content-Type" . "text/html"))
    (let* ((audience "http://localhost:8080")
           (assertion (elnode-http-param httpcon "assertion"))
           (result (persona-verify-credentials audience assertion))
           (message (if (equal (cdr (assoc 'status result)) "okay")
                        (format "Logged in as: %s" (cdr (assq 'email result)))
                      (format "Error: %s" (cdr (assq 'reason result))))))
      (elnode-http-return httpcon
        (concat
         "<!DOCTYPE html>\n"
         (esxml-to-xml
          `(html ((lang . "en"))
                 (head ()
                       (meta ((charset . "utf-8")))
                       (title () "Status"))
                 (body ()
                       (p () ,message)
                       (p ()
                          (a ((href . "/")) "Return to login page"))))))))))

(defvar persona-app-routes
  `(("//$" . persona-index-handler)
    ("//login.js" . ,(elnode-make-send-file "login.js"))
    ("//status$" . persona-status-handler)))

(defun persona-root-handler (httpcon)
  (elnode-hostpath-dispatcher httpcon persona-app-routes))

(elnode-start 'persona-root-handler :port 8080 :host "localhost")
