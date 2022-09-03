#!/bin/bash	

# 
# Author: Haykel Snoussi (dr.haykel.snoussi@gmail.com)
# Project: ADNI3 Study for Brain Connectivity - Blueprints 
# March 2022, UT Health San Antonio, Texas
#

echo "--------------------------------------------"
echo "Preprocessing diffusion MRI data for ADNI3 :" 


# DIRS
BASEDIR=/home/snoussi/my_work/ADNI_Study/data
OUTPUTBASE=/home/snoussi/my_work/ADNI_Study/processed

# VARIABLES
SUBJECTID=$1
NUTHREADS=4

# FILES' NAME
# DTI
DTI_4D="${BASEDIR}/${SUBJECTID}/dti/${SUBJECTID}_DTI.nii.gz"
DTI_BVEC="${BASEDIR}/${SUBJECTID}/dti/${SUBJECTID}_DTI.bvec"
DTI_BVAL="${BASEDIR}/${SUBJECTID}/dti/${SUBJECTID}_DTI.bval"

# T1W
T1W_3D="${BASEDIR}/${SUBJECTID}/T1W/${SUBJECTID}_T1W.nii.gz"
T1W_3D_LPS_BC="${OUTPUTBASE}/BiasCorrected/${SUBJECTID}/${SUBJECTID}_T1W_LPS_N4.nii.gz"
T1W_3D_LPS_BC_MASKED="${OUTPUTBASE}/Skull-Stripped/${SUBJECTID}/${SUBJECTID}_T1W_LPS_N4_brain_muse-ss_CD.nii.gz"

# OUTPUTS DIRS AND FILES
LPCA_Denoising_DIR_SUB=${OUTPUTBASE}/LPCA_Denoising/${SUBJECTID}
Degibbs_DIR_SUB=${OUTPUTBASE}/Degibbs/${SUBJECTID}
SYNB0_DISCO_DIR_SUB=${OUTPUTBASE}/SYNB0_DISCO/${SUBJECTID}
EDDY_DIR_SUB=${OUTPUTBASE}/EDDY/${SUBJECTID}
BIASCORRECT_DIR_SUB=${OUTPUTBASE}/BIASCORRECT/${SUBJECTID}

QC_DISCO_DIR_SUB=${OUTPUTBASE}/QC_DISCO
QC_B0BET_DIR_SUB=${OUTPUTBASE}/QC_B0BET

TOPUTP_OUT=${SYNB0_DISCO_DIR_SUB}/outputs/b0_all_topup


DTI_4D_DEN="${LPCA_Denoising_DIR_SUB}/${SUBJECTID}_DTI_Den.nii.gz"
DTI_4D_DEN_DEG="${Degibbs_DIR_SUB}/${SUBJECTID}_DTI_Den_Deg.nii.gz"
DTI_4D_DEN_DEG_MASK="${Degibbs_DIR_SUB}/${SUBJECTID}_DTI_Den_Deg_Mask.nii.gz"
DTI_4D_DEN_DEG_B0="${SYNB0_DISCO_DIR_SUB}/inputs/b0.nii.gz"




echo "-------------------------------------------------"
echo "Start preprocessing diffusion MRI data for Subject :" 
echo $SUBJECTID


LPCA_STEP="ALREADYDONE"
GIBS_STEP="ALREADYDONE"
SYNB_STEP="ALREADYDONE"
MASK_STEP="ALREADYDONE"
EDDY_STEP="ALREADYDONE"
MASK2STEP="ALREADYDONE"
BIAS_STEP="ALREADYDONE"
MASK3STEP="TODO"


echo "PREPROCESSING STEPS:"
echo "LPCA_STEP: "$LPCA_STEP
echo "GIBS_STEP: "$GIBS_STEP
echo "SYNB_STEP: "$SYNB_STEP
echo "MASK_STEP: "$MASK_STEP
echo "EDDY_STEP: "$EDDY_STEP
echo "MASK2STEP: "$MASK2STEP
echo "BIAS_STEP: "$BIAS_STEP
echo "MASK3STEP: "$MASK3STEP



echo "-------------------------------------------------" && date
echo "I. LPCA Denoising using MRtrix3's dwidenoise: "$LPCA_STEP
if [[ $LPCA_STEP == "TODO" ]]; then

	mkdir -p ${LPCA_Denoising_DIR_SUB}
	dwidenoise -nthreads $NUTHREADS ${DTI_4D} ${DTI_4D_DEN}
