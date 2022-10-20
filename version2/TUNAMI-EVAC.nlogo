extensions [gis pathdir vid]

__includes [ "Rayleigh2011.nls" "Astar2011.nls"]

;;***********************************************************************************************
;; DECLARING VARIABLES
;;***********************************************************************************************
;; GLOBAL VARIABLES

globals [ land-patches
          urban-patches
          sea-patches
          street-patches
          exit-patches
          teb-patches
          teb-capacity
          exit-capacity
          tsu-counter
          tsunami-file-name
          Cmax-ped
          Cmax-car

          decided-peds
          decided-cars

          safe-peds
          safe-cars

          casualty-peds
          casualty-cars

          pop-peds
          pop-cars
        ]

breed [ peds ped ]
breed [ cars car]

peds-own [ dim speed handicap stage path ini goal L heuri td age ]
cars-own [ dim speed handicap stage path ini goal L heuri td ]

patches-own [ zt ]

;;************************************************************************************************
;; INITIAL CONDITIONS
;;************************************************************************************************ SETUP

to setup
  clear-all
  reset-ticks
  set-initial-values
  load-spatial
  load-population
  display
end

;;************************************************************************************************ SETUP 2

to reload
  reset-timer
  clear-turtles
  clear-output
  clear-globals
  reset-ticks
  set-initial-values
  load-population
end

;;************************************************************************************************ INITIAL VALUES

to set-initial-values
  random-seed seed
  set-default-shape turtles "dot"
  set decided-peds 0
  set decided-cars 0
  set safe-peds 0
  set safe-cars 0
  set casualty-peds 0
  set casualty-cars 0
  set pop-peds 0
  set pop-cars 0
  set teb-capacity [ ]
  set exit-capacity [ ]
  ;set scale 5  ;--> very important parameter!
  set Cmax-ped ceiling (0.7 * scale ^ 2)
  set Cmax-car ceiling (0.07 * scale ^ 2)
  if tsunami? [set tsu-counter 53900] ;<------------------------------------------------------------------------------------------CHANGE!!!
  if movie? [ vid:reset-recorder vid:start-recorder];v.4.1 ->  movie-set-frame-rate movie-frame-rate] let name (word movie-name ETA ".mp4") vid:movie-open name
  ask patches [set plabel "" set plabel-color black set zt -99]
  let dir-temp (word pathdir:get-model-path "//Output")
  set-current-directory dir-temp
  file-close-all
  file-open (word "Evacuation-Record" run-number ".txt")
  file-print "id,x-ini,y-ini,x-goal,y-goal,x-end,y-end,L0-path,L1-path,td,tsh,zt,C"
  file-close
  set-current-directory pathdir:get-model-path
end

;;************************************************************************************************ LOAD SPATIAL

to load-spatial
  ;resizing the world
  let x (1320 / scale) - 1
  let y (-1) * ((1150 / scale) - 1)
  resize-world 0 x y 0 ;Original 1320x1150

  if scale = 5
  [ set-patch-size 3 ]
  if scale = 2
  [ set-patch-size 1 ] ;this is the scale 2mx2m grid

  ;loading GIS data
  let dir-temp word pathdir:get-model-path "//SpatialDB"
  set-current-directory dir-temp
