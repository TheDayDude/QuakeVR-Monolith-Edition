# QuakeVR-Monolith-Edition

An unofficial virtual reality adaptation of Quake Brutalist Jam III, built upon QuakeVR: Unleashed.

Project Status: Early Development / Pre-Alpha
Engine Base: QuakeVR: Unleashed 1.0.1
Target Game: Quake Brutalist Jam III 1.3
Development Reference: Monolith Devkit

Overview

QuakeVR: Monolith Edition is an unofficial fork of QuakeVR: Unleashed, created to bring the world and gameplay of Quake Brutalist Jam III into virtual reality.

The project aims to preserve the distinctive atmosphere, weaponry, monsters, and level design of QBJ3 while adapting its gameplay to the immersive, physically interactive systems of QuakeVR.

Rather than simply running QBJ3 maps in VR, Monolith Edition seeks to create a complete VR gameplay experience designed specifically around QBJ3's mechanics.

# Project Goals

Make Quake Brutalist Jam III 1.3 playable in VR.

Preserve the original game's mechanics, weapons, enemies, and map progression.

Integrate QuakeVR's physical interaction systems into QBJ3 gameplay.

Adapt QBJ3's unique arsenal for immersive VR combat.

Expand environmental and enemy interactions using VR-specific mechanics.

Develop original features that give Monolith Edition its own identity.

Maintain a clean, documented, and independently buildable fork.

Planned Features

The following features are development targets and are not necessarily implemented.

Core VR Support

OpenXR-based PCVR support

Tracked head and hand movement

Room-scale movement and interaction

Smooth and snap turning

Seated and standing play options

VR calibration and comfort settings

Motion-controller aiming and interaction

QBJ3 Integration

Support for Quake Brutalist Jam III 1.3

Compatibility with QBJ3's original maps and hub

Preservation of QBJ3's weapon mechanics and damage systems

Support for custom enemies and scripted behaviors

Support for QBJ3 powerups, pickups, armor, and ammunition

Correct level progression and persistent game state

Physical Combat

Physically controlled melee weapons

Independent dual-wielded weapons

Two-handed weapon handling

VR-oriented weapon reloading where appropriate

Weapon holsters and physical inventory interactions

Improved recoil and weapon feedback

Optional physical parrying and projectile interactions

Environmental Interactions

Physical interaction with compatible world objects

Hand-operated switches and environmental controls

Throwable objects and interactive props

Contextual climbing and environmental traversal

VR-oriented interaction with compatible environmental hazards

Enemies and Combat Feedback

VR-compatible enemy collision and hit detection

Support for QBJ3's unique enemy attacks

Physical hit reactions and knockback

Optional ragdoll integration where technically appropriate

Improved spatial audio and directional feedback

Configurable interaction and combat intensity

Monolith Edition Exclusive Features

Following the completion of basic QBJ3 compatibility, additional gameplay mechanics will be considered, including:

Expanded physical weapon interactions

New environmental interaction systems

Unique VR combat mechanics

Additional immersive gameplay options

Optional gameplay modifiers and challenge features

New systems will prioritize compatibility with QBJ3's original gameplay and level design.

Development Roadmap

Phase

Milestone

Status

0

Source Audit and Baseline Build

Planned

1

QBJ3 VR Compatibility

Planned

2

Native Gameplay Integration

Planned

3

Physical Weapon Systems

Planned

4

Enemies and Environmental Interaction

Planned

5

Campaign Support and Optimization

Planned

6

Exclusive Mechanics and Polish

Planned

Initial Development Target

The first major goal is a working VR build capable of loading and playing QBJ3 using its original gameplay code.

Native VR weapon interactions and further gameplay enhancements will follow once basic compatibility is established.

Development and Building

The project is based on QuakeVR: Unleashed 1.0.1, which uses an Ironwail-derived engine with OpenXR support.

Development is initially targeted at Windows x64.

Expected Development Tools

Visual Studio 2022 with C++ and ClangCL components

FTEQCC for compiling QuakeC

Python 3 for build and validation utilities

An OpenXR-compatible PCVR headset/runtime

QuakeVR: Unleashed 1.0.1 source

Monolith Devkit

Quake Brutalist Jam III 1.3 game data

Build and installation instructions specific to Monolith Edition will be added as development progresses.

The Monolith devkit and QBJ3 game files are maintained as separate development inputs.

Compatibility

The intended target is Windows PCVR using OpenXR.

The initial target game is Quake Brutalist Jam III 1.3.

Hardware compatibility and required performance specifications will be documented after testing.

Credits

QuakeVR: Monolith Edition is made possible through the work of the following projects and their contributors:

id Software — Quake

Vittorio Romeo and contributors — QuakeVR: Unleashed

Ironwail contributors — Ironwail Engine

QBJ3 development team and participating map authors — Quake Brutalist Jam III

Monolith Devkit contributors — QBJ3 development resources

Additional credits will be maintained as new code and assets are integrated.

License and Distribution

The upstream QuakeVR source includes GPL version 2 licensing. Existing license notices, applicable source-code obligations, and third-party notices must be preserved.

Game content, artwork, sounds, and other assets may be subject to separate permissions and licenses.

Distribution of QBJ3 or Monolith devkit content is not assumed to be permitted merely because the files are available to download.

Any release containing third-party assets will be reviewed for the relevant permissions and attribution requirements.
