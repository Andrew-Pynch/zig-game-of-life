# Zig Game of Life

A Conway's Game of Life implementation in Zig with entropy visualization and analysis features.

![Game of Life Demo](https://upload.wikimedia.org/wikipedia/commons/e/e5/Gospers_glider_gun.gif)
*Example of Conway's Game of Life patterns*

## About

This project implements Conway's Game of Life, a cellular automaton devised by mathematician John Horton Conway. The simulation follows simple rules that generate complex emergent behavior from initial patterns.

### Key Features

- Visual simulation of Conway's Game of Life in the terminal
- Entropy calculation for measuring the complexity of board states
- Save entropy data to CSV files for external analysis
- Built-in ASCII-based visualization of entropy evolution over time
- Configurable grid dimensions, iterations, and animation speed
- Multiple run modes: interactive, headless, data collection

## Code Structure

The project is structured as follows:

- `src/main.zig`: Entry point and CLI options handling
- `src/board.zig`: Implementation of the game board and entropy calculations
- `src/cell.zig`: Cell representation and state management
- `build.zig`: Zig build system configuration

### Source Files Explained

#### `main.zig`
Contains program entry point, command-line argument parsing, and run options. Handles the simulation loop, visualization of the board state, and entropy data collection/graphing.

#### `board.zig`
Implements the `Board` struct, which represents the Game of Life grid. Features include:
- Board initialization and memory management
- Game of Life update rules implementation
- Entropy calculation based on 3x3 neighborhood patterns
- Pattern hash calculations for identifying unique configurations
- Board state visualization and printing

#### `cell.zig`
Defines the `Cell` struct representing individual cells in the simulation. Includes methods for:
- Cell state management (alive/dead)
- Coordinates tracking
- Terminal display formatting

## Running the Application

### Building the Project

```bash
zig build
```

The executable will be available at `zig-out/bin/zig_game_of_life`.

### Running Options

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

#### Combined Options

Options can be combined, for example:

```bash
zig build run -- --graph --headless
```

This runs the simulation without visual output, but displays the entropy graph at the end.

## Entropy Analysis

The simulation calculates entropy based on:

1. Pattern diversity: The distribution of unique 3x3 cell neighborhoods
2. Density entropy: The information content of cell distribution
3. Pattern diversity ratio: Complexity measure based on unique patterns

These metrics provide insights into the complexity and organization of the Game of Life patterns.

## Configuration

Core simulation parameters can be modified in `src/main.zig`:

- `ITERATIONS`: Number of simulation steps (default: 1000)
- `WIDTH`: Width of the simulation grid (default: 100)
- `HEIGHT`: Height of the simulation grid (default: 40)
- `DELAY_MS`: Delay between simulation steps in milliseconds (default: 15)

## License

See the [LICENSE](LICENSE) file for details.