# Projectile Motion Simulator (MATLAB App Designer)

An interactive 2D projectile simulator built in MATLAB App Designer. It animates a projectile's trajectory in real time, detects whether it clears a rectangular obstacle, and calculates the minimum/maximum velocity or launch angle required to hit it.

![App Demo](assets/demo.gif)

## Features

- **Live animated trajectory** — adjust initial height (y₀), velocity (v₀), launch angle (θ), and gravity (g), and watch the projectile fly in real time
- **Obstacle collision detection** — define an obstacle's width, height, and distance from origin; the animation stops automatically if the projectile hits it
- **Real-time data table** — displays live X/Y position, elapsed time, and angle as the projectile moves
- **Trajectory comparison** — compare two projectiles side-by-side by changing parameters like launch angle while keeping the rest constant
- **Min/max clearance calculator** — automatically computes the minimum and maximum velocity (or angle) needed to clear the obstacle
- **Customization** — line colour, marker style, line width, obstacle colour, gridlines, and adjustable animation speed
- **Save/Load data** — export trajectory results to file and reload them later

## Demo

*(GIF above shows the app in action — entering parameters, running the animation, and displaying min/max clearance results.)*

## How It Works

The projectile's position at time *t* is calculated from standard kinematics:

```
x = v₀ · t · cos(θ)
y = y₀ + v₀ · t · sin(θ) − ½ · g · t²
```

The minimum/maximum angle needed to just clear the obstacle is solved numerically using the **bisection method**, since the trajectory equation can't be solved for θ in closed form. Velocity bounds are solved analytically for the same boundary conditions.

## Requirements

- **MATLAB R2018a or later**
- **Symbolic Math Toolbox** — required for the `vpa()` calls used in the velocity/angle calculations

When installing MATLAB, make sure **Symbolic Math Toolbox** is checked in the product selection screen — the app will error without it.

## Getting Started

Open `app/assignmentgroup8.mlapp` in App Designer to run the app, or view `code-export/assignmentgroup8.m` for a plain-text read of the app's code.
4. Click **Run**, enter your parameters, and click **START**.

## Repository Structure

```
projectile-simulator/
├── app/
│   └── assignmentgroup8.mlapp     # Main app
├── code-export/
│   └── assignmentgroup8.m         # Readable code export of the app (for reference/browsing)
├── assets/
│   └── demo.gif                   # App demo recording
└── README.md
```

## Authors

- Pang Kou Yi
- Gan Wei Hang

## License

This project is licensed under the [MIT License](LICENSE).
