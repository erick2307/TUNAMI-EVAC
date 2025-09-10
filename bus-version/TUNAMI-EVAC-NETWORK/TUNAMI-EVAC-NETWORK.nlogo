// TUNAMI-EVAC-NETWORK.nlogo
// NetLogo model: Tsunami Evacuation with Network-based Pathfinding
// Author: Adapted for performance and clarity
//
// This version uses a street network (nodes/edges) for agent pathfinding.
// Pedestrians and cars use the network for efficient route calculation.
//
extensions [gis pathdir vid]

__includes [ "network-utils.nls" ]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GLOBAL VARIABLES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
globals [
  street-nodes           ;; list of node agents (intersections)
  street-edges           ;; list of edge agents (road segments)
  exit-nodes             ;; nodes that are exits
  teb-nodes              ;; nodes that are TEBs
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
breed [ cars car ]
breed [ nodes node ]      ;; network nodes (intersections, stops, etc)
breed [ edges edge ]      ;; network edges (road segments)

peds-own [ speed handicap stage path ini goal L heuri td age ]
cars-own [ speed handicap stage path ini goal L heuri td ]
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
  display
end

;; Set initial values for globals
;; ...existing code for set-initial-values, but remove legacy variables and add documentation...

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; LOAD SPATIAL DATA AND BUILD NETWORK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to load-spatial
  ;; ...existing code to load GIS data...
  ;; Instead of patch-based, extract nodes and edges for the network
end

to build-network
  ;; Build nodes and edges from GIS street data
  ;; Each intersection becomes a node, each street segment an edge
  ;; Store node/edge agents in street-nodes and street-edges
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; POPULATION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to load-population
  ;; ...existing code, but assign ini/goal to nodes, not patches...
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
  ;; ...existing code for tsunami, outputs, plots, etc...
  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; AGENT PROCEDURES (NETWORK VERSION)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to t.search-road-network
  if stage = 2 [
    ;; Find nearest node (intersection) and compute shortest path to goal node
    let start-node min-one-of nodes [distance myself]
    let end-node goal
    set path network-shortest-path start-node end-node
    set stage 3
  ]
end

to t.follow-network-path
  if stage = 3 [
    if not empty? path [
      let next-node first path
      move-to next-node
      set path but-first path
    ]
    if empty? path [ set stage 4 ]
  ]
end

;; ...other procedures updated to use nodes/edges instead of patches...

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; NETWORK UTILS (in network-utils.nls)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; to-report network-shortest-path [start-node end-node]
;;   ;; Dijkstra or A* implementation on node/edge agents
;; end

// ...rest of the code, plots, outputs, etc, updated for network...
