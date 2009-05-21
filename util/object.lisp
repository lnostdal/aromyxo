;;;; http://nostdal.org/ ;;;;

(in-package #:aromyxo)


(defmacro mk-meta-slot (accessor-name &key
                        (test '#'eq) (weakness :key) synchronized (type t)
                        documentation
                        default)
  (with-gensyms (slot-data)
    `(let ((,slot-data (make-hash-table :test ,test
                                        :weakness ,weakness
                                        :synchronized ,synchronized)))
       
       (defmethod (setf ,accessor-name) (new-value (object ,type))
         ,documentation
         (setf (gethash object ,slot-data) new-value))
       
       (defmethod ,accessor-name ((object ,type))
         ,documentation
         (gethash object ,slot-data ,default))

       (defmethod slot-data-of ((accessor-name (eql ',accessor-name)))
         ,slot-data))))
(export '(mk-meta-slot object slot-data-of))



(mk-meta-slot properties-of)

(defun property-of (object property-name &key (test #'eq))
  (let ((result (assoc property-name (properties-of object) :test test)))
    (if result
        (values (cdr result) t)
        (values nil nil))))
(export 'property-of)


(defun (setf property-of) (property-value object property-name &key (test #'eq))
  (let ((already-existing (assoc property-name (properties-of object) :test test)))
    (if already-existing
        (setf (cdr already-existing) property-value)
        (push (cons property-name property-value) (properties-of object)))))
(export 'property-of)



(declaim (inline mk-id-generator))
(defun mk-id-generator ()
  (cons 0 (make-lock)))
(export 'mk-id-generator)


(declaim (inline id-generator-next))
(defun id-generator-next (id-generator)
  (declare ((cons integer mutex) id-generator)
           (optimize speed))
  (with-lock-held ((cdr id-generator))
    (muffle-compiler-note 
      (incf (the integer (car id-generator))))))
(export 'id-generator-next)


(declaim (inline id-generator-next-str))
(defun id-generator-next-str (id-generator)
  (declare (cons id-generator)
           (optimize speed))
  (write-to-string (id-generator-next id-generator)
                   :pretty nil
                   :escape nil
                   :base 36))
(export 'id-generator-next-str)


(defvar *object->id*
  (make-hash-table :test #'eq :weakness :key))
(export '*object->id*)



;;(mk-meta-slot id-generator-fn-of)


(let ((lock (bt:make-recursive-lock))) ;; Got to be a bit paranoid about this stuff; it cannot be "locked from the outside".
  (defmethod generate-id-for (object)
    (declare (optimize speed))
    (bt:with-recursive-lock-held (lock)
      (let ((class (class-of object)))
        (multiple-value-bind (id-generator found-p)
            (id-generator-fn-of class)
          (if found-p
              (funcall (the function id-generator))
              (prog1 0
                (setf (id-generator-fn-of class)
                      (let ((id 0))
                        (declare (integer id))
                        (lambda ()
                          (locally (declare (sb-ext:muffle-conditions sb-ext:compiler-note))
                            (incf id)))))))))))
  (export 'generate-id-for)
  
  
  (defmethod id-of (object)
    (declare (optimize speed))
    (bt:with-recursive-lock-held (lock)
      (multiple-value-bind (id found-p) (gethash object *object->id*)
        (if found-p
            id
            (let ((id (generate-id-for object)))
              (setf (gethash object *object->id*) id)
              id)))))
  (export 'id-of))


(defun id-str-of (object)
  "Convert the ID of OBJECT to a string and try to make it as short (number of characters) as possible."
  (declare (optimize speed))
  (write-to-string (id-of object)
                   :pretty nil
                   :base 36))
(export 'id-str-of)
