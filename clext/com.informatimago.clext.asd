;;;; -*- mode:lisp;coding:utf-8 -*-
;;;;**************************************************************************
;;;;FILE:               com.informatimago.clext.asd
;;;;LANGUAGE:           Common-Lisp
;;;;SYSTEM:             Common-Lisp
;;;;USER-INTERFACE:     NONE
;;;;DESCRIPTION
;;;;
;;;;    ASD file to load the com.informatimago.clext library.
;;;;
;;;;AUTHORS
;;;;    <PJB> Pascal J. Bourguignon <pjb@informatimago.com>
;;;;MODIFICATIONS
;;;;    2010-10-31 <PJB> Created this .asd file.
;;;;BUGS
;;;;LEGAL
;;;;    AGPL3
;;;;
;;;;    Copyright Pascal J. Bourguignon 2010 - 2016
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
;;;;    along with this program.  If not, see http://www.gnu.org/licenses/
;;;;**************************************************************************

(asdf:defsystem "com.informatimago.clext"
  ;; system attributes:
  :description "Informatimago Common Lisp Extensions"
  :long-description "

This system provides Common-Lisp packages that are mostly portable,
but that use some extensions, packages out of the Common-Lisp
specifications, like GRAY or other portability libraries.

"
  :author     "Pascal J. Bourguignon <pjb@informatimago.com>"
  :maintainer "Pascal J. Bourguignon <pjb@informatimago.com>"
  :licence "AGPL3"
  ;; component attributes:
  :version "1.6.0"
  :properties ((#:author-email                   . "pjb@informatimago.com")
               (#:date                           . "Spring 2017")
               ((#:albert #:output-dir)          . "/tmp/documentation/com.informatimago.clext/")
               ((#:albert #:formats)             . ("docbook"))
               ((#:albert #:docbook #:template)  . "book")
               ((#:albert #:docbook #:bgcolor)   . "white")
               ((#:albert #:docbook #:textcolor) . "black"))
  :depends-on ("com.informatimago.clext.association"
               "com.informatimago.clext.character-sets"
               #+(or ccl clisp sbcl cmu) "com.informatimago.clext.closer-weak"
               #+(or ccl clisp sbcl cmu) "com.informatimago.clext.pipe"
               "com.informatimago.clext.queue"
               "com.informatimago.clext.filter-stream"
               "com.informatimago.clext.redirecting-stream"
               "com.informatimago.clext.shell")
  :components ()
  #+adsf3 :in-order-to
  #+adsf3 ((asdf:test-op (asdf:test-op "com.informatimago.clext.test")
                         (asdf:test-op "com.informatimago.clext.association.test")
                         (asdf:test-op "com.informatimago.clext.pipe.test")
                         (asdf:test-op "com.informatimago.clext.queue.test")))
  #+asdf-unicode :encoding #+asdf-unicode :utf-8)


;;;; THE END ;;;;
