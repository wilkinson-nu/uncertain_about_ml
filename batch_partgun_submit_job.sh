#!/bin/bash

## If I want to pile more on later
FIRST_JOB=1
LAST_JOB=19

## List of particles (probably the energy list is specific)
PART_LIST=( mu+ mu- e+ e- proton gamma pi0 pi+ pi- kaon+ kaon- kaon0 )

declare -A EMIN_ARR=( ["mu+"]=10 \
		      ["mu-"]=10 \
		      ["e+"]=10 \
		      ["e-"]=10 \
		      ["proton"]=10 \
		      ["gamma"]=10 \
		      ["pi0"]=10 \
		      ["pi+"]=10 \
		      ["pi-"]=10 \
		      ["kaon+"]=10 \
		      ["kaon-"]=10 \
		      ["kaon0"]=10)
declare -A EMAX_ARR=( ["mu+"]=10000 \
                      ["mu-"]=10000 \
                      ["e+"]=3000 \
                      ["e-"]=3000 \
                      ["proton"]=5000 \
                      ["gamma"]=3000 \
                      ["pi0"]=5000 \
                      ["pi+"]=5000 \
                      ["pi-"]=5000 \
                      ["kaon+"]=10000 \
                      ["kaon-"]=10000 \
                      ["kaon0"]=10000)

TEMPLATE=batch_partgun_TEMPLATE.sh
THIS_GEOM=BigLArCube.gdml

NEVENTS=10000
NEVTSTR=10k

## As inputs will be relative to here
INPUTS_DIR=${PWD}/MC_inputs

## Loop over particles
for PART in "${PART_LIST[@]}"
do
    ## Change output directory based on the particle gun info
    OUTDIR=/global/cfs/cdirs/dune/users/cwilk/LArBoxSim/PARTGUN/${PART}
    for N in $(seq ${FIRST_JOB} ${LAST_JOB})
    do
	## Get the relevant file number
	printf -v PADJOB "%03d" ${N}

	OUTFILE="${THIS_GEOM/.gdml/}_partgun_${PART}_${EMIN_ARR[${PART}]}to${EMAX_ARR[${PART}]}MeV_${NEVTSTR}_${PADJOB}.root"
	echo "Processing ${OUTFILE}"
	
	## Copy the template
	THIS_TEMP=${TEMPLATE/_TEMPLATE/_${PART}_${NEVTSTR}_${PADJOB}}
	cp ${TEMPLATE} ${THIS_TEMP}
	
	## RANDOM SEED FOR EACH JOB
	sed -i "s/__THIS_SEED1__/${RANDOM}/g" ${THIS_TEMP}
        sed -i "s/__THIS_SEED2__/${RANDOM}/g" ${THIS_TEMP}
	sed -i "s/__OUTDIR__/${OUTDIR//\//\\/}/g" ${THIS_TEMP}
	sed -i "s/__THIS_GEOM__/${THIS_GEOM}/g" ${THIS_TEMP}
	sed -i "s/__OUTFILE__/${OUTFILE}/g" ${THIS_TEMP}
	sed -i "s/__PART__/${PART}/g" ${THIS_TEMP}
	sed -i "s/__NEVENTS__/${NEVENTS}/g" ${THIS_TEMP}
	sed -i "s/__EMIN__/${EMIN_ARR[${PART}]}/g" ${THIS_TEMP}
        sed -i "s/__EMAX__/${EMAX_ARR[${PART}]}/g" ${THIS_TEMP}
	sed -i "s/__INPUTS_DIR__/${INPUTS_DIR//\//\\/}/g" ${THIS_TEMP}
	echo "Submitting ${THIS_TEMP}"
	
	## Submit the template
	sbatch ${THIS_TEMP}
	
	## No need to delete, so done
	rm ${THIS_TEMP}
    done
done
