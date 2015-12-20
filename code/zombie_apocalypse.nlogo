globals [turn-probability]

;; diggers are used only for setup
breed [ diggers ]
breed [ humans ]
breed [ zombies ]
breed [ military ]

humans-own [panic-time]
zombies-own [chasing-time lifespan ]
patches-own [fade-time]
turtles-own [generation paralysis-time kills]

to go
  set-current-plot "Population vs. time"
  set-current-plot-pen "Zombies"
  plot count zombies

  set-current-plot-pen "Military"
  plot count military

  set-current-plot-pen "Humans"
  plot count humans

  set-current-plot "Zombie lifespan"
  plot ifelse-value any? zombies [ mean [lifespan] of zombies / zombie-lifespan ] [0]

  ask patches with [fade-time > 0] [
    set fade-time fade-time - 1
    if-else fade-time <= 0 [ set pcolor black ] [ set pcolor scale-color red fade-time 0 120 ]
  ]

  ask military with [paralysis-time <= 0] [
    if (who - ticks) mod 5 = 0 [
      let beings-seen turtles in-cone vision-distance vision-angle with [self != myself]
      ;; run towards zombies
      ifelse any? beings-seen with [breed = zombies] [
        let target one-of beings-seen with [breed = zombies]
        face target
        step 1
      ] [
        ;; or failing that, towards the most panic
        if any? beings-seen with [breed = humans and panic-time > 0] [
          let target max-one-of beings-seen with [breed = humans and panic-time > 0] [panic-time]
          face target
          step 1
        ]
      ]

      if nukes-authorized? [
        let nuke-zone-seen turtles in-cone nuke-distance vision-angle with [breed = zombies]
        if count nuke-zone-seen > nuke-minimum-kill [
          detonate-nuke
        ]
      ]
    ]

    step-turnily 1

    set kills kills + count zombies-here

    ask zombies-here [ die ]

    ;; Military will recruit civilians back up to their starting population
    ;; aka "Hey you, here's a gun and a pocket nuke. Have fun."
    if random-float 100.0 < recruit-%age and  count military < num-military and any? humans-here [
      ask one-of humans-here [
        set breed military
        set color red
        set generation [generation] of myself + 1
      ]
    ]
  ]

  ask zombies with [paralysis-time <= 0] [
    ifelse chasing-time > 0 [
      set chasing-time chasing-time - 1
    ] [
      if random 4 = 0 [set heading random 360]
    ]

    if (who - ticks) mod 5 = 0 [
      let beings-seen turtles in-cone (vision-distance * zombie-acuteness) vision-angle with [self != myself]
      if any? beings-seen [
        let target one-of beings-seen
        face target
        set chasing-time 20
      ]
    ]

    ;; Zombies can break down walls if they're following something
    corrode-step 0.2 (random-float 100 < wall-break-%age and chasing-time > 0)

    if zombies-age? [
      set lifespan lifespan - 1
      if lifespan <= 0 [ die ]
    ]

    if any? turtles-here with [breed != zombies]
    [
      set kills kills + count turtles-here with [breed != zombies]
      ask turtles-here with [breed != zombies] [
        set paralysis-time nom-time
        set breed zombies
        set color green
        set lifespan zombie-lifespan
        set generation [generation] of myself + 1
      ]
      set lifespan lifespan + zombie-lifespan * nom-boost
      set paralysis-time nom-time
    ]
  ]

  ask humans with [paralysis-time <= 0] [
    step-turnily 1
    if panic-time > 0 [
       set panic-time panic-time - 1
       if panic-time = 0 [set color white - 4]
       step 1
    ]

    if (who - ticks) mod 5 = 0 [
      let beings-seen turtles in-cone vision-distance vision-angle with [self != myself and (breed = zombies or (breed = humans and panic-time > 0))]
      if any? beings-seen [
        lt 157.5 + random-float 45
        set color magenta + 3

        ;; panicked humans are infectious
        if any? beings-seen with [breed = humans and panic-time > 0] [
          set panic-time (max [panic-time] of beings-seen with [breed = humans])
        ]
        ;; oh noes teh zombie
        if any? beings-seen with [breed = zombies] [ set panic-time panic-duration ]
      ]

    ]

    if panic-time <= 0 and random-float 100 < breeding-%age and any? humans-here [
      hatch 1 [
        set generation [generation] of myself + 1
      ]
    ]
  ]

  ask turtles with [paralysis-time > 0] [
    set paralysis-time paralysis-time - 1
  ]

  tick
end

to detonate-nuke
  ask patches in-radius nuke-radius [
    ifelse random-float 1 > nuke-damage and ([pcolor] of one-of patches in-radius 3) != black [ set pcolor gray - 3 ] [ set fade-time 60 ]
  ]
  ask turtles in-radius nuke-radius [ die ]