;  gis:set-coordinate-system "WGS 84"
;  gis:load-coordinate-system "Projection.prj"
  let Land gis:load-dataset "land.geojson"
  let Urban gis:load-dataset "urban.geojson"
  let Streets gis:load-dataset "streets.geojson"
  let Sea gis:load-dataset "sea.geojson"
  let Exit-dataset gis:load-dataset "exits.geojson"
  let TEB-dataset gis:load-dataset "teb.geojson"
  let pop-dataset gis:load-dataset "census_clip.geojson"

  gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of Land)
                                                (gis:envelope-of Urban)
                                                (gis:envelope-of Streets)
                                                (gis:envelope-of Sea)
                                                (gis:envelope-of Exit-dataset)
                                                (gis:envelope-of TEB-dataset)
                                                (gis:envelope-of pop-dataset))

  set land-patches patches gis:intersecting land
  set urban-patches patches gis:intersecting urban
  gis:set-drawing-color gray
  gis:fill urban 0.1
  gis:set-drawing-color blue
  gis:fill sea 0.1
  set street-patches patches gis:intersecting streets
  set exit-patches patches gis:intersecting exit-dataset
  set teb-patches patches gis:intersecting teb-dataset

  ask land-patches [ set pcolor white ]
  ask street-patches [ set pcolor green ]
  ask exit-patches [ sprout 1 [set color violet set size 4 set shape "circle" stamp die]
                     set exit-capacity lput (list self 0) exit-capacity ]
  foreach gis:feature-list-of teb-dataset
  [ feat -> ask patches gis:intersecting feat [ sprout 1 [set color violet set size 4 set shape "circle" stamp die]
                                     set teb-capacity lput (list self 0) teb-capacity ;gis:property-value ? "capacity") teb-capacity
                                   ]
  ]
  set-current-directory pathdir:get-model-path
  output-print (word "Spatial data: " timer " sec.")
  reset-timer
end

;;************************************************************************************************ LOAD POPULATION

to load-population
  let dir-temp word pathdir:get-model-path "//SpatialDB"
  set-current-directory dir-temp
  let dataset gis:load-dataset "census_clip.geojson"

  foreach gis:feature-list-of dataset [ this-vector-feature ->
    gis:create-turtles-inside-polygon this-vector-feature peds round read-from-string gis:property-value this-vector-feature "8" [
      move-to one-of urban-patches with-min [distance myself]
      set dim 1.0
      set speed 1.0 * 1.33 / scale
      set color black
      set size ( 1 / scale * dim ) * scale * 5
      let s-shapes [ ]
      let str 0
      let nd 0
      ifelse u < ETA
      [ set str u set nd ETA]
      [ set str ETA set nd u]
      while [ str <= nd]
        [ set s-shapes lput str s-shapes
          set str str + 1 ]
      set td floor ( random-td-rayleigh random-float 1 one-of s-shapes )
      set heuri random 5
      set ini patch-here
      set goal patch-here
    ]
  ]

  create-cars #-of-cars     [ set dim 1.2 set speed 1.0 * 1.68 / scale] ;same speed but 5 times running
  ask cars [ move-to one-of street-patches
    set color magenta
    set size ( 1 / scale * dim ) * scale * 5
    let s-shapes [ ]
    let str 0
    let nd 0
    ifelse u < ETA
    [ set str u set nd ETA]
    [ set str ETA set nd u]
    while [ str <= nd]
      [ set s-shapes lput str s-shapes
        set str str + 1 ]
    set td floor (random-td-rayleigh random-float 1 one-of s-shapes)
    ;if td < 5 [ set td random one-of s-shapes ]
    set heuri random 5
    set ini patch-here
    set goal patch-here
    ;set shape "car"
  ]
  let p round ( %-of-handicap * count peds / 100 )
  ask n-of p peds [ set handicap true set speed speed * 0.5 ]
  set pop-peds count peds
  set pop-cars count cars
  update-text
  if movie? [vid:record-view];[movie-grab-interface];
  output-print (word "Population data: " timer " sec.")
  set-current-plot "Preparation time"
  histogram [td] of turtles
  set-current-directory pathdir:get-model-path
end

