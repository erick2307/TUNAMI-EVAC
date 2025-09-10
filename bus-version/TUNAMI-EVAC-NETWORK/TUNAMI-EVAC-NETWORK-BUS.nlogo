// TUNAMI-EVAC-NETWORK-BUS.nlogo
// NetLogo model: Tsunami Evacuation with Network-based Pathfinding and Bus Agents
// Author: Adapted for performance, clarity, and bus support
//
// This version adds a 'bus' agent that moves along the street network and can pick up/drop off peds at bus stops.
//
extensions [gis pathdir vid]

__includes [ "network-utils.nls" ]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GLOBAL VARIABLES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
globals [
  street-nodes
  street-edges
  exit-nodes
  teb-nodes
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
  pop-buses
]

breed [ peds ped ]
breed [ cars car ]
breed [ buses bus ]
breed [ nodes node ]
breed [ edges edge ]

peds-own [ speed handicap stage path ini goal L heuri td age riding-bus ]
cars-own [ speed handicap stage path ini goal L heuri td ]
buses-own [ speed route current-stop passengers capacity ]
nodes-own [ node-id node-type ]
edges-own [ from-node to-node length allowed-breeds ]

patches-own [ zt ]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SETUP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup
  clear-all
  reset-ticks
  set-initial-values
  load-spatial
  build-network
  load-population
  load-buses
  display
end

;; ...existing code for set-initial-values, load-spatial, build-network, load-population...

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; BUS AGENT SETUP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to load-buses
  ;; Create bus agents, assign them to routes (list of nodes), set capacity
  create-buses 3 [
    set speed 1.0
    set route [list of node agents representing bus stops]
    set current-stop 0
    set passengers []
    set capacity 20
    move-to item 0 route
  ]
  set pop-buses count buses
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; MAIN PROGRAM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to go
  if ticks = 0 [reset-timer no-display]
  ask turtles [
    t.decide-to-start
    t.decide-shelter
    t.search-road-network
    t.follow-network-path
    t.search-shelter-route-network
  ]
  ask buses [ bus-move-along-route ]
  ;; ...existing code for tsunami, outputs, plots, etc...
  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; BUS PROCEDURES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to bus-move-along-route
  ;; Move to next stop in route
  let next-stop (item ((current-stop + 1) mod length route) route)
  move-to next-stop
  set current-stop (current-stop + 1) mod length route
  ;; Drop off passengers whose goal is this stop
  let to-drop passengers with [goal = next-stop]
  ask to-drop [
    set riding-bus false
    move-to next-stop
    set passengers remove self passengers
  ]
  ;; Pick up waiting peds at this stop
  let waiting-peds peds with [patch-here = next-stop and not riding-bus]
  let available (capacity - length passengers)
  let to-pickup n-of available waiting-peds
  ask to-pickup [
    set riding-bus true
    set passengers lput self passengers
  ]
end

// ...rest of the code, plots, outputs, etc, updated for network and bus...
