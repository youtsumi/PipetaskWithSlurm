#!/bin/bash
 
#SBATCH --partition=shared
#
#SBATCH --job-name=my_pipeline_job
#SBATCH --output=my_pipeline_job-%j.txt
#SBATCH --error=my_pipeline_job-%j.txt
#
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=2G
#
#SBATCH --time=2:00:00
 
export REPO=/sdf/group/lsst/camera/IandT/repo_gen3/spot_test_v2
export output=u/youtsumi/run_12781/bf_work
export yamldir=/sdf/group/lsst/camera/IandT/repo_gen3/spot_test_v2/u/youtsumi/work
export mycalibcollection=/calib/run_12781_v3

source /cvmfs/sw.lsst.eu/linux-x86_64/lsst_distrib/w_2021_20/loadLSST.bash
setup lsst_distrib
cd ${REPO}/u/youtsumi/work

# PTCs
srun pipetask run  \
	-d "instrument='LSSTCam' AND exposure.science_program IN ('12781') AND detector in ( 28, 29, 96 ) AND exposure.observation_type = 'flat' AND exposure.observation_reason='flat' " \
	-b ${REPO} \
	-i LSSTCam/raw/all,LSSTCam/calib,${mycalibcollection} \
	-o ${output}/ptcs \
	-p ${yamldir}/measurePhotonTransferCurve.yaml \
	-c ptcSolve:ptcFitType=EXPAPPROXIMATION \
	--register-dataset-types \
	-j 16


# Certify PTCs
butler certify-calibrations ${REPO} ${output}/ptcs ${mycalibcollection} ptc

# Generate BF Kernels
# You must only specify one exposure at a time, I selected the first in the sequence. This generated the kernel for the given detectors.
srun pipetask run \
	-d "instrument='LSSTCam' AND exposure IN (3020111900045) AND detector in ( 28, 29, 96 ) " \
	-b ${REPO} \
	-i LSSTCam/raw/all,LSSTCam/calib,${mycalibcollection}  \
	-o ${output}_v2/bfks \
	-p ${yamldir}/cpBfkSolve.yaml \
	--register-dataset-types \
	--clobber-partial-outputs \
	-j 16

#Certify BF Kernels
butler certify-calibrations ${REPO} ${output}/bfks ${mycalibcollection} bfk
