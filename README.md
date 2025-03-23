# Zig Game of Life

A Conway's Game of Life implementation in Zig with entropy visualization and analysis features.

![Game of Life Demo](https://upload.wikimedia.org/wikipedia/commons/e/e5/Gospers_glider_gun.gif)

#### Future ideas?

- feed final entropy values from simulation runs into evolutionary algorithm to produce initial board states that have the highest entropy? (i.e can we evolve more complex board states?)

#### Basic Run

To run the simulation with default settings (visual display in terminal):

```bash
zig build run --
```

#### Help

To display command-line options and configuration:

```bash
zig build run -- --help
```

#### Save Entropy Data

To save entropy values to a CSV file:

```bash
zig build run -- --save
```

This saves data to `entropy_data.csv` in the current directory.

#### Visualize Entropy Graph

To run the simulation and display an ASCII graph of entropy over time:

```bash
zig build run -- --graph
```

#### Headless Mode

To run without visual simulation (faster execution):

```bash
zig build run -- --headless
```

## Entropy Analysis

The simulation calculates entropy based on:

1. Pattern diversity: The distribution of unique 3x3 cell neighborhoods
2. Density entropy: The information content of cell distribution
3. Pattern diversity ratio: Complexity measure based on unique patterns

