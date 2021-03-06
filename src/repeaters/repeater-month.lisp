;;; -*- Mode: LISP; Syntax: COMMON-LISP; Package: CL-USER; Base: 10 -*-
;;; repeater-month.lisp

;;; See the LICENSE file for licensing information.

(cl:in-package #:chronicity)

(defclass repeater-month (repeater)
  ((current :initform nil)))

(defmethod r-next ((repeater repeater-month) pointer)
  (let ((offset (if (eql pointer :future) 1 -1)))
    (with-slots (current now)
        repeater
      (if (not current)
          (setf current (start-of-month (datetime-incr now :month offset)))
          (setf current (start-of-month (datetime-incr current :month offset))))
      (make-span current (datetime-incr (copy-date current) :month)))))

(defmethod r-this ((repeater repeater-month) pointer)
  (with-slots (now)
      repeater
    (ecase pointer
      (:future (make-span now (datetime-incr (copy-date now :day 1) :month)))
      (:past (make-span (copy-date now :day 1) now))
      (:none (make-span (copy-date now :day 1)
                        (datetime-incr (copy-date now :day 1) :month)
                        nil
                        now)))))

(defmethod r-offset ((repeater repeater-month) span amount pointer)
  (let ((offset (* (if (eql pointer :future) 1 -1) amount)))
    (span+ span offset :month)))

(defmethod r-width ((repeater repeater-month))
  +month-seconds+)
