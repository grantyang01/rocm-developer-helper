#!/usr/bin/env pwsh

$pythonScript = Join-Path $PSScriptRoot "pdf2text.py"
python $pythonScript @args
exit $LASTEXITCODE