end

;; Step without running into things.  dist, the distance to step, should not
;; exceed 1, else the turtle might jump through a wall.
to step [dist] ;; kludge for default parameter
  corrode-step dist false
end

to step-turnily [dist]
  corrode-step dist false
  if random-float 1 < turn-probability [ lt random-normal 0 60 ]
end

to corrode-step [dist corrode]
  if [pcolor] of patch-ahead dist != black [
    ;; Turn so that we're facing parallel to the wall, ie. find the black neighbouring
    ;; patch closest to where we would have gone (at distance 1), and turn to face it.
    if-else corrode [
      ask patch-ahead dist [ set pcolor black ]
    ][
      let x dx + xcor
      let y dy + ycor
      if not any? neighbors with [pcolor = black] [die]
      face min-one-of neighbors with [pcolor = black] [distancexy x y]
    ]
  ]
  fd dist
end

;; doesn't quite always uninfect, if num-zombies was increased
to uninfect
  ;; Reduce the number of zombies to num-zombies.
  ask zombies with [who >= num-zombies] [
    set breed humans
    set color magenta
  ]
  ask humans with [who < num-zombies] [
    set breed zombies
    set color green
  ]
end

to setup
  setup-town
  setup-beings

  ;; globals
  set turn-probability 1 / 60.0
end

to setup-beings
  ct
  ;; this stuff is in this function just so it always happens
  clear-all-plots

  reset-ticks

  ;; Zombies get the earliest who numbers; we use this elsewhere.
  ;; Make sure the beings are on non-built squares.
  create-zombies num-zombies [
    set color green
    set lifespan zombie-lifespan
  ]

  create-humans num-humans [
    set color white - 4
  ]

  create-military num-military [
    set color red
  ]

  ask turtles [
    setxy random-float world-width random-float world-height
    set heading random-float 360
    set paralysis-time 0
    set generation 0
    set kills 0
    while [pcolor != black] [fd 1]
  ]
end

to setup-town
  cp
  ask patches [
    set pcolor gray - 3
    set fade-time 0
  ]

  ;; Make the alleyways.  Instead of the rectangle-placing approach, which proves slow,
  ;; let a special kind of turtle dig them.
  ;; The number of diggers here and later will need changing if the screen size is changed.
  ct
  create-diggers 154;; 112

  ;; Set the diggers up in pairs facing away from each other, so we don't get dead end passages
  ask diggers with [who mod 2 = 0] [
    setxy random-float world-width random-float world-height
    set heading 90 * random 4
  ]
  ask diggers with [who mod 2 = 1] [
    setxy [xcor] of turtle (who - 1) [ycor] of turtle (who - 1)
    set heading 180 + [heading] of turtle (who - 1)
    fd 1
  ]

  ask diggers [
    while [pcolor != black] [
      set pcolor black
      fd 1
      if random-float 1 < (1 / 30) [lt 90 + 180 * random 2]
    ]
  ]

  ;; Make the squares, by getting a few diggers to dig them out.
  ct
  create-diggers num-squares [
    setxy random-float world-width random-float world-height
    let xsize 2 + random 60
    let ysize 2 + random 60
    foreach n-values xsize [?] [
      let x ?
      foreach n-values ysize [?] [ask patch-at x ? [set pcolor black]]
    ]
  ]

  ct
end
@#$#@#$#@
GRAPHICS-WINDOW
561
10
1189
659
154
154
2.0
1
10
1
1
1
0
1
1
1
-154
154
-154
154
0
0
1
ticks

CC-WINDOW
5
673
1198
768
Command Center
0

SLIDER
17
90
189
123
num-humans
num-humans
0
6144
665
1
1
NIL
HORIZONTAL

SLIDER
17
127
189
160
num-zombies
num-zombies
0
64
20
1
1
NIL
HORIZONTAL

BUTTON
17
10
83
43
NIL
setup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
211
10
274
43
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

BUTTON
86
10
200
43
NIL
setup-beings
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

MONITOR
204
342
267
387
zombies
count zombies
3
1
11

MONITOR
204
295
267
340
humans
count humans
3
1
11

PLOT
17
435
538
657
Population vs. time
Time
Population
0.0
512.0
0.0
32.0
true
false
PENS
"Zombies" 1.0 0 -10899396 true
"Military" 1.0 0 -2674135 true
"Humans" 1.0 0 -7500403 true

MONITOR
361
295
429
340
panicked %
100 * count humans with [panic-time > 0] / count humans
0
1
11

SLIDER
17
198
189
231
num-military
num-military
0
64
10
1
1
NIL
HORIZONTAL

MONITOR
204
388
267
433
military
count military
0
1
11

SWITCH
329
198
478
231
nukes-authorized?
nukes-authorized?
0
1
-1000

