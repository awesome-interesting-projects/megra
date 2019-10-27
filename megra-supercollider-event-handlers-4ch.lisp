(in-package :megra)

;; handler method for grain event, supercollider
(defmethod handle-grain-event-sc-4ch ((g grain-event-4ch) timestamp &key)
  (unless (gethash (grain-4ch-sample-location g) *sc-buffer-directory*)
    (register-sample (grain-4ch-sample-location g)))
  ;; might save a hashtable access here ... later ...
  (let ((bufnum (gethash (grain-4ch-sample-location g) *sc-buffer-directory*)))    
    (osc:simple-bundle cm::*oscout* timestamp  
		       "/s_new"	    
		       "siiisisfsfsfsfsfsfsfsfsfsfsfsfsfsfsfsfsfsfsf"
		       "grain_4ch_rev" -1 0 1
		       "bufnum" bufnum
		       "lvl" (coerce (event-level g) 'float)
		       "rate" (coerce (event-rate g) 'float)
		       "start" (coerce (event-start g) 'float)
		       "lp_freq" (coerce (event-lp-freq g) 'float)
		       "lp_q" (coerce (event-lp-q g) 'float)
		       "lp_dist" (coerce (event-lp-dist g) 'float)
		       "lp_freq_lfo_freq" (coerce (event-lp-freq-lfo-speed g) 'float)
		       "lp_freq_lfo_depth" (coerce (event-lp-freq-lfo-depth g) 'float)
		       "lp_freq_lfo_phase" (coerce (event-lp-freq-lfo-phase g) 'float)
		       "pf_freq" (coerce (event-pf-freq g) 'float)
		       "pf_q" (coerce (event-pf-q g) 'float)
		       "pf_gain" (coerce (event-pf-gain g) 'float)
		       "hp_freq" (coerce (event-hp-freq g) 'float)
		       "hp_q" (coerce (event-hp-q g)  'float)
		       "a" (coerce (* (event-attack g) 0.001) 'float)
		       "length" (coerce (* (- (event-duration g) (event-attack g) (event-release g)) 0.001) 'float)
		       "r" (coerce (* (event-release g) 0.001) 'float)
		       "pos" (coerce (- (event-position g) 0.5) 'float)
		       "rev" (coerce (event-reverb g) 'float))))

