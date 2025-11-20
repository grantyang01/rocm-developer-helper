# Installation Guide for SSP/SP3 VSCode Extension

## Quick Install (Easiest)

### Option 1: Direct Copy (No Build Required)

1. **Copy the extension folder** to VSCode extensions directory:

```powershell
# Windows
$dest = "$env:USERPROFILE\.vscode\extensions\ssp-language-support-0.1.0"
Copy-Item -Recurse C:\work\rdh\vscode-ssp-extension $dest
```

2. **Reload VS Code**: 
   - Press `Ctrl+Shift+P`
   - Type "Reload Window" and press Enter

3. **Test**: Open any `.ssp` or `.sp3` file - syntax highlighting should work!

---

## Option 2: Build and Install VSIX Package

### Prerequisites

```powershell
# Install Node.js and npm (if not already installed)
winget install OpenJS.NodeJS

# Install vsce (VSCode Extension Manager)
npm install -g @vscode/vsce
```

### Build Steps

```powershell
cd C:\work\rdh\vscode-ssp-extension

# Build the .vsix package
vsce package
# This creates: ssp-language-support-0.1.0.vsix
```

### Install in VSCode

1. Open VS Code
2. Go to Extensions (`Ctrl+Shift+X`)
3. Click `...` (More Actions) → `Install from VSIX...`
4. Select `ssp-language-support-0.1.0.vsix`
5. Reload VS Code

---

## Verify Installation

1. Open a `.ssp` file (e.g., `C:\work\shisa\shader_dev_SSP\shaders\GEMM\gemm_f32_bf16.ssp`)

2. Check status bar (bottom right) - should show "SSP" or "SP3"

3. Keywords should be highlighted:
   - `function`, `var`, `if` - control keywords
   - `#include`, `#define` - preprocessor directives
   - `v_mfma_*`, `s_waitcnt` - GPU instructions
   - `v0`, `s1`, `exec` - registers

---

## Troubleshooting

### Extension Not Loading

```powershell
# Check if extension is recognized
code --list-extensions | Select-String "ssp"

# If not found, verify folder name
Get-ChildItem "$env:USERPROFILE\.vscode\extensions" | Select-String "ssp"
```

### Syntax Highlighting Not Working

1. Check file association: Click language mode (bottom right) → "SSP" or "SP3"
2. Manually set: `Ctrl+K M` → type "ssp" → Enter
3. Reload Window: `Ctrl+Shift+P` → "Reload Window"

### Errors in package.json

```powershell
# Validate the extension
cd C:\work\rdh\vscode-ssp-extension
vsce ls
```

---

## Next Steps

### Customize Colors

Add to your VSCode `settings.json`:

```json
"editor.tokenColorCustomizations": {
  "textMateRules": [
    {
      "scope": "keyword.other.instruction.mfma.ssp",
      "settings": {
        "foreground": "#C586C0",
        "fontStyle": "bold"
      }
    },
    {
      "scope": "variable.other.register.vector.ssp",
      "settings": {
        "foreground": "#4EC9B0"
      }
    }
  ]
}
```

### Test Files

Create a test file to verify highlighting:

```ssp
// test.ssp
#include "test.sp3"
#define N_WAVES 8

function test_shader(var x, var y) begin
    var result = 0
    
    // MFMA instruction
    v_mfma_f32_32x32x16_bf16 v[0:3], v0, v1, v[0:3]
    
    // Scalar operations
    s_waitcnt vmcnt(0)
    s_barrier
    
    if (x > 0) begin
        result = x + y
    end
    
    return result
end
```

---

## Uninstall

```powershell
# Remove extension
Remove-Item "$env:USERPROFILE\.vscode\extensions\ssp-language-support-0.1.0" -Recurse -Force

# Or through VS Code
# Extensions → SSP Language Support → Uninstall
```