;to load-population
;  create-peds #-of-peds [ set dim 1.0 set speed 1.0 * 1.33 / scale]
;  create-cars #-of-cars     [ set dim 1.2 set speed 1.0 * 1.68 / scale] ;same speed but 5 times running
;  ask peds [ move-to one-of urban-patches
;                    set color black
;                    set size ( 1 / scale * dim ) * scale * 5
;                    let s-shapes [ ]
;                    let str 0
;                    let nd 0
;                    ifelse u < ETA
;                    [ set str u set nd ETA]
;                    [ set str ETA set nd u]
;                    while [ str <= nd]
;                     [ set s-shapes lput str s-shapes
;                       set str str + 1 ]
;                    set td floor ( random-td-rayleigh random-float 1 one-of s-shapes )
;                    set heuri random 5
;                    set ini patch-here
;                    set goal patch-here
;                  ]
;
;  ask cars [ move-to one-of street-patches
;             set color magenta
;             set size ( 1 / scale * dim ) * scale * 5
;             let s-shapes [ ]
;                    let str 0
;                    let nd 0
;                    ifelse u < ETA
;                    [ set str u set nd ETA]
;                    [ set str ETA set nd u]
;                    while [ str <= nd]
;                     [ set s-shapes lput str s-shapes
;                       set str str + 1 ]
;             set td floor (random-td-rayleigh random-float 1 one-of s-shapes)
;             ;if td < 5 [ set td random one-of s-shapes ]
;             set heuri random 5
;             set ini patch-here
;             set goal patch-here
;             ;set shape "car"
;           ]
;  let p round ( %-of-handicap * count peds / 100 )
;  ask n-of p peds [ set handicap true set speed speed * 0.5 ]
;  set pop-peds count peds
;  set pop-cars count cars
;  update-text
;  if movie? [vid:record-view];[movie-grab-interface];
;  output-print (word "Population data: " timer " sec.")
;  set-current-plot "Preparation time"
;  histogram [td] of turtles
;end

;;************************************************************************************************
;; MAIN PROGRAM
;;************************************************************************************************ MAIN PROG. (GO)

to go
if ticks = 0 [reset-timer no-display]
ask turtles
[ t.decide-to-start
  t.decide-shelter
  t.search-road
  ifelse breed != cars
  [ t.follow-path ]
  [ repeat 5 [ t.follow-path] ]
  t.search-shelter-route
]
if tsunami? [if ticks >= (65 * 60) [tsunami-run]  ]
outputs
update-text
if ticks mod movie-interval = 0 and movie? [vid:record-view];[movie-grab-interface];
if ticks mod (10 * 60) = 0 and snapshots? [do-snapshots]
if ticks mod (5 * 60) = 0 and snapshots? [ display export-interface (word "Model_" run-number "_K" ticks ".png") no-display ]
tick
do-plots
if ticks = (TS * 60)
   [ output-print (word "Total time:" timer " sec.")
     if output-files?
       [ let dir-temp (word pathdir:get-model-path "//Output")
         set-current-directory dir-temp
         let name (word "Safe_" run-number ".csv")
         export-plot "Safe" name
         set name (word "Casualty_" run-number ".csv")
         export-plot "Casualty" name
         ;set name "Monitor.csv"
         ;export-output name
         set name (word "TEBs_" run-number ".csv")
         export-plot "TEBs" name
         set-current-directory pathdir:get-model-path
       ]
       if movie? [vid:record-view let name (word movie-name ETA ".mp4") vid:save-recording name];[movie-grab-interface movie-close];
       display
       export-interface (word "Model_" run-number "_K" ticks ".png")
       do-snapshots
       no-display
       stop
    ]

end

;;************************************************************************************************ START DECISION

to t.decide-to-start
if stage = 0 and ( ticks = ( td * 60 ) )
                  [ set stage 1
                    if breed = peds [ set decided-peds decided-peds + 1]
                    if breed = cars [ set decided-cars decided-cars + 1 ]
                   ]
end

;;************************************************************************************************ SHELTER DECISION

to t.decide-shelter
if stage = 1 [ ifelse random-shelter?
                 [ set goal one-of teb-patches ]
                 [ set goal one-of teb-patches with-min [distance myself] ]
               ifelse breed != cars
                 [ set stage 2 ]
                 [ if random-float 1 < 0.68 ;this means 68% probability of true
                   [ ifelse random-shelter?
                     [ set goal one-of exit-patches ]
                     [ set goal one-of exit-patches with-min [distance myself] ]
                     set stage 4
                   ]
                 ]
              ]
end

;;************************************************************************************************ ROAD SEARCH

