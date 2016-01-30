;;;; -*- coding:utf-8 -*-
;;;;**************************************************************************
;;;;FILE:               generic-cl.lisp
;;;;LANGUAGE:           Common-Lisp
;;;;SYSTEM:             Common-Lisp
;;;;USER-INTERFACE:     NONE
;;;;DESCRIPTION
;;;;    
;;;;    See :documentation of package below.
;;;;    
;;;;AUTHORS
;;;;    <PJB> Pascal J. Bourguignon <pjb@informatimago.com>
;;;;MODIFICATIONS
;;;;    2006-05-27 <PJB> Created
;;;;BUGS
;;;;LEGAL
;;;;    AGPL3
;;;;    
;;;;    Copyright Pascal J. Bourguignon 2006 - 2016
;;;;    
;;;;    This program is free software: you can redistribute it and/or modify
;;;;    it under the terms of the GNU Affero General Public License as published by
;;;;    the Free Software Foundation, either version 3 of the License, or
;;;;    (at your option) any later version.
;;;;    
;;;;    This program is distributed in the hope that it will be useful,
;;;;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;;;;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;;;    GNU Affero General Public License for more details.
;;;;    
;;;;    You should have received a copy of the GNU Affero General Public License
;;;;    along with this program.  If not, see <http://www.gnu.org/licenses/>
;;;;**************************************************************************
(eval-when (:compile-toplevel :load-toplevel :execute)
  (setf *readtable* (copy-readtable nil)))
(defpackage "COM.INFORMATIMAGO.COMMON-LISP.LISP.GENERIC-COMMON-LISP"
  (:nicknames "GENERIC-COMMON-LISP"
              "GENERIC-CL")
  (:use "COMMON-LISP")
  (:documentation
   "

This package exports generic functions that forward to the COMMON-LISP
package when there's no specialization.

Copyright Pascal J. Bourguignon 2006 - 2006
This package is provided under the Afero General Public License 3.
See the source file for details.

")
  ;; export the same symbols as CL:
  (:export . #.(let ((symbols '()))
         (do-external-symbols (sym "COMMON-LISP")
           (push (string sym) symbols))
         symbols)))
(in-package "COM.INFORMATIMAGO.COMMON-LISP.LISP.GENERIC-COMMON-LISP")




;; export at the end.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defparameter *not-implemented-yet* (make-hash-table :test (function equal))))

(defmacro not-implemented-yet (what)
  (unless (gethash what *not-implemented-yet*)
    (setf (gethash what *not-implemented-yet*) t)
    (warn "~S not implemented yet." what))
  `(progn
     (unless (gethash ',what *not-implemented-yet*)
       (setf (gethash ',what *not-implemented-yet*) t)
       (warn "~S not implemented yet." ',what))
     nil))

(defmacro define-forward (name arguments)
  ;; (let* ((lambda-list       (parse-lambda-list arguments :ordinary))
  ;;        (m-name            (intern (format nil "%~A" name)))
  ;;        (cl-name           (intern (string (if (consp name)
  ;;                                               (second name)
  ;;                                               name))
  ;;                                   "COMMON-LISP")))
  ;;   ;; When a  keyword or optional argument has no initform
  ;;   ;; then add one to the method and use APPLY.
  ;;   `(progn
  ;;      (shadow '(,m-name))
  ;;      (defgeneric ,m-name ,(mapcar (lambda (arg)
  ;;                                     (if (consp arg)
  ;;                                         (if (consp (first arg))
  ;;                                             (second (first arg))
  ;;                                             (first arg))
  ;;                                         arg))
  ;;                                   arguments)
  ;;        (:method ,arguments
  ;;          ,(if (consp name)
  ;;               `(setf (,cl-name ,@(cdr arguments)) ,(car arguments))
  ;;               `(,cl-name ,@arguments))))))
  (declare (ignore name arguments))
  (not-implemented-yet define-forward))

(defmacro defmethod-and-forward (name fname arguments)
  (declare (ignore name fname arguments))
  (not-implemented-yet defmethod-and-forward))

(defmacro define-method (name qualifiers-or-lambda-list &body body)
  (declare (ignore name qualifiers-or-lambda-list body))
  (not-implemented-yet define-method))

;; t
;;    sequence
;;       vector
;;       list
;;          null
;;          cons
;;    user-sequence
;;       direct-access-sequence
;;       sequential-access-sequence

   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; After these define-foward, these functions become generic functions,
