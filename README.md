# Project Remedy

Project Remedy is an addon system for FFXIVMinion providing enhanced combat, performance, and utility features.

## Project Structure

The project is organized into the following main directories:

### Core
Contains foundational modules that power the system:
- **Debug/**: Debugging and logging system
- **Performance/**: Performance monitoring and optimization
- **Combat/**: Combat mechanics and abilities

### Config
Configuration and settings management:
- **Settings.lua**: Main settings system

### UI
User interface components:
- **GUI.lua**: Main user interface system

### Features
Specialized gameplay features:
- **Party/**: Party management and analysis
- **Targeting/**: Target selection and evaluation

### Olympus
Core system files:
- **Olympus.lua**: Main system core
- **Olympus_Constants.lua**: System constants and enumerations
- **Olympus_Abilities.lua**: Ability definitions and management

### Content
Game-specific content:
- **Dungeons/**: Dungeon and raid-specific logic

## Getting Started

1. Install the project by copying all files to your FFXIVMinion64 LuaMods directory
2. Launch FFXIVMinion and enable the Olympus module
3. Configure your settings via the in-game UI

## Development

When adding new features, please maintain the existing structure:
- Put core systems in the appropriate Core/ subdirectory
- Place new features in the Features/ directory
- Add UI components to the UI/ directory
- Store configuration in the Config/ directory 