fi



echo "-------------------------------------------------" && date
echo "II. Gibbs de-ringing using MTrix3's mrdegibbs: "$GIBS_STEP
if [[ $GIBS_STEP == "TODO" ]]; then

	mkdir -p ${Degibbs_DIR_SUB}
	mrdegibbs -nthreads $NUTHREADS -axes 0,1 ${DTI_4D_DEN} ${DTI_4D_DEN_DEG}
fi



echo "-------------------------------------------------" && date
echo "III. Distortion correction using Synb0-DISCO and TOPUP: "$SYNB_STEP

if [[ $SYNB_STEP == "TODO" ]]; then

	mkdir -p ${SYNB0_DISCO_DIR_SUB}/inputs
	mkdir -p ${SYNB0_DISCO_DIR_SUB}/outputs

	# prepare T1 and T1_mask: solution 1 : failed for many subject, it seems because we adding the LPS step
	# cp ${T1W_3D_LPS_BC} ${SYNB0_DISCO_DIR_SUB}/inputs/T1.nii.gz
	# cp ${T1W_3D_LPS_BC_MASKED} ${SYNB0_DISCO_DIR_SUB}/inputs/T1_mask.nii.gz

	# prepare T1 and T1_mask: solution 2, it seems to be better
	cp ${T1W_3D} ${SYNB0_DISCO_DIR_SUB}/inputs/T1.nii.gz

	# Finaly, we give only the first b0 to Synb0-DISCO. We got some error when giving all many b0s
	# dwiextract -bzero -fslgrad ${DTI_BVEC} ${DTI_BVAL} ${DTI_4D_DEN_DEG} ${DTI_4D_DEN_DEG_B0}
	
	fslroi ${DTI_4D_DEN_DEG} ${DTI_4D_DEN_DEG_B0} 0 1

	# Readout = Echo spacing * (EPI factor - 1) * 0.001 = 0.55 (ms) x (116-1) =  0.06325 for ADNI3 (Multi-shell data)
	echo "0 1 0 0.06325" > ${SYNB0_DISCO_DIR_SUB}/inputs/acqparams.txt
	echo "0 1 0 0.000" >> ${SYNB0_DISCO_DIR_SUB}/inputs/acqparams.txt

	# Run container on Genie
	singularity run -e \
	-B ${SYNB0_DISCO_DIR_SUB}/inputs/:/INPUTS \
	-B ${SYNB0_DISCO_DIR_SUB}/outputs/:/OUTPUTS \
	-B /project/biggs/Containers/synb0_disco/license.txt:/extra/freesurfer/license.txt \
	   /project/biggs/Containers/synb0_disco/synb0_latest.sif

	# # Run on my computer
	# singularity run -e \
	# -B ${SYNB0_DISCO_DIR_SUB}/inputs/:/INPUTS \
	# -B ${SYNB0_DISCO_DIR_SUB}/outputs/:/OUTPUTS \
	# -B /home/hsnoussi/software/containers/synb0/license.txt:/extra/freesurfer/license.txt \
	#    /home/hsnoussi/software/containers/synb0/synb0_latest.sif

fi


echo "-------------------------------------------------" && date
echo "IV. QCs + Removal of extracerebral tissue using FSL's BET: "$MASK_STEP

if [[ $MASK_STEP == "TODO" ]]; then

	mkdir -p ${QC_DISCO_DIR_SUB}
	mkdir -p ${QC_B0BET_DIR_SUB}

	# QC of the distortion correction Synb0-DISCO and TOPUP
	fslroi ${TOPUTP_OUT} ${TOPUTP_OUT}_0 0 1
	slicer ${TOPUTP_OUT}_0 -i 0 1700 -s 6 -a ${QC_DISCO_DIR_SUB}/${SUBJECTID}_b0_all_topup_0.ppm

	# Segmentation and QC of the first b0_topup
	fslmaths ${TOPUTP_OUT} -Tmean ${TOPUTP_OUT}_mean
	bet ${TOPUTP_OUT}_mean ${TOPUTP_OUT}_mean_brain -m
	slicer ${TOPUTP_OUT}_mean ${TOPUTP_OUT}_mean_brain_mask -i 0 1700 -s 6 -a ${QC_B0BET_DIR_SUB}/${SUBJECTID}_b0_all_topup_mean_brain_mask.ppm

