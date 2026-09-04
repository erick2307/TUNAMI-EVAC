# Changelog

All notable changes to TUNAMI-EVAC are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and release numbers follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Entries describe user-visible behavior, scientific assumptions, compatibility, performance, and verification evidence in plain language.

## [2.0.0] - 2026-09-04

### Added

- Added a built-in `profile-run` procedure using NetLogo's profiler extension. It runs a 600-tick benchmark and writes a timestamped report under `Output`.
- Added `Output/README.txt` to explain the purpose of the output directory.
- Added this changelog as the authoritative release-history record.

### Changed

- Migrated the main model from the NetLogo 6.2.2 `.nlogo` format to the NetLogo 7.0.4 XML-based `.nlogox` format. Version 2 must be opened with NetLogo 7 or later.
- Renamed `Astar2011.nls` to `Astar.nls` and `Rayleigh2011.nls` to `Rayleigh.nls`; updated the model includes accordingly.
- Updated the README and in-model documentation for version 2, NetLogo 7, the optimized pathfinding library, and the inherited Rayleigh decision-time behavior.
- Documented that the model currently gives each agent a randomly selected integer Rayleigh mean between `u` and `ETA`. The population therefore follows a heterogeneous mixture of Rayleigh distributions. This behavior remains unchanged in 2.0.0 for compatibility and is planned for review in a future release.

### Performance

- Rewrote A* pathfinding to maintain an explicit open list instead of repeatedly scanning every patch in the world.
- Added an incremental cumulative path cost (`gcum`) and removed repeated parent-chain traversal.
- Limited score recalculation and cleanup to patches touched by each search.
- In a matched 10-agent, 600-tick release benchmark, 20 A* searches completed in 0.108 seconds instead of 4.901 seconds of inclusive profiler time, approximately 45.4 times faster. Total `go` time decreased from 5.203 seconds to 0.485 seconds, approximately 10.7 times faster.

### Verification

- The matched A* benchmark produced byte-identical evacuation records and identical final counts: seven evacuated agents and three agents still active after 600 ticks.
- Verified that all 42 files in `SpatialDB` and all 301 tsunami rasters from `out53900.asc` through `out54200.asc` are byte-for-byte unchanged from version 1.
- Verified that the README, license, PhD thesis, and QGIS project carried into the initial version-2 working folder were unchanged before the version-2 documentation update.
- Verified the core Rayleigh CDF, PDF, and inverse-CDF formulas. Version 2 changes their documentation and filename but not their calculations.
- Profiled a 1,041-agent, 4,200-tick headless core scenario at approximately 10.59 seconds after JVM warm-up, excluding tsunami ingestion, movie creation, and snapshots. Loading and applying 300 tsunami rasters separately took approximately 9.19 seconds. Results were measured with NetLogo 7.0.4 on the release-development machine and should not be treated as cross-platform guarantees.

### Fixed

- Corrected the profiling documentation: `profile-run` restores the widget-backed settings it changes, but it calls `setup` and therefore replaces the current world state. It should be run from a freshly opened model or disposable copy.

<!--### Known limitations

- The Rayleigh helper names are historical: `random-rayleigh` evaluates a PDF and does not generate a random value.
- The Rayleigh functions do not yet guard invalid domains such as negative `x-ray`, non-positive means, or a cumulative probability equal to 1.
- The heterogeneous Rayleigh mixture can produce decision times after `ETA` and after the configured simulation duration.
- A* equivalence has been checked on the matched release benchmark but not yet exhaustively across every start/target pair, heuristic, tie, and unreachable-route case.
- Heuristic modes 1, 3, and 4 require a future admissibility and parenthesization review before shortest-route optimality can be claimed for every agent.
- `reload` requires a future state-reset review after tsunami inundation because it does not reload the base spatial layers.-->

## [1.0.0-alpha] - 2022-04-21

### Added

- Published the original TUNAMI-EVAC1 NetLogo model, spatial datasets, tsunami raster sequence, documentation, and example outputs.
- Included the original 2011 A* and Rayleigh helper libraries.

[2.0.0]: https://doi.org/10.5281/zenodo.6477682
[1.0.0-alpha]: https://github.com/erick2307/TUNAMI-EVAC/releases/tag/v1.0.0-alpha