to t.search-road
if stage = 2 [ let road-1 distance min-one-of patches with [pcolor = green] [distance myself]
               let road-2 distance min-one-of exit-patches [distance myself]
               let road nobody
               ifelse road-1 < road-2
                  [ set road min-one-of patches with [pcolor = green] [distance myself] set stage 3]
                  [ set road min-one-of exit-patches [distance myself]
                    set goal road
                    set stage 5 ]
               set path Astar patch-here road white 4
             ]
end

;;************************************************************************************************ MOVE

to t.follow-path
if stage = 3 [ ifelse not empty? path
               [ let next first path
                 face next
                 if r.topology?-to-street next
                 [ fd adjust-speed ]
                 if patch-here = next
                 [ set path but-first path ]
               ]
               [ set stage 4 ]
]

if stage = 5 [ ifelse not empty? path
               [ let next first path
                 face next
                 if r.topology?-on-street next
                 [ fd adjust-speed ]
                 if patch-here = next
                 [ set path but-first path ]
               ]
               [ if patch-here = goal [ if breed = peds [ set safe-peds safe-peds + 1 ]
                                        if breed = cars [ set safe-cars safe-cars + 1 ]
                                        adjust-teb-capacity
                                        export-record
                                        die ]
               ]
]
end

;;************************************************************************************************ SHELTER SEARCH

to t.search-shelter-route
  if stage = 4 [ set path [ ]
                 if breed = cars  ; --> correcting a pedestrian bridge, this should be corrected with a street shape for car and street shape for pedestrians
                 [ ask patch 164 -132 [ set pcolor white]
                   ask patch 165 -131 [ set pcolor white]
                   ask patch 165 -132 [ set pcolor white]
                   ask patch 166 -131 [ set pcolor white]
                   ask patch 166 -132 [ set pcolor white]
                 ]
                 set path Astar patch-here goal green 4
                 set L length path
                 set stage 5
                 if breed = cars
                 [ ask patch 164 -132 [ set pcolor green]
                   ask patch 165 -131 [ set pcolor green]
                   ask patch 165 -132 [ set pcolor green]
                   ask patch 166 -131 [ set pcolor green]
                   ask patch 166 -132 [ set pcolor green]
                 ]
               ]
end

;;************************************************************************************************
;;************************************************************************************************ REPORTERS

to-report adjust-speed
let s 0
ifelse breed != cars
[ let pedestrians (turtle-set other peds in-cone ( 5 / scale) 60 )
  let p count pedestrians with [td > [td] of self]
  let a (((pi / 3) * 5 ^ 2) / 2)
  let d p / a
  set s precision ((1 / SQRT(2 * PI * 0.3 ^ 2 )) * EXP(-((d - 0) ^ 2) / (2 * 0.3 ^ 2))) 2
]
[ let ahead-cars (turtle-set other cars in-cone ( 10 / scale) 60 )
  let p count ahead-cars with [td <= [td] of self ]
  let a (((pi / 3) * 10 ^ 2) / 2)
  let d p / a
  set s precision ((1 / SQRT(2 * PI * 0.047 ^ 2 )) * EXP(-((d - 0) ^ 2) / (2 * 0.047 ^ 2)) / 5.0 ) 2  ;/5.0 because is repeated 5 times every second of computation
]
set s s / scale
report s
end

to-report r.topology?-on-street [next]
ifelse ( breed != cars )
 [ let pedestrians (turtle-set other peds in-cone ( 5 / scale) 60 )
   ifelse next != nobody and count pedestrians with [td <= [td] of self and next != patch-here] < Cmax-ped
     [ set color black report true  ]
     [ set color white stamp
       report false ]
 ]
 [ let ahead-cars (turtle-set other cars in-cone (10 / scale) 60)
   ifelse next != nobody and count ahead-cars with [td <= [td] of self and next != patch-here] < Cmax-car ;not include pedestrians cars in road
     [ set color magenta report true  ]
     [ set color white stamp
       report false ]
 ]
end

;;************************************************************************************************

