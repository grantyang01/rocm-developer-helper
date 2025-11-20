# SSP/SP3 Language Support for VS Code

Syntax highlighting and language support for SHISA Shader Processor (SSP) and SP3 assembly language.

## Features

- **Syntax Highlighting** for:
  - SSP keywords (`function`, `shader`, `var`, `if`, `for`, `while`, etc.)
  - Preprocessor directives (`#include`, `#define`, `#ifdef`, etc.)
  - AMD GPU instructions (VALU, SALU, MFMA, buffer/memory operations)
  - Registers (vector `v[0-9]+`, scalar `s[0-9]+`, special registers)
  - Numbers (hex, binary, decimal, float)
  - Comments (line `//` and block `/* */`)
  - Labels and functions

- **Code Folding** for:
  - Functions and shaders
  - Control flow blocks (`if`, `for`, `while`)

- **Auto-closing** brackets, parentheses, and quotes

## Supported File Extensions

- `.ssp` - SHISA Shader Processor files
- `.sp3` - SP3 assembly files
- `.radasm2` - Radeon assembly definition files

## Installation

### From VSIX (Recommended)

1. Build the extension: `vsce package`
2. Install in VS Code: Extensions → ... → Install from VSIX

### From Source

1. Clone this repository
2. Copy to: `%USERPROFILE%\.vscode\extensions\ssp-language-support-0.1.0`
3. Reload VS Code

## Usage

Open any `.ssp` or `.sp3` file and syntax highlighting will activate automatically.

## Based On

This extension is based on the Visual Studio SHISA Tools extension, specifically:
- Grammar from `RadAsm2Lexer.g4`
- Instruction definitions from architecture `.radasm2` files
- Syntax highlighting classifications from `ShisaTools.Syntax`

## Development

To enhance this extension:

1. **Add more instructions**: Edit `syntaxes/ssp.tmLanguage.json` → `instructions` patterns
2. **Add architecture-specific constants**: Extract from `.radasm2` files
3. **Implement Language Server**: For IntelliSense, go-to-definition, error checking

### Generating Instruction Lists

To extract instructions from `.radasm2` files:

```bash
# From Visual Studio plugin source
grep -h "^instruction" ShisaTools.Syntax/DefaultConfiguration/*.radasm2 | sort -u
```

## Future Enhancements

- [ ] IntelliSense/autocompletion
- [ ] Hover tooltips for instructions
- [ ] Go-to-definition for functions/labels
- [ ] Error diagnostics
- [ ] Snippets for common patterns
- [ ] Architecture-specific instruction sets (MI300, GFX10, GFX11, etc.)

## License

[Your License Here]

## Contributing

Contributions welcome! Please submit issues and pull requests.

