# Project Remedy Technical Documentation

## Project Overview
Project Remedy is a Lua-based automation module designed for FFXIVMinion64, providing advanced combat routines and automation features for Final Fantasy XIV.

## Technical Architecture

### Core Technologies
- **Primary Language:** Lua
- **Runtime Environment:** FFXIVMinion64
- **Core Dependency:** minionlib
- **Module Version:** 1.0

### Project Structure and Components

#### 1. Core System (`/Core`)
- **Performance Module** (`/Core/Performance`)
  - Handles optimization and resource management
  - Monitors system performance metrics
  - Implements performance-critical operations

- **Combat System** (`/Core/Combat`)
  - Core combat logic implementation
  - Ability queue management
  - Combat state machine
  - Damage calculation systems

#### 2. Features (`/Features`)
- **Party Management** (`/Features/Party`)
  - Party member tracking
  - Role-based coordination
  - Party buff synchronization

- **Targeting System** (`/Features/Targeting`)
  - Target priority logic
  - Enemy assessment
  - Position-based target selection

#### 3. Content Handlers (`/Content`)
- **Dungeon Systems** (`/Content/Dungeons`)
  - Dungeon-specific mechanics
  - Automated navigation
  - Boss fight strategies

#### 4. Combat Routines (`/CombatRoutines`)
- Job-specific combat rotations
- Ability priority systems
- Situational combat logic

#### 5. Olympus Core (`/Olympus`)
- **Main Systems**
  - Olympus.lua: Primary entry point
  - Olympus_Debug.lua: Debugging utilities
  - Olympus_Constants.lua: System constants
  - Olympus_Abilities.lua: Ability definitions

### File Dependencies (from module.def)
1. Olympus/Olympus_Debug.lua
2. Olympus/Olympus_Constants.lua
3. Core/Performance/Performance.lua
4. Core/Combat/Combat.lua
5. Olympus/Olympus.lua
6. Olympus/Olympus_Abilities.lua
7. Features/Party/Party.lua
8. Features/Targeting/Targeting.lua
9. Content/Dungeons/Olympus_Dungeons.lua

## Implementation Details

### Core Systems

#### Combat System
- Real-time combat decision making
- Ability cooldown tracking
- Resource management
- Combat state transitions
- Position and movement optimization

#### Performance Module
- Memory usage optimization
- CPU utilization management
- Frame time monitoring
- Resource allocation

### Feature Systems

#### Party Management
- Real-time party member status tracking
- Role-based ability coordination
- Party buff optimization
- Heal priority system

#### Targeting
- Dynamic target priority calculation
- Position-based target selection
- Target switching logic
- AOE target optimization

### Content Systems

#### Dungeon Automation
- Path finding and navigation
- Mechanic recognition
- Boss phase tracking
- Automated responses to mechanics

## Technical Requirements

### System Requirements
- FFXIVMinion installed and configured
- Active Final Fantasy XIV installation
- Minimum system specifications:
  - Windows OS
  - DirectX compatible graphics
  - Sufficient memory for addon operation

### Dependencies
- minionlib (core FFXIVMinion library)
- FFXIV client
- FFXIVMinion runtime environment

## Development Guidelines

### Code Structure
- Modular design pattern
- Event-driven architecture
- State machine implementation for combat
- Object-oriented approach where applicable

### Performance Considerations
- Minimal memory footprint
- Efficient CPU utilization
- Optimized combat calculations
- Reduced garbage collection impact

### Debug Systems
- Comprehensive logging
- Performance monitoring
- State tracking
- Error handling and reporting

## Integration Points

### FFXIVMinion Integration
- Core hook points
- Event system integration
- Memory reading optimization
- Game state synchronization

### Combat System Integration
- Ability execution pipeline
- Cooldown management
- Resource tracking
- Status effect monitoring

## Version Control
- Git-based version control
- Feature branch workflow
- Version tagging
- Change tracking

This documentation is designed to provide AI systems with comprehensive context about the project's technical implementation and architecture. It includes all major systems, their interactions, and technical considerations for development and maintenance. 