to-report r.topology?-to-street [next]
   let pedestrians (turtle-set other peds in-cone ( 5 / scale) 60 )
   ifelse next != nobody and count pedestrians with [td <= [td] of self and next != patch-here] < Cmax-ped
     [ set color black report true  ]
     [ set color white stamp
       report false ]
end

;;************************************************************************************************

to do-snapshots
let dir-temp (word pathdir:get-model-path "//Output")
set-current-directory dir-temp
let name (word run-number "K_" ticks ".png")
export-view name
set-current-directory pathdir:get-model-path
end

;;************************************************************************************************

to adjust-teb-capacity
ifelse not member? patch-here exit-patches
[ let new-teb [ ]
  let pos 0
  foreach teb-capacity
  [ t -> if goal = item 0 t
     [ let cap item 1 t
       ifelse breed = cars
       [ set cap cap + 4 ]
       [ set cap cap + 1 ]
       set new-teb replace-item 1 t cap
       set pos position t teb-capacity
     ]
  ]
  set teb-capacity replace-item pos teb-capacity new-teb
]
[ let new-exit [ ]
  let pos 0
  foreach exit-capacity
  [ x -> if goal = item 0 x
     [ let cap item 1 x
       ifelse breed = cars
       [ set cap cap + 4 ]
       [ set cap cap + 1 ]
       set new-exit replace-item 1 x cap
       set pos position x exit-capacity
     ]
  ]
  set exit-capacity replace-item pos exit-capacity new-exit
]
end

;;************************************************************************************************

to update-text
if scale = 5
[ ask patch 185 -210 [set plabel title]
  ask patch 185 -220 [set plabel (word "TIME: " round (ticks / 60) " min." )]
]
if scale = 2
[ ask patch 645 -515 [set plabel title]
  ask patch 645 -535 [set plabel (word "TIME: " round (ticks / 60) " min." )]
]
end

;;************************************************************************************************

to-report clock
let minutes floor (ticks / (60 ))
let seconds floor (((ticks / (60 )) - (floor (ticks / (60 )))) * (60))
report (word  minutes " min. " seconds " secs.")
end

;;************************************************************************************************

to do-plots
set-current-plot "Decision"
if pop-peds > 0
[ set-current-plot-pen "peds"
  plot (decided-peds / pop-peds) * 100
]
if pop-cars > 0
[ set-current-plot-pen "cars"
  plot (decided-cars / pop-cars) * 100
]

set-current-plot "Safe"
if pop-peds > 0
[ set-current-plot-pen "peds"
  plot (safe-peds / pop-peds) * 100
]
if pop-cars > 0
[ set-current-plot-pen "cars"
  plot (safe-cars / pop-cars) * 100
]

set-current-plot "Casualty"
if pop-peds > 0
[ set-current-plot-pen "peds"
  plot (casualty-peds / pop-peds) * 100
]
if pop-cars > 0
[ set-current-plot-pen "cars"
  plot (casualty-cars / pop-cars) * 100
]

set-current-plot "TEBs"
set-current-plot-pen "TEB#1_1"
plot (item 1 item 0 teb-capacity)
set-current-plot-pen "TEB#1_2"
plot (item 1 item 1 teb-capacity)
set-current-plot-pen "Exit#1"
plot (item 1 item 0 exit-capacity)
set-current-plot-pen "Exit#2"
plot (item 1 item 1 exit-capacity)
end

;;************************************************************************************************

to outputs
  ask cars [
    if [zt] of patch-here > 0.50
    [ set casualty-cars casualty-cars + 1      ;(Suga, 1995 in Yasuda, 2004)
      set color red
      stamp
      export-record
      die ]
  ]
  ask peds [
    let HZ [zt] of patch-here
    if HZ >= 0
    [ ifelse HZ <= 0.85
      [ let z -12.37 + 22.036 * [zt] of patch-here + 11.517 * 2.0  ;average velocity 1.80m/s from TUNAMI
        let fz 1 / ( 1 + exp (15.48 - z) )
        if fz > 0.50
        [ set casualty-peds casualty-peds + 1 ]
      ]
      [ set casualty-peds casualty-peds + 1
      ]
      set color red
      stamp
      export-record
      die
    ]
  ]
