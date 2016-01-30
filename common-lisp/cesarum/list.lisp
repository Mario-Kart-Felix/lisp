;;;; -*- coding:utf-8 -*-
;;;;****************************************************************************
;;;;FILE:              list.lisp
;;;;LANGUAGE:          common-lisp
;;;;SYSTEM:            UNIX
;;;;USER-INTERFACE:    UNIX
;;;;DESCRIPTION
;;;;    This module exports some list utility functions.
;;;;AUTHORS
;;;;    <PJB> Pascal J. Bourguignon <pjb@informatimago.com>
;;;;MODIFICATIONS
;;;;    2015-08-19 <PJB> Removed dll from this package. cf. the dll package.
;;;;    2014-11-18 <PJB> Added map-cartesian-product.
;;;;    2012-03-14 <PJB> Added plist-keys.
;;;;    2012-02-19 <PJB> Moved HASHED-* functions that work on sequence to
;;;;                     COM.INFORMATIMAGO.COMMON-LISP.CESARUM.SEQUENCE.
;;;;    2011-04-03 <PJB> Added LIST-LENGTHS.
;;;;    2008-06-24 <PJB> Added ENSURE-CIRCULAR, MAKE-CIRCULAR-LIST, CIRCULAR-LENGTH.
;;;;    2007-01-05 <PJB> Added REPLACE-TREE (should move to a new package later).
;;;;    2005-09-02 <PJB> Moved EQUIVALENCE-CLASSES in from ECMA048.
;;;;    2005-08-10 <PJB> Moved TRIM-LIST in from make-depends.
;;;;    2004-10-15 <PJB> Added IOTA.
;;;;    2004-08-24 <PJB> Added TRANSPOSE, HASHED-REMOVE-DUPLICATE.
;;;;    2003-06-10 <PJB> Added NSPLIT-LIST
;;;;    2002-12-03 <PJB> Common-Lisp'ized.
;;;;    2001-11-30 <PJB> Added list-remove-elements.
;;;;    199?-??-?? <PJB> Creation.
;;;;BUGS
;;;;LEGAL
;;;;    AGPL3
;;;;    
;;;;    Copyright Pascal J. Bourguignon 2002 - 2016
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
;;;;****************************************************************************
(eval-when (:compile-toplevel :load-toplevel :execute)
  (setf *readtable* (copy-readtable nil)))
