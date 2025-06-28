#!/bin/bash

bin_dir=$(realpath $0|xargs dirname)
source $bin_dir/config.sh

MISA="$(pwd)/misa_new/"
MISASP3="$(pwd)/misa_new_sp3/"

DEV=0
mkdir -p $RESDIR
ordinal=1
for c in ${TEST_CASES}/part_00[1234]*
do
	for d in fwd bwd wrw
	do
		for t in fp32 fp16 bf16
		do
			p=`echo $c | sed -e 's/.*\///'`
			OUTDIR="$RESDIR/res_${d}_${t}_${p}"
			LOGP="$RESDIR/log_${d}_${t}_${p}.log"
			#DEV=$((1+DEV%7))
			#LOGP=`printf "%s/%03d_dev_%02d_log_%s_%s_%s.log" "$RESDIR" "$ordinal" "$DEV" "$d" "$t" "$p"`
			#(( ordinal = ordinal + 1 ))
			echo "./run_misa_cases.pl -v -misa $MISA -o $OUTDIR -lr /SHISA/ref_cache -sr /SHISA/ref_cache -- $c -k1 -t1004 --device $DEV --misasp3 $MISASP3 --dir $d --type $t | tee $LOGP"
			(( DEV = (DEV + 1) % 8 ))

			OUTDIR="$RESDIR/res_page_${d}_${t}_${p}"
			LOGP="$RESDIR/log_page_${d}_${t}_${p}.log"	
			#DEV=$((1+DEV%7))
			#LOGP=`printf "%s/%03d_dev_%02d_log_page_%s_%s_%s.log" "$RESDIR" "$ordinal" "$DEV" "$d" "$t" "$p"`
			# (( ordinal = ordinal + 1 ))
			echo "./run_misa_cases.pl -v -misa $MISA -o $OUTDIR -lr /SHISA/ref_cache -sr /SHISA/ref_cache -- $c -k1 -t1004 --device $DEV --misasp3 $MISASP3 --dir $d --type $t --dbg_force_alloc_granularity_misa 2097152 --dbg 0 | tee $LOGP"
			(( DEV = (DEV + 1) % 8 ))

			OUTDIR="$RESDIR/res_align4_${d}_${t}_${p}"
			LOGP="$RESDIR/log_align4_${d}_${t}_${p}.log"
			#DEV=$((1+DEV%7))
			#echo "./run_misa_cases.pl -v -misa $MISA -o $OUTDIR -lr /SHISA/ref_cache -sr /SHISA/ref_cache -- $c -k1 -t1004 --device $DEV --misasp3 $MISASP3 --dir $d --type $t --dbg_force_alloc_granularity_misa 2097152 --dbg 1 --dbg_align_start 4 | tee $LOGP"

			OUTDIR="$RESDIR/res_align16_${d}_${t}_${p}"
			LOGP="$RESDIR/log_align16_${d}_${t}_${p}.log"
			#DEV=$((1+DEV%7))
			#echo "./run_misa_cases.pl -v -misa $MISA -o $OUTDIR -lr /SHISA/ref_cache -sr /SHISA/ref_cache -- $c -k1 -t1004 --device $DEV --misasp3 $MISASP3 --dir $d --type $t --dbg_force_alloc_granularity_misa 2097152 --dbg 1 --dbg_align_start 16 | tee $LOGP"
		done
	done
done
