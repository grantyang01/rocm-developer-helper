"""Clone GPU Interface repository - cross-platform (Windows 11 & Linux)"""

import sys
import shutil
import subprocess
from pathlib import Path


def run(cmd, cwd=None):
    """Run command and raise exception on failure"""
    result = subprocess.run(cmd, cwd=cwd, shell=isinstance(cmd, str))
    if result.returncode != 0:
        raise RuntimeError(f"Command failed: {' '.join(cmd) if isinstance(cmd, list) else cmd}")


def clone_gi(target, gi_branch=None):
    """Clone GPU Interface and dependencies"""
    target = Path(target)
    
    # Remove and recreate target directory
    try:
        if target.exists():
            shutil.rmtree(target)
        target.mkdir(parents=True)
    except Exception as e:
        raise RuntimeError(f"Failed to create target directory: {e}")
    
    # Clone gpu_interface
    cmd = ["git", "clone", "git@github.com:LibAmd/SHISA_gpu_interface.git"]
    if gi_branch:
        cmd.extend(["-b", gi_branch])
    cmd.append(str(target))
    run(cmd)
    
    # Setup drivers (sparse checkout)
    run(["git", "init", "drivers"], cwd=target)
    drivers = target / "drivers"
    run(["git", "sparse-checkout", "set", 
         "drivers/pxproxy", "drivers/inc/asic_reg", 
         "drivers/inc/shared", "drivers/dx/dxx/vam"], cwd=drivers)
    run(["git", "remote", "add", "origin", 
         "git@github.com:AMD-Radeon-Driver/drivers.git"], cwd=drivers)
    run(["git", "pull", "--depth", "1", "origin", "amd/release/23.30"], cwd=drivers)
    
    # Move directories
    try:
        shutil.move(str(drivers / "drivers" / "pxproxy"), str(drivers))
        shutil.move(str(drivers / "drivers" / "inc"), str(drivers))
        shutil.move(str(drivers / "drivers" / "dx" / "dxx" / "vam"), str(drivers))
    except Exception as e:
        raise RuntimeError(f"Failed to reorganize drivers structure: {e}")
    
    # Update submodules
    run(["git", "submodule", "update", "--init"], cwd=target)
    
    # Apply pal_navi patch
    pal_navi = target / "pal_navi"
    run(["git", "apply", "../0001-PAL_CLIENT_SHISA.pal_navi.patch"], cwd=pal_navi)
    
    # Apply pal_vega patch
    pal_vega = target / "pal_vega"
    run(["git", "apply", "../0001-PAL_CLIENT_SHISA.pal_vega.patch"], cwd=pal_vega)
    run(["git", "submodule", "update", "--init"], cwd=pal_vega)
    
    # Fix .gitmodules
    gitmodules = pal_vega / "shared/devdriver/.gitmodules"
    if gitmodules.exists():
        try:
            text = gitmodules.read_text()
            gitmodules.write_text(text.replace("Developer-Solutions", "AMD-Developer-Solutions"))
        except Exception as e:
            raise RuntimeError(f"Failed to fix .gitmodules: {e}")
    
    # Update all submodules recursively
    run(["git", "submodule", "update", "--init", "--recursive"], cwd=target)
    
    # Patch rapidjson AFTER submodules are initialized
    rapidjson = pal_navi / "shared/devdriver/third_party/rapidjson/include/rapidjson/document.h"
    if rapidjson.exists():
        try:
            text = rapidjson.read_text()
            text = text.replace("const SizeType length;", "SizeType length;")
            rapidjson.write_text(text)
            print(f"✓ Patched rapidjson document.h")
        except Exception as e:
            print(f"Warning: Failed to patch rapidjson: {e}")
    else:
        print(f"Warning: rapidjson not found at {rapidjson}")
    
    print(f"✓ GPU Interface cloned successfully: {target}")


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Clone GPU Interface")
    parser.add_argument("target", nargs="?", default="gpu_interface", help="Target directory (default: gpu_interface)")
    parser.add_argument("-b", "--branch", default="", help="Branch name (optional)")
    args = parser.parse_args()
    
    try:
        clone_gi(args.target, args.branch)
    except Exception as e:
        print(f"✗ Error: {e}", file=sys.stderr)
        sys.exit(1)
