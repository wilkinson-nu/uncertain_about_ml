#!/bin/bash

## If I want to pile more on later
FIRST_JOB=0
LAST_JOB=19

## Which neutrino flavors to produce
NU_PDG_ARR=( -16 -14 -12 12 14 16 )

TEMPLATE=batch_beam_TEMPLATE.sh
OUTDIR_ROOT=/global/cfs/cdirs/dune/users/cwilk/LArBoxSim/BEAM
INPUTS_DIR=/global/homes/c/cwilk/LArBoxSim/MC_inputs
FLUX_FILE=DUNE_OptimizedEngineeredNov2017_REGULAR.root

## Loop over the PDGs of interest
for NU_PDG in "${NU_PDG_ARR[@]}"; do
    
    ## FLUX_HIST can be set based on NU_PDG (flux swap)
    if [ "$NU_PDG" -gt 0 ]; then
	FLUX_HIST=numu_FDFHC_flux
    else
	FLUX_HIST=numubar_FDRHC_flux
    fi
    
    ## Loop over flux files
    for N in $(seq ${FIRST_JOB} ${LAST_JOB})
    do
	## Get the relevant file number
	printf -v PADJOB "%03d" ${N}
	
	OUTFILE="LArBoxSim_${NU_PDG}_10k_${PADJOB}.root"
	
	if [ -f "${OUTDIR_ROOT}/EDEPSIM/${OUTFILE/.root/_EDEPSIM.root}" ]; then
	    continue
	fi
	
	echo "Processing ${OUTFILE}"
	
	## Copy the template
	THIS_TEMP=${TEMPLATE/_TEMPLATE/_${NU_PDG}_${PADJOB}}
	cp ${TEMPLATE} ${THIS_TEMP}
	
	## RANDOM SEED FOR EACH JOB
	sed -i "s/__THIS_SEED__/${RANDOM}/g" ${THIS_TEMP}
	sed -i "s/__OUTDIR_ROOT__/${OUTDIR_ROOT//\//\\/}/g" ${THIS_TEMP}
	sed -i "s/__INPUTS_DIR__/${INPUTS_DIR//\//\\/}/g" ${THIS_TEMP}
	sed -i "s/__OUTFILE__/${OUTFILE}/g" ${THIS_TEMP}
	sed -i "s/__FLUX_FILE__/${FLUX_FILE}/g" ${THIS_TEMP}
	sed -i "s/__FLUX_HIST__/${FLUX_HIST}/g" ${THIS_TEMP}
	sed -i "s/__NU_PDG__/${NU_PDG}/g" ${THIS_TEMP}
	
	echo "Submitting ${THIS_TEMP}"
	
	## Submit the template
	sbatch ${THIS_TEMP}
	
	## No need to delete, so done
	rm ${THIS_TEMP}
    done
done
