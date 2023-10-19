# astropolis_sdk

**WIP - Currently restructuring the whole project. Content in 'astropolis_public' will be moved here.**

This repository contains the *moddable* part of Astropolis including content data, GUI and game AI. It is a Godot Project (not yet runnable - but it will be in the future!) and also the Software Development Kit used by Charlie Whitfield for non-public development.

Astropolis is a simulation game that explores human expansion and evolution in our own solar system. It is an early stage, open development project created by Charlie Whitfield built in the [I, Voyager](https://www.ivoyager.dev/) solar system simulation using the [Godot Engine](https://godotengine.org/).

Astropolis will be highly moddable. Although it is an open development project, it is not open source. Please see [About](https://t2civ.com/about/) for details.

[About](https://t2civ.com/about/) | [Dev Blog](https://t2civ.com/) | [Forum](https://github.com/orgs/t2civ/discussions) | [Modding](https://github.com/t2civ/astropolis_public) | [Download](https://t2civ.com/download/)

### Development Plan for Modding
In the future, our modding "software development kit" will be the [Godot Editor](https://godotengine.org/features/) with an Astropolis SDK add-on. You will be able to make changes, run the modified game directly from the editor, and then export the mod as a .pck file. This won't happen until we are much further in development.

### Content Data
Content data is defined in simple text data tables in this repository ([data/tables/](https://github.com/t2civ/astropolis_public/tree/main/data/tables)) and in I, Voyager ([ivoyager/data/solar_system/](https://github.com/ivoyager/ivoyager/tree/master/data/solar_system)). Exactly which tables are loaded is defined in [IVGlobal](https://github.com/ivoyager/ivoyager/blob/master/singletons/global.gd) as modified in [astropolis_public/astropolis_public.gd](https://github.com/t2civ/astropolis_public/blob/main/astropolis_public.gd) (search "table").


Table row entities are *never* hard-coded in core Astropolis, although some tables (particularly those named "_classes") contain categories that are "soft"-coded in GUI files that can be modded. Cell values may be modified based on column header values for Default, Unit and Prefix. Row names are always globally unique (after prefixing). Tables include enumerations that may refer to a data table row entity or an internal enum (look for text in Type INT columns).


The I, Voyager table [README](https://github.com/ivoyager/ivoyager/blob/master/data/solar_system/README.txt) explains general table structure. This repository's table [README](https://github.com/t2civ/astropolis_public/blob/main/data/tables/README.md) contains *very* rough work-in-progress notes on Astropolis content.

### Program Architecture
Astropolis has essentially a client-server architecture. AI and GUI are clients and communicate with the servers (the game internals) exclusively via "interface" classes like PlayerInterface, FacilityInterface, BodyInterface, and so on (find in [interfaces/](https://github.com/t2civ/astropolis_public/tree/main/interfaces)). Game AIs are subclasses of these interfaces; e.g., PlayerBaseAI and PlayerCustomAI extend PlayerInterface. GUIs hook up to interface classes to get data or make changes (with care for multithreading since interface changes happen on the AI thread while GUI runs on the SceneTree main thread).


The interface/AI classes are composed with (optional) objects Inventory, Operations, Financials, Composition, Population, Biome and Metaverse (find in [net_refs/](https://github.com/t2civ/astropolis_public/tree/main/net_refs)). These "NetRef" objects are optimized for network data sync.


It's very likely that the NetRef and Interface classes will be ported to C++, becoming GDExtension classes. In true Godot-fashion, individual AI subclasses then can be coded in GDScript, C#, C++, or any other language [supported by the Godot community](https://godotengine.org/features/). Regardless of language chosen, it will be possible to interface with Python's AI libraries.