BUTTON
278
10
341
43
step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

SLIDER
147
232
257
265
nuke-distance
nuke-distance
1
20
5
1
1
NIL
HORIZONTAL

SLIDER
260
232
391
265
nuke-minimum-kill
nuke-minimum-kill
1
20
3
1
1
NIL
HORIZONTAL

SLIDER
395
232
498
265
nuke-radius
nuke-radius
0
60
25
1
1
NIL
HORIZONTAL

SLIDER
193
90
326
123
panic-duration
panic-duration
0
50
20
1
1
NIL
HORIZONTAL

SLIDER
193
198
326
231
recruit-%age
recruit-%age
0
100
3.8
0.2
1
NIL
HORIZONTAL

SLIDER
193
127
326
160
wall-break-%age
wall-break-%age
0
100
10
0.2
1
NIL
HORIZONTAL

SLIDER
329
127
474
160
zombie-acuteness
zombie-acuteness
0
4
1.5
0.01
1
NIL
HORIZONTAL

SLIDER
18
55
164
88
num-squares
num-squares
0
112
48
1
1
NIL
HORIZONTAL

SWITCH
22
161
148
194
zombies-age?
zombies-age?
1
1
-1000

SLIDER
150
161
293
194
zombie-lifespan
zombie-lifespan
50
5000
1500
1
1
NIL
HORIZONTAL

SLIDER
329
161
421
194
nom-time
nom-time
0
200
10
1
1
NIL
HORIZONTAL

SLIDER
23
232
145
265
nuke-damage
nuke-damage
0
1
0.33
0.01
1
NIL
HORIZONTAL

PLOT
17
313
199
433
Zombie lifespan
Time
Avg left
0.0
512.0
0.0
1.0
true
false
PENS
"default" 1.0 0 -16777216 false

MONITOR
362
388
412
433
avg kills
mean [kills] of military
2
1
11

MONITOR
362
342
412
387
avg kills
mean [kills] of zombies
2
1
11

MONITOR
413
342
487
387
avg lifespan
mean [lifespan] of zombies
0
1
11

SLIDER
423
161
529
194
nom-boost
nom-boost
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
169
55
290
88
vision-distance
vision-distance
1
100
10
1
1
NIL
HORIZONTAL

SLIDER
292
55
395
88
vision-angle
vision-angle
1
360
90
1
1
NIL
HORIZONTAL

SLIDER
328
90
474
123
breeding-%age
breeding-%age
0
1
0
0.001
1
NIL
HORIZONTAL

MONITOR
269
295
360
340
avg generation
mean [generation] of humans
2
1
11

MONITOR
269
342
360
387
avg generation
mean [generation] of zombies
2
1
11

MONITOR
269
388
360
433
avg generation
mean [generation] of military
2
1
11

@#$#@#$#@
WHAT IS IT?
-----------
This is a simulation of a town in which a zombie infection arises.  The first version was a moderately faithful rewrite of Kevan Davis' Zombie Infection Simulation in NetLogo; since then we've added a lot of functionality.

HOW IT WORKS
------------
Zombies are green, shamble around very slowly and change direction randomly and frequently unless they can see something moving in front of them, in which case they start walking towards it. After a while they get bored and wander randomly again.

If a zombie finds a human on the same patch, it infects them; the human immediately joins the ranks of the undead.

Humans are lightish gray and walk five times as fast as zombies, changing direction when they run into a wall, and sporadically otherwise.  If they see a zombie in front of them, they turn around and panic.

Panicked humans are pink and run twice as fast as other humans. If a human sees another panicked human, it starts panicking as well. A panicked human who has seen nothing to panic about for a while will calm down again.

The military are red and move as regular humans do, unless they see a zombie or panicked human, which they will run towards.  A member of the military will kill any zombies on a patch they walk into.  Further options are open to the military if authorised:
* they may detonate a pocket nuke if they see sufficiently many zombies, immolating all life (undead included) in the blast radius and damaging buildings.
* they may recruit ordinary humans, up to the originally specified size of the force.

HOW TO USE IT
-------------
Press SETUP to create and populate a new city.
Press SETUP-BEINGS to place the beings while retaining the current city.
GO, as usual, runs the model.  STEP runs it for one step.

Parameters:

*Town parameters* (only takes effect on SETUP)
NUM-SQUARES: number of open areas in the city

*Initial populations* (only takes effect on SETUP or SETUP-BEINGS)
NUM-HUMANS: number of humans
NUM-ZOMBIES: number of zombies
NUM-MILITARY: number of military (changing RECRUIT-%AGE looks at this in real time, though)

*Perception*
VISION-DISTANCE: baseline distance which creatures can sense (see/hear/smell/...) other creatures in
ZOMBIE-ACUTENESS: multiplier to this distance for zombies
VISION-ANGLE: angle of the sensory cone