end

;;************************************************************************************************

to export-record ;turtle procedure
  let dir-temp (word pathdir:get-model-path "//Output")
  set-current-directory dir-temp
  file-close-all
  file-open (word "Evacuation-Record" run-number ".txt")
  ifelse [color] of self = red
  [ set stage 1 ]
  [ set stage 0 ]
  if path = 0
  [set path [ ]]
  file-print (word self "," [pxcor] of ini "," [pycor] of ini "," [pxcor] of goal "," [pycor] of goal "," [pxcor] of patch-here "," [pycor] of patch-here "," L "," (L - length path) "," td ","
                   precision (ticks / 60) 1 "," [zt] of patch-here "," stage ) ;stage=0 safe stage=1 casualty
  file-close
  set-current-directory pathdir:get-model-path
end

;;************************************************************************************************

to tsunami-run
   let dir-temp word pathdir:get-model-path "//TsunamiDB"
   set-current-directory dir-temp
   set tsunami-file-name (word "out" tsu-counter ".asc")
   let inundation gis:load-dataset tsunami-file-name
   gis:set-world-envelope-ds (gis:envelope-of inundation)
   gis:apply-raster inundation zt
   ask patches with [zt > 0] [ set pcolor scale-color blue zt 20 -20 ]
   display
   no-display
   set tsu-counter tsu-counter + 1 ;because data is at 0.5s output
   set-current-directory pathdir:get-model-path
end
@#$#@#$#@
GRAPHICS-WINDOW
297
10
1097
709
-1
-1
3.0
1
10
1
1
1
0
0
0
1
0
263
-229
0
1
1
1
ticks
30.0

BUTTON
228
46
291
79
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
1

BUTTON
217
10
291
43
NIL
reload
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
151
10
214
43
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

TEXTBOX
9
13
159
41
press SETUP only when open first time, then use RELOAD
11
0.0
1

SWITCH
10
325
157
358
movie?
movie?
0
1
-1000

INPUTBOX
8
45
225
105
title
\"Arahama Model\"
1
0
String

INPUTBOX
10
360
103
420
movie-name
Model_Test
1
0
String

SWITCH
163
230
295
263
random-shelter?
random-shelter?
1
1
-1000

INPUTBOX
8
106
81
168
#-of-cars
50.0
1
0
Number

SWITCH
163
265
295
298
tsunami?
tsunami?
0
1
-1000

SWITCH
10
291
159
324
output-files?
output-files?
0
1
-1000

PLOT
1108
287
1429
514
Safe
time (s)
%safe
0.0
1800.0
0.0
100.0
true
true
"" ""
PENS
"peds" 1.0 0 -955883 true "" ""
"cars" 1.0 0 -5825686 true "" ""

PLOT
1109
516
1429
731
Casualty
time (s)
%casualty
0.0
1800.0
0.0
100.0
true
true
"" ""
PENS
"peds" 1.0 0 -955883 true "" ""
"cars" 1.0 0 -5825686 true "" ""

SWITCH
162
299
296
332
snapshots?
snapshots?
0
1
-1000

INPUTBOX
10
421
107
481
movie-frame-rate
10.0
1
0
Number

INPUTBOX
196
361
291
421
movie-interval
5.0
1
0
Number

TEXTBOX
113
431
289
473
(Only v 4.1) when making movie \"movie-frame-rate\" numbers of frames are compress in one second of movie
11
0.0
1

PLOT
1108
51
1429
287
Decision
time (s)
%decision
0.0
1800.0
0.0
100.0
true
true
"" ""
PENS
"peds" 1.0 0 -955883 true "" ""
"cars" 1.0 0 -5825686 true "" ""

TEXTBOX
1218
20
1344
38
OUTPUT PLOTS
11
0.0
1

INPUTBOX
111
230
161
290
TS
70.0
1
0
Number

PLOT
10
483
289
649
Preparation time
t (min)
#evacs
0.0
60.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" ""