;;; with a default method that calls the corresponding function in CL.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Forwarding 14. Conses
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-forward rplaca (cons object))
(define-forward rplacd (cons object))

(dolist (name '(car cdr caar cadr cdar cddr caaar caadr cadar caddr
                cdaar cdadr cddar cdddr caaaar caaadr caadar caaddr
                cadaar cadadr caddar cadddr cdaaar cdaadr cdadar cdaddr
                cddaar cddadr cdddar cddddr first second third fourth
                fifth sixth seventh eighth ninth tenth ))
  (eval `(define-forward ,name (cons)))
  (eval `(define-forward (setf ,name) (value cons))))

(define-forward copy-tree (tree))

(dolist (name '(sublis nsublis))
  (eval `(define-forward ,name
             (alist tree &key (key nil) (test (function eql)) test-not))))

(dolist (name '(subst nsubst))
  (eval `(define-forward ,name
             (new old tree &key (key nil) (test (function eql)) test-not))))

(dolist (name '(subst nsubst))
  (eval `(define-forward ,name
             (new old tree &key (key nil) (test (function eql)) test-not))))

(dolist (name '(subst-if subst-if-not nsubst-if nsubst-if-not))
  (eval `(define-forward ,name
             (new predicate tree
                  &key (key nil) (test (function eql)) test-not))))

(define-forward tree-equal (tree-1 tree-2 &key (test (function eql)) test-not))
(define-forward copy-list (list))
(define-forward endp (list))
(define-forward nth (n list))
(define-forward (setf nth) (value n list))




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Forwarding 17. Sequences
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-forward copy-seq      (sequence))
(define-forward elt           (sequence index))
(define-forward (setf elt)    (value sequence index))
(define-forward fill          (sequence item &key (start 0) (end nil)))
(define-forward make-sequence (result-type size &key initial-element))
(define-forward subseq        (sequence start &optional (end nil)))
(define-forward (setf subseq) (value sequence start &optional (end nil)))
(define-forward map           (result-type function sequence &rest sequences))
(define-forward map-into      (result-sequence function &rest sequences))
(define-forward length        (sequence))
(define-forward reverse       (sequence))
(define-forward nreverse      (sequence))
(define-forward sort          (sequence predicate &key (key nil)))
(define-forward stable-sort   (sequence predicate &key (key nil)))
(define-forward concatenate   (result-type &rest sequences))
(define-forward merge         (result-type sequence-1 sequence-2 predicate
                                           &key (key nil)))


(dolist (name '(remove-duplicates delete-duplicates))
  (eval `(define-forward ,name
             (sequence &key (key nil) (from-end nil) (start 0) (end nil)
                       (test (function eql)) test-not))))

(dolist (name '(count find position))
  (eval `(define-forward ,name
             (item sequence &key (key nil) (from-end nil) (start 0) (end nil)
                   (test (function eql)) test-not))))

(dolist (name '(count-if count-if-not
                find-if  find-if-not
                position-if position-if-not))
  (eval `(define-forward ,name
             (predicate sequence &key (key nil) (from-end nil)
                        (start 0) (end nil)))))

(define-forward reduce
    (function sequence &key (key nil) (from-end nil) (start 0) (end nil)
              initial-value))

(dolist (name '(search mismatch))
  (eval `(define-forward ,name
             (sequence-1 sequence-2 &key (key nil) (from-end nil)
                         (start1 0) (end1 nil)(start2 0) (end2 nil)
                         (test (function eql)) test-not))))

(define-forward replace
    (sequence-1 sequence-2 &key (start1 0) (end1 nil) (start2 0) (end2 nil)))

(defmethod-and-forward substitute    nsubstitute 
  (newitem olditem (self  sequential-access-sequence)
           &key (from-end nil) (test (function eql)) test-not
           (start 0) (end nil) (count nil) (key nil)))
 
(defmethod-and-forward substitute-if nsubstitute-if 
  (newitem olditem (self  sequential-access-sequence)
           &key (from-end nil) (test (function eql)) test-not
           (start 0) (end nil) (count nil) (key nil)))

(defmethod-and-forward substitute-if-not nsubstitute-if-not
  (newitem olditem (self  sequential-access-sequence)
           &key (from-end nil) (test (function eql)) test-not
           (start 0) (end nil) (count nil) (key nil))
  )




(dolist (name '(remove delete))
  (eval `(define-forward ,name
             (item sequence &key (from-end nil) (test (function eql)) test-not
                   (start 0) (end nil) (count nil) (key nil)))))

(dolist (name '(remove-if remove-if-not
                delete-if delete-if-not))
  (eval `(define-forward ,name
             (test sequence &key (from-end nil)
                   (start 0) (end nil) (count nil) (key nil)))))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;---------------------------------------------------------------------
;;; So now, we can define our own subclasses of sequences.
;;;---------------------------------------------------------------------


;; (define-method closer-mop:validate-superclass :before ((c class) (s class))
;;   (call-next-method))


;; (remove-method (function closer-mop:validate-superclass)
;;                (find-method (function closer-mop:validate-superclass)
;;                             ':before
;;                             '(class  class)))

;;; this doesn't work on ccl for built-in-class vs stanard-class
;;; and not on clisp for find-class can't find the class pased in arguments.
;; (define-method closer-mop:validate-superclass :before
;;     ((class class) (superclass class))
;;   (warn "~S check again this implementation!"'(closer-mop:validate-superclass :before
;;                                                ((class class) (superclass class))))
;;   (print class)
;;   (print (list class  (eql class       (find-class 'user-sequence))
;;                superclass (eql superclass  (load-time-value (find-class 'sequence)))))
;;   (print (or (and #-clisp (eql class       (find-class 'user-sequence))
;;                   #+clisp (eq 'user-sequence (class-name class))
;;                   (eql superclass  (load-time-value (find-class 'sequence))))
;;              (call-next-method))))

(warn "TODO: implement user-sequence as subclass of sequence")
(defclass user-sequence (#+not-yet sequence)
  ()
  (:documentation "Our own abstract sequence class."))




;;;---------------------------------------------------------------------
;;; Abstract direct access sequence
;;;---------------------------------------------------------------------


(defclass direct-access-sequence (user-sequence)
  ((length #+not-yet :reader #+not-yet length))
  (:documentation "A class of vector-like sequences with direct access."))

(define-method copy-seq ((self direct-access-sequence))
  (let ((copy (make-instance (class-of self) :size (length self))))
    (loop
       :for i :from 0 :below (length self)
       :do (setf (elt copy i)  (elt self i))
       :finally (return copy))))

;;; primitives:
;;; (define-method elt ((self direct-access-sequence) index) )
;;; (define-method (setf elt) (value (self direct-access-sequence) index)   value)


;;;---------------------------------------------------------------------
;;; Abstract sequential access sequence
;;;---------------------------------------------------------------------

(defclass sequential-access-sequence (user-sequence)
  ()
  (:documentation "A class of list-like sequences with sequential access."))

(defgeneric sas-head (self)
  (:documentation "RETURN:  A cursor at the head of the sequence."))


(defclass sas-cursor ()
  ((sas :reader cursor-sas :initarg :sequence))
  (:documentation "A cursor on a sequential access sequence."))
(defgeneric sas-cursor-copy (self)
  (:documentation
   "RETURN: a copy of the cursor. 
        Calling (sas-cursor-next self) won't change the copy."))
(defgeneric sas-cursor-next (self)
  (:documentation "RETURN:  the next cursor. 
         May modify self, or may return a new object."))
(defgeneric sas-cursor-end-p  (self)
  (:documentation
   "RETURN:  whether the cursor has reached the end of the sequence."))
(defgeneric sas-cursor-value (self)
  (:documentation
   "PRE: (not (sas-cursor-end-p self))
RETURN: the value at the cursor position in the sequence."))
(defgeneric (setf sas-cursor-value) (value self)
  (:documentation
   "DO:     Sets the value at the cursor position in the sequence.
        If the cursor is at the end, then append then new value.
POST:   (not (sas-cursor-end-p self))"))


(define-method length ((self sequential-access-sequence))
  (loop
     :for cursor = (sas-head self) :then (sas-cursor-next cursor)
     :for length :from 0
     :until (sas-cursor-end-p cursor)
     :finally (return length)))

(define-method copy-seq ((self sequential-access-sequence))
  (let ((copy  (make-instance (class-of self))))
    (loop
       :for src = (sas-head self) :then (sas-cursor-next src)
       :for dst = (sas-head self) :then (sas-cursor-next dst)
       :until (sas-cursor-end-p src)
       :do (setf (sas-cursor-value dst) (sas-cursor-value src))
       :finally (return copy))))

(define-method elt ((self sequential-access-sequence) index)
  (check-type index (integer 0))
  (loop
     :for cursor = (sas-head self) :then (sas-cursor-next cursor)
     :for length :from 0 :below index
     :do (if (sas-cursor-end-p cursor)
             (check-type index `(integer 0 ,length))
             (return (sas-cursor-value cursor)))))

(define-method (setf elt) (value (self sequential-access-sequence) index)
  (check-type index (integer 0))
  (loop
     :for cursor = (sas-head self) :then (sas-cursor-next cursor)
     :for length :from 0 :below index
     :do (if (sas-cursor-end-p cursor)
             (check-type index `(integer 0 ,length))
             (return (setf  (sas-cursor-value cursor) value)))))


(define-method fill ((self sequential-access-sequence) item &key (start 0) (end nil))
  (loop
     :for cursor = (sas-head self) :then (sas-cursor-next cursor)
     :for index :from start :below end
     :do (cond
           ((sas-cursor-end-p cursor) (return self))
           ((< index start))
           ((and end (<= end index))  (return self))
           (t                         (setf  (sas-cursor-value cursor) item)))))

(define-method subseq ((self sequential-access-sequence) start &optional (end nil))
  (loop
     :with sub = (make-instance (class-of self))
     :with dst = (sas-head sub)
     :for  src = (sas-head self) :then (sas-cursor-next src)
     :for  index :from start
     :do (cond
           ((sas-cursor-end-p src)    (return sub))
           ((< index start))
           ((and end (<= end index))  (return sub))
           (t  (setf (sas-cursor-value dst) (sas-cursor-value src))))))

(define-method (setf subseq) (value sequence start &optional (end nil))
  (declare (ignore value sequence start end))
  (not-implemented-yet  (setf subseq)))
(define-forward map           (result-type function sequence &rest sequences))
(define-forward map-into      (result-sequence function &rest sequences))
(define-forward length        (sequence))
(define-forward nreverse      (sequence))
(define-forward sort          (sequence predicate &key (key nil)))
(define-forward stable-sort   (sequence predicate &key (key nil)))
(define-forward concatenate   (result-type &rest sequences))
(define-forward merge         (result-type sequence-1 sequence-2 predicate
                                           &key (key nil)))


(define-method make-sequence ((result-type sequence) size &key initial-element)
  (declare (ignore result-type size initial-element))
  (not-implemented-yet  make-sequence))


(dolist (name '(remove delete))
  (eval `(define-forward ,name
             (item sequence &key (from-end nil) (test (function eql)) test-not
                   (start 0) (end nil) (count nil) (key nil)))))

(dolist (name '(remove-if remove-if-not
                delete-if delete-if-not))
  (eval `(define-forward ,name
             (test sequence &key (from-end nil)
                   (start 0) (end nil) (count nil) (key nil)))))


(dolist (name '(remove-duplicates delete-duplicates))
  (eval `(define-forward ,name
             (sequence &key (key nil) (from-end nil) (start 0) (end nil)
                       (test (function eql)) test-not))))

(dolist (name '(count find position))
  (eval `(define-forward ,name
             (item sequence &key (key nil) (from-end nil) (start 0) (end nil)
                   (test (function eql)) test-not))))

(dolist (name '(count-if count-if-not
                find-if  find-if-not
                position-if position-if-not))
  (eval `(define-forward ,name
             (predicate sequence &key (key nil) (from-end nil)
                        (start 0) (end nil)))))

(define-forward reduce
    (function sequence &key (key nil) (from-end nil) (start 0) (end nil)
              initial-value))

(dolist (name '(search mismatch))
  (eval `(define-forward ,name
             (sequence-1 sequence-2 &key (key nil) (from-end nil)
                         (start1 0) (end1 nil)(start2 0) (end2 nil)
                         (test (function eql)) test-not))))

(define-forward replace
    (sequence-1 sequence-2 &key (start1 0) (end1 nil)(start2 0) (end2 nil)))

(defmethod-and-forward substitute    nsubstitute 
  (newitem olditem (self  sequential-access-sequence)
           &key (from-end nil) (test (function eql)) test-not
           (start 0) (end nil) (count nil) (key nil))
  )
 
(defmethod-and-forward substitute-if nsubstitute-if 
  (newitem olditem (self  sequential-access-sequence)
           &key (from-end nil) (test (function eql)) test-not
           (start 0) (end nil) (count nil) (key nil))
  )

(defmethod-and-forward substitute-if-not nsubstitute-if-not
  (newitem olditem (self  sequential-access-sequence)
           &key (from-end nil) (test (function eql)) test-not
           (start 0) (end nil) (count nil) (key nil))
  )


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; THE END ;;;;