*Human-specific behaviour*
PANIC-DURATION: how long humans panic upon seeing something frightening
BREEDING-%AGE: how likely two humans meeting are to procreate (immediately!)

*Zombie-specific behaviour*
WALL-BREAK-%AGE: how likely a zombie sensing something across a wall is to smash through
NOM-TIME: how long a zombie takes to consume its prey's brains
ZOMBIES-AGE?: if on, zombies become decrepit and eventually cease to exist with the passage of time
ZOMBIE-LIFESPAN: if aging is on, how long a new zombie can expect to live, unfed
NOM-BOOST: if aging is on, the extension catching a victim provides to a zombie's lifespan, as a fraction of ZOMBIE-LIFESPAN

*Military-specific behaviour*
RECRUIT-%AGE: how likely the military are to recruit humans into the military.  The military will never expand past NUM-MILITARY members (one imagines they have a finite supply of guns, or badges, or whatnot.)
NUKES-AUTHORIZED?: can the military use their pocket nukes?
NUKE-RADIUS: the blast radius of pocket nukes
NUKE-DAMAGE: how damaging the nukes are to buildings (they always annihilate all creatures in their radius)
NUKE-DISTANCE:
NUKE-MINIMUM-KILL: military will only use pocket nukes if they think there are NUKE-MINIMUM-KILL zombies within NUKE-DISTANCE.

SIGNIFICANT DIFFERENCES FROM KEVAN'S
------------------------------------
The model of space is the standard NetLogo model, in which space and direction are both continuous.  Thus, for instance, it's more reasonable for humans to keep
running in straight lines when nothing is in their way; they don't miss entrances to small passages or cluster as much as they would in the discrete grid-based model.

Beings' fields of vision are cones with 90 degree width instead of just the lines directly ahead.  These fields of vision go through walls (I guess the beings can hear, or smell, or something).

The city wraps around unless you change the model topology; again, this is more natural in NetLogo than it might be in proce55ing.

Arbitrarily many beings may occupy one patch.

The city is carved out differently: although it has the same general feel, more types of passages can occur, for instance zig-zags:
| *****************
|                 *
|                 *
|                 *
|                 *****************

Beings only look ahead of themselves every fifth time step.  This was done to speed the model up, and appears to have no significant effects on the simulation.

THINGS TO NOTICE
----------------
Infection takes place much more slowly, in terms of simulation timesteps, than in the original model.

In zombie-dominated areas of the city, the zombies tend to form into lines (in the original model, we instead observe blobs).

THINGS TO TRY
-------------
In general: when do humans win, when do zombies win?  Find combinations of settings that make it a fair fight.  (E.g. does zombie wall-breaking actually help the zombie side?  Do zombies do better when they sit in wait in their corridors, or destroy them digging out to where the brains are?)

What population density does panic need to be self-sustaining?

Make everyone a zombie, let zombies break walls 100% of the time, and watch the zombie streamers.

Play with NetLogo perspective features like watch and follow.

Resize the city, using the Edit button on the city display.  This will probably require adjusting the numbers in the setup-town procedure to get the same overall proportion of open space.

EXTENDING THE MODEL
-------------------
You've seen at least as many zombie movies as I have...

These extensions are more like bug-fixes:
- Ensure that there are no completely isolated spaces without entrances or exits when the city is created.
- Make the walls actually opaque?  (This will probably be a mess, since there is no support for this among the NetLogo agentset reporters like in-cone.)

And, of course, it would be nice to make it run faster.

NETLOGO FEATURES
----------------
The tunnels in the city are carved by a dedicated breed of turtle (an initial attempt to generate them with patch agentsets proved horribly slow).

I like the way beings reorient themselves after hitting a wall -- they can even follow tunnels with no special case movement rules.

Building damage after a nuke is implemented by having each patch in the blast radius
change to open space with a constant probability, otherwise change its state to that of a random neighbour in a small radius.  This nicely and quickly simulates rubble getting blown about.

Beings never move by more than distance 1 at a time, to prevent them from jumping through walls.



CREDITS AND REFERENCES
----------------------
Alex Fink and Sai Emrys, this version
AF, the first version, Jan 2006

Kevan Davis' original Zombie Infection Simulation, version 2.3:
http://kevan.org/proce55ing/zombies/

NetLogo zombie simulators seem to've become popular in these last few years;
one might also check out Asymptote's one,
http://ccl.northwestern.edu/netlogo/models/community/Zombie_Infection_2
and Marcel Jira's ones,
http://web.student.tuwien.ac.at/~e0250890/netlogo/ .
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

link
true
0
Line -7500403 true 150 0 150 300

link direction
true
0
Line -7500403 true 150 150 30 225
Line -7500403 true 150 150 270 225

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
NetLogo 4.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
