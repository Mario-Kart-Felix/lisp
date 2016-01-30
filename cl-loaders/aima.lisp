;;;; -*- coding:utf-8 -*-

;; ----------------------------------------------------------------------
;; -- CMU-AI -- AIMA: Artificial Inteligence - A Modern Approach --
;; ----------------------------------------------------------------
(eval-when (:compile-toplevel :load-toplevel :execute)
  (setf *readtable* (copy-readtable nil)))

(load "cmu-ai:bookcode;aima;aima")
(aima-load 'all)

(defun compile-aima ()
  (aima-compile)
  (test 'all))

;;;; aima.lisp                        -- 2003-05-02 08:02:18 -- pascal   ;;;;
