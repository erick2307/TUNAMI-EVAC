# TUNAMI-EVAC 2

TUNAMI-EVAC is a [NetLogo](https://ccl.northwestern.edu/netlogo/) agent-based model for [tsunami evacuation analysis](https://link.springer.com/article/10.1007/s00024-015-1105-y). The original model was developed by Erick Mas in 2012 as part of a PhD study at [Tohoku University](https://www.tohoku.ac.jp/en/).

Version 2 migrates the model to NetLogo 7 and substantially improves pathfinding performance while retaining the established evacuation and hazard data. See [CHANGELOG.md](CHANGELOG.md) for the verified changes, benchmark conditions, and known limitations.

The model's development and applications are described in the included [PhD thesis](resources/PhD_Thesis_ErickMas.pdf).

![Snapshot](Output/0K_4200.png?raw=true "TUNAMI-EVAC snapshot")

## Getting Started

1. Install [NetLogo](https://ccl.northwestern.edu/netlogo/download.shtml). Version 2.0.0 was verified with NetLogo 7.0.4.
2. Download or clone this repository.
3. Open `TUNAMI-EVAC2.nlogox` in NetLogo.
4. Press **setup** for the first run, configure the population and scenario controls, then press **go**.

Simulation outputs are written to the `Output` directory. The model depends on the bundled `SpatialDB`, `TsunamiDB`, `Astar.nls`, and `Rayleigh.nls` files, so keep the package directory structure intact.

## Example

[Animation from the original model](./Model67.mp4)

## Publications

You can use, modify, adapt this model to your own needs. If you use this model to any extent, we ask you to cite our relevent publications:

+ Mas, E., Suppasri, A., Imamura, F. & Koshimura, S. (2012). Agent-based Simulation of the 2011 Great East Japan Earthquake/Tsunami Evacuation: An Integrated Model of Tsunami Inundation and Evacuation. Journal of Natural Disaster Science, 34(1), 41–57. https://doi.org/10.2328/jnds.34.41

+ Mas, E., Adriano, B., & Koshimura, S. (2013). An Integrated Simulation of Tsunami Hazard and Human Evacuation in La Punta, Peru. Journal of Disaster Research, 8(2), 285–295. https://doi.org/10.20965/jdr.2013.p0285

+ Mas, E., Adriano, B., Pulido, N., Jimenez, C. & Koshimura, S. (2014). Simulation of Tsunami Inundation in Central Peru from Future Megathrust Earthquake Scenarios. Journal of Disaster Research, 9(6), 961–967. https://doi.org/10.20965/jdr.2014.p0961

+  Mas, E., Koshimura, S., Imamura, F., Suppasri, A., Muhari, A. & Adriano, B. (2015). Recent Advances in Agent-Based Tsunami Evacuation Simulations: Case Studies in Indonesia, Thailand, Japan and Peru. Pure and Applied Geophysics, 172(12), 3409–3424. https://doi.org/10.1007/s00024-015-1105-y

## Releases

[![DOI](https://zenodo.org/badge/483123627.svg)](https://zenodo.org/badge/latestdoi/483123627)

## Author

* **Erick Mas** - [erick2307](https://github.com/erick2307) / [erickmas](https://researchmap.jp/mas.erick?lang=en)
