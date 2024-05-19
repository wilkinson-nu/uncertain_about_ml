#!/bin/bash
#SBATCH --image=docker:wilkinsonnu/larcv2:ub20.04-cuda12.1-pytorch2.2.1-larndsim-genie
#SBATCH --qos=shared
#SBATCH --constraint=cpu
#SBATCH --time=600
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=2GB

## These change for each job
THIS_SEED=__THIS_SEED__
OUTDIR_ROOT=__OUTDIR_ROOT__
OUTFILE=__OUTFILE__
INPUTS_DIR=__INPUTS_DIR__
FLUX_FILE=__FLUX_FILE__
FLUX_HIST=__FLUX_HIST__
NU_PDG=__NU_PDG__

## Fixed
NEVTS=10000
THIS_EDEP_MAC=LArBoxBeam.mac
TUNE=AR23_20i_00_000
GEOM_FILE=BigLArCube.gdml

## To calculate from inputs (recalculate with: gmxpl -f ${GEOM_FILE} -L cm -D g_cm3 -o ${GEOM_FILE/.gdml/_maxpath.xml} -n 10000 -r 1000 --seed 0)
MAXPATH_FILE=${GEOM_FILE/.gdml/_maxpath.xml}

## Where to do stuff
tempDir=${SCRATCH}/${OUTFILE/.root/}_${THIS_SEED}
echo "Moving to SCRATCH: ${tempDir}"
mkdir ${tempDir}
cd ${tempDir}

## Get the inputs (all in the folder CURRENTLY)
cp -r ${INPUTS_DIR}/* .

## The flux string is doing a loooot of work here
shifter -V ${PWD}:/output --entrypoint gevgen_fnal \
	-f "${FLUX_FILE},${NU_PDG}[${FLUX_HIST}]" \
	-g ${GEOM_FILE} \
	-m ${MAXPATH_FILE} \
	-L cm -D g_cm3 \
	-n ${NEVTS} \
	--cross-sections ${TUNE}_v340_splines.xml.gz \
	--tune ${TUNE} \
	--seed ${THIS_SEED}

## The above generates neutrinos traveling in the direction 0,0,1 from the point 0,0,0
## More fancy things can be done with flux arguments like:
## 	-f "${FLUX_FILE},${NU_PDG}[${FLUX_HIST}];r=1000,dir=(0,0,1),spot=(0,0,-3000)" \


## Convert to rootracker
shifter -V ${PWD}:/output --entrypoint gntpc \
	-i gntp.0.ghep.root -f rootracker -o gntp.0.roo.root

## Copy back the GENIE output file
if [ ! -d "${OUTDIR_ROOT}/GENIE" ]; then
    mkdir -p ${OUTDIR_ROOT}/GENIE
fi
cp ${tempDir}/gntp.0.roo.root ${OUTDIR_ROOT}/GENIE/${OUTFILE/.root/_GENIE.root}

## Run edep-sim
shifter -V ${PWD}:/output --entrypoint edep-sim \
	-C -g ${GEOM_FILE} \
	-o ${OUTFILE/.root/_EDEPSIM.root} \
	${THIS_EDEP_MAC} \
	-e ${NEVTS}

## Copy back the edep-sim file
if [ ! -d "${OUTDIR_ROOT}/EDEPSIM" ]; then
    mkdir -p ${OUTDIR_ROOT}/EDEPSIM
fi
cp ${tempDir}/${OUTFILE/.root/_EDEPSIM.root} ${OUTDIR_ROOT}/EDEPSIM/.

## Clean up
rm -r ${tempDir}

