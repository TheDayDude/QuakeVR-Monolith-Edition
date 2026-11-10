# Initial build verification

The live Windows installation is Builds/Q-MVR. MonolithVR.bat mounts id1, qbj3, then mvr and opens The Monument (start). Windows/README.md describes compilation and packaging. Engine source comes from QuakeVR 1.0.1. Server and HUD source come from the supplied Monolith Devkit. FTEQCC compiles both to standard Quake bytecode.

The desktop test used the packaged x64 engine, the actual QBJ3 hub and the simulated headset. The console identified mvr/progs.dat, completed client sign-on, and reported a valid head pose. A simulated 65-degree look down changed camera pitch to 65 degrees. Forward stick input moved the player from Y -1648 to -1601. The first-person screenshot showed Rover’s torso. The model keeps the devkit player animations and uses a separate local mesh for the headset view.

A second launch selected the installed SteamVR OpenXR runtime. SteamVR was not running and xrCreateInstance returned -2. For hardware acceptance, connect the headset, start its PC runtime, launch MonolithVR.bat and check stereo, eye height, leaning, stick movement, turning and the view of the body while walking. Only the hub was exercised.
