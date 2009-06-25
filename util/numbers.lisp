;;;; http://nostdal.org/ ;;;;

(in-package #:aromyxo)


(defun smallest (a &rest args)
  (let ((till-now a))
    (dolist (item args)
      (if (< item till-now)
          (setf till-now item)))
    till-now))
(export 'smallest)


(defun biggest (a &rest args)
  (let ((till-now a))
    (dolist (item args)
      (if (> item till-now)
          (setf till-now item)))
    till-now))
(export 'biggest)


;; NOTE: For every float dividable by 256 this'll return a float with a 0 fraction.
(defun urandom (limit)
  (let ((result
         (with-open-file (fs "/dev/urandom" :direction :input :element-type '(unsigned-byte 8))
           (let* ((num (/ limit 256))
                  (ceil (ceiling num)))
             (* (loop :repeat ceil :summing (read-byte fs))
                (/ limit (* ceil 256)))))))
    (if (integerp limit)
        (values (truncate result))
        result)))
(export 'urandom)
