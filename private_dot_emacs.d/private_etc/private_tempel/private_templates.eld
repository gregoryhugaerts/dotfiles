org-mode
;;; src blocks
(plantuml & "#+begin_src plantuml :file assets/" p ".svg" n r n "#+end_src"
 :post (org-edit-src-code))
