;;;; -*- mode:lisp;coding:utf-8 -*-
;;;;**************************************************************************
;;;;FILE:               com.informatimago.tools.thread.asd
;;;;LANGUAGE:           Common-Lisp
;;;;SYSTEM:             Common-Lisp
;;;;USER-INTERFACE:     NONE
;;;;DESCRIPTION
;;;;    
;;;;    ASD file to load the com.informatimago.tools.thread package.
;;;;    
;;;;AUTHORS
;;;;    <PJB> Pascal J. Bourguignon <pjb@informatimago.com>
;;;;MODIFICATIONS
;;;;    2015-02-23 <PJB> Created this .asd file.
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
;;;;    along with this program.  If not, see http://www.gnu.org/licenses/
;;;;**************************************************************************
                 
(asdf:defsystem "com.informatimago.tools.thread"
    ;; system attributes:
    :description "Informatimago Common Lisp Thread Tools"
    :long-description  "

Interactive commands to manipulate threads.

"
    :author     "Pascal J. Bourguignon <pjb@informatimago.com>"
    :maintainer "Pascal J. Bourguignon <pjb@informatimago.com>"
    :licence "AGPL3"
    ;; component attributes:
    :version "1.0.2"
    :properties ((#:author-email                   . "pjb@informatimago.com")
                 (#:date                           . "Winter 2015")
                 ((#:albert #:output-dir)          . "/tmp/documentation/com.informatimago.common-lisp.thread/")
                 ((#:albert #:formats)             . ("docbook"))
                 ((#:albert #:docbook #:template)  . "book")
                 ((#:albert #:docbook #:bgcolor)   . "white")
                 ((#:albert #:docbook #:textcolor) . "black"))
    #+asdf-unicode :encoding #+asdf-unicode :utf-8
    :depends-on ("bordeaux-threads")
    :components ((:file "thread" :depends-on ())))

;;;; THE END ;;;;
