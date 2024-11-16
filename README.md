# Olympus Installation Guide

Welcome to Olympus! This guide will walk you through the installation and initial setup process.

## Prerequisites

- FFXIV Minion installed and working
- Active FFXIV game subscription
- FFXIVMinion64 folder in your Minion installation

## Installation Steps

### 1. Prepare Installation Location
Navigate to your FFXIVMinion64 installation folder:
```
...\MINIONAPP\Bots\FFXIVMinion64\LuaMods\
```

### 2. Install Olympus
1. If there isn't already an "Olympus" folder in the LuaMods directory, create one
2. Copy all Olympus files into this folder, maintaining the following structure:
   ```
   Olympus/
   ├── CombatRoutines/
   ├── Images/
   ├── Systems/
   └── *.lua files
   ```

### 3. Verify Installation
After installation, ensure you have the following key files:
- Olympus.lua (main file)
- module.def (module definition)
- All required subfolders (CombatRoutines, Images, Systems)

## Initial Setup

### 1. Load the Module
1. Start FFXIV and log into your character
2. Launch FFXIVMinion
3. Profit

> ⚠️ **Important Notes:**
> - Always ensure FFXIV is running before starting FFXIVMinion
> - The first time you load Olympus, it may take a moment to initialize
> - If you encounter any errors, check the FFXIVMinion console for details

## Getting Started

Once installed and configured:
1. Select your desired combat routine from the available options
2. Test in a safe area first to ensure everything is working as expected
3. Use the built-in debugging tools (Olympus_Debug.lua) if you need to troubleshoot

## Support

If you need help or encounter issues, check the following resources:
- FFXIVMinion forums
- Olympus documentation
- Olympus Discord channel
