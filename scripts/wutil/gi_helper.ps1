# GPU Interface Setup Helper Functions
# Translated from gi-setup bash script

. "$PSScriptRoot\tools.ps1"

function Get-GpuInterface {
    python $PSScriptRoot/../putil/clone_gi.py gpu_interface
}

function Build-GpuInterface {
    # To build gpu_interface with support for GFX10, GFX11, GFX11.5, GFX12:
    cmake -S . -B build_navi -G "Visual Studio 17 2022"
    cmake --build build_navi --config Release
    cmake --build build_navi
    
    # To build gpu_interface with support for GFX9, GFX10, GFX11:
    cmake -S . -B build_vega -G "Visual Studio 17 2022" -DGPU_INTERFACE_PAL_VEGA_SUPPORT=ON
    cmake --build build_vega --config Release
    cmake --build build_vega
}
