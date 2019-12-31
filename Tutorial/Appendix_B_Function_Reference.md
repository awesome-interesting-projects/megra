# Mégra Function Reference

Table of Contents
=================

* [always - Event Stream Modificator Probablity](#always---event-stream-modificator-probablity)           
* [bpan - Apply Browninan Stereo Panning to Event Stream](#bpan---apply-browninan-stereo-panning-to-event-stream) 
* [brownian - Bounded Brownian Motion](#brownian---bounded-brownian-motion)   
* [chain - Create Event Processor Chain](#chain---create-event-processor-chain)
* [chop - Chop a sample](#chop---chop-a-sample)
* [clear - Clear Session](#clear---clear-session)
* [ctrl - Control Functions](#ctrl---control-functions)
* [cyc - Cycle Generator](#cyc---cycle-generator)
* [cyc2 - Cycle Generator](#cyc2---cycle-generator)
* [discourage - Stir Up Generator](#discourage---stir-up-generator)
* [dup - Duplicate Generators, Time-Dependent](#dup---duplicate-generators-time-dependent)
* [e, edge - Edge Constructor](#e-edge---edge-constructor)
* [encourage - Consolidate Generator](#encourage---consolidate-generator)
* [env - Parameter Envelope](#env---parameter-envelope)
* [evr - Count-Based Generator Manipulators](#evr---count-based-generator-manipulators)
* [exh - Event Stream Manipulator](#exh---event-stream-manipulator)
* [fade - Parameter Fader](#fade---parameter-fader)
* [for - Event Stream Selector](#for---event-stream-selector)
* [g, graph  - Markov Graph Constructor](#g-graph----markov-graph-constructor)
* [grow - Enlarge Generator](#grow---enlarge-generator)
* [grow2 - Enlarge Generator](#grow2---enlarge-generator)
* [grown - Enlarge Generator n times](#grown---enlarge-generator-n-times)
* [grown2 - Enlarge Generator n times](#grown2---enlarge-generator-n-times)
* [haste - speed up evaluation](#haste---speed-up-evaluation)
* [inh - Event Stream Manipulator](#inh---event-stream-manipulator)
* [lifemodel - Manipulate Generator](#lifemodel---manipulate-generator)
* [n, node - Node Constructor](#n-node---node-constructor)
* [nuc - Nucleus Generator](#nuc---nucleus-generator)
* [nuc2 - Nucleus Generator](#nuc2---nucleus-generator)
* [oscil - Parameter Oscillator](#oscil---parameter-oscillator)
* [pear - Apply Modifiers](#pear---apply-modifiers)
* [probctrl - Manipulate Generator](#probctrl---manipulate-generator)
* [prob - Event Stream Manipulator Probablity](#prob---event-stream-manipulator-probablity)
* [pprob - Event Stream Manipulator Probablity](#pprob---event-stream-manipulator-probablity)
* [pseq - Event Sequence Generated from Parameters](#pseq---event-sequence-generated-from-parameters)
* [pulspread - Pulsating Stereo Spread](#pulspread---pulsating-stereo-spread)
* [relax - Slow Down Generator](#relax---slow-down-generator)
* [shrink - Shrink Generator](#shrink---shrink-generator)
* [skip - Skip Events](#skip---skip-events)
* [s, sink - Event Sink](#s-sink---event-sink)
* [sx - Multiple Event Sinks](#sx---multiple-event-sinks)
* [slearn - Learn Generator from Distribution](#slearn---learn-generator-from-distribution)
* [sinfer - Infer Generator from Rules](#sinfer---infer-generator-from-rules)
* [stop - Stop Event Processing](#stop---stop-event-processing)
* [xdup - Multiply Generators Independently](#xdup---multiply-generators-independently)

## `always` - Event Stream Modificator Probablity

Applies an event stream modificator with probability one.

### Parameters

* modificators (list)

### Syntax

```lisp
(always <modificators>)
```

### Examples

Always apply reverb to events:

```lisp
(s 'some ()
  (always (rev 0.1))
  (cyc 'beat "bd ~ ~ ~ sn ~ ~ ~"))
```
## `bpan` - Apply Browninan Stereo Panning to Event Stream

### Examples

```lisp
(s 'some ()
  (bpan beat)
  (cyc 'beat "bd ~ ~ ~ sn ~ ~ ~"))
```

## `brownian` - Bounded Brownian Motion 

Define a bounded brownian motion on a parameter.

### Parameters

* lower boundary (float)
* upper boundary (float)
* `:wrap` (boolean) (t) - wrap value if it reaches lower or upper boundary
* `:limit` (boolean) (nil) - limit value if it reaches upper or lower boundary
* `:step-size` (float) (0.1) - step that the parameter will be incremented/decremented

### Syntax

```lisp
(brownian <lower boundary> <upper boundary> :wrap <wrap> :limit <limit> :step-size <step-size>)
```

### Examples

```lisp
(s 'some ()
  (always (rate (brownian 0.8 1.2)))
  (nuc 'violin (violin 'a3)))
 ```

## `chain` - Create Event Processor Chain

Creates an event processor chain without dispatching it to sink.

### Parameters

* name - chain name
* generators - event generators

### Syntax

```lisp
(chain '<name> () 
  <generators>
)
```

### Example

```lisp
;; first define a chain
(chain 'some ()
  (always (rev 0.1))
  (nuc 'violin (violin 'a3)))
  
(s 'some ()) ;; dispatch to sink later  
```
## `chop` - Chop a sample

## `clear` - Clear Session

Stops and deletes all present generators.

## `ctrl` - Control Functions

Executes any function, can be used to conduct execution of generators.

### Parameters

* function

### Syntax

```lisp
(ctrl <function>)
```

### Example

```lisp
(chain 'some ()
  (always (rev 0.1))
  (nuc 'violin (violin 'a3)))

(chain 'more ()
  (always (rev 0.1))
  (nuc 'cello (cello 'c1)))

(s 'controller ()
  (g 'conductor ()
    (n 1 (ctrl #'(lambda () (stop 'more) (sink 'some ())))) ;; control function
    (n 2 (ctrl #'(lambda () (stop 'some) (sink 'more ()))))
    (e 1 2 :p 100 :d 3000)
    (e 2 1 :p 100 :d 3000)))

```

## `cyc` - Cycle Generator

Generates a cycle (aka loop) from a simple sequencing language.

### Parameters

* name - generator name
* sequence - sequence description
* `:dur` - default space between events 
* `:rep` - probability of repeating an event
* `:max-rep` - limits number of repetitions
* `:rnd` - random connection probability

### Syntax

```lisp
(cyc <name> <sequence> :dur <duration> :rep <repetition probability> :max-rep <max number of repetitions> :rnd <random connection prob>)
```

### Example 
```lisp
(s 'simple ()
  (cyc 'beat "bd ~ hats ~ sn ~ hats ~"))
```

## `cyc2` - Cycle Generator

Generates a cycle (aka loop) from a simple sequencing language, using the advanced PFA model. Currently doesn't have the `:rnd` parameter.

### Parameters

* name - generator name
* sequence - sequence description
* `:dur` - default space between events 
* `:rep` - probability of repeating an event
* `:max-rep` - limits number of repetitions

### Syntax

```lisp
(cyc2 <name> <sequence> :dur <duration> :rep <repetition probability> :max-rep <max number of repetitions>)
```

### Example

```lisp
(s 'simple ()
  (cyc2 'beat "bd ~ hats ~ sn ~ hats ~" :rep 60 :max-rep 3))
```

## `discourage` - Stir Up Generator

Looks at the last path through the graph and decreases the probablity for that sequence to happen again, effectively increasing entropy of the results. 

Only works with generators generated by `(cyc ...)`,  `(nuc ...)` or  `(graph ...)`.

### Syntax

```lisp
(discourage <graph>)
```

### Example

```lisp
(s 'chaos ()
  (cyc 'gen "bd ~ ~ sn sn ~ casio ~" :rep 80 :rnd 80 :max-rep 4))
  
(grow 'gen :var 0.3) ;; execute a couple times

(discourage 'gen) ;; hear what happens
```
## `dup` - Duplicate Generators, Time-Dependent

## `e`, `edge` - Edge Constructor

Construct an edge between two nodes.

### Parameters

* source - source node (or sequence)
* destination - destination node
* `:dur`, `:d` - transition duration
* `:prob`, `:p` - transition probablity

### Syntax

```lisp
(e <source> <destination> :p <probability> :d <duration>) ;; short form
(edge <source> <destination> :prob <probability> :dur <duration>) ;; long form
```

### Example

```lisp
(s 'some ()
  (graph 'nodes ()
    (node 1 (bd))
    (node 2 (sn))
    (e 1 1 :p 80 :d 200) ;; source node is single node
    (e '(1 1 1 1) 1 :p 80 :d 200) ;; source is sequence 
    (e 1 2 :p 20 :d 200)
    (e 2 1 :p 100 :d 200)))
```

## `encourage` - Consolidate Generator

Looks at the last path through the graph and increases the probablity for that sequence to happen again, effectively decreasing entropy of the results. 

Only works with generators generated by `(cyc ...)`,  `(nuc ...)` or  `(graph ...)`.

### Syntax

```lisp
(encourage <graph>)
```

### Example

```lisp
(s 'chaos ()
  (cyc 'gen "bd ~ ~ sn sn ~ casio ~" :rep 80 :rnd 80 :max-rep 4))
  
(grow 'gen :var 0.3) ;; execute a couple times

(encourage 'gen) ;; hear what happens
```

## `env` - Parameter Envelope

Define an envelope on any parameter. Length of list of levels must be one more than length of list of durations.

### Paramters

* levels (list) - level points on envelope path
* durations (list) - transition durations (in steps)
* `repeat` (boolean) - loop envelope 

### Syntax

```lisp
(env <levels> <durations> :repeat <t/nil>)
```

### Example

```lisp
(s 'simple ()
  (always (lvl (env '(0.0 0.4 0.0) '(20 30))))
  (cyc 'beat "bd ~ hats ~ sn ~ hats ~"))
```

## `evr` - Count-Based Generator Manipulators

## `exh` - Event Stream Manipulator

Exhibit event type, that is, mute all other events, with a certain probability.

### Parameters

* probablility (int) - exhibit probablility
* filter (filter function) - event type filter

### Syntax
```lisp
(exh <probability> <filter>)
```

### Example
```lisp
(s 'simple ()
  (exh 30 hats)
  (exh 30 bd)
  (nuc 'beat (~ (bd) (sn) (hats))))
```

## `fade` - Parameter Fader

## `for` - Event Stream Selector

## `g`, `graph`  - Markov Graph Constructor

## `grow` - Enlarge Generator

## `grow2` - Enlarge Generator

## `grown` - Enlarge Generator n times

## `grown2` - Enlarge Generator n times

## `haste` - speed up evaluation

## `inh` - Event Stream Manipulator

Inhibit event type, that is, mute event of that type, with a certain probability.

### Parameters

* probablility (int) - inhibit probablility
* filter (filter function) - event type filter

### Syntax

```lisp
(inh <probability> <filter>)
```

### Example

```lisp
(s 'simple ()
  (inh 30 hats)
  (inh 30 bd)
  (inh 30 sn)
  (nuc 'beat (~ (bd) (sn) (hats))))
```

## `lifemodel` - Manipulate Generator 

## `n`, `node` - Node Constructor

## `nuc` - Nucleus Generator

Generates a one-node repeating generator, i.e. as a starting point for growing.

### Parameters

* name (symbol)
* event(s) (event or list of events) - events to be repeated
* `:dur` - transition duration between events

### Syntax

```lisp
(nuc <name> <event(s)> :dur <duration>)
```

### Example

```lisp
(s 'simple ()
  (nuc 'beat (bd) :dur 400))
```

## `nuc2` - Nucleus Generator

Generates a one-node repeating generator, i.e. as a starting point for growing, based on PFA model.

### Parameters

* name (symbol)
* event(s) (event or list of events) - events to be repeated
* `:dur` - transition duration between events

### Syntax

```lisp
(nuc2 <name> <event(s)> :dur <duration>)
```

### Example

```lisp
(s 'simple ()
  (nuc2 'beat (bd) :dur 400))
```

## `oscil` - Parameter Oscillator

Define oscillation on any parameter. The oscillation curve is a bit bouncy, not really sinusoidal.

### Parameters 

* upper limit - upper limit for oscillation 
* lower limit - lower limit for oscillation 
* `:cycle` - oscillation cycle length in steps

### Syntax

```lisp
(oscil <upper limit> <lower limit> :cycle <cycle length in steps>)
```

### Example

```lisp
(s 'simple ()
  (nuc2 'beat (bd) :dur (oscil 200 600 :steps 80)))
```

## `pear` - Apply Modifiers

Appl-ys and Pears ...

## `probctrl` - Manipulate Generator

## `prob` - Event Stream Manipulator Probablity

## `pprob` - Event Stream Manipulator Probablity

## `pseq` - Event Sequence Generated from Parameters

## `pulspread` - Pulsating Stereo Spread
```lisp
(pulspread <pulse cycle> <variance> <selectors>)
```
## `relax` - Slow Down Generator

## `shrink` - Shrink Generator

## `skip` - Skip Events

## `s`, `sink` - Event Sink

Takes events and turns them into sound.

### Parameters:

* name (symbol)
* `:sync` (symbol) *optional*
* `:shift` (integer) *optional*

### Syntax:

```lisp
(s '<name> (:sync '<sync> :shift <milliseconds>) 
  <list of generators>
)
```
## `sx` - Multiple Event Sinks

## `slearn` - Learn Generator from Distribution

## `sinfer` - Infer Generator from Rules

## `stop` - Stop Event Processing

Stop event processing without deleting generators, thus maintaining current state.

## `xdup` - Multiply Generators Independently



