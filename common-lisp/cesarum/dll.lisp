;;;; -*- coding:utf-8 -*-
;;;;****************************************************************************
;;;;FILE:               dll.lisp
;;;;LANGUAGE:           Common-Lisp
;;;;SYSTEM:             Common-Lisp
;;;;USER-INTERFACE:     NONE
;;;;DESCRIPTION
;;;;    
;;;;    A doubly-linked list.
;;;;    
;;;;AUTHORS
;;;;    <PJB> Pascal J. Bourguignon <pjb@informatimago.com>
;;;;MODIFICATIONS
;;;;    2011-06-22 <PJB> Corrected a bug in DLL.
;;;;    2005-04-28 <PJB> Clean-up.
;;;;    2004-03-01 <PJB> Created.
;;;;BUGS
;;;;LEGAL
;;;;    AGPL3
;;;;    
;;;;    Copyright Pascal J. Bourguignon 2004 - 2016
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
(defpackage "COM.INFORMATIMAGO.COMMON-LISP.CESARUM.DLL"
  (:use "COMMON-LISP")
  (:export "DLL-DELETE" "DLL-INSERT" "DLL-NODE-POSITION" "DLL-NODE-NTH"
           "DLL-NODE-ITEM" "DLL-NODE-PREVIOUS" "DLL-NODE-NEXT" "DLL-NODE" "DLL-LAST"
           "DLL-FIRST" "DLL-POSITION" "DLL-NTH" "DLL-CONTENTS" "DLL-NCONC" "DLL-APPEND"
           "DLL-COPY" "DLL-EQUAL" "DLL-LENGTH" "DLL-EMPTY-P" "DLL-LAST-NODE"
           "DLL-FIRST-NODE" "DLL")
  (:documentation
   "

This module exports a double-linked list type.  This is a structure
optimized for insertions and deletions in any place, each node keeping
a pointer to both the previous and the next node.  The stub keeps a
pointer to the head of the list, and the list is circularly closed
\(the tail points to the head).


License:

    AGPL3
    
    Copyright Pascal J. Bourguignon 2001 - 2012
    
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
(in-package "COM.INFORMATIMAGO.COMMON-LISP.CESARUM.DLL")



(defstruct (dll (:conc-name %dll-))
  "A Doubly-Linked List.
A DLL keeps a reference to the first node and to the last node."
  (first    nil)
  (last     nil))


(defstruct dll-node
  "A node in a Doubly-Linked List.
Each node is linked to the previous and to the next node in the list,
and keeps a reference to its item."
  (previous nil)
  (next     nil)
  (item     nil))

(setf (documentation 'dll-node-previous 'function)
      "The previous node."
      (documentation 'dll-node-next 'function)
      "The next node."
      (documentation 'dll-node-item 'function)
      "The item of the node.")

(defun dll (&rest list)
  "
RETURN: A new DLL containing the elements passed as arguments.
"
  (loop
     :with dlist = (make-dll)
     :for element :in list
     :for last-node = (dll-insert dlist nil element)
     :then (dll-insert dlist last-node element)
     :finally (return dlist)))


(defun dll-first-node (dlist)
  "
RETURN: The first node of the DLIST.
"
  (%dll-first dlist))


(defun dll-last-node  (dlist)
    "
RETURN: The last node of the DLIST.
"
    (%dll-last dlist))


(defun dll-empty-p (dlist)
  "
RETURN: Whether the DLL DLIST is empty. ie. (zerop (dll-length dlist))
"
  (null (%dll-first dlist)))


(defun dll-length (dlist)
  "
RETURN: The number of elements in the DLL DLIST.
"
  (do ((len 0 (1+ len))
       (current (%dll-last dlist) (dll-node-previous current)))
      ((null current) len)))


(defun dll-nth (index dlist)
  "
RETURN: The INDEXth element in the DLL DLIST.
"
  (do ((i 0 (1+ i))
       (current (%dll-first dlist) (dll-node-next current)))
      ((or (null current) (= i index))
       (when current (dll-node-item current)))))


(defun dll-position (item dlist &key (test (function eql)))
    "
RETURN: The INDEX of the first element in the DLL DLIST that satisfies
        the test (TEST element ITEM).
"
  (do ((i 0 (1+ i))
       (current (%dll-first dlist) (dll-node-next current)))
      ((or (null current) (funcall test (dll-node-item current) item))
       (when current i))))


(defun dll-node-position (node dlist &key (test (function eql)))
  "
RETURN: The INDEX of the first node in the DLL DLIST that satisfies
        the test (TEST element NODE).
"
  (do ((i 0 (1+ i))
       (current (%dll-first dlist) (dll-node-next current)))
      ((or (null current) (funcall test current node))
       (when current i))))


(defun dll-equal (&rest dlls)
  "
RETURN: Whether all the DLLS contain the same elements in the same order.
"
  (or
   (null dlls)
   (null (cdr dlls))
   (and
    (let ((left (first dlls))
          (right (second dlls)))
      (and
       (equal (dll-node-item (%dll-first left))
              (dll-node-item (%dll-first right)))
       (equal (dll-node-item (%dll-last left))
              (dll-node-item (%dll-last right)))
       (do ((lnodes (dll-node-next (%dll-first left))
                    (dll-node-next lnodes))
            (rnodes (dll-node-next (%dll-first right))
                    (dll-node-next rnodes)))
           ((or (eq lnodes (%dll-last left))
                (eq rnodes (%dll-last right))
                (not (equal (dll-node-item lnodes) (dll-node-item rnodes))))
            (and (eq lnodes (%dll-last left))
                 (eq rnodes (%dll-last right)))))
       (dll-equal (cdr dlls)))))))


(defun dll-copy (dlist)
  "
RETURN: A copy of the DLL DLIST.
"
  (do ((new-dll (make-dll))
       (src (%dll-first dlist) (dll-node-next src))
       (dst nil))
      ((null src) new-dll)
    (setf dst (dll-insert new-dll dst (dll-node-item src)))))


(defun dll-append (&rest dlls)
  "
DO:     Appends the elements in all the DLLS into a single dll.
        The DLLs are not modified.
RETURN: A new dll with all the elements in DLLS.
"
  (if (null dlls)
      (make-dll)
      (apply (function dll-nconc) (mapcar (function dll-copy) dlls))))


(defun dll-nconc (first-dll &rest dlls)
  "
PRE:   No dll appears twice in (CONS FIRST-DLL DLLS).
DO:    Extract the nodes from all but the FIRST-DLL,
       and append them all to that FIRST-DLL.
POST:  ∀l∈dlls, (dll-empty-p l)
       (dll-length first-dll) =   Σ  (dll-length old l)
                                l∈dlls
"
  (if (null dlls)
      first-dll
      (dolist (dll (rest dlls) first-dll)
        (let ((first (%dll-first dll)))
          (unless (null first)
            (setf (dll-node-previous first) (%dll-last first-dll)
                  (dll-node-next (%dll-last first-dll)) first
                  (%dll-last first-dll) (%dll-last dll)
                  (%dll-first dll) nil
                  (%dll-last dll) nil))))))



(defun dll-contents (dlist)
  "
RETURN:  A new list containing the items of the dll.
"
  (do ((current (%dll-last dlist) (dll-node-previous current))
       (result ()))
      ((null current) result)
    (push (dll-node-item current) result)))


(defun dll-first (dlist)
  "
RETURN: The first element in the DLL DLIST, or NIL if it's empty.
"
  (unless (dll-empty-p  dlist)  (dll-node-item (%dll-first dlist))))


(defun dll-last  (dlist)
    "
RETURN: The last element in the DLL DLIST, or NIL if it's empty.
"
  (unless (dll-empty-p  dlist)  (dll-node-item (%dll-last  dlist))))


(defun dll-node-nth (index dlist)
  "
RETURN: The INDEXth node of the DLL DLIST, or NIL if it's empty.
"
  (do ((i 0 (1+ i))
       (current (%dll-first dlist) (dll-node-next current)))
      ((or (null current) (= i index)) current)))
      




(defun dll-insert (dlist node item)
  "
DO:     Insert a new node after NODE, or before first position when (NULL NODE).
RETURN: The new node.
"
  (let ((new-node nil))
    (cond
      ((dll-empty-p dlist) ;; first item
       (setf new-node (make-dll-node :item item))
       (setf (%dll-first dlist) new-node
             (%dll-last dlist) (%dll-first dlist)))
      ((null node) ;; insert before first
       (setf new-node (make-dll-node :previous nil
                                     :next     (dll-first-node dlist)
                                     :item     item))
       (setf (dll-node-previous (%dll-first dlist)) new-node
             (%dll-first dlist) new-node))
      ((not (dll-node-position node dlist))
       (error "Node not in doubly-linked list."))
      (t
       (setf new-node (make-dll-node :previous node
                                     :next     (dll-node-next node)
                                     :item     item))
       (if (dll-node-next node)
           (setf (dll-node-previous (dll-node-next node)) new-node)
           (setf (%dll-last dlist) new-node))
       (setf (dll-node-next node) new-node)))
    new-node))


(defun dll-extract-node (dlist node)
  (if (eq (dll-first-node dlist) node)
      (setf (%dll-first dlist) (dll-node-next node))
      (setf (dll-node-next (dll-node-previous node)) (dll-node-next node)))
  (if (eq (dll-last-node dlist) node)
      (setf (%dll-last dlist) (dll-node-previous node))
      (setf (dll-node-previous (dll-node-next node)) (dll-node-previous node)))
  dlist)


(defun dll-delete (node dlist)
  "
DO:     Delete the NODE from the DLL DLIST.
RETURN: DLIST
"
  (unless (or (null node) (dll-empty-p dlist)
              (not (dll-node-position node dlist))) ;; Note O(N)!
    (dll-extract-node dlist node))
  dlist)


(defun dll-delete-nth (index dlist)
    "
DO:     Delete the INDEXth element of the DLL DLIST.
RETURN: DLIST
"
  (dll-extract-node dlist (dll-node-nth index dlist)))


;;;; THE END ;;;;
