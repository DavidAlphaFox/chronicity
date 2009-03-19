(cl:in-package #:chronicity)

;;; Some constants

(defconstant +sec-seconds+ 1)
(defconstant +minute-seconds+ 60)
(defconstant +hour-seconds+ (* 60 60))
(defconstant +day-seconds+ (* 24 60 60))
(defconstant +weekend-seconds+ (* 2 24 60 60))
(defconstant +week-seconds+ (* 7 24 60 60))
(defconstant +fortnight-seconds+ (* 14 24 60 60))
(defconstant +month-seconds+ (* 30 24 60 60))
(defconstant +year-seconds+ (* 365 24 60 60))
(defconstant +year-months+ 12)

;;; Enable CL-INTERPOL's special reader syntax

#.(cl-interpol:enable-interpol-syntax)

(defvar *context* :future)
(defvar *now*)
(defvar *endian-preference* :little)
(defvar *guess* :start)
(defvar *ambiguous-time-range* 6)

(defun parse (text &key
              ((:context *context*) *context*)
              ((:now *now*) (or *now* (now)))
              (guess *guess*)
              ((:ambiguous-time-range *ambiguous-time-range*) *ambiguous-time-range*)
              (tokens-to-span t)
              &aux tokens)
  "The API."
  (setf text (pre-normalize text))
  (setf tokens (tokenize text))
  (loop
     for type in (list 'repeater 'grabber 'pointer 'scalar 'ordinal 'separator) ; 'timezone
     do (scan-tokens type tokens))
  (if tokens-to-span
      (let ((span (tokens-to-span tokens)))
        (when span
          (ecase guess
            (:start (span-start span))
            (:end (if (span-end-included-p span)
                      (span-end span)
                      (datetime-decr (span-end span) :sec)))
            (:middle (universal-to-datetime
                      (truncate (+ (datetime-to-universal (span-start span))
                                   (datetime-to-universal (span-end span)))
                                2)))
            ((nil) span))))
      tokens))

(defun pre-normalize (text)
  (setf text (string-downcase text))
  ;; FIXME: (setf text (numerize text))
  (rr-all-f text #?/['\"\.]/ "")
  (rr-all-f text #?/([\/\-\,\@])/ " \\1 ")
  (rr-all-f text #?/\btoday\b/ "this day")
  (rr-all-f text #?/\btomm?orr?ow\b/ "next day")
  (rr-all-f text #?/\byesterday\b/ "last day")
  (rr-all-f text #?/\bnoon\b/ "12:00")
  (rr-all-f text #?/\bmidnight\b/ "24:00")
  (rr-all-f text #?/\bbefor now\b/  "past")
  (rr-all-f text #?/\bnow\b/ "this second")
  (rr-all-f text "\\b(ago|before)\\b" "past")
  (rr-all-f text #?/\bthi past\b/ "last")
  (rr-all-f text #?/\bthi last\b/ "last")
  (rr-all-f text "\\b(?:in|during) the (morning)\\b" "\\1")
  (rr-all-f text "\\b(?:in the|during the|at) (afternoon|evening|night)\\b" "\\1")
  (rr-all-f text #?/\btonight\b/ "this night")
  (rr-all-f text "(\\d)([ap]m|oclock)\\b" "\\1 \\2")
  (rr-all-f text "\\b(hence|after|from)\\b" "future")
  ;; TODO: (setf text (numericize-ordinals text)) 
  text)

(defun tokenize (text)
  (mapcar #'create-token
          (cl-ppcre:split #?r"\s+" text)))

(defclass token ()
  ((word :initarg :word
         :reader token-word)
   (tags :initarg :tags
         :initform nil
         :accessor token-tags)))

(defmethod print-object ((x token) stream)
  (print-unreadable-object (x stream :type t :identity t)
    (format stream "~A~@[ [~{~A~^, ~}]~]"
            (token-word x)
            (mapcar #'type-of (token-tags x)))))

(defun create-token (word &rest tags)
  (make-instance 'token
                 :word word
                 :tags tags))

(defclass tag ()
  ((type :initarg :type
         :reader tag-type)
   (now :initarg :now
        :accessor tag-now
        :initform nil)))

(defun create-tag (class type &key now)
  (make-instance class :type type :now now))

(defmethod tag (tag token)
  (push tag (token-tags token)))

(defmethod untag ((tag tag) (token token))
  (setf (token-tags token) (remove tag (token-tags token))))

(defmethod untag ((x class) (token token))
  (untag (class-name x) token))

(defmethod untag ((x symbol) token)
  (setf (token-tags token) (remove-if #'(lambda (tag)
                                          (typep tag x))
                                      (token-tags token))))

(defun token-has-tag-p (token tag-name)
  (some #'(lambda (tag) (typep tag tag-name)) (token-tags token)))

(defun find-tag (tag-name token)
  (find-if #'(lambda (x)
               (typep x tag-name))
           (token-tags token)))

(defun token-tag-type (tag-name token)
  (tag-type (find-tag tag-name token)))

;;; Generic token scanner

(defgeneric scan-tokens (tag tokens)
  (:documentation "Scan the list of TOKENS and tag the appropriately."))

;;; Data

(defparameter *months*
  (list :JANUARY
        :FEBRUARY
        :MARCH
        :APRIL
        :MAY
        :JUNE
        :JULY
        :AUGUST
        :SEPTEMBER
        :OCTOBER
        :NOVEMBER
        :DECEMBER))

(defun month-name (index)
  (elt *months* (1- index)))

(defun month-index (name)
  (1+ (position name *months*)))

(defparameter *days-of-week*
  (list :SUNDAY
        :MONDAY
        :TUESDAY
        :WEDNESDAY
        :THURSDAY
        :FRIDAY
        :SATURDAY))

(defun dow-index (name)
  (position name *days-of-week*))

(defun dow-name (index)
  (elt *days-of-week* index))

;;; Disable CL-INTERPOL's special reader syntax

#.(cl-interpol:disable-interpol-syntax)





