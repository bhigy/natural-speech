#!/bin/bash

# Does a single iteration of HERest training.
#
# This handles the parallel splitting and recombining
# of the accumulator files.  This is neccessary to
# prevent inccuracies and eventual failure with large
# amounts of training data.
#
# According to Phil Woodland, one accumulator file
# should be generated for about each hour of training
# data.
#
# Parameters:
#   $1 - root directory (where HMM directories are, tiedlist, wintri.mlf)
#   $2 - name of existing HMM directory
#   $3 - name of new output HMM directory
#   $4 - name of model list (tiedlist or monophones1)
#   $5 - training mlf (wintri.mlf or aligned2.mlf)
#   $6 - minimum examples -m switch for HERest
#   $7 - "text" if we want text output of HMM
#
# Environment variable $HEREST_SPLIT should be set to how
# many chunks to split the training data into.
#
# This is a version that can split up the work amoung multiple
# processors/cores on the same machine.  The environment variable
# $HEREST_THREADS controls the number of threads.
# Thanks to Mikel Penagarikano.

# Delete any existing log file
rm -f $1/$3.log

# Make sure we have a place to put things
mkdir -p $1/$3
rm -f $1/$3/HER*.acc

# Create all the accumulator files, parallaize over $HEREST_THREADS workers
for ((I=1,J=0;I<=$HEREST_SPLIT;)); do
    for ((T=0;T<$HEREST_THREADS&I<=$HEREST_SPLIT;T++,I++,J++)); do
        perl $HTK_SCRIPTS/OutputEvery.pl $1/train.scp $HEREST_SPLIT $J > $1/train_temp_split_$T.scp

        HERest -B -m $6 -A -T 1 -p $I -s $1/$3/stats_$3 -C $HTK_COMMON/$FEAT_CONF_FILE -I $1/$5 -t 250.0 150.0 2000.0 -S $1/train_temp_split_$T.scp -H $1/$2/macros -H $1/$2/hmmdefs -M $1/$3 $1/$4 > $1/THREAD_$T.log &
    done
    wait
    for ((t=0;t<$T;t++)); do cat $1/THREAD_$t.log >> $1/$3.log; rm $1/THREAD_$t.log ; done
done

ls -1 $1/$3/HER*.acc >$1/acc_files.txt

# Now combine them all and create the new HMM definition
if [[ $7 != "text" ]]
then
HERest -B -m $6 -A -T 1 -p 0 -s $1/$3/stats_$3 -C $HTK_COMMON/$FEAT_CONF_FILE -I $1/$5 -t 250.0 150.0 2000.0 -S $1/acc_files.txt -H $1/$2/macros -H $1/$2/hmmdefs -M $1/$3 $1/$4 >>$1/$3.log
else
HERest -m $6 -A -T 1 -p 0 -s $1/$3/stats_$3 -C $HTK_COMMON/$FEAT_CONF_FILE -I $1/$5 -t 250.0 150.0 2000.0 -S $1/acc_files.txt -H $1/$2/macros -H $1/$2/hmmdefs -M $1/$3 $1/$4 >>$1/$3.log
fi

rm -f $1/train_temp_split.scp $1/acc_files.txt
rm -f $1/$3/HER*.acc
