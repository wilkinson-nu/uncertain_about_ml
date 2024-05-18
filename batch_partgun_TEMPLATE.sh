#!/bin/bash
#SBATCH --image=docker:wilkinsonnu/larcv2:ub20.04-cuda12.1-pytorch2.2.1-larndsim-genie
#SBATCH --qos=shared
#SBATCH --constraint=cpu
#SBATCH --time=600
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=2GB

## These change for each job
THIS_SEED1=__THIS_SEED1__
THIS_SEED2=__THIS_SEED2__
THIS_GEOM=__THIS_GEOM__
OUTDIR=__OUTDIR__
OUTFILE=__OUTFILE__
NEVENTS=__NEVENTS__
PART=__PART__
EMIN=__EMIN__
EMAX=__EMAX__
INPUTS_DIR=__INPUTS_DIR__

THIS_EDEP_MAC=LArBoxPartgun.mac

## Where to do stuff
tempDir=${SCRATCH}/${OUTFILE/.root/}_${THIS_SEED1}_${THIS_SEED2}
echo "Moving to SCRATCH: ${tempDir}"
mkdir ${tempDir}
cd ${tempDir}

## Get the inputs (all in the folder CURRENTLY)
cp ${INPUTS_DIR}/${THIS_EDEP_MAC} .
cp ${INPUTS_DIR}/${THIS_GEOM} .

## Modify the mac file to throw the correct particle
sed -i "s/_PART_/${PART}/g" ${THIS_EDEP_MAC}

## For the correct energy range
sed -i "s/_EMIN_/${EMIN}/g" ${THIS_EDEP_MAC}
sed -i "s/_EMAX_/${EMAX}/g" ${THIS_EDEP_MAC}

## Set the seeds
sed -i "s/_RAND1_/${THIS_SEED1}/g" ${THIS_EDEP_MAC}
sed -i "s/_RAND2_/${THIS_SEED2}/g" ${THIS_EDEP_MAC}

## Run edep-sim
shifter -V ${PWD}:/output --entrypoint edep-sim \
	-C -g ${THIS_GEOM} \
	-o ${OUTFILE} \
	${THIS_EDEP_MAC} \
	-e ${NEVENTS}

## Copy back the edep-sim file
if [ ! -d "${OUTDIR}" ]; then
    mkdir -p ${OUTDIR}
fi
cp ${tempDir}/${OUTFILE} ${OUTDIR}/.

## Clean up
rm -r ${tempDir}

