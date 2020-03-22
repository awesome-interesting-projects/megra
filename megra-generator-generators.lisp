(in-package :megra)

(defun string->cycle-list (str)
  "parse a cycle from a string to a list of events and durations"
  (let* ((split
           (cl-ppcre:split "\\s+"
           (cl-ppcre:regex-replace-all "\\]"
           (cl-ppcre:regex-replace-all "\\["
           (cl-ppcre:regex-replace-all "\\~" str "silence") "( ") " )")))
         (cycle (list))
         (stack (list))
         (stack-mode nil))
    (loop for token in split 
          do (cond ((string= token "(")
		    (setf stack-mode t))
		   ((string= token ")")
		    (setf stack-mode nil)
		    (setf cycle (nconc cycle (list stack)))
		    (setf stack (list)))
		   ((ignore-errors (parse-integer token)) (setf cycle (nconc cycle (list (parse-integer token)))))
		   (t (if stack-mode
		          (setf stack (nconc stack (list (let ((f-par (cl-ppcre:split ":" token)))  
							   (eval (read-from-string (format nil "(~{~a~^ ~})" f-par)))))))
		          (setf cycle (nconc cycle (list (let ((f-par (cl-ppcre:split ":" token)))  
							   (eval (read-from-string (format nil "(~{~a~^ ~})" f-par)))))))))))
    cycle))

