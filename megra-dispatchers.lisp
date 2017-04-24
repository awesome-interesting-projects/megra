;; event dispatchers and related stuff ... 

(defclass dispatcher ()
  ((step-dispatch)
   (perform-dispatch)
   (handle-events)
   (handle-transition)))

;; simple time-recursive dispatching
;; not using local variable binding to reduce consing (??)
(in-package :megra)
(defmethod perform-dispatch ((d dispatcher) proc time &key)
  (when (and (gethash proc *processor-directory*) (is-active (gethash proc *processor-directory*)))
    (when (synced-processors (gethash proc *processor-directory*))
      ;;(format t "~a" (synced-processors (gethash proc *processor-directory*)))
      (loop for synced-proc in (synced-processors (gethash proc *processor-directory*))
	 ;; dont check if it's active, as ondly deactivated procs are added to sync list
	 do (let ((sync-d (make-instance 'event-dispatcher)))
	      (format t "~a" synced-proc)
	      (activate synced-proc)
	      (perform-dispatch sync-d synced-proc (incudine:now))))
      (setf (synced-processors (gethash proc *processor-directory*)) nil))
    (handle-events d (pull-events (gethash proc *processor-directory*)))
    (let* ((trans-time (handle-transition d (car
					     (pull-transition
					      (gethash proc *processor-directory*)))))
	   (next (+ time #[trans-time ms])))
      (incudine:at next #'perform-dispatch d proc next))))

;; manual step-by step dispatching ...
(defmethod step-dispatch ((d dispatcher) proc &key)
  (when (and (gethash proc *processor-directory*) (is-active (gethash proc *processor-directory*)) )
    (handle-events d (pull-events (gethash proc *processor-directory*)))
    (handle-transition d (car (pull-transition (gethash proc *processor-directory*))))))

(defmethod handle-transition ((s dispatcher) (tr transition) &key)
  (transition-duration tr))	 

;; dummy dispatcher for testing and development
(defclass string-dispatcher (dispatcher) ())

(defmethod handle-events ((s string-dispatcher) events &key)
  (fresh-line)
  (princ "the following events should be handled: ")
  (mapc #'(lambda (event)
	    (princ (event-message event))
	    (princ " from ")
	    (princ (event-source event))
	    (princ ", ")) events))

;; the main event dispatcher
(defclass event-dispatcher (dispatcher) ())

(defmethod handle-events ((e event-dispatcher) events &key)
  (mapc #'handle-event events))

;; see what we can still do with this ... 
(defmethod handle-event ((e incomplete-event) &key))

;; if nothing else helps ...
(defmethod handle-event ((e event) &key))

;; handler methods for individual events ... 
;;(in-package :megra)
(defmethod handle-event ((m midi-event) &key)
  (events (cm::new cm::midi
	       :time *global-midi-delay*
	       :keynum (event-pitch m)
	       :duration (coerce (* (event-duration m) 0.001) 'single-float)
	       :amplitude (round (* 127 (event-level m))))
	  :at (incudine:now)))

(defmethod handle-event ((c control-event) &key)
  (funcall (control-function c)))

(defmethod handle-event ((g grain-event) &key)
  (if (member 'inc (event-backends g)) (handle-grain-event-incu g))
  (if (member 'sc (event-backends g)) (handle-grain-event-sc g)))

(defmethod handle-grain-event-sc ((g grain-event) &key)
  (unless (gethash (sample-location g) *buffer-directory*)
    (register-sample (sample-location g)))
  (let ((bufnum (gethash (sample-location g) *buffer-directory*)))
    (cm::send-osc  
     "/s_new"	    
     "siiisisfsfsfsfsfsfsfsfsfsfsfsfsfsfsf"
     "grain_2ch" -1 0 1
     "bufnum" bufnum
     "lvl" (coerce (event-level g) 'float)
     "rate" (coerce (event-rate g) 'float)
     "start" (coerce (event-start g) 'float)
     "lp_freq" (coerce (event-lp-freq g) 'float)
     "lp_q" (coerce (event-lp-q g) 'float)
     "lp_dist" (coerce (event-lp-dist g) 'float)
     "pf_freq" (coerce (event-pf-freq g) 'float)
     "pf_q" (coerce (event-pf-q g) 'float)
     "pf_gain" (coerce (event-pf-gain g) 'float)
     "hp_freq" (coerce (event-hp-freq g) 'float)
     "hp_q" (coerce (event-hp-q g)  'float)
     "a" (coerce (* (event-attack g) 0.001) 'float)
     "length" (coerce (* (- (event-duration g) (event-attack g) (event-release g)) 0.001) 'float)
     "r" (coerce (* (event-release g) 0.001) 'float)
     "pos" (coerce (- (event-position g) 0.5) 'float))))

(defmethod handle-grain-event-incu ((g grain-event) &key)
  (unless (gethash (sample-location g) *buffer-directory*)
    (let* ((buffer (incudine:buffer-load (sample-location g)))
	   (bdata (make-buffer-data :buffer buffer
				    :buffer-rate (/ (incudine:buffer-sample-rate buffer)
						    (incudine:buffer-frames buffer))
				    :buffer-frames (incudine:buffer-frames buffer))))
      (setf (gethash (sample-location g) *buffer-directory*) bdata)))
  (let ((bdata (gethash (sample-location g) *buffer-directory*)))    
    (cond ((not (event-ambi-p g))
	   (scratch::megra-grain-rev (buffer-data-buffer bdata)
		 (buffer-data-buffer-rate bdata)
		 (buffer-data-buffer-frames bdata)
		 (event-level g)
		 (event-rate g)
		 (event-start g)
		 (event-lp-freq g)
		 (event-lp-q g)
		 (event-lp-dist g)
		 (event-pf-freq g)
		 (event-pf-q g)
		 (event-pf-gain g)
		 (event-hp-freq g)
		 (event-hp-q g)
		 (* (event-attack g) 0.001)
		 (* (- (event-duration g) (event-attack g) (event-release g)) 0.001)
		 (* (event-release g) 0.001)
		 (event-position g)
		 (event-reverb g)
		 scratch::*rev-chapel*))
	((event-ambi-p g)  
	 (scratch::megra-grain-ambi-rev (buffer-data-buffer bdata)
		 (buffer-data-buffer-rate bdata)
		 (buffer-data-buffer-frames bdata)
		 (event-level g)
		 (event-rate g)
		 (event-start g)
		 (event-lp-freq g)
		 (event-lp-q g)
		 (event-lp-dist g)
		 (event-pf-freq g)
		 (event-pf-q g)
		 (event-pf-gain g)
		 (event-hp-freq g)
		 (event-hp-q g)
		 (* (event-attack g) 0.001)
		 (* (- (event-duration g) (event-attack g) (event-release g)) 0.001)
		 (* (event-release g) 0.001)
		 (+ (event-azimuth g) *global-azimuth-offset*)
		 (+ (event-elevation g) *global-elevation-offset*)
		 (event-reverb g)
		 scratch::*rev-chapel*)))))

(defmethod handle-event ((g gendy-event) &key)
  (scratch::gendy-stereo-rev
   (event-amp-distr g)
   (event-dur-distr g)
   (event-amp-distr-param g)
   (event-dur-distr-param g)
   (event-freq-min g)
   (event-freq-max g)
   (event-amp-scale g)
   (event-dur-scale g)
   (event-level g)
   (event-lp-freq g)
   (event-lp-q g)
   (event-lp-dist g)
   (* (event-attack g) 0.001)
   (* (- (event-duration g) (event-attack g) (event-release g)) 0.001)
   (* (event-release g) 0.001)
   (event-position g)
   (event-reverb g)
   scratch::*rev-chapel*))
