;;;; -*- mode:lisp;coding:utf-8 -*-
;;;;**************************************************************************
;;;;FILE:               dictionary.lisp
;;;;LANGUAGE:           Common-Lisp
;;;;SYSTEM:             Common-Lisp
;;;;USER-INTERFACE:     NONE
;;;;DESCRIPTION
;;;;    
;;;;    See defpackage documentation string.
;;;;    
;;;;AUTHORS
;;;;    <PJB> Pascal J. Bourguignon <pjb@informatimago.com>
;;;;MODIFICATIONS
;;;;    2010-08-16 <PJB> Created
;;;;BUGS
;;;;LEGAL
;;;;    AGPL3
;;;;    
;;;;    Copyright Pascal J. Bourguignon 2010 - 2015
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

(defpackage "COM.INFORMATIMAGO.COMMON-LISP.CESARUM.DICTIONARY"
  (:use "COMMON-LISP")
  (:export "DICTIONARY" 
           "MAKE-DICTIONARY" "A-LIST" "P-LIST" "ADAPTATING-DICTIONARY" ; "HASH-TABLE"
           "DICTIONARY-SET" "DICTIONARY-GET" "DICTIONARY-DELETE"
           "DICTIONARY-MAP" "DICTIONARY-COUNT"
           ;; low-level:
           "DICTIONARY-CLASS" "DICTIONARY-TEST" "DICTIONARY-DATA"
           "ADAPTATING-DICTIONARY-LIMIT")
  (:documentation "

Implements a DICTIONARY API over HASH-TABLE, P-LIST, A-LIST and an
ADAPTATIVE-DICTIONARY class that automatically switch between
HASH-TABLE and A-LIST depending on the number of entries.


License:

    AGPL3
    
    Copyright Pascal J. Bourguignon 2010 - 2015
    
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

(in-package "COM.INFORMATIMAGO.COMMON-LISP.CESARUM.DICTIONARY")


(defgeneric dictionary-test (dictionary)
  (:documentation "RETURN: The test function of the dictionary."))

(defclass dictionary-class ()
  ((test :initarg :test
         :initform (function eql)
         :reader dictionary-test))
  (:documentation "An abstract Dictionary clas."))

(deftype dictionary () '(or hash-table dictionary-class))

(defgeneric make-dictionary   (type &key test size contents)
  (:documentation "
TYPE:     Name of a class implementing the dictionary protocol.
TEST:     Restricted to EQL, EQUAL or EQUALP when type is HASH-TABLE.
CONTENTS: A p-list containing the initial key value pairs.
"))


(defgeneric dictionary-set    (dictionary key value)
  (:documentation "Enter or update the VALUE associated with the KEY into the DICTIONARY."))

(defgeneric dictionary-get    (dictionary key &optional default)
  (:documentation "RETURN: The value associated with the KEY in the DICTIONARY."))

(defgeneric dictionary-delete (dictionary key)
  (:documentation "Remove the KEY from the DICTIONARY."))

(defgeneric dictionary-map    (fun dictionary)
  (:documentation "Call the function FUN on each KEY VALUE association in the DICTIONARY."))

(defgeneric dictionary-count  (dictionary)
  (:documentation "RETURN: the number of associations in the DICTIONARY."))

(defsetf dictionary-get (dictionary key &optional default) (new-value)
  (declare (ignorable default))
  `(dictionary-set ,dictionary ,key ,new-value))


;; hash-table

(defmethod make-dictionary ((type (eql 'hash-table)) &key (test (function eql)) (size 8) (contents '()))
  (declare (ignore type))
  (let ((dictionary (make-hash-table :test test :size size)))
    (loop :for (key value) :on contents :by (function cddr) :do
       (dictionary-set dictionary key value))
    dictionary))

(defmethod dictionary-test   ((dictionary hash-table))
  (hash-table-test dictionary))

(defmethod dictionary-set    ((dictionary hash-table) key value)
  (setf (gethash key dictionary) value))

(defmethod dictionary-get    ((dictionary hash-table) key &optional default)
  (gethash key dictionary default))

(defmethod dictionary-delete ((dictionary hash-table) key)
  (remhash key dictionary))

(defmethod dictionary-map    (fun (dictionary hash-table))
  (let ((results '()))
    (maphash (lambda (key value) (push (funcall fun key value) results)) dictionary)
    (nreverse results)))

(defmethod dictionary-count  ((dictionary hash-table))
  (hash-table-count dictionary))


(defgeneric dictionary-data (dictionary)
  (:documentation "The data in the dictionary."))

(defclass a-list (dictionary-class)
  ((data :initarg :data
         :initform '()
         :accessor dictionary-data))
  (:documentation "A dictionary implemented as an A-list."))


(defmethod make-dictionary ((type (eql 'a-list)) &key (test (function eql)) (size 8) (contents '()))
  (declare (ignore type size))
  (let ((dictionary (make-instance 'a-list :test test)))
    (loop :for (key value) :on contents :by (function cddr) :do
       (dictionary-set dictionary key value))
    dictionary))

(defmethod dictionary-set    ((dictionary a-list) key value)
  (let ((pair (assoc key (dictionary-data dictionary)
                     :test (dictionary-test dictionary))))
    (if pair
        (setf (cdr pair) value)
        (setf (dictionary-data dictionary) (acons key value (dictionary-data dictionary))))
    value))

(defmethod dictionary-get    ((dictionary a-list) key &optional default)
  (let ((pair (assoc key (dictionary-data dictionary)
                     :test (dictionary-test dictionary))))
    (if pair
        (values (cdr pair) t)
        (values default nil))))

(defmethod dictionary-delete ((dictionary a-list) key)
  (let ((pair (assoc key (dictionary-data dictionary)
                     :test (dictionary-test dictionary))))
    (setf (dictionary-data dictionary) (delete key (dictionary-data dictionary)
                                               :test (dictionary-test dictionary)
                                               :key (function car)))
    pair))

(defmethod dictionary-map    (fun (dictionary a-list))
  (mapcar (lambda (pair) (funcall fun (car pair) (cdr pair)))
          (dictionary-data dictionary)))

(defmethod dictionary-count  ((dictionary a-list))
  (length (dictionary-data dictionary)))





(defclass p-list (dictionary-class)
  ((data :initarg :data
         :initform '()
         :accessor dictionary-data))
  (:documentation "A dictionary implemented as a P-list."))

;; Note: these are not lisp p-list, which are restricted to symbol keys and therefore eql test.

(defmethod make-dictionary ((type (eql 'p-list)) &key (test (function eql)) (size 8) (contents '()))
  (declare (ignore type size))
   (make-instance 'p-list :test test :data (copy-list contents)))

(defmethod dictionary-set    ((dictionary p-list) key value)
  (loop
     :with test = (dictionary-test dictionary)
     :for cell :on (dictionary-data dictionary) :by (function cddr)
     :when (funcall test (first cell) key)
     :do (return-from dictionary-set (setf (second cell) value))
     :finally (setf (dictionary-data dictionary) (list* key value  (dictionary-data dictionary)))
              (return-from dictionary-set value)))

(defmethod dictionary-get    ((dictionary p-list) key &optional default)
    (loop
     :with test = (dictionary-test dictionary)
     :for cell :on (dictionary-data dictionary) :by (function cddr)
     :when (funcall test (first cell) key)
     :do (return-from dictionary-get (values (second cell) t))
     :finally (return-from dictionary-get (values default nil))))

(defmethod dictionary-delete ((dictionary p-list) key)
  (let ((test  (dictionary-test dictionary))
        (data  (dictionary-data dictionary)))
    (when data
      (when (funcall test (first data) key)
        (setf (dictionary-data dictionary) (cddr (dictionary-data dictionary)))
        (return-from dictionary-delete (cons (first data) (second data))))
      (loop
         :for cell :on  data :by (function cddr)
         :for k = (third cell)
         :while (cddr data)
         :when (funcall test key k)
         :do (let ((v (fourth cell)))
               (setf (cddr cell) (cddddr cell))
               (return-from dictionary-delete (cons k v))))
      nil)))

(defmethod dictionary-map    (fun (dictionary p-list))
  (loop
     :for (key value) :on (dictionary-data dictionary) :by (function cddr)
     :collect (funcall fun key value)))

(defmethod dictionary-count  ((dictionary p-list))
  (truncate (length (dictionary-data dictionary)) 2))



(defgeneric adaptating-dictionary-limit (dictionary)
  (:documentation
   "The number of elements over which the adaptating DICTIONARY
switches to hash-tables, and below which it switches to A-lists."))


(defclass adaptating-dictionary (dictionary-class)
  ((dictionary :initarg :dictionary)
   (limit      :initarg :limit
               :initform 10
               :type (integer 0)
               :accessor adaptating-dictionary-limit))
  (:documentation "A dictionary that changes between an A-list implementation and a hash-table implementation depending on the number of entries."))

(defgeneric adaptating-dictionary-adapt (dictionary))
(defmethod adaptating-dictionary-adapt ((dictionary adaptating-dictionary))
  (flet ((copy-dictionary (dictionary type)
           (make-dictionary type
                            :test (dictionary-test dictionary)
                            :size (dictionary-count dictionary)
                            :contents (let ((contents '()))
                                        (dictionary-map (lambda (key value)
                                                          (push value contents)
                                                          (push key contents))
                                                        dictionary)
                                        contents))))
    (with-slots (dictionary limit)  dictionary
      (cond
        ((and (typep dictionary 'hash-table)
              (< (dictionary-count dictionary) limit))
         (setf dictionary (copy-dictionary dictionary 'a-list)))
        ((and (not (typep dictionary 'hash-table))
              (<= limit (dictionary-count dictionary)))
         (setf dictionary (copy-dictionary dictionary 'hash-table)))))))

(defmethod make-dictionary ((type (eql 'adaptating-dictionary)) &key (test (function eql)) (size 8) (contents '()))
  (declare (ignore type))
  ;; TODO: determine the limit automatically.
  (let ((limit 10))
    (make-instance 'adaptating-dictionary
        :limit limit
        :dictionary (make-dictionary (if (< size limit)
                                         'a-list
                                         'hash-table)
                                     :test test :size size :contents contents))))

(defmethod dictionary-set    ((dictionary adaptating-dictionary) key value)
  (prog1 (with-slots (dictionary) dictionary
           (dictionary-set dictionary key value))
    (adaptating-dictionary-adapt dictionary)))

(defmethod dictionary-get    ((dictionary adaptating-dictionary) key &optional default)
  (multiple-value-prog1 (with-slots (dictionary) dictionary
                          (dictionary-get dictionary key default))
    (adaptating-dictionary-adapt dictionary)))

(defmethod dictionary-delete ((dictionary adaptating-dictionary) key)
  (prog1 (with-slots (dictionary) dictionary
           (dictionary-delete dictionary key))
    (adaptating-dictionary-adapt dictionary)))

(defmethod dictionary-map    (fun (dictionary adaptating-dictionary))
  (with-slots (dictionary) dictionary
    (dictionary-map fun dictionary)))

(defmethod dictionary-count  ((dictionary adaptating-dictionary))
  (with-slots (dictionary) dictionary
    (dictionary-count dictionary)))




;;;; THE END ;;;;
