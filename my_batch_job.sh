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
#SBATCH --time=24:00:00
 
export REPO=/sdf/group/lsst/camera/IandT/repo_gen3/spot_test_v2
export output=u/youtsumi/run_12781/bf_work_v3
export yamldir=/sdf/group/lsst/camera/IandT/repo_gen3/spot_test_v2/u/youtsumi/work
export superdark=u/youtsumi/calib/dark/run_12781
export superbias=u/jchiang/calib/bias/run_12781/20210525T184949Z 
export superflat=u/abrought/run_12781/bf_work/flats/20210608T205612Z
export defects=u/youtsumi/calib/defects/run_12781

source /cvmfs/sw.lsst.eu/linux-x86_64/lsst_distrib/w_2021_20/loadLSST.bash
setup lsst_distrib
cd ${REPO}/u/youtsumi/work

# PTCs
srun pipetask run  \
	-d "instrument='LSSTCam' AND exposure.science_program IN ('12781') AND detector in ( 28, 29, 96 ) AND exposure.observation_type = 'flat' AND exposure.observation_reason='flat' " \
	-b ${REPO} \
	-i LSSTCam/raw/all,LSSTCam/calib,${superbias},${superdark},${superflat},${defects} \
	-o ${output}/ptcs \
	-p ${yamldir}/measurePhotonTransferCurve.yaml \
	--register-dataset-types \

# Generate BF Kernels
# You must only specify one exposure at a time, I selected the first in the sequence. This generated the kernel for the given detectors.
srun pipetask run \
	-d "instrument='LSSTCam' AND exposure IN (3020111900045) AND detector in ( 28, 29, 96 ) " \
	-b ${REPO} \
	-i LSSTCam/raw/all,LSSTCam/calib,${superbias},${superdark},${superflat},${defects},${output}/ptcs  \
	-o ${output}_v2/bfks \
	-p ${yamldir}/cpBfkSolve.yaml \
	--register-dataset-types \
	--clobber-partial-outputs \