(defun parse-cycle (events &key (dur *global-default-duration*) (rep 0) (max-rep 4))
  "parse a list of events and durations to a list of rules and event mappings"
  (let ((count 1)
	(rules (list))
	(event-mapping (make-hash-table :test #'equal))
	(real-events (if (typep events 'string)
			 (string->cycle-list events)
			 events)))
    (loop for (a b) on real-events while b
          do (cond
	       ((and (or (typep a 'event) (typep a 'list)) (or (typep b 'event) (typep b 'list)))
	        (setf (gethash count event-mapping) (if (typep a 'list) a (list a)))
	        (setf (gethash (+ count 1) event-mapping) (if (typep b 'list) b (list b)))
                (if (> rep 0)
		    (if (< (random 100) rep)
                        (progn
                          (let ((new-rule (list (list count) count 0.5)))
	                    (alexandria::nconcf rules (list new-rule)))
                          (let ((new-rule (list (list count) (incf count) 0.5)))
	                    (alexandria::nconcf rules (list new-rule)))
		          (when max-rep
                            (let ((new-rule (list (make-list max-rep :initial-element (- count 1)) count 1.0)))
	                      (alexandria::nconcf rules (list new-rule)))))
                        (let ((new-rule (list (list count) (incf count) 1.0)))
	                  (alexandria::nconcf rules (list new-rule))))
                    (let ((new-rule (list (list count) (incf count) 1.0)))
	              (alexandria::nconcf rules (list new-rule)))))
	       ((and (or (typep a 'event) (typep a 'list)) (typep b 'number))
	        (setf (gethash count event-mapping) (if (typep a 'list) a (list a))))
	       ((and (typep a 'number) (or (typep b 'event) (typep b 'list)))
	        (setf (gethash (+ count 1) event-mapping) (if (typep b 'list) b (list b)))
                (if (> rep 0)
		    (if (< (random 100) rep)
                        (progn
                          (let ((new-rule (list (list count) count 0.5)))
	                    (alexandria::nconcf rules (list new-rule)))
                          (let ((new-rule (list (list count) (incf count) 0.5 a)))
	                    (alexandria::nconcf rules (list new-rule)))
		          (when max-rep
                            (let ((new-rule (list (make-list max-rep :initial-element (- count 1)) count 1.0)))
	                      (alexandria::nconcf rules (list new-rule)))))
                        (let ((new-rule (list (list count) (incf count) 1.0 a)))
	                  (alexandria::nconcf rules (list new-rule))))
                    (let ((new-rule (list (list count) (incf count) 1.0 a)))
	              (alexandria::nconcf rules (list new-rule)))))))
    (if (typep (car (last real-events)) 'number)
	(setf rules (nconc rules (list (list (list count) 1 1.0 (car (last real-events))))))
	(setf rules (nconc rules (list (list (list count) 1 1.0)))))
    (list event-mapping rules)))

(defun cyc (name cyc-def &key (rep 0) (max-rep 2) (dur *global-default-duration*) (reset t))
  (let ((gen-ev (parse-cycle cyc-def :rep rep :max-rep max-rep :dur dur)))
    (infer-from-rules :type 'naive :name name :mapping (car gen-ev) :rules (cadr gen-ev) :default-dur dur :reset reset)))

(defun cyc2 (name cyc-def &key (rep 0) (max-rep 2) (dur *global-default-duration*) (reset t))
  (let ((gen-ev (parse-cycle cyc-def :rep rep :max-rep max-rep :dur dur)))
    (infer-from-rules :type 'pfa :name name :mapping (car gen-ev) :rules (cadr gen-ev) :default-dur dur :reset reset)))

(defun nuc (name event &key (dur *global-default-duration*) (reset t))  
  (infer-from-rules :type 'naive
                    :name name
                    :mapping (alexandria::plist-hash-table (list 1 (list event)))
	            :rules (list (list '(1) 1 100 dur))
	            :default-dur dur
                    :reset reset))

(defun nuc2 (name event &key (dur *global-default-duration*) (reset t))  
  (infer-from-rules :type 'pfa
                    :name name
                    :mapping (alexandria::plist-hash-table (list 1 (list event)))
	            :rules (list (list '(1) 1 1.0 dur))
	            :default-dur dur
                    :reset reset))

(defun find-keyword-list (keyword seq)
  (when (and
         (member keyword seq)
         (> (length (member keyword seq)) 0) ;; check if there's chance the keyword has a value ...
         (not (eql (type-of (cadr (member keyword seq))) 'keyword)))
    (let* ((pos (position keyword seq))
	   (vals (loop for val in (cdr (member keyword seq))
                       while (not (keywordp val))
                       collect val)))
      vals)))

(defun p-events-list (event-plist)  
  (let ((mapping (make-hash-table :test #'equal))
	(key))    
    (loop for m in event-plist 
	  do (if (or (typep m 'symbol) (typep m 'number))
 		 (progn
		   (setf key m)
		   (setf (gethash key mapping) (list)))
		 
                 (if (typep m 'list)
                     (loop for ev in m do (push ev (gethash key mapping)))
                     (push m (gethash key mapping)))))
    mapping))

(defun infer (name &rest params)
  "infer a generator from rules"
  (let ((events (find-keyword-list :events params))
        (rules (find-keyword-list :rules params))
        (dur (find-keyword-val :dur params :default *global-default-duration*))
        (type (find-keyword-val :type params :default 'pfa))
        (reset (find-keyword-val :reset params :default t)))
    (infer-from-rules :type type 
                      :name name
                      :mapping (p-events-list events)
	              :rules rules
	              :default-dur dur
                      :reset reset)))

(defun sstring (string-as-sym)
  "convenience method to enter sample strings without spaces"
  (let ((sname (if (typep string-as-sym 'string)
		   string-as-sym
		   (symbol-name string-as-sym))))
    (loop for c in (coerce sname 'list)
          collecting (intern (string-upcase (string c))))))

(defun learn (name &rest params)
  "lear a generator from a sample"
  (let* ((sample (alexandria::lastcar params))
         (type (find-keyword-val :type params :default 'pfa))
         (reset (find-keyword-val :reset params :default t))
         (bound (find-keyword-val :bound params :default 3))
         (size (find-keyword-val :size params :default 40))
         (epsilon (find-keyword-val :epsilon params :default 0.01))
         (dur (find-keyword-val :dur params :default *global-default-duration*))
         (events (delete sample (find-keyword-list :events params) :test 'equal)))
    (learn-generator :name name
                     :sample (if (listp sample) sample (sstring sample))
                     :mapping (p-events-list events)
                     :default-dur dur)))

;;;;;;;;;;;;; SOME SHORTHANDS ;;;;;;;;;;;;;;;;;;;

;; parameter sequence
(defmacro pseq (param &rest rest)
  (let ((p-events (loop for val in rest
                        collect `(,param ,val))))
    `(funcall (lambda () (cyc ',(gensym) (list ,@p-events))))))

;; chop a sample
(defmacro chop (name template num &key (start 0.0))
  (let ((p-events (loop for val from 0 to num
		        collect `(let ((cur-ev ,template))                                   
                                   (setf (event-start cur-ev) (+ ,start (* ,val (coerce (/  (- 1.0 ,start) ,num) 'float))))
                                   cur-ev))))
    `(funcall (lambda () (cyc ,name (list ,@p-events))))))

(defmacro chop2 (name template num &key (start 0.0))
  (let ((p-events (loop for val from 0 to num
		        collect `(let ((cur-ev ,template))
                                   (setf (event-start cur-ev) (+ ,start (* ,val (coerce (/  (- 1.0 ,start) ,num) 'float))))
                                   cur-ev))))
    `(funcall (lambda () (cyc2 ,name (list ,@p-events))))))