PLOT
1434
53
1668
203
TEBs
time (s)
Capacity
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"TEB#1_1" 1.0 0 -16777216 true "" ""
"TEB#1_2" 1.0 0 -7500403 true "" ""
"Exit#2" 1.0 0 -955883 true "" ""
"Exit#1" 1.0 0 -13345367 true "" ""

MONITOR
1435
206
1507
251
Evacuated
safe-peds + (safe-cars * 4)
17
1
11

MONITOR
1435
252
1507
297
Casualties
casualty-peds + (casualty-cars * 4)
17
1
11

INPUTBOX
60
230
110
290
ETA
67.0
1
0
Number

MONITOR
1510
205
1567
250
Exit#1
(item 1 item 0 exit-capacity)
17
1
11

MONITOR
1511
252
1568
297
TEB#1
(item 1 item 0 teb-capacity) + (item 1 item 1 teb-capacity)
17
1
11

MONITOR
1570
251
1627
296
Exit#2
(item 1 item 1 exit-capacity)
17
1
11

INPUTBOX
9
230
59
290
u
7.0
1
0
Number

INPUTBOX
82
108
186
168
run-number
0.0
1
0
Number

OUTPUT
1435
301
1675
729
12

INPUTBOX
187
108
270
168
seed
100.0
1
0
Number

INPUTBOX
8
168
66
228
scale
5.0
1
0
Number

INPUTBOX
67
168
147
228
#-of-peds
1000.0
1
0
Number

INPUTBOX
147
167
296
227
%-of-handicap
2.0
1
0
Number

MONITOR
10
650
95
695
Pedestrians
count peds
17
1
11

MONITOR
97
649
154
694
Cars
count cars
17
1
11

@#$#@#$#@
## WHAT IS IT?

TUNAMI-EVAC is a tsunami evacuation agent-based model (ABM).
The word 'TUNAMI' is from the Tohoku University's Numerical Analysis Model for Investigation of Near field tsunamis known as TUNAMI-N2.
TUNAMI provides the tsunami inundation input to this ABM.
The word 'EVAC' is from 'evacuation'.

## WHAT IS NEW

In version 1.0 population was created randomnly within buildings in the target area.
In version 2.0 population input as raster is possible. This allows for census or mobile statistical data.

## CREDITS AND REFERENCES

Developed by Erick Mas
Version 1.0 - 2012
Version 2.0 - 2022
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

bot
true
6
Circle -13840069 true true 30 30 240

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

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="movie-interval">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random-shelter?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-of-elders">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TS">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tsunami?">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="ETA" first="40" step="5" last="60"/>
    <enumeratedValueSet variable="output-files?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="movie-name">
      <value value="&quot;ArahamaETA&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-of-cars">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="snapshots?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="title">
      <value value="&quot;\&quot;Arahama Scenario - Tohoku 2011\&quot;&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-of-kids">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-of-teens">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="movie-frame-rate">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="movie?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-of-adults">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-of-handicap">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>safe-kids + safe-teens + safe-adults + safe-elders + (safe-cars * 4)</metric>
    <metric>casualty-kids + casualty-teens + casualty-adults + casualty-elders + (casualty-cars * 4)</metric>
    <metric>(item 1 item 0 teb-capacity) + (item 1 item 1 teb-capacity)</metric>
    <metric>(item 1 item 0 exit-capacity)</metric>
    <metric>(item 1 item 1 exit-capacity)</metric>
    <enumeratedValueSet variable="tsunami?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="output-files?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-of-kids">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="movie-name">
      <value value="&quot;Tohoku&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-of-adults">
      <value value="631"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random-shelter?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-of-cars">
      <value value="410"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-of-elders">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="run-number" first="1" step="1" last="250"/>
    <enumeratedValueSet variable="title">
      <value value="&quot;\&quot;Arahama Scenario - Tohoku 2011\&quot;&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="movie-frame-rate">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="#-of-teens">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="movie?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="movie-interval">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-of-handicap">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ETA">
      <value value="67"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="snapshots?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TS">
      <value value="70"/>
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
