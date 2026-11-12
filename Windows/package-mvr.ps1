param(
    [Parameter(Mandatory)][string]$EngineDirectory,
    [string]$Content = "$PSScriptRoot/../../qbj3",
    [string]$Destination = "$PSScriptRoot/../../../Builds/Q-MVR"
)
$ErrorActionPreference = "Stop"
$repo = Split-Path $PSScriptRoot
foreach ($folder in "id1","qbj3","mvr/progs") {
    New-Item -ItemType Directory -Force "$Destination/$folder" | Out-Null
}
Copy-Item "$EngineDirectory/ironwail.exe","$EngineDirectory/*.dll","$repo/Quake/ironwail.pak","$PSScriptRoot/MonolithVR.bat","$PSScriptRoot/README.md","$repo/LICENSE.txt" $Destination
# Use the runtime paired with the bundled x64 import library, even for older engine builds.
Copy-Item "$PSScriptRoot/curl/lib/x64/libcurl.dll","$PSScriptRoot/zlib/x64/zlib1.dll","$repo/Quake/vr/external/steamaudio/lib/windows-x64/phonon.dll" $Destination -Force
foreach ($folder in "gfx","maps","music","particles","progs","sound","textures","docs") {
    Copy-Item "$Content/$folder" "$Destination/qbj3" -Recurse -Force
}
Copy-Item "$Content/gfx.wad","$Content/qbj3_readme.txt" "$Destination/qbj3"
Copy-Item "$repo/mvr/progs.dat","$repo/mvr/csprogs.dat","$repo/mvr/quake.rc" "$Destination/mvr"
# MVR runs Monolith gameplay even when no campaign content is mounted.
$devkit = "$PSScriptRoot/../../monolith_devkit"
foreach ($folder in "progs","sound","gfx") {
    Copy-Item "$devkit/$folder" "$Destination/mvr" -Recurse -Force
}
# Limbo uses the blood sky and music track 31 even before QBJ3 is mounted.
Copy-Item "$Content/gfx/env/blood_*.tga" "$Destination/mvr/gfx/env"
New-Item -ItemType Directory -Force "$Destination/mvr/music" | Out-Null
Copy-Item "$Content/music/track31.mp3" "$Destination/mvr/music"
Copy-Item "$devkit/gfx.wad" "$Destination/mvr"
New-Item -ItemType Directory -Force "$Destination/mvr/maps" | Out-Null
$hub = "$PSScriptRoot/../../../Maps"
if (!(Test-Path "$hub/mvr_start.bsp")) { $hub = "$repo/mvr/maps" }
Copy-Item "$devkit/maps/b_*.bsp","$hub/mvr_start.bsp" "$Destination/mvr/maps"
if (Test-Path "$hub/mvr_start.lit") {
    Copy-Item "$hub/mvr_start.lit" "$Destination/mvr/maps"
}
Copy-Item "$repo/mvr/progs/v_mvrinvoker.mdl","$repo/mvr/progs/v_mvrwrench.mdl","$repo/mvr/progs/v_mvrgren.mdl","$repo/mvr/progs/mvr_canister.mdl","$repo/mvr/progs/v_mvrmmml.mdl","$repo/mvr/progs/mvr_mmmlrack.mdl","$repo/mvr/progs/v_mvrflak.mdl","$repo/mvr/progs/mvr_flakshell.mdl","$repo/mvr/progs/v_mvrnail.mdl","$repo/mvr/progs/mvr_nailmag.mdl","$repo/mvr/progs/v_mvrrebar.mdl","$repo/mvr/progs/mvr_rebarbundle.mdl" "$Destination/mvr/progs"
python "$repo/Misc/rover_body.py" "$Content/progs/player_qbj.mdl" "$Destination/mvr/progs/rover_body.mdl"
if ($LASTEXITCODE) { throw "Rover model generation failed" }

