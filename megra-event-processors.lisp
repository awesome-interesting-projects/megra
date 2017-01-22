(load "megra-structures")

					; generic event-generator			        
(defclass event-processor ()
  ((pull-events)
   (pull-transition)       
   (active :accessor is-active :initform t)
   (successor :accessor successor)
   (has-successor)
   (current-events)      ; abstract
   (current-transition)  ; abstract   
   ))

(defmethod has-successor ((e event-processor) &key)
  (slot-boundp e 'successor))

(defmethod pull-events ((e event-processor) &key)
  (if (has-successor e)
      (apply-self e (pull-events (successor e)))
      (current-events e)))

(defmethod pull-transition ((e event-processor) &key)
  (if (has-successor e)
      (progn
	(current-transition e)
	(pull-transition (successor e)))
      (current-transition e)))

					; dummy for testing, development and debugging ..
(defclass dummy-event-processor (event-processor)
  ((name :accessor dummy-name)))

(defmethod apply-self ((e dummy-event-processor) events &key)
  (fresh-line)
  (princ "applying ")
  (current-events e))

(defmethod current-events ((e dummy-event-processor) &key)
  (fresh-line)
  (princ "dummy events from ")
  (princ (dummy-name e)))

(defmethod current-transition ((e dummy-event-processor) &key)
  (fresh-line)
  (princ "dummy transition from ")
  (princ (dummy-name e)))

					; graph-based event-generator ... 
(defclass graph-event-processor (event-processor) 
  ((source-graph :accessor source-graph :initarg graph)
   (current-node :accessor current-node)
   (path)))

(defmethod current-events ((g graph-event-processor) &key)
  (node-content (gethash (current-node g) (graph-nodes (source-graph g)))))

					; get the transition and set next current node
(defmethod current-transition ((g graph-event-processor) &key)
  (labels
      ((choice-list (edge counter)
	 (loop repeat (edge-probablity edge)
	    collect counter))
       (collect-choices (edges counter)
	 (if edges
	     (append (choice-list (car edges) counter) (collect-choices (cdr edges) (1+ counter)))
	     '())))
  (let* ((current-edges (gethash (current-node g) (graph-edges (source-graph g))))
	 (current-choices (collect-choices current-edges 0))
	 (chosen-edge-id (nth (random (length current-choices)) current-choices))
	 (chosen-edge (nth chosen-edge-id current-edges)))
    (setf (current-node g) (edge-destination chosen-edge))
    (car (edge-content chosen-edge)))))

(defmethod apply-self ((g graph-event-processor) events &key)
  (combine-events (current-events g) events))

(defclass modifying-event-processor (event-processor) ())
  
					;contains additional method "just-process"


					; next-event recursively calls next-event of successors
					; maybe reverse list (or keep them in order, and let reversal be done by macros)
					; then return (apply-events (next-events successor) to handle event combination
					; BUT this leaves out pure modificatiors ! 






