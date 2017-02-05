(require 'cm)
(in-package :cm)
;; initialize -- seems like it has to be like this ...
(progn
    (incudine:rt-start)
    (sleep 1)
    (midi-open-default :direction :input)
    (midi-open-default :direction :output)
    (osc-open-default :host "127.0.0.1" :port 3002 :direction :input)
    (osc-open-default :host "127.0.0.1" :port 3003 :direction :output)    
    (setf *out* (cm::new cm::incudine-stream))
    (setf *rts-out* *out*))

;; then load the megra dsp stuff .. wait until compilation has finished !!
(compile-file "megra-dsp")
(load "megra-dsp")

;; now everything should be ready to load the megra package ... 
(load "megra-package")

(in-package :megra)

;; define some test graph structures
(graph 'uno-midi ()
       (node 1 (mid 65 :lvl .4 :dur 50))
       (node 2 (mid 81 :lvl 1 :dur 50) (mid 50 :lvl 1 :dur 50))
       (edge 1 2 :prob 100 :dur 200)
       (edge 2 1 :prob 100 :dur 200))

(deactivate 'dos-midi)

(dispatch 'dos-midi) 

;; individual graphs are basically first-order markov chains ...
(graph 'dos-midi ()
       (node 1 (mid 59 :lvl .8 :dur 350))
       (node 2 (mid 73 :lvl .9 :dur 350))
       (node 3 (mid 78 :lvl .9 :dur 350))
       (edge 1 2 :prob 50 :dur 500)
       (edge 1 3 :prob 50 :dur 750)
       (edge 2 1 :prob 100 :dur 500)
       (edge 3 1 :prob 100 :dur 250))

(graph 'the-grain (:perma t) 
       (node 1 (grain "misc" "tada" :dur 256 :lvl 0.5 :rate 0.5 :atk 64 :rel 64))
       (edge 1 1 :prob 100 :dur 64))

(graph 'the-512-beat ()
       (node 1 (grain "03_electronics" "01_808_long_kick" :dur 256
		      :lvl 1.0 :rate 1.0 :start 0.001 :atk 0.1 :lp-dist 1.0 :lp-freq 600))
       (node 2 (grain "03_electronics" "08_fat_snare" :dur 128 :atk 0.1 :lvl 0.5 :rate 0.4))
       (edge 1 2 :prob 100 :dur 256)
       (edge 2 1 :prob 100 :dur 256))


(dispatch
 (oscillate-between 'lp-freq-b 'lp-freq 100 8000 :cycle 100)
 (oscillate-between 'dist-b 'rate 0.1 1.0 :cycle 400)
 (oscillate-between 'dist-b 'rate 0.1 1.0 :cycle 400)
 (oscillate-between 'q-b 'lp-q 0.1 1.0 :cycle 50) 
 'the-512-beat)

(dispatch
 (brownian-motion 'start-b 'start :step 0.001 :ubound 0.001 :lbound 0.8 :wrap t)
 (oscillate-between 'lp-freq-c 'lp-freq 100 8000 :cycle 1000)
 (oscillate-between 'q-c 'lp-q 0.1 1.0 :cycle 50)
 (oscillate-between 'pos-c 'pos 0.4 0.8 :cycle 50) 
 (oscillate-between 'rate-b 'rate 0.1 0.14 :cycle 400) 
 'the-grain)

(dispatch 'the-grain)

(deactivate 'the-grain)
(deactivate 'lp-freq-b)
(deactivate 'start-b)

;; dispatch a graph to make it sound 
(dispatch
  'uno-midi)

(deactivate 'uno-midi)

(dispatch
  'dos-midi)

;; PERMANENT CHANGE
;; this should be passed as parameter to (graph ... )
;; so i might have to replace (graph ..) by a macro ??
;(setf (copy-events (gethash 'tres-midi *processor-directory*)) nil)

(graph 'tres-midi (:perma t)
       (node 1 (mid 84 :lvl .9 :dur 150))
       (edge 1 1 :prob 100 :dur 100))


(dispatch
 'tres-midi)


;; TRANSITORY STATE (default)
(dispatch
 (brownian-motion 'tres-br 'pitch :step 3 :ubound 84 :lbound 50 :wrap t)
 'tres-midi)

(deactivate 'tres-br)

(deactivate 'tres-midi)

;; the last graph in the chain determines the timing, so each
;; processor chain needs a unique ending point, but it's possible
;; for multiple processors to have the same predecessor ... 
(dispatch 
 'uno-midi
 'tres-midi) 

;; deactivating the first processor in a chain makes it stop ...
;; if it's a modifier, the modifier needs to be deactivated;; as everything is named, this shouldn't pose a problem ... 
(deactivate 'uno-midi)
(deactivate 'dos-midi)
(deactivate 'tres-midi)

;; hook an event modifier into the chain ...
(dispatch
 'tres-midi
 (brownian-motion 'tres-rw 'pitch :step 5 :ubound 84 :lbound 50 :wrap t)
 'uno-midi)

;; TBD:
;; chain rebuilding - if you hook a new effect to the END of the dispatcher chain,
;;     multiple dispatiching will happen !
;; eventually make multiple dispatching possible ... like, (dispatch :check-active nil ...)
;; arranging modifiers in graphs ...
;; define meaningful behaviour for non-mandatory modifiers ...
;; (chance ...) shortcut ... even though the semantics of "chance" is
;;    slightly different, as is evaluates the chance of something to happen for the current
;;    event, whereas a graph modifies the modification for the next event ... 
;; graph-theory stuff -- graph transformations etc
;; syncstart
;; midi note blocker for disklavier
;; vugs
;; get rid of deactivating error msg ...

;; DONE:
;; fix de-/reactivating graphs -- stupid mistake ...
;; fix midi handling -- works, seems to be connected to the way of initializing incudine ...
;; (brownian-motion 'tres-rw 'pitch :step 4 :ubound 84 :lbound 50 :wrap t TRACK-STATE: nil) -- makes sense in comination with below ... ??
;; (graph 'xyz :copy-events nil) --- original events are sent out, makes sense in comination with the above
;; oscillating event modifier -- works !
;; tree-like dispatch branching -- works !
;; avoid duplicate dispatches -- works !
;; automatic re-activation -- works !