(defpackage "COM.INFORMATIMAGO.COMMON-LISP.CESARUM.LIST"
  (:use "COMMON-LISP")
  (:export
   "APPENDF" "PREPENDF" "PREPEND" "PUSH*"
   "EQUIVALENCE-CLASSES" "SUBSETS" "COMBINE" "IOTA"
   "MAKE-LIST-OF-RANDOM-NUMBERS" "LIST-INSERT-SEPARATOR"
   "NSPLIT-LIST-ON-INDICATOR" "NSPLIT-LIST" "DEEPEST-REC" "DEEPEST" "DEPTH"
   "FLATTEN" "LIST-TRIM" "TRANSPOSE" "AGET" "MEMQ"
   "MAP-CARTESIAN-PRODUCT"
   "PLIST-KEYS" "PLIST-REMOVE" "PLIST-GET"
   "PLIST-PUT" "PLIST-CLEANUP" "HASHED-INTERSECTION" 
   ;; "HASHED-REMOVE-DUPLICATES" moved to COM.INFORMATIMAGO.COMMON-LISP.CESARUM.SEQUENCE
   "ENSURE-LIST" "PROPER-LIST-P" "LIST-LENGTHS" "LIST-ELEMENTS"
   "ENSURE-CIRCULAR" "MAKE-CIRCULAR-LIST" "CIRCULAR-LENGTH"
   "TREE-FIND" "TREE-DIFFERENCE" "REPLACE-TREE"
   "META-LIST" "MAPTREE")
  (:documentation
   "
This package exports list processing functions.
    

License:

    AGPL3
    
    Copyright Pascal J. Bourguignon 2003 - 2014
    
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.
    
    You should have received a copy of the GNU Affero General Public License
    along with this program.
    If not, see <http://www.gnu.org/licenses/>

"))
(in-package "COM.INFORMATIMAGO.COMMON-LISP.CESARUM.LIST")



(defun prepend (tail &rest lists)
  (apply (function append) (append lists (list tail))))
(define-modify-macro prependf (&rest lists) prepend "Prepend the LISTS at the beginning of the PLACE.")
(define-modify-macro appendf  (&rest lists)  append "Append the LISTS at the end of the PLACE.")

(defmacro push* (&rest elements-and-place)
  `(prependf ,(car (last elements-and-place))
             (list ,@(butlast elements-and-place))))

(assert (equal (let ((i -1)
                     (v (vector nil)))
                 (push* 5 6 7 8 (aref v (incf i)))
                 (decf i)
                 (push* 1 2 3 4 (aref v (incf i)))
                 (aref v 0))
               '(1 2 3 4 5 6 7 8)))


(defun meta-list (list)
  "
Returns a list whose CARs are the CONS cells of the LIST.
LIST must be a proper list.
"
  (loop :for meta :on list :collect meta))


(defun ensure-list (object)
                    "
RETURN:         If OBJECT is a list then OBJECT, otherwise a fresh
                list containing OBJECT.
"
  (if (listp object) object (list object)))


(defun proper-list-p (object)
  "
RETURN: whether OBJECT is a proper list
NOTE:   terminates with any kind of list, dotted, circular, etc.
"
  (and (listp object)
       (loop
         :named proper
         :for current = object :then (cddr current)
         :for slow = (cons nil object) :then (cdr slow)
         :do (cond
               ((null current)       (return-from proper t))
               ((atom current)       (return-from proper nil))
               ((null (cdr current)) (return-from proper t))
               ((atom (cdr current)) (return-from proper nil))
               ((eq current slow)    (return-from proper nil)))))
  #-(and)
  (labels ((proper (current slow)
             (cond ((null current)       t)
                   ((atom current)       nil)
                   ((null (cdr current)) t)
                   ((atom (cdr current)) nil)
                   ((eq current slow)    nil)
                   (t                    (proper (cddr current) (cdr slow))))))
    (and (listp object) (proper object (cons nil object)))))


(defun dotted-list-length (dotted-list)
  "
DOTTED-LIST must be a dotted list or a proper list.
RETURN:  the number of cons cells in the list.
"
  (loop
    :for length :from 0
    :for current = dotted-list :then (cdr current)
    :until (atom current)
    :finally (return length)))


(defun circular-list-lengths (circular-list)
  "
CIRCULAR-LIST must be a circular list.
RETURN:  the length of the stem; the length of the circle.
"
  (let ((cells (make-hash-table)))
    (loop
      :for index :from 0
      :for cell = circular-list :then (cdr cell)
      :for previous = (gethash cell cells)
      :do (if previous
              (return-from circular-list-lengths
                (values previous (- index previous)))
              (setf (gethash cell cells) index)))))


(defun list-lengths (list)
  "
LIST is any kind of list: proper-list, circular-list or dotted-list.
RETURN: for a proper list, the length of the list and 0;
        for a circular list, the length of the stem, and the length of the circle;
        for a dotted list, the number of cons cells, and nil;
        for an atom, 0, and nil.
"
  (typecase list
    (cons  (loop
             :named proper
             :for current = list :then (cddr current)
             :for slow = (cons nil list) :then (cdr slow)
             :do (cond
                   ((null current)       (return-from proper (values (list-length        list) 0)))
                   ((atom current)       (return-from proper (values (dotted-list-length list) nil)))
                   ((null (cdr current)) (return-from proper (values (list-length        list) 0)))
                   ((atom (cdr current)) (return-from proper (values (dotted-list-length list) nil)))
                   ((eq current slow)    (return-from proper (circular-list-lengths list))))))
    (null  (values 0 0))
    (t     (values 0 nil)))
  #-(and)
  (labels ((proper (current slow)
             ;; (print (list 'proper current slow))
             (cond ((null current)       (values (list-length        list) 0))
                   ((atom current)       (values (dotted-list-length list) nil))
                   ((null (cdr current)) (values (list-length        list) 0))
                   ((atom (cdr current)) (values (dotted-list-length list) nil))
                   ((eq current slow)    (circular-list-lengths list))
                   (t                    (proper (cddr current) (cdr slow))))))
    (typecase list
      (cons  (proper list (cons nil list)))
      (null  (values 0 0))
      (t     (values 0 nil)))))


(defun list-elements (clist)
  "
CLIST is any kind of list: proper-list, circular-list or dotted-list.
RETURN: for a proper list:     a copy of clist, the length of the list and 0;
        for a circular list:   a list of elements in the clist, the length of the stem, and the length of the circle;
        for a dotted list:     a list of the elements in the clist, the number of cons cells, and nil;
        for an atom:           a list of the atom, 0, and nil.
"
  (cond
    ((null clist) ; a proper list
     (values '() 0 0))
    ((atom clist)
     (values (list clist) 0 nil))
    (t
     (loop
       :named scan
       :with cells = (make-hash-table)
       :with elements = '()
       :for index :from 0
       :for cell = clist :then (cdr cell)
       :for previous = (gethash cell cells)
       :do (cond
             ((null cell)             ; proper list
              (return-from scan (values (nreverse elements) index 0)))
             ((atom cell)             ; dotted list
              (push cell elements)
              (return-from scan (values (nreverse elements) index nil)))
             (previous                ; a circular list
              (return-from scan (values (nreverse elements) previous (- index previous))))
             (t                       ; in the middle
              (setf (gethash cell cells) index)
              (push (car cell) elements)))))))



(defun ensure-circular (list)
  "
If list is not a circular list, then modify it to make it circular.
RETURN: LIST
"
  (if (proper-list-p list)
      (setf (cdr (last list)) list)
      list))


(defun make-circular-list (size &key initial-element)
  "
RETURN: a new circular list of length SIZE.
POST: (circular-length (make-circular-list size)) == (values size 0 size)
"
  (let ((list (make-list size :initial-element initial-element)))
    (setf (cdr (last list)) list)
    list))


(defun circular-length (list)
  "LIST must be either a proper-list or a circular-list, not a dotted-list.
RETURN: the total length ; the length of the stem ; the length of the circle.
"
  (let ((indexes (make-hash-table)))
    (loop
      :for i :from 0
      :for current :on list
      :do (let ((index (gethash current indexes)))
            (if index
                ;; found loop
                (return (values i index (- i index)))
                (setf (gethash current indexes) i)))
      :finally (return (values i i 0)))))


(defun map-cartesian-product (fun &rest lists)
"
DO:         Call FUN with as arguments the elements of the cartesian
            products of the lists in LISTS.
RETURN:     A list of all the results of FUN.
EXAMPLE:    (map-cartesian-product (function list) '(1 2 3) '(a b c) '(11 22))
            --> ((1 a 11) (1 a 22) (1 b 11) (1 b 22) (1 c 11) (1 c 22)
                 (2 a 11) (2 a 22) (2 b 11) (2 b 22) (2 c 11) (2 c 22)
                 (3 a 11) (3 a 22) (3 b 11) (3 b 22) (3 c 11) (3 c 22))
"
  (unless (null lists)
    (if (null (cdr lists))
        (mapcar fun (car lists))
        (mapcan (lambda (element)
                  (apply (function map-cartesian-product)
                         (lambda (&rest args)
                           (apply fun element args))
                         (cdr lists)))
                (car lists)))))

(declaim (inline plist-put plist-get plist-remove memq))

(defun plist-keys (plist)
  "Returns a list of the properties in PLIST."
  (remove-duplicates (loop :for (key) :on plist :by (function cddr) :collect key)))


(defun plist-cleanup (plist)
  "Returns a plist that has the same associations than PLIST, but with
a single occurence of each key and the first value found.

EXAMPLE:        (plist-cleanup '(:a 1 :b 2 :a 11 :c 3)) --> (:b 2 :c 3 :a 1)
"
  (loop
    :with h =  (make-hash-table)
    :for (key value) :on plist :by (function cddr)
    :do (when (eq h (gethash key h h))
          (setf (gethash key h) value))
    :finally (let ((result '()))
               (maphash (lambda (key value) (push value result) (push key result)) h)
               (return result))))



(defun plist-put (plist prop value)
  "
 Change value in PLIST of PROP to VALUE.
 PLIST is a property list, which is a list of the form
 (PROP1 VALUE1 PROP2 VALUE2 ...).  PROP is a symbol and VALUE is any object.
 If PROP is already a property on the list, its value is set to VALUE,
 otherwise the new PROP VALUE pair is added.  The new plist is returned;
 use `(setq x (plist-put x prop val))' to be sure to use the new value.
 The PLIST is modified by side effects.
"
  (setf (getf plist prop) value)
  plist)


(defun plist-get (plist prop)
  "
 Extract a value from a property list.
 PLIST is a property list, which is a list of the form
 (PROP1 VALUE1 PROP2 VALUE2...).  This function returns the value
 corresponding to the given PROP, or nil if PROP is not
 one of the properties on the list.
"
  (getf plist prop))


(defun plist-remove (plist prop)
  "
DO:      (REMF PLIST PROP)
RETURN:  The modified PLIST.
"
  (remf plist prop)
  plist)


(defun memq (item list)
  "
RETURN:   (MEMBER ITEM LIST :TEST (FUNCTION EQ))
"
  (member item list :test (function eq)))



(defun transpose (tree)
  "
RETURN: A tree where all the CAR and CDR are exchanged.
"
  (if (atom tree)
      tree
      (cons (transpose (cdr tree)) (transpose (car tree)))))



(defun list-trim (bag list
                  &key (test (function eql)) (key (function identity)))
  "
RETURN: A sublist of LIST with the elements in the BAG removed from
        both ends.
"
  (do ((list (reverse list) (cdr list)))
      ((or (null list) (not (member (car list) bag :test test :key key)))
       (do ((list (nreverse list) (cdr list)))
           ((or (null list) (not (member (car list) bag :test test :key key)))
            list)))))


(defun list-trim-test ()
  (every
   (lambda (x) (equalp '(d e f) x))
   (list
    (list-trim '(a b c) '( a b c d e f a b c c c ))
    (list-trim '((a 1)(b 2)(c 3)) '( a b c d e f a b c c ) :key (function car))
    (list-trim '(:a :b :c) '( a b c d e f a b c c ) :test (function string=))
    (list-trim '(a b c) '( a b c d e f))
    (list-trim '(a b c) '( d e f a b c c c )))))


(defun maptree (fun &rest trees)
  "
DO:     Calls FUN on each non-null atom of the TREES.
PRE:    The trees in TREES must be congruent, or else the result is
        pruned like the smallest tree.
RETURN: A tree congruent to the TREES, each node being the result of
        FUN (it may be a subtree).
"
  (cond ((null trees) nil)
        ((every (function null)  trees) nil)
        ((every (function atom)  trees) (apply fun trees))
        ((every (function consp) trees)
         (cons (apply (function maptree) fun (mapcar (function car) trees))
               (apply (function maptree) fun (mapcar (function cdr) trees))))
        (t nil)))


(defun flatten (tree)
  "
RETURN: A list containing all the elements of the `tree'.
"
  (loop
    :with result = nil
    :with stack = nil
    :while (or tree stack)
    :do (cond
          ((null tree)
           (setq tree (pop stack)))
          ((atom tree)
           (push tree result)
           (setq tree (pop stack)))
          ((listp (car tree))
           (push (cdr tree) stack)
           (setq tree (car tree)))
          (t
           (push (car tree) result)
           (setq tree (cdr tree))))
    :finally (return (nreverse result))))


(defun depth (tree)
  "
RETURN:     The depth of the tree.
"
  (if (atom tree)
      0
      (1+ (apply (function max) 
                 0
                 (do ((tree tree (cdr tree))
                      (results '()))
                     ((atom tree) results)
                   (if (listp (car tree)) (push (depth (car tree)) results)))))))


(defun deepest-rec (tree)
  "
RETURN:     The deepest list in the tree.
NOTE:       Recursive algorithm.
SEE-ALSO:   deepest-iti
"
  (let ((subtree (delete-if (function atom) tree)))
    (cond
      ((null subtree)    tree)
      ((every (lambda (item) (every (function atom) item)) subtree)
       (car subtree))
      (t
       (deepest-rec (apply 'concatenate 'list subtree))))))


(defun deepest (tree)
  "
RETURN:     The deepest list in the tree.
NOTE:       Iterative algorithm.
SEE-ALSO:   deepest-rec
"
  (do* ((tree tree (apply 'concatenate 'list subtree))
        (subtree (delete-if (function atom) tree)
                 (delete-if (function atom) tree)))
       ((or (null subtree)
            (every (lambda (item) (every (function atom) item)) subtree))
        (if (null subtree) tree (car subtree)))))


(defun nsplit-list (list position &key (from-end nil))
  "
PRE:            0<=POSITION<=(LENGTH LIST)
DO:             SPLIT THE LIST IN TWO AT THE GIVEN POSITION.
                (NSPLIT-LIST (LIST 'A 'B 'C) 0) --> NIL ; (A B C)
                (NSPLIT-LIST (LIST 'A 'B 'C) 1) --> (A) ; (B C)
                (NSPLIT-LIST (LIST 'A 'B 'C) 2) --> (A B) ; (C)
                (NSPLIT-LIST (LIST 'A 'B 'C) 3) --> (A B C) ; NIL
POSITION:       POSITION OF THE SPLIT; 
                WHEN FROM-START AND 0<=POSITION<=(LENGTH LIST),
                THAT'S THE LENGTH OF THE FIRST RESULT
FROM-START:     THE DEFAULT, SPLIT COUNTING FROM THE START.
FROM-END:       WHEN SET, COUNT FROM THE END OF THE LIST.
                 (NSPLIT-LIST L P :FROM-END T)
                 === (NSPLIT-LIST L (- (LENGTH L) P))
RETURN:         THE FIRST PART ; THE LAST PART
"
  (if from-end
      (nsplit-list list (- (length list) position))
      (do* ((prev nil  rest)
            (rest list (cdr rest)))
           ((or (null rest) (zerop position))
            (progn
              (if prev
                  (setf (cdr prev) nil)
                  (setf list nil))
              (values list rest)))
        (decf position))))


(defun nsplit-list-on-indicator (list indicator)
  "
RETURN: a list of sublists of list (the conses from list are reused),
        the list is splited between items a and b for which (indicator a b).
"
  (declare (type (function (t t) t) indicator))
  (let* ((result nil)
         (sublist list)
         (current list)
         (next    (cdr current)))
    (loop :while next :do
      (if (funcall indicator (car current) (car next))
          (progn ;; split
            (setf (cdr current) nil)
            (push sublist result)
            (setq current next)
            (setq next (cdr current))
            (setq sublist current))
          (progn ;; keep
            (setq current next)
            (setq next (cdr current)))))
    (push sublist result)
    (nreverse result)))


(defun list-insert-separator (list separator)
  "
RETURN:  A list composed of all the elements in `list'
         with `separator' in-between.
EXAMPLE: (list-insert-separator '(a b (d e f)  c) 'x)
         ==> (a x b x (d e f) x c)
"
  (cond
    ((null list)       '())
    ((null (cdr list)) (list (car list)))
    (t  (do ((result '())
             (items list (cdr items)))
            ((endp items) (nreverse (cdr result)))
          (push (car items) result)
          (push separator result)))))



(defun iota (count &optional (start 0) (step 1))
  "
RETURN:   A list containing the elements 
          (start start+step ... start+(count-1)*step)
          The start and step parameters default to 0 and 1, respectively. 
          This procedure takes its name from the APL primitive.
EXAMPLE:  (iota 5) => (0 1 2 3 4)
          (iota 5 0 -0.1) => (0 -0.1 -0.2 -0.3 -0.4)
"
  (loop
    :repeat count
    :for item = start :then (+ item step)
    :collect item))



(defun make-list-of-random-numbers (length &key (modulo most-positive-fixnum))
  "
RETURN:  A list of length `length' filled with random numbers
MODULO:  The argument to RANDOM.
"
  (loop while (< 0 length)
     collect (random modulo) into result
     do (setq length (1- length))
     finally (return result)))


(defun combine (&rest args)
  "
RETURN:  (elt args 0) x (elt args 1) x ... x (elt args (1- (length args)))
         = the set of tuples built taking one item in order from each list
           in args.
EXAMPLE: (COMBINE '(WWW FTP) '(EXA) '(COM ORG))) 
           --> ((WWW EXA COM) (WWW EXA ORG) (FTP EXA COM) (FTP EXA ORG))
"
  (cond
    ((null args)        '(nil))
    ((null  (car args)) (apply (function combine) (cdr args)))
    ((consp (car args)) (mapcan (lambda (item)
                                  (apply (function combine) item (cdr args)))
                                (car args)))
    (t                  (mapcan (lambda (rest) (list (cons (car args) rest)))
                                (apply (function combine) (cdr args))))))

;; Sets:

(defun hashed-intersection (set1 set2)
  "
AUTHORS: Paul F. Dietz <dietz@dls.net>
         Thomas A. Russ <tar@sevak.isi.edu>
"
  (declare (optimize speed (safety 0) (debug 0))
           (list set1 set2))
  (let ((table (make-hash-table :size (length set2)))
        (result nil))
    (dolist (e set2) (setf (gethash e table) t))
    (dolist (e set1) (when (gethash e table)
                       (push e result)
                       (setf (gethash e table) nil)))
    result))


(defun subsets (set)
  "
RETURN: The set of all subsets of the strict SET.
"
  (loop
    :with card = (length set)
    :for indicator :from 0 :below (expt 2 card)
    :collect (loop
               :for index :from 0 :below card
               :for item :in set
               :nconc (if (logbitp index indicator) (list item) nil) 
               :into result 
               :finally (return result)) :into result
    :finally (return result)))


(defun equivalence-classes (set &key (test (function eql))
                            (key (function identity)))
  "
RETURN: The equivalence classes of SET, via KEY, modulo TEST.
"
  (loop
    :with classes = '()
    :for item :in set
    :for item-key = (funcall key item)
    :for class = (car (member item-key classes
                              :test test :key (function second)))
    :do (if class
            (push item (cddr class))
            (push (list :class item-key item ) classes))
    :finally (return (mapcar (function cddr) classes))))



;; A-lists:

(defun aget (place indicator &optional default)
  "
RETURN:   The value of the entry INDICATOR of the a-list PLACE, or DEFAULT.
"
  (let ((a (assoc indicator place)))
    (if a (cdr a) default)))


;; (DEFSETF AGET (PLACE INDICATOR &OPTIONAL DEFAULT) (VALUE)
;;   "
;; DO:       Set or add a new entry INDICATOR in the a-list at PLACE.
;; "
;;   (DECLARE (IGNORE DEFAULT))
;;   (ERROR "THIS DOES NOT WORK. DEALING WITH SETF EXPANSION IS NEEDED HERE!")
;;   (LET ((ACS (GENSYM "AC")))
;;     `(LET* ((,ACS (ASSOC ,INDICATOR ,PLACE)))
;;        (IF ,ACS
;;            (SETF (CDR ,ACS) ,VALUE)
;;            (SETF ,PLACE (ACONS ,INDICATOR ,VALUE ,PLACE)))
;;        ,VALUE)))


(define-setf-expander aget (place indicator &optional default &environment env)
  (declare (ignore default))
  (multiple-value-bind (vars vals store-vars writer-form reader-form)
      (get-setf-expansion place env)
    (let* ((vindicator (gensym "INDICATOR"))
           (vvalue     (gensym "VALUE"))
           (vstore     (first store-vars))
           (acs        (gensym "PAIR")))
      (values (list* vindicator vars)
              (list* indicator  vals)
              (list  vvalue)
              `(let* ((,acs (assoc ,vindicator ,reader-form)))
                 (if ,acs
                     (setf (cdr ,acs) ,vvalue)
                     (let ((,vstore (acons ,vindicator ,vvalue ,reader-form)))
                       ,writer-form))
                 ,vvalue)
              `(assoc ,vindicator ,reader-form)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun tree-find (object tree &key (key (function identity)) (test (function eql)))
  "
RETURN: The object in TREE that matches OBJECT (using the KEY and TEST functions.
TREE:   A sexp.
"
  (if (atom tree)
      (if (funcall test object (funcall key tree))
          tree
          nil)
      (or (tree-find object (car tree) :key key :test test)
          (tree-find object (cdr tree) :key key :test test))))


(defun tree-difference (a b &key (test (function eql)))
  "
RETURN: A tree congruent to A and B where each node is = when the
        corresponding nodes are equal (as indicated by TEST),
        or (/= a-elem b-elem) otherwise.

EXAMPLE: (tree-difference '((a b c) 1 (d e f)) '((a b c) (1) (d x f)))
         --> ((= = = . =) (/= 1 (1)) (= (/= e x) = . =) . =)
"
  (cond
    ((funcall test a b)     '=)
    ((or (atom a) (atom b)) `(/= ,a ,b))
    (t (cons (tree-difference (car a) (car b) :test test)
             (tree-difference (cdr a) (cdr b) :test test)))))


(defun tree-structure-and-leaf-difference (a b &key (test (function eql)))
  (cond
    ((and (null a) (null b)) '=)
    ((or (null a) (null b)) `(/= ,a ,b))
    ((and (atom a) (atom b))
     (if (funcall test a b)
         '=
         `(/= ,a ,b)))
    ((or (atom a) (atom b)) `(/= ,a ,b))
    (t (cons (tree-structure-and-leaf-difference (car a) (car b) :test test)
             (tree-structure-and-leaf-difference (cdr a) (cdr b) :test test)))))

(defun replace-tree (dst src)
  "
DO:     Copies the elements of the src tree into the dst tree.
        If dst is missing cons cells, structure sharing occurs.
RETURN: dst
"
  (cond ((atom dst)  src)
        ((atom src) nil)
        (t (if (or (atom (car dst)) (atom (car src)))
               (setf (car dst) (car src))
               (replace-tree (car dst) (car src)))
           (if (or (atom (cdr dst)) (atom (cdr src)))
               (setf (cdr dst) (cdr src))
               (replace-tree (cdr dst) (cdr src)))
           dst)))


;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ;; Sets


;;; (DEFUN CONS-LESSP (A B)
;;;   "PRIVATE.
;;; RETURN: a<=b
;;; "
;;;   (DO* ( (AP A (CDR AP))
;;;          (AI (CAR AP) (CAR AP))
;;;          (BP B (CDR BP))
;;;          (BI (CAR BP) (CAR BP)) )
;;;       ( (NOT (AND AI BI (EQ AI BI)))
;;;         (ANY-LESSP AI BI) )
;;;     )
;;;   ) ;;cons-lessp


;;; (DEFUN FORMATED-LESSP (A B)
;;;   "PRIVATE.
;;; RETURN: a<=b
;;; "
;;;   (STRING-LESSP (FORMAT NIL "~S" A) (FORMAT NIL "~S" B))
;;;   );;formated-lessp


;;; (DEFUN SYMBOL-LESSP (A B)
;;;   "PRIVATE.
;;; RETURN: a<=b
;;; "
;;;   (STRING-LESSP (SYMBOL-NAME A) (SYMBOL-NAME B))
;;;   );;symbol-lessp


;;; (DEFUN VECTOR-LESSP (A B)
;;;   "PRIVATE.
;;; RETURN: a<=b
;;; "
;;;   (IF (= (LENGTH A) (LENGTH B))
;;;       (LOOP FOR I FROM 0 BELOW (LENGTH A)
;;;             FOR AI = (AREF A I)
;;;             FOR BI = (AREF B I)
;;;             WHILE (EQ AI BI)
;;;             ;;do (show ai bi)
;;;             ;;finally (show ai bi) (show (or bi (not ai)))
;;;             FINALLY (RETURN (ANY-LESSP AI BI)))
;;;     (< (LENGTH A) (LENGTH B)))
;;;   );;vector-lessp


;;; (DEFUN ANY-LESSP (A B)
;;;   "PRIVATE.
;;; RETURN: a<=b
;;; "
;;;   (IF (EQ (TYPE-OF A) (TYPE-OF B))
;;;       (FUNCALL
;;;        (CDR (ASSOC
;;;              (TYPE-OF A)
;;;              '((BOOL-VECTOR . VECTOR-LESSP)
;;;                (BUFFER . FORMATED-LESSP)
;;;                (CHAR-TABLE . VECTOR-LESSP)
;;;                (COMPILED-FUNCTION . VECTOR-LESSP)
;;;                (CONS . CONS-LESSP)
;;;                (FLOAT . <=)
;;;                (FRAME . FORMATED-LESSP)
;;;                (INTEGER . <=)
;;;                (MARKER . <=)
;;;                (OVERLAY . FORMATED-LESSP)
;;;                (PROCESS . FORMATED-LESSP)
;;;                (STRING . STRING-LESSP)
;;;                (SUBR . FORMATED-LESSP)
;;;                (SYMBOL . SYMBOL-LESSP)
;;;                (VECTOR . VECTOR-LESSP)
;;;                (WINDOW . FORMATED-LESSP)
;;;                (WINDOW-CONFIGURATION . FORMATED-LESSP)
;;;                ))) A B)
;;;     (STRING-LESSP (SYMBOL-NAME (TYPE-OF A))
;;;                   (SYMBOL-NAME (TYPE-OF B))))
;;;   );;any-lessp


;;; (DEFUN LIST-TO-SET-SORTED (LIST)
;;;   "
;;; RETURN: A set, that is a list where duplicate elements from `list' are removed.
;;; NOTE:   This implementation first sorts the list, so its complexity should be
;;;         of the order of O(N*(1+log(N))) [N==(length list)]
;;;         BUT, it's still slower than list-to-set
;;; "
;;;   (IF (NULL LIST)
;;;       NIL
;;;     (LET* ((SORTED-LIST (SORT LIST 'ANY-LESSP))
;;;            (FIRST (CAR SORTED-LIST))
;;;            (REST  (CDR SORTED-LIST))
;;;            (SET NIL))
;;;       (LOOP WHILE REST DO
;;;         (IF (EQ FIRST (CAR REST))
;;;             (SETQ REST (CDR REST))
;;;           (PROGN
;;;             (PUSH FIRST SET)
;;;             (SETQ FIRST (CAR REST)
;;;                   REST  (CDR REST)))))
;;;       SET)));;list-to-set-sorted

;;; (loop for size = 10 then (* 10 size)
;;;       for l1 = (make-list-of-random-numbers size)
;;;       for l2 = (copy-seq l1)
;;;       do
;;;       (format t "~%-----------~%list-to-set        (~s)~%-----------" size)
;;;       (finish-output)
;;;       (time (setf l1 (list-to-set l1)))
;;;       (format t "~%-----------~%list-to-set-sorted (~s)~%-----------" size)
;;;       (finish-output)
;;;       (time (setf l2 (list-to-set l2))))
;; (array->list array) --> (coerce array 'list)


;;;; THE END ;;;;
