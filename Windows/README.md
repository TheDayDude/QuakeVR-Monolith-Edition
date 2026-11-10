# Monolith VR initial build

Place your registered Quake pak0.pak and pak1.pak in id1. Start your PC OpenXR runtime, connect your headset and launch MonolithVR.bat. The game starts in Limbo (mvr_start). Walk under the Quad for the original Quake maps or the Invoker for QBJ3. The Pentagram displays a notice until the tutorial is ready. Enter gohome in the console to return to Limbo. Use the movement stick to walk and A to jump. Look down to inspect Rover while standing and walking.

The first-person body uses Rover’s original animations. Independent hand posing and VR weapon handling are outside this build. The launcher mounts MVR over id1. Entering the Invoker gate adds qbj3 underneath mvr. Both campaigns use MVR gameplay and Rover.

For a developer build, compile the x64 Release engine with Visual Studio and ClangCL or use CMake with Ninja and clang-cl from a Windows SDK developer prompt. From QC run fteqcc64 -srcfile progs.src to build both gameplay and client HUD programs. From the repository run Windows/package-mvr.ps1 -EngineDirectory <compiled-engine-folder>. Python 3 generates the local first-person model from your QBJ3 installation. Keep retail Quake and QBJ3 assets in your local test installation. See qbj3/qbj3_readme.txt for credits and permissions.

## Editing Limbo

Compile Maps/mvr_start.map as usual. Leave mvr_start.bsp and its matching mvr_start.lit in the project Maps folder. Each launch from Builds/Q-MVR copies the fresh pair into mvr/maps. Standalone builds use the packaged pair. To see edits made during play, relaunch MonolithVR.bat.

Keep one item_artifact_super_damage, one weapon_invoker and one item_artifact_invulnerability above their intended gates. On mvr_start, these entities act as signs and touch triggers. Moving a sign also moves its gate. The trigger extends 30 units horizontally in each direction and 144 units below the sign origin.