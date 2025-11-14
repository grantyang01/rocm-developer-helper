$testing = "$env:SHISA/testing"
$shader = "$env:SHISA/shader_dev_IL/shaders/winograd/Conv_Winograd_v40_6_0_IL.sp3"

Write-Host "=== Running Winograd Conv Test ===" -ForegroundColor Cyan
conv_test -W128 -H128 -C4 -N2 -K320 -S3 -R3 -k1 --perf all -p $shader

Write-Host "`n=== Running Test Cases (a_case_3) ===" -ForegroundColor Cyan
perl $testing/run_cases.pl -o $env:SHISA/log_dir $testing/cases/a_case_3.csv --perf all -p $shader