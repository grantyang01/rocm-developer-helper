# !bin/sh

bin_dir=$(realpath $0|xargs dirname)
RESDIR_PARTIAL=results_partial
#RESDIR=results_base
RESDIR=results_l2_flash_after_zero_shader
mkdir -p "$RESDIR"
TEST_CASES="$bin_dir/cases"
#TEST_CASES="$bin_dir/misa_new_cases"
REF_CACHE="$SHISA/ref_cache"