fi



echo "-------------------------------------------------" && date
echo "V. Eddy current correction using FSL's eddy: "$EDDY_STEP

if [[ $EDDY_STEP == "TODO" ]]; then
	
	mkdir -p ${EDDY_DIR_SUB}

	echo "Create index and acqp txt files"
	ap_nvols=`fslnvols ${DTI_4D_DEN_DEG}`

	echo "0 1 0 0.06325" > ${EDDY_DIR_SUB}/acqp_all.txt
	echo -n "1 "> ${EDDY_DIR_SUB}/index_all.txt

	j=2
	while [ ${j} -le ${ap_nvols} ]; do
	    echo "0 1 0 0.06325" >> ${EDDY_DIR_SUB}/acqp_all.txt
	    echo -n "1 " >> ${EDDY_DIR_SUB}/index_all.txt
	    ((j++))
	done


	echo "Running Eddy ..."
	eddy --imain=${DTI_4D_DEN_DEG} \
	--mask=${TOPUTP_OUT}_mean_brain_mask.nii.gz \
	--index=${EDDY_DIR_SUB}/index_all.txt \
	--acqp=${EDDY_DIR_SUB}/acqp_all.txt \
	--bvecs=${DTI_BVEC} \
	--bvals=${DTI_BVAL} \
	--topup=${SYNB0_DISCO_DIR_SUB}/outputs/topup \
	--out=${EDDY_DIR_SUB}/${SUBJECTID}_ppDTI \
	--data_is_shelled \
	--verbose

	# To add QC: EDDY_QUAD
fi



echo "-------------------------------------------------" && date
echo "VI. Removal of extracerebral tissue using MRtrix3's dwi2mask: "$MASK2STEP
if [[ $MASK2STEP == "TODO" ]]; then
	
	dwi2mask ${EDDY_DIR_SUB}/${SUBJECTID}_ppDTI.nii.gz \
		${EDDY_DIR_SUB}/${SUBJECTID}_ppDTI_brain_mask_Trix3.nii.gz \
		-fslgrad ${EDDY_DIR_SUB}/${SUBJECTID}_ppDTI.eddy_rotated_bvecs ${DTI_BVAL}

	# TO add QC: Slicer
fi



echo "-------------------------------------------------" && date
echo "VII. B0 inhomogeneity correction using MRtrix3's dwibiascorrection: "$BIAS_STEP

if [[ $BIAS_STEP == "TODO" ]]; then

	mkdir -p ${BIASCORRECT_DIR_SUB}

	dwibiascorrect fsl \
		-mask  ${EDDY_DIR_SUB}/${SUBJECTID}_ppDTI_brain_mask_Trix3.nii.gz \
	 	${EDDY_DIR_SUB}/${SUBJECTID}_ppDTI.nii.gz \
	  	-fslgrad ${EDDY_DIR_SUB}/${SUBJECTID}_ppDTI.eddy_rotated_bvecs ${DTI_BVAL} \
	  	${BIASCORRECT_DIR_SUB}/${SUBJECTID}_CorrectDTI.nii.gz

	# TO ADD QC
fi



echo "-------------------------------------------------" && date
echo "VIII. Removal of extracerebral tissue using MRtrix3's dwi2mask: "$MASK3STEP
if [[ $MASK3STEP == "TODO" ]]; then
	
	cp ${EDDY_DIR_SUB}/${SUBJECTID}_ppDTI.eddy_rotated_bvecs ${BIASCORRECT_DIR_SUB}/${SUBJECTID}_CorrectDTI.bvec
	cp ${DTI_BVAL} ${BIASCORRECT_DIR_SUB}/${SUBJECTID}_CorrectDTI.bval

	dwi2mask ${BIASCORRECT_DIR_SUB}/${SUBJECTID}_CorrectDTI.nii.gz \
		${BIASCORRECT_DIR_SUB}/${SUBJECTID}_CorrectDTI_brain_mask.nii.gz \
		-fslgrad ${BIASCORRECT_DIR_SUB}/${SUBJECTID}_CorrectDTI.bvec ${BIASCORRECT_DIR_SUB}/${SUBJECTID}_CorrectDTI.bval

	# TO add QC: Slicer
fi 
