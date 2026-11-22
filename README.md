# PKS Factory Simulator

<p align="left">
  <img src="assets/branding/app_logo.svg" alt="PKS Factory Simulator Logo" width="84" />
</p>

A 3D industrial automation & PLC sandbox simulator built with **Godot Engine 4.7.2** (`gl_compatibility` renderer). Design conveyor lines, wire sensors and actuators, program logic using the built-in **Ladder PLC** or connect external controllers via **Modbus TCP**, and watch autonomous factory NPCs patrol the floor.

- **Website & Downloads:** https://pksofttech.github.io/pks_factory_simulator/
- **Direct Web Simulator:** https://pksofttech.github.io/pks_factory_simulator/play/

> **Note on Web build:** Browsers do not support raw TCP sockets, so the Web version runs **Internal Ladder PLC** and **Manual** modes. Use a Desktop build (Windows / Linux / macOS) for **Modbus TCP** Server/Client communication.

---

## Features

- **Industrial Equipment & Handling**
  - Straight Conveyors (`9m` & `3m`), 90° Turn Table, Box Emitter, Box Remover, Reject Bin
  - Sensors & Safety: Photo Sensor, Vision Sensor, RGB Sensor, Light Curtain
  - Actuators & Process: Pneumatic Pusher, Stopper, Motor Fan, Centrifugal Pump, Water Tank (L/M/H sensors + outlet valve), Solenoid Valve
  - Control & Signal: Stack Light (3-color tower), 3D/2D Control Cabinet (buttons, switches, E-STOP, gauges)
- **Props & Decor**
  - Warehouse & Logistics: Pallet Rack, Forklift, Pallet Stack, Pallet Jack
  - Safety & Signage: Safety Barrier, Safety Bollard, Safety Sign, Steel Drum
  - Shop & QA: Workbench, QC Desk, Production Board, Locker Station
- **Autonomous Factory NPCs**
  - **Operator**, **Supervisor (Tester)**, **Safety**, **Maintenance**, and **QC Inspector**
  - Role-based equipment inspection, A* obstacle avoidance, safety alert response, periodic shift-break routines, and procedural soft-chirp audio (`FactoryAudio`)
  - Individual visibility, speed, inspection duration, chat bubbles, and NPC sound toggles in **NPC Settings**
- **Dual PLC Control**
  - **Internal Ladder PLC** ([`soft_plc.gd`](soft_plc.gd)) supporting Mitsubishi & IEC notation
  - **Modbus TCP** ([`autoload/modbus_tcp.gd`](autoload/modbus_tcp.gd)) Server/Client for Desktop builds

---

## Controls

| Action | Shortcut / Input |
| :--- | :--- |
| **Orbit Camera** | Right-click + Drag |
| **Pan Camera** | Middle-click + Drag |
| **Zoom** | Mouse Wheel |
| **Reset Camera** | `R` |
| **Toggle Fullscreen** | `F11` |
| **Open Add Object / Return to Select** *(Edit Mode)* | Right-click (without dragging) |
| **Rotate Object (90°)** *(Edit Mode)* | `Q` / `E` |
| **Delete Selected** *(Edit Mode)* | `Delete` |
| **Undo / Redo** *(Edit Mode)* | `Ctrl+Z` / `Ctrl+Y` (`Ctrl+Shift+Z`) |

---

## Example Projects

Ready-to-run `.pksfac` simulations are included in [`example/`](example/):

1. [`example/01_conveyor_sorting_line.pksfac`](example/01_conveyor_sorting_line.pksfac) — Automated sorting line using `VisionSensor` + `DivertPusher` + `RejectBin`
2. [`example/02_water_tank_level_control.pksfac`](example/02_water_tank_level_control.pksfac) — `WaterTank` high-level interlock with `FeedPump`, `OutletValve`, and `CoolingFan`
3. [`example/03_l_turn_warehouse_line.pksfac`](example/03_l_turn_warehouse_line.pksfac) — 90° L-turn warehouse line with `SafetyCurtain` interlock

---

## Running & Exporting

- **Engine:** Godot Engine `4.7.2-stable`
- **Entry Scene:** [`loading_screen.tscn`](loading_screen.tscn) → [`main.tscn`](main.tscn)
- **Web Export & Auto-Deploy:** Configured via [`export_presets.cfg`](export_presets.cfg) and [`.github/workflows/pages.yml`](.github/workflows/pages.yml), which automatically builds and deploys to GitHub Pages on every push to `main`.

To test the Landing Page & Web export locally:

```bash
./tools/run_web.sh
# Or preview only the landing page without running Godot Web export:
./tools/run_web.sh --skip-export
```
