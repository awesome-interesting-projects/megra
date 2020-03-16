(in-package :megra)

(defmethod grow (graph-or-id &key (var 0)		        
			          durs
			          functors
			          (method 'old)
			          (rnd 0)
			          (higher-order 0))
  (let* ((g (if (typep graph-or-id 'symbol)
			    (gethash graph-or-id *processor-directory*)
			    graph-or-id))
         (result (cond ((eql method 'triloop)
	                (vom::grow-triloop (inner-generator g) 
	                              :rnd rnd
	                              :higher-order higher-order))
	               ((eql method 'quadloop)
	                (vom::grow-quadloop (inner-generator g)
				       :rnd rnd
				       :higher-order higher-order))
	               ((eql method 'loop)
	                (vom::grow-loop (inner-generator g)
			           :rnd rnd
			           :higher-order higher-order))
	               (t (vom::grow-old (inner-generator g)
		                    :rnd rnd
		                    :higher-order higher-order)))))
    ;; set the new event ...
    (setf (gethash (vom::growth-result-added-symbol result) (event-dictionary g))
          (deepcopy-list (gethash (vom::growth-result-template-symbol result) (event-dictionary g))
			 :imprecision var
			 :functors functors))
    ;; now for the durations ... 
    (let ((appropiate-duration            
            (gethash (car (vom::growth-result-removed-transitions result)) (transition-durations g))))
      (if appropiate-duration
          (loop for added in (vom::growth-result-added-transitions result)
                do (setf (gethash added (transition-durations g)) appropiate-duration)))
      (list result appropiate-duration))))

(defun prune (graph-id &key exclude node-id)
  (prune-graph (gethash graph-id *processor-directory*)
	       :exclude exclude
               :node-id node-id))
