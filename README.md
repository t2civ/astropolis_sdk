# Astropolis SDK

[Astropolis](https://t2civ.com/) is a simulation game that explores human expansion and evolution in our own solar system. It is an early stage, open development project created by Charlie Whitfield built in the [I, Voyager](https://www.ivoyager.dev/) solar system simulation using the [Godot Engine](https://godotengine.org/).

This software development kit contains the *moddable* part of Astropolis, which includes all content data, all GUI, and all AI systems. Astropolis and the SDK are *work in progress!*

[About](https://t2civ.com/about/) | [Dev Blog](https://t2civ.com/) | [Forum](https://github.com/orgs/t2civ/discussions) | [Modding](https://github.com/t2civ/astropolis_sdk) | [Download](https://t2civ.com/download/)

### Development Plan for Modding
This 'SDK' is the base Godot project used by the author to develop Astropolis. You can import the SDK using the most current [Godot Editor](https://godotengine.org/) version and browse and edit code. However, the public project is not (yet!) runnable because it lacks the core 'servers' that run Astropolis internals. In the future, these internals will be integral to a custom-built Godot Editor distribution. Modders will then be able to edit code, test run changes directly in the editor, and export mods for distribution as Godot .pck files.

### Content Data
All content data is defined in simple text data tables in [public/data/tables/](https://github.com/t2civ/astropolis_sdk/tree/master/public/data/tables) and [addons/ivoyager_core/data/solar_system/](https://github.com/ivoyager/ivoyager_core/tree/master/data/solar_system). Modders can modify or replace existing tables, or create new tables defining entirely new systems. Table row entities are *never* hard-coded in core Astropolis, making all game content moddable. For more information about our data table system, go [here](https://github.com/ivoyager/ivoyager_table_importer).

### Program Architecture
Astropolis has essentially a client-server architecture. AIs and GUIs are clients and communicate with servers, the non-public game internals, exclusively via 'interface' classes like PlayerInterface, FacilityInterface, BodyInterface, and so on (find [here](https://github.com/t2civ/astropolis_sdk/tree/master/public/interfaces)). Game AIs are instantiations (i.e., subclasses) of these interfaces. GUIs hook up to interface classes to get display data or apply human player changes (with care for multithreading since the Interface/AI system runs in its own thread).


Interface/AI classes are composed with objects Inventory, Operations, Financials, Composition, Population, Biome and Cyberspace (find [here](https://github.com/t2civ/astropolis_sdk/tree/master/public/net_refs)). These 'NetRef' objects are optimized for network data sync for multiplayer support.


Interface (base) and NetRef classes are presently coded in GDScript, but will be ported to C++ becoming GDExtension classes. Modders will then be able to code AI subclasses in GDScript, C#, C++, or any other language [supported by the Godot community](https://godotengine.org/features/).

### Installation

I, Voyager's [Developers Page](https://www.ivoyager.dev/developers/) might be helpful (the SDK is built from I, Voyager's [Project Template](https://github.com/ivoyager/project_template)). Also, the author uses and highly recommends [GitKraken](https://www.gitkraken.com/) for Git version control. It’s free for public repositories.

The SDK repository contains submodules. To clone the SDK with its submodules in one step using Git:

`git clone --recursive git://github.com/t2civ/astropolis_sdk.git`

You'll also have to download 'ivoyager_assets' and add it manually to you addons directory (assets are not Git-tracked). You can find these with the latest ivoyager_core releases [here](https://github.com/ivoyager/ivoyager_core/releases).

You can download the SDK without Git but it's more work. After downloading the SDK, you'll need to separately download and add two plugins ('ivoyager_core' and 'ivoyager_table_importer') into your addons directory. Find links and more information [here](https://www.ivoyager.dev/developers/). (But seriously, learn to use Git so you don't have to do that!)
