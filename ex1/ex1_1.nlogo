turtles-own [
  degree  ;; all nodes will have a degree of edges
  elected?  ;; check if a node is elected
  inactive? ;; check if a node is active for the mis
  same-degree? ;; flag that shows adjacent nodes of same degree
  pv ;; needed for the bio_enhanced, each node has a variable probability of joining
  reps ;; keep track of the iterations each node did of the algorithm.
]

globals [
  msg ;; total message count for the algorithm
  bits ;; total bits of communication
  max-degree ;; the maximum degree of the graph
]

;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;; setup ;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  setup-turtles
  reset-ticks
end

to setup-turtles
  set-default-shape turtles "circle"
  create-turtles number-of-nodes [
    set color blue
    set size 1
    set inactive? false
    set elected? false
    set same-degree? false
    set pv 0.5
    set reps 0
  ]

  ifelse circle-layout?
  [layout-circle turtles (world-width / 2 - 2)]
  [ask turtles [ setxy random-xcor random-ycor]]

  setup-links
  ;; find and display the degree of each node and the max degree
  ask turtles [
    set degree count my-links
    set label degree
    if degree > max-degree [set max-degree degree]
  ]
end

;; Here we set up the links from the setup of the model
;; due to the fact we want to model the algorithms for the MIS
;; and not the linking.
to setup-links
  let number-of-links edge-factor * number-of-nodes
  while [count links < number-of-links][
    ask turtles [
      create-link-with one-of other turtles ;; if link already exists, nothing happens
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; go ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;

to go
  if not any? turtles [ stop ]
  if not any? turtles with [inactive? = false] [ stop ]

  if mode = "Simple MIS" [
    simple-mis
    set bits msg  ;; msg complexity 1
  ]
  if mode = "Luby's" [
    luby
    set bits  round (msg * log number-of-nodes 2)  ;; msg complexity logn
  ]
  if mode = "Biology inspired" [
    bio
    set bits msg  ;; msg complexity 1
  ]
  if mode = "Biology inspired Enhanced" [
    bio_enhanced
    set bits msg  ;; msg complexity 1
  ]

  tick
end


;; Implament the simple MIS algorithm (p.13 from lecture)
to simple-mis
  ;; all ACTIVE nodes try to get in the IS
  ask turtles with [inactive? = false] [
    set reps (reps + 1)
    ;; find current active degree
    set degree (count link-neighbors with [inactive? = false])
    let p (1 / max-degree)
    set msg (msg + 2 * degree)  ;; node sends and recieves status to/from active neighbors

    ;; each turtle elects itself with p probability
    ifelse random-float 1 < p [
      set elected? true
      set msg (msg + degree)

      ;; if any neighbor has elected itself with me, both diselect.
      ifelse any? link-neighbors with [elected? = true]
      [ set elected? false]
      ;; else recolor to show that node got in the IS and deactivate
      [
        set msg (msg + degree) ;; I send that I got in the MIS
        get-in-mis]
    ]
      ;; Else if it didn't elect itself but a neighbor is green,
      ;; then that neighbor got into the IS and is deactivated
    [
      if any? link-neighbors with [color = green] [
        set msg (msg + degree)  ;; node tells neighbors its deactivated
        recolor  ;; inactive nodes not in the MIS are red
        set inactive? true
        set elected? false]
    ]
  ]
end

;; Implament Luby's algorithm (p.24 from lecture)
to luby
  ;;update the current active degree of all nodes
  ask turtles
  [set degree (count link-neighbors with [inactive? = false])
    set label degree] ;; for debugging and overview

  ;; all ACTIVE nodes try to get in the IS
  ask turtles with [inactive? = false] [
    set reps (reps + 1)
    let p 1 ;; in case the degree is 0
    set elected? false  ;; all active nodes deselect, safety measure

    ;; if my degree is 0, i have no other active neighbors
    ;; and since i'm not inactive, none of them is in the mis
    ;; so I get in the mis!!
    if degree = 0 [get-in-mis]


    if degree > 0 [
      set p (1 / (2 * degree))  ;; by luby's algorithm
      set msg (msg + 2 * degree) ]  ;; node sends and recieves status to/from active neighbors

    let my-degree degree  ;; for better readability
    ;; each node elects itself with p probability
    if random-float 1 < p [
      set elected? true]

    ;; if any neighbor with higher degree has elected itself with me, I deselect myself.
    if any? link-neighbors with [degree >= my-degree and elected? = true]
      [
        set elected? false
      ]
    ;; if any neighbor with the same degree elects itself, we all wait for a random selection
    if any? link-neighbors with
    [inactive? = false and elected? = true and degree = my-degree]
    [
      ;; raise the flag of same degree
      set same-degree? true
    ]
    ;; in any other ocasion I still have the elected status and keep it to
    ;; get in the mis. These ocasions at this point are:
    ;; - Neighbors elected themeselves but had lower degree than me
    ;; - No other neighbor elected itself with me
  ]

  if any? turtles with [same-degree? = true] [
    ;; breaking the ties of same degree elected neighbors
    ask turtles with [same-degree? = true]
    [
      ;; deselect the nodes
      set elected? false
      ;; ask one of them to join the mis
      ask one-of turtles with [same-degree? = true] [set elected? true]
      ;; lower the flag of sae degree and continue
      set same-degree? false
    ]
  ]

  ;; any node with elected still true gets in the mis!
  ask turtles with [inactive? = false and elected? = true][
    get-in-mis
  ]

end

;; Implament the Biologically inspired algorithm for the MIS (p.38 from lecture)
to bio
  let i log ((max-degree) + 1) 2  ;; outside loop increment. +1 for safety.
  let j log number-of-nodes 2     ;; inside loop increment. M = 1.


  repeat i [
    ask turtles with [inactive? = false][
      ;; the probability is the same for all so calculate it once per i
      let p (1 / (2 ^ (log (max-degree - i) 2 )))

      ;;update the current active degree of all nodes
      set degree count link-neighbors with [inactive? = false]
      set label who ;; for debugging and overview

        repeat j [                                          ;; step 1
        ;;;;;;;;;;;;; EXCHANGE 1 ;;;;;;;;;;;;;;;;

        ;; all ACTIVE nodes try to get in the MIS
          ask turtles with [inactive? = false][
          set elected? false                                ;; step 2

          if random-float 1 < p [                           ;; step 3
            set msg (msg + degree)  ;; broadcasting to neighbors
            set elected? true
          ]
          if any? link-neighbors with [elected? = true]   ;; step 4
          [
            set elected? false
          ]
          ;;;;;;;;;;;;; EXCHANGE 2 ;;;;;;;;;;;;;;;;
          if elected? [                               ;; step 5
            get-in-mis
            ;; there's no need to implament step 7 due to the implementation
            ;; of it in the get-in-mis function where all the neighbors of
            ;; the node get deactivated.
          ]
        ]
        set reps (reps + 1)
      ]

      set reps (reps + 1)
    ]
  ]
end

to bio_enhanced

  ask turtles with [inactive? = false] [
    set reps (reps + 1)
    ;; Exchange 1

    ;; with probability pv i signal to others
    ifelse random-float 1 < pv [
      set elected? true
      ;; 2 msgs per adjacent node, one that i send and one i recieve
      set msg (msg + 2 * count link-neighbors with [inactive? = false])

      ;; if any of my neighbors is signaling, I deselect
      if any? link-neighbors with [elected? = true] [
        set elected? false
        ;; adjust the probability
        set pv (pv / 2)
      ]
    ]
    [
      ;; next p is the minimum of the double current p or 1/2.
      set pv min list (2 * pv) 0.5
    ]

    ;; Exchange 2
    if elected? [get-in-mis]
    ;; here when a node is joining the mis then all its neighbors
    ;; deactivate and get deselected, resembling step 5 of the algorithm.
  ]

end

to get-in-mis
  let link-color (5 + (10 + 10 * random 8)) ;; for better visibility
  set inactive? true  ;; deactivate the node
  set elected? true   ;; keep the mis status for all to see
  set same-degree? false ;; safety measure for luby's
  ask my-links [set color link-color] ;; coloring the links
  ;; deactivate all connected nodes since they are linked to an elected node.
  ask link-neighbors [
    set inactive? true
    set elected? false
    set same-degree? false
    recolor
  ]
  set msg (msg + degree)  ;; broadcast joining the mis to active nodes.
  recolor
end

to recolor
  ifelse elected? [set color green] [set color red]
end





; Public Domain:
; To the extent possible under law, Uri Wilensky has waived all
; copyright and related or neighboring rights to this model.
@#$#@#$#@
GRAPHICS-WINDOW
286
15
880
610
-1
-1
14.3
1
10
1
1
1
0
0
0
1
-20
20
-20
20
1
1
1
ticks
30.0

BUTTON
113
216
196
249
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
19
10
198
43
number-of-nodes
number-of-nodes
10
300
58.0
1
1
NIL
HORIZONTAL

BUTTON
21
216
98
249
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
34
50
172
95
edge-factor
edge-factor
3 7 15
2

MONITOR
38
379
166
424
maximum degree
max-degree
17
1
11

MONITOR
38
322
158
367
total messages
msg
17
1
11

SWITCH
25
102
175
135
circle-layout?
circle-layout?
1
1
-1000

MONITOR
38
439
168
484
deactivated nodes
count turtles with [inactive? = true]
17
1
11

CHOOSER
17
145
256
190
mode
mode
"Simple MIS" "Luby's" "Biology inspired" "Biology inspired Enhanced"
3

MONITOR
40
619
376
664
NIL
turtles with [inactive? = true and elected? = true]
17
1
11

MONITOR
39
554
218
599
elected neigbors
turtles with [elected? = true and any? link-neighbors with [elected? =  true]]
17
1
11

MONITOR
39
498
114
543
iterations
max [reps] of turtles
17
1
11

MONITOR
38
268
163
313
NIL
bits
17
1
11

@#$#@#$#@
## WHAT IS IT?

This example demonstrates how to make a network in NetLogo.  The network consists of a collection of nodes, some of which are connected by links.

This example doesn't do anything in particular with the nodes and links.  You can use it as the basis for your own model that actually does something with them.

## THINGS TO NOTICE

In this particular example, the links are undirected.  NetLogo supports directed links too, though.

## EXTENDING THE MODEL

Try making it so you can drag the nodes around using the mouse.

Use the turtle variable `label` to label the nodes and/or links with some information.

Try calculating some statistics about the network that forms, for example the average degree.

Try other rules for connecting nodes besides totally randomly.  For example, you could:

- Connect every node to every other node.
- Make sure each node has at least one link going in or out.
- Only connect nodes that are spatially close to each other.
- Make some nodes into "hubs" (with lots of links).

And so on.

Make two kinds of nodes, differentiated by color, then only allow links to connect two nodes that are different colors.  This makes the network "bipartite."  (You might position the two kinds of nodes in two straight lines.)

## NETLOGO FEATURES

Nodes and edges are both agents.  Nodes are turtles, edges are links.

## RELATED MODELS

* Random Network Example
* Fully Connected Network Example
* Preferential Attachment
* Small Worlds

<!-- 2004 -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Simple MIS" repetitions="10" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>msg</metric>
    <metric>bits</metric>
    <metric>max [reps] of turtles</metric>
    <enumeratedValueSet variable="number-of-nodes">
      <value value="50"/>
      <value value="150"/>
      <value value="300"/>
      <value value="550"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="circle-layout?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;Simple MIS&quot;"/>
      <value value="&quot;Luby's&quot;"/>
      <value value="&quot;Biology inspired&quot;"/>
      <value value="&quot;Biology inspired Enhanced&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="edge-factor">
      <value value="3"/>
      <value value="7"/>
      <value value="15"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
