;;;; -*- mode:lisp;coding:utf-8 -*-
;;;;**************************************************************************
;;;;FILE:               xmls-tools.lisp
;;;;LANGUAGE:           Common-Lisp
;;;;SYSTEM:             Common-Lisp
;;;;USER-INTERFACE:     NONE
;;;;DESCRIPTION
;;;;    
;;;;    Some tools to process xmls generated sexps.
;;;;    
;;;;AUTHORS
;;;;    <PJB> Pascal J. Bourguignon <pjb@informatimago.com>
;;;;MODIFICATIONS
;;;;    2011-05-27 <PJB> Extracted from personal code.
;;;;BUGS
;;;;LEGAL
;;;;    AGPL3
;;;;    
;;;;    Copyright Pascal J. Bourguignon 2011 - 2012
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
;;;;    

(defpackage "XMLS-TOOLS"
  (:use "COMMON-LISP"
        #+ccl "CCL" #-ccl "CLOS")
  (:export "SCASE"
           "CONC-SYMBOL" "MAKE-KEYWORD"
           "COMPUTE-CLOSURE" "TOPOLOGICAL-SORT"

           "DEFCLASS*" "*PRINT-OBJECT-READABLY*"
           
           "DEFINE-CLASS-STRUCTURE"
           "DEFINE-LIST-STRUCTURE"

           "MAKE-ELEMENT" "ELEMENT-NAME" "ELEMENT-ATTRIBUTES" "ELEMENT-CHILDREN"
           "MAKE-ATTRIBUTE" "ATTRIBUTE-NAME" "ATTRIBUTE-VALUE"

           "GET-ATTRIBUTE-NAMED" "VALUE-OF-ATTRIBUTE-NAMED"
           "GET-FIRST-CHILD" "GET-FIRST-CHILD-VALUED"
           "GET-FIRST-CHILD-TAGGED" "GET-CHILDREN-TAGGED"
           "FIND-CHILDREN-TAGGED"
           "VALUE-TO-BOOLEAN"
           "SINGLE-STRING-CHILD-P"
           "GET-CHILDREN-WITH-TAG-AND-ATTRIBUTE"
           "ELEMENT-AT-PATH")
  (:documentation
   "Defines some tools to manipulate sxml trees."))
(in-package "XMLS-TOOLS")

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defvar *dump-exportable-symbols-p* nil
    "Set to T to get a message with the list of the symbols defined
by define-class-structure and define-list-structure."))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Extracted from com.informatimago.common-lisp.utilities et al.:

(defmacro scase (keyform &rest clauses)
  "
DO:         A CASE, but for string keys. That is, it uses STRING= as test
            insteand of the ''being the same'' test.
"
  (let ((key (gensym "KEY")))
    `(let ((,key ,keyform))
       (cond
         ,@(mapcar (lambda (clause)
                     (if (or (eq (car clause) 'otherwise) (eq (car clause) 't))
                         `(t ,@(cdr clause))
                         `((member ,key ',(car clause) :test (function string=))
                           ,@(cdr clause))))
                   clauses)))))


(defun make-keyword (sym)
  "
RETURN: A new keyword with SYM as name.
"
  (intern (string sym) (find-package "KEYWORD")))


(defun conc-symbol (&rest args)
  "
DO:      Concatenate the arguments and INTERN the resulting string.
NOTE:    The last two arguments maybe :PACKAGE <a-package>
         in which case the symbol is interned into the given package
         instead of *PACKAGE*.
"
  (let ((package *package*))
    (when (and (<= 2 (length args))
               (eq :package (car (last args 2))))
      (setf package (car (last args))
            args (butlast args 2)))
    (intern (with-standard-io-syntax
              (apply (function concatenate) 'string
                     (mapcar (function string) args)))
            package)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;  DEFCLASS*
;;;
;;;    Define a class with the same syntax as CL:DEFCLASS,
;;;    but adding a PRINT-OBJECT method, an indicator predicate,
;;;    and a MAKE-XXX constructor.
;;;

(defvar *print-object-readably* nil
  "When true, the PRINT-OBJECT methods generated by DEFCLASS* will
write a read-time evaluation (#.) to build back an object similar to the
one printed.")

(defmacro defclass* (classname superclasses slots &rest options)
  "
As CL:DEFCLASS, but in addition defines a PRINT-OBJECT method,
a MAKE-${CLASSNAME} constructor, and
a ${CLASSNAME}P or -P predicate.
"
  (let ((constructor (intern (with-standard-io-syntax (format nil "MAKE-~A" classname)))))
    `(progn
       (defclass ,classname ,superclasses ,slots ,@options)
       (when (fboundp ',constructor)
         (warn "There was already a function named ~S ~%Redefining it for ~S"
               ',constructor ',classname))
       (defun ,constructor (&rest arguments &key &allow-other-keys)
         (apply (function make-instance) ',classname arguments))
       , (let ((name (intern (with-standard-io-syntax (format nil "~A~:[P~;-P~]" classname
                                                              (find #\- (string classname)))))))
           `(defgeneric ,name (object)
              (:method ((object t))      nil)
              (:method ((object ,classname)) t)))
       (defmethod format-slots ((self ,classname) &optional (stream nil))
         (format stream "~:[~; ~:*~A~]~@{~:[~2*~; :~A ~S~]~}"
                 (and (next-method-p) (call-next-method))
                 ,@(mapcan (lambda (slot)
                             (let ((slot (if (consp slot)
                                             (first slot)
                                             slot)))
                               (list `(slot-boundp self ',slot)
                                     `',slot
                                     `(and (slot-boundp self ',slot)
                                           (slot-value  self ',slot)))))
                           (remove-if (lambda (s)
                                        (and (consp s)
                                             (eq :class (getf (cdr s) :allocation))))
                                      slots))))
       (defmethod print-object ((self ,classname) stream)
         (if *print-object-readably*
             (progn (format stream "#.(~S"  ',constructor)
                    (format-slots self stream)
                    (princ ")" stream))
             (print-unreadable-object (self stream :identity t :type t)
               (format-slots self stream)))
         self)
       ',classname)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;  DEFINE-CLASS-STRUCTURE
;;;
;;;    Define a class with the same syntax and niceties as DEFSTRUCT.
;;;


(defun get-option (key options &optional list)
  (let ((opt (remove-if (lambda (x) (not (eq key (if (symbolp x) x (car x))))) options)))
    (cond
      (list opt)
      ((null opt) nil)
      ((null (cdr opt))
       (if (symbolp (car opt)) t (cdar opt)))
      (t (error "Expected only one ~A option."
                (if (symbolp (car opt)) (car opt) (caar opt)))))))


(defun make-name (option prefix name suffix)
  (cond
    ((or (null option) (and option (not (listp option))))
     (intern (with-standard-io-syntax (format nil "~A~A~A" prefix name suffix))))
    ((and option (listp option) (car option))
     (car option))
    (t nil)))


(defun get-name (option)
  (if (and option (listp option))
      (car option)
      nil))


(defmacro define-class-structure (name-and-options &rest doc-and-slots)
  "
DO:     Define a class implementing the structure API.
        This macro presents the same API as DEFSTRUCT, but instead of
        defining a structure, it defines a class, and the same functions
        as would be defined by DEFSTRUCT.
        The DEFSTRUCT options: :TYPE and :INITIAL-OFFSET are not supported.
"
  (let (name options documentation slots slot-names accessors
             conc-name constructors copier
             include initial-offset predicate
             print-function print-object unbound
             symbols)
    (flet ((push1 (symbol) (push symbol symbols) symbol))
      (if (symbolp name-and-options)
          (setf name    name-and-options
                options nil)
          (setf name    (car name-and-options)
                options (cdr name-and-options)))
      (if (stringp (car doc-and-slots))
          (setf documentation (car doc-and-slots)
                slots         (cdr doc-and-slots))
          (setf documentation nil
                slots         doc-and-slots))
      (setf conc-name           (get-option :conc-name      options)
            constructors        (get-option :constructor    options :list)
            copier              (get-option :copier         options)
            predicate           (get-option :predicate      options)
            include             (get-option :include        options)
            initial-offset      (get-option :initial-offset options)
            print-function      (get-option :print-function options)
            print-object        (get-option :print-object   options)
            unbound        (car (get-option :unbound        options)))
      (when (and print-object print-function)
        (error "Cannot have both :print-object and :print-function options."))
      (when (cdr include)
        (setf slots   (append (cddr include) slots)
              include (list (car include))))
      (setf conc-name (make-name conc-name ""      name "-")
            copier    (make-name copier    "COPY-" name "")
            predicate (make-name predicate ""      name "-P")
            print-function (get-name print-function)
            print-object   (get-name print-object))
      (setf slot-names (mapcar (lambda (s) (if (symbolp s) s (car s))) slots))
      (setf accessors  (mapcar
                        (lambda (s) (make-name nil (or conc-name "")
                                          (if (symbolp s) s (car s)) "")) slots))
      (if (null constructors)
          (setf constructors (list (make-name nil "MAKE-" name "")))
          (setf constructors
                (mapcan (lambda (x)
                          (cond
                            ((or (symbolp x) (= 1 (length x)))
                             (list (make-name nil "MAKE-" name "")))
                            ((null (second x))
                             nil)
                            ((= 2 (length x))
                             (list (second x)))
                            (t
                             (list (list (second x) (third x)))))) constructors)))
      (prog1
          `(progn
             (defclass ,(push1 name) ,include
               ,(mapcar
                 (lambda (slot accessor)
                   (if (symbolp slot)
                       `(,slot :initarg   ,(make-keyword slot)
                               :accessor  ,(push1 accessor)
                               ,@ (unless unbound 
                                    `(:initform  nil)))
                       (let* ((name        (first slot))
                              (initarg     (make-keyword name))
                              (initform-p  (cdr slot))
                              (initform    (car initform-p))
                              (type-p      (member :type (cddr slot)))
                              (type        (cadr type-p))
                              (read-only-p (member :read-only (cddr slot)))
                              (read-only   (cadr read-only-p)))
                         `(,name
                           :initarg ,initarg
;;; (insert (karnaugh '(unbound initform-p (eql unbound initform)) '(:initform)))
;;; +---------+------------+------------------------+-----------+
;;; | unbound | initform-p | (eql unbound initform) | :initform |
;;; +---------+------------+------------------------+-----------+
;;; |   YES   |     YES    |          YES           |    no     |
;;; |   YES   |     YES    |           NO           |   yes     |
;;; |   YES   |      NO    |          YES           |    no     |
;;; |   YES   |      NO    |           NO           |    no     |
;;; |    NO   |     YES    |          YES           |   yes     |
;;; |    NO   |     YES    |           NO           |   yes     |
;;; |    NO   |      NO    |          YES           |   yes     |
;;; |    NO   |      NO    |           NO           |   yes     |
;;; +---------+------------+------------------------+-----------+
;;; :initform = (or (not unbound) (and initform-p (not (eql unbound initform))))
                           ,@ (when (or (not unbound) (and initform-p (not (eql unbound initform))))
                                `(:initform  ,(if initform-p initform 'nil)))
                           ,(if (and read-only-p read-only) :reader :accessor) ,(push1 accessor)
                           ,@(when type-p (list :type type))))))
                 slots accessors)
               ,@(when documentation (list `(:documentation ,documentation))))
             ,@(mapcar
                (lambda (constructor)
                  ;; generate a constructor.
                  (if (symbolp constructor)
                      (let ((initargs (remove-duplicates
                                       (if (first include)
                                           (union slot-names
                                                  (mapcan
                                                   (lambda (slot)
                                                     (mapcar (lambda (keyword) (intern (string keyword)))
                                                             (slot-definition-initargs slot)))
                                                   (class-slots (find-class (first include)))))
                                           slot-names))))
                        `(defun ,(push1 constructor) (&rest arguments &key ,@initargs)
                           (declare (ignore ,@initargs))
                           (apply (function make-instance) ',name arguments)))
                      (let ((cname  (first  constructor))
                            (pospar (second constructor)))
                        (declare (ignore pospar))
                        (warn "~S does not implement this case yet." 'define-class-structure)
                        `(defun ,(push1 cname) (&rest args)
                           (declare (ignore args))
                           (error "~S does not implement this yet." 'define-class-structure)))))
                constructors)
             ,@(when copier
                     (list `(defmethod ,(push1 copier) ((self ,name))
                              (make-instance ',name
                                  ,@(mapcan
                                     (lambda (slot accessor)
                                       (list (make-keyword slot) (list accessor 'self)))
                                     slot-names accessors)))))
             ,@(when predicate
                     (list `(defmethod ,(push1 predicate) (object)
                              (eq (type-of object) ',name))))
             (defmethod print-object ((self ,name) stream)
               ,(cond
                 (print-function  `(,print-function self stream 0))
                 (print-object    `(,print-object self stream))  
                 (t `(print-unreadable-object (self stream :identity t :type t)
                       ,@(mapcar (lambda (name)
                                   `(when (slot-boundp self ',name)
                                      (format stream " :~A ~S"
                                              ',name (slot-value self ',name))))
                                 (remove-duplicates
                                  (if (first include)
                                      (union (mapcar
                                              (function slot-definition-name)
                                              (class-slots (find-class (first include))))
                                             slot-names)
                                      slot-names))))))
               self)
             ',name)
        (when *dump-exportable-symbols-p*
          (format *trace-output* ";; Exportable symbols:~%;; ~{~S~^ ~}~%"
                  (mapcar (function string) symbols)))))))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;  DEFINE-LIST-STRUCTURE
;;;
;;;     Defines list structures with &rest
;;;

(defmacro define-list-structure (name &rest fields)
  "
NAME:   A symbol naming the structure.
FIELDS: A list of symbols.  The before the last one can be &REST in which case
        the list structure takes a variable number of values and the last field
        is bound to the rest.
"
  (flet ((gen-accessors (n dotted)
           (loop
              :with tens   = '(first second third fourth fifth
                               sixth seventh eighth ninth tenth)
              :with others = '(nth i structure)
              :with cdrs   = '(identity cdr cddr cdddr)
              :with rests  = '(cdr (nthcdr (1- i) structure))
              :for i :from 0 :below n
              :collect (if (or (not dotted) (< i (1- n)))
                           (if (< i (length tens))
                               (nth i tens)
                               (substitute i 'i others))
                           (if (< i (length cdrs))
                               (nth i cdrs)
                               (substitute i 'i rests)))))
         (symcat (&rest syms) (intern (with-standard-io-syntax (format nil "~{~A~^-~}" syms)))))
    (let* ((dotted (eq '&rest  (car (last fields 2))))
           (slots (if dotted
                      (nconc (butlast fields 2) (last fields))
                      fields))
           (accessors (gen-accessors (length slots) dotted))
           (symbols '()))
      (flet ((push1 (symbol) (push symbol symbols) symbol))
        (prog1
            `(progn
               ;; constructor
               (defun ,(push1 (symcat 'make name)) ,slots
                 (,(if dotted 'list* 'list) ,@slots))
               ,@(loop
                    :with vvalue = (gensym "VAL")
                    :for slot :in slots
                    :for accessor :in accessors
                    :for acxepsor = (if (symbolp accessor)
                                        accessor
                                        (substitute name 'structure accessor))
                    :collect `(defmethod ,(push1 (symcat name slot)) ((,name list))
                                (,acxepsor ,name))
                    :collect `(defmethod (setf ,(symcat name slot)) (,vvalue (,name list))
                                (setf (,acxepsor ,name) ,vvalue)))
               ',name)
          (when *dump-exportable-symbols-p*
            (format *trace-output* ";; Exportable symbols:~%;; ~{~S~^ ~}~%"
                    (mapcar (function string) symbols))))))))

;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



(defgeneric element-name       (element)   (:method ((element   t)) nil))
(defgeneric element-attributes (element)   (:method ((element   t)) nil))
(defgeneric element-children   (element)   (:method ((element   t)) nil))
(defgeneric attribute-name     (attribute) (:method ((attribute t)) nil))
(defgeneric attribute-value    (attribute) (:method ((attribute t)) nil))

(defgeneric (setf element-name)       (new-name       element) (:method (new (element   t)) new))
(defgeneric (setf element-attributes) (new-attributes element) (:method (new (element   t)) new))
(defgeneric (setf element-children)   (new-children   element) (:method (new (element   t)) new))
(defgeneric (setf attribute-name)     (new-name     attribute) (:method (new (attribute t)) new))
(defgeneric (setf attribute-value)    (new-value    attribute) (:method (new (attribute t)) new))

(define-list-structure element name attributes &rest children)
(define-list-structure attribute name value)

(defgeneric entity-name-equal-p (a b)
  (:documentation "xmls entity name may go in namespaces in which case they're lists: (name namespace)")
  (:method ((a string) (b string)) (string= a b))
  (:method ((a string) (b symbol)) (string= a b))
  (:method ((a symbol) (b string)) (string= a b))
  (:method ((a symbol) (b symbol)) (string= a b))
  (:method ((a cons)   (b cons))   (entity-name-equal-p (car a) (car b)))
  (:method ((a cons)   (b string)) (entity-name-equal-p (car a) b))
  (:method ((a cons)   (b symbol)) (entity-name-equal-p (car a) b))
  (:method ((a string) (b cons))   (entity-name-equal-p a (car b)))
  (:method ((a symbol) (b cons))   (entity-name-equal-p a (car b))))


(defun get-attribute-named (element attribute-name)
  (find attribute-name (element-attributes element)
        :test (function string=)
        :key (function attribute-name)))

(defun value-of-attribute-named (element attribute-name)
  (attribute-value (get-attribute-named element attribute-name)))

(defun get-first-child (element)
  (first (element-children element)))

(defun single-string-child-p (element)
  (and (= 1 (length (element-children element)))
       (stringp (get-first-child element))))


(defun get-first-child-tagged (element element-name)
  (find element-name
        (element-children element)
        :test (function entity-name-equal-p)
        :key (function element-name)))

(defun get-first-child-valued (element attribute value)
  (find-if
   (lambda (child) (string= value (value-of-attribute-named child attribute)))
   (element-children element)))

(defun get-children-tagged (element element-name)
  (remove element-name
          (element-children element)
          :test-not (function entity-name-equal-p)
          :key (lambda (x) (if (consp x) (element-name x) ""))))


(defun get-children-with-tag-and-attribute (element element-name attribute-name attribute-value)
  (remove-if-not (lambda (child)
                   (and (consp child)
                        (entity-name-equal-p (element-name child) element-name)
                        (string= (value-of-attribute-named child attribute-name) attribute-value)))
                 (element-children element)))


(defun find-children-tagged (element element-name)
  (append (get-children-tagged element element-name)
          (mapcan (lambda (child) (find-children-tagged child element-name))
                  (element-children element))))


(defun value-to-boolean (value)
  (string= "true" value))


(defun element-at-path (root path)
  (if (null path)
      root
      (element-at-path (get-first-child-tagged root (first path)) (rest path))))

;; (DEFUN COMPUTE-CLOSURE (FUN SET)
;;   "
;; FUN:     set --> P(set)
;;           x |--> { y }
;; RETURN:  The closure of fun on the set.
;; NOTE:    Not a lisp closure!
;; EXAMPLE: (compute-closure (lambda (x) (list (mod (* x 2) 5))) '(1)) --> (2 4 3 1)
;; "
;;   (LOOP
;;      :FOR NEW-SET = (DELETE-DUPLICATES (UNION SET (MAPCAN FUN SET)))
;;      :WHILE (SET-EXCLUSIVE-OR NEW-SET SET)
;;      :DO (SETF SET NEW-SET)
;;      :FINALLY (RETURN NEW-SET)))

(defun compute-closure (fun set)
  "
FUN:     set --> P(set)
          x |--> { y }
RETURN:  The closure of fun on the set.
NOTE:    Not a lisp closure!
EXAMPLE: (compute-closure (lambda (x) (list (mod (* x 2) 5))) '(1)) --> (2 4 3 1)
NOTE:    This version avoids calling FUN twice with the same argument.
"
  (loop
     :for follows = (delete-duplicates (mapcan fun set))
     :then (delete-duplicates (append (mapcan fun newbies) follows))
     :for newbies = (set-difference follows set)
     :while newbies
     :do (setf set (append newbies set))
     :finally (return set)))


(defun topological-sort (nodes lessp)
  "
RETURN: A list of NODES sorted topologically according to 
        the partial order function LESSP.
        If there are cycles (discounting reflexivity), 
        then the list returned won't contain all the NODES.
"
  (loop
     :with sorted = '()
     :with incoming = (map 'vector (lambda (to)
                                     (loop
                                        :for from :in nodes
                                        :when (and (not (eq from to))
                                                   (funcall lessp from to))
                                        :sum 1))
                           nodes)
     :with q = (loop
                  :for node :in nodes
                  :for inco :across incoming
                  :when (zerop inco)
                  :collect node) 
     :while q
     :do (let ((n (pop q)))
           (push n sorted)
           (loop
              :for m :in nodes
              :for i :from 0
              :do (when (and (and (not (eq n m))
                                  (funcall lessp n m))
                             (zerop (decf (aref incoming i))))
                    (push m q))))
     :finally (return (nreverse sorted))))




;;;; THE END ;;;;

