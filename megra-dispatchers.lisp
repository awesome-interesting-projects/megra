;; event dispatching and related stuff ... 

;; simple time-recursive dispatching
;; not using local variable binding to reduce consing (??)
(in-package :megra)

(defun perform-dispatch (proc time)
  (let ((event-processor (gethash proc *processor-directory*)))    
    (when (and event-processor (is-active event-processor))
      ;; here, the events are produced and handled ...
      (loop for synced-proc in (synced-processors event-processor)
	 ;; don't check if it's active, as only deactivated procs are added to sync list
	 do (progn
	      (activate synced-proc)
	      (perform-dispatch synced-proc (incudine:now))))
      ;; reset all synced processors
      (setf (synced-processors event-processor) nil)      
      ;; handle events from current graph
      (handle-events (pull-events event-processor))
      ;; here, the transition time between events is determinend,
      ;; and the next evaluation is scheduled ...
      (let* ((trans-time (handle-transition (car
					     (pull-transition
					      event-processor))))
	     (next (+ time #[trans-time ms])))	
	;;(incudine:at next #'incudine:nrt-funcall #'(lambda () (perform-dispatch d proc next)))))))
	(incudine:at next #'perform-dispatch proc next)))))

(defun handle-transition (tr)
  (transition-duration tr))	 

(defun handle-events (events)
  (mapc #'handle-event events))

(defmacro dispatch ((&key (sync-to nil) (unique t) (chain nil)) &body proc-body)
  `(funcall #'(lambda () (let ((event-processors (list ,@proc-body)))		      
		      (when (and ,unique (not ,chain))
			(detach (gethash (car (last event-processors)) *processor-directory*) event-processors)) 
		      (when (not ,chain)
			(connect event-processors))		      
		      (if (and ,sync-to (gethash ,sync-to *processor-directory*))
			  ;; if this processor is synced to another, don't start now ..
			  ;; dispatching will be started by the processor this one is synced to 
			  (progn			    
			    (deactivate (car event-processors) :del nil)
			    (setf (synced-processors (gethash ,sync-to *processor-directory*))
				  (append (synced-processors (gethash ,sync-to *processor-directory*))
					  (list (car event-processors)))))
			  ;; if the first event-processor is not active yet,
			  ;; create a dispatcher to dispatch it ... 
			  (unless (is-active (gethash (car event-processors) *processor-directory*))
			    (activate (car event-processors))
			    ;; the step dispatching 
			    ;; with chain rebuilding for
			    ;; each dispatch
			    ;; is pretty inefficient and currently
			    ;; only intended for debugging purposes.
			    ;; If it should become a regular feature, i might need to this concept ... 			             
			    (incudine:at (incudine:now) #'perform-dispatch (car event-processors) (incudine:now) ,repeat)
			    ;;(incudine:at (incudine:now) #'incudine:nrt-funcall #'(lambda () (perform-dispatch dispatcher (car event-processors) (incudine:now))))
			    ))))))

