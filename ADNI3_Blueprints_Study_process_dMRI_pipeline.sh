#!/bin/bash	



# 
# Author: Haykel Snoussi (dr.haykel.snoussi@gmail.com)
# Project: ADNI3 Study for Brain Connectivity - Blueprints 
# March 2022, UT Health San Antonio, Texas
#

echo "-------------------------------------------------"
echo "Processing diffusion MRI data for ADNI3 :" 

# DIRS
BASEDIR=/home/snoussi/my_work/ADNI_Study/data
OUTPUTBASE=/home/snoussi/my_work/ADNI_Study/processed
FILES_FOR_FSL_DIR=/home/snoussi/my_work/ADNI_Study/scripts/2_DTI_pipeline/22_process_dMRI/files_for_fsl
REORIENTRPI=/home/snoussi/my_work/ADNI_Study/scripts/2_DTI_pipeline/22_process_dMRI/ReOrientRPI.sh

# VARIABLES/PARAMETERS
SUBJECTID=$1
NUTHREADS=2


# OUTPUTS DIRS AND FILES
T1W_3D_LPS_BC_MASKED=${OUTPUTBASE}/Skull-Stripped/${SUBJECTID}/${SUBJECTID}_T1W_LPS_N4_brain_muse-ss_CD.nii.gz
T1W_3D_LPS_BC_MASKED_RPI=${OUTPUTBASE}/Skull-Stripped/${SUBJECTID}/${SUBJECTID}_T1W_LPS_N4_brain_muse-ss_CD_RPI.nii.gz

T1W_3D_LPS_BC=${OUTPUTBASE}/BiasCorrected/${SUBJECTID}/${SUBJECTID}_T1W_LPS_N4.nii.gz
T1W_3D_LPS_BC_RPI=${OUTPUTBASE}/BiasCorrected/${SUBJECTID}/${SUBJECTID}_T1W_LPS_N4_RPI.nii.gz


BIASCORRECT_DIR_SUB=${OUTPUTBASE}/BIASCORRECT/${SUBJECTID}
CONNECTIVITY_DIR_SUB=${OUTPUTBASE}/Connectivity/${SUBJECTID}
BEDPOSTX_DIR_SUB=${OUTPUTBASE}/Connectivity/${SUBJECTID}/diffusion.bedpostX

RECONALL_DIR_SUB=${OUTPUTBASE}/Recon_all/${SUBJECTID}

QC_DIFF2STR=${OUTPUTBASE}/QC_process_part/QC_DIFF2STR
QC_STR2STANDARD=${OUTPUTBASE}/QC_process_part/QC_STR2STANDARD
QC_DIFF2STANDARD=${OUTPUTBASE}/QC_process_part/QC_DIFF2STANDARD
QC_CONVERTWARP=${OUTPUTBASE}/QC_process_part/QC_CONVERTWARP

mkdir -p ${QC_DIFF2STR}
mkdir -p ${QC_STR2STANDARD}
mkdir -p ${QC_DIFF2STANDARD}
mkdir -p ${QC_CONVERTWARP}


echo "-------------------------------------------------"
echo "Start processing diffusion MRI data for Subject :" 
echo $SUBJECTID

DTIFIT_STEP="DONE"
BPOSTX_STEP="DONE"
PREPAR_STEP="DONE"
REGIST_STEP="DONE"
XTRACT_STEP="DONE"
XSTATS_STEP="DONE"
XBLUEP_STEP="TODO"

echo "PROCESSING STEPS:"
echo "I.   DTIFIT_STEP: "$DTIFIT_STEP
echo "II.  BPOSTX_STEP: "$BPOSTX_STEP
echo "III. PREPAR_STEP: "$PREPAR_STEP
echo "IV.  REGIST_STEP: "$REGIST_STEP
echo "V.   XTRACT_STEP: "$XTRACT_STEP
echo "VI.  XSTATS_STEP: "$XSTATS_STEP
echo "VII. XBLUEP_STEP: "$XBLUEP_STEP


echo -e "\n-------------------------------------------------" && date && echo "-------------------------------------------------"
echo "I. Diffusion tensor estimation using FSL's DTIFIT : "$DTIFIT_STEP

if [[ $DTIFIT_STEP == "TODO" ]]; then


	# Prepare data for BedpostX
	mkdir -p ${CONNECTIVITY_DIR_SUB}/diffusion

	echo "I.1 Copy requried data"
	cp ${BIASCORRECT_DIR_SUB}/${SUBJECTID}_CorrectDTI.bvec ${CONNECTIVITY_DIR_SUB}/diffusion/bvecs
	cp ${BIASCORRECT_DIR_SUB}/${SUBJECTID}_CorrectDTI.bval ${CONNECTIVITY_DIR_SUB}/diffusion/bvals
	cp ${BIASCORRECT_DIR_SUB}/${SUBJECTID}_CorrectDTI.nii.gz ${CONNECTIVITY_DIR_SUB}/diffusion/data.nii.gz
	cp ${BIASCORRECT_DIR_SUB}/${SUBJECTID}_CorrectDTI_brain_mask.nii.gz ${CONNECTIVITY_DIR_SUB}/diffusion/nodif_brain_mask.nii.gz

	echo "I.2 Running ditfit..."
	# create output folder for FSL's DTIFIT
	mkdir ${CONNECTIVITY_DIR_SUB}/dtifit

	singularity exec /home/snoussi/software/Containers/fsl_6051.sif dtifit \
				--data=${CONNECTIVITY_DIR_SUB}/diffusion/data.nii.gz \
				--mask=${CONNECTIVITY_DIR_SUB}/diffusion/nodif_brain_mask.nii.gz \
				--bvecs=${CONNECTIVITY_DIR_SUB}/diffusion/bvecs \
				--bvals=${CONNECTIVITY_DIR_SUB}/diffusion/bvals \
				--out=${CONNECTIVITY_DIR_SUB}/dtifit/dti \
				--save_tensor --kurt --kurtdir

fi


echo -e "\n-------------------------------------------------" && date && echo "-------------------------------------------------"
echo "II. Fitting the crossing fiber model using FSL's bedpostx : "$BPOSTX_STEP

if [[ $BPOSTX_STEP == "TODO" ]]; then


	echo "II.1 Check data"
	singularity exec /project/biggs/Containers/muse_container/cbica_1.0.sif bedpostx_datacheck ${CONNECTIVITY_DIR_SUB}/diffusion

	echo "II.2 Start BedpostX data"
	singularity exec /project/biggs/Containers/muse_container/cbica_1.0.sif bedpostx ${CONNECTIVITY_DIR_SUB}/diffusion

fi



echo -e "\n-------------------------------------------------" && date && echo "-------------------------------------------------"
echo "III. Prepare some requried file for Registration of Structural then to MNI152 standard space: "$PREPAR_STEP

if [[ $PREPAR_STEP == "TODO" ]]; then

	echo "III.1 Get first b0 --->"
	fslroi ${BIASCORRECT_DIR_SUB}/${SUBJECTID}_CorrectDTI.nii.gz ${BIASCORRECT_DIR_SUB}/${SUBJECTID}_CorrectDTI_b0.nii.gz 0 1
	fslmaths ${BIASCORRECT_DIR_SUB}/${SUBJECTID}_CorrectDTI_b0.nii.gz -mul ${BIASCORRECT_DIR_SUB}/${SUBJECTID}_CorrectDTI_brain_mask.nii.gz ${BEDPOSTX_DIR_SUB}/nodif_brain.nii.gz



	echo "III.2 A step of re-orientation is requried"
	echo "III.2.1 Reorient T1W Brain-Extracted"
	singularity exec /project/biggs/Containers/muse_container/cbica_1.0.sif ${REORIENTRPI} ${T1W_3D_LPS_BC_MASKED} ${OUTPUTBASE}/Skull-Stripped/${SUBJECTID}
	echo "III.2.2 Reorient T1W non-Brain-Extracted"
	singularity exec /project/biggs/Containers/muse_container/cbica_1.0.sif ${REORIENTRPI} ${T1W_3D_LPS_BC} ${OUTPUTBASE}/BiasCorrected/${SUBJECTID}

fi




echo -e "\n-------------------------------------------------" && date && echo "-------------------------------------------------"
echo "IV. Registration to Structural then to MNI152 standard space using FSL's FLIRT and FNIRT : "$REGIST_STEP


if [[ $REGIST_STEP == "TODO" ]]; then
	

	echo " Start Registration and QC: Check Registration"

	echo "Starting FLIRT affine: diff2str.mat and str2diff.mat"
	#diffusion to structural
	flirt -in ${BEDPOSTX_DIR_SUB}/nodif_brain.nii.gz -ref ${T1W_3D_LPS_BC_MASKED_RPI} -omat ${BEDPOSTX_DIR_SUB}/xfms/diff2str.mat -dof 12
	#structural to diffusion inverse
	convert_xfm -omat ${BEDPOSTX_DIR_SUB}/xfms/str2diff.mat -inverse ${BEDPOSTX_DIR_SUB}/xfms/diff2str.mat


	echo "Starting FLIRT affine: str2standard.mat and standard2str.mat"
	#structural to standard affine
	flirt -in ${T1W_3D_LPS_BC_MASKED_RPI} -ref ${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz -omat ${BEDPOSTX_DIR_SUB}/xfms/str2standard.mat -dof 12
	#standard to structural affine inverse
	convert_xfm -omat ${BEDPOSTX_DIR_SUB}/xfms/standard2str.mat -inverse ${BEDPOSTX_DIR_SUB}/xfms/str2standard.mat


	echo "Starting FLIRT affine: diff2standard.mat and standard2diff.mat"
	#diffusion to standard (6 & 12 DOF)
	convert_xfm -omat ${BEDPOSTX_DIR_SUB}/xfms/diff2standard.mat -concat ${BEDPOSTX_DIR_SUB}/xfms/str2standard.mat ${BEDPOSTX_DIR_SUB}/xfms/diff2str.mat
	#standard to diffusion (12 & 6 DOF)
	convert_xfm -omat ${BEDPOSTX_DIR_SUB}/xfms/standard2diff.mat -inverse ${BEDPOSTX_DIR_SUB}/xfms/diff2standard.mat



	echo "Starting FNIRT: str2standard.mat and standard2str.mat"
	#structural to standard: non-linear
	fnirt --in=${T1W_3D_LPS_BC_RPI} --aff=${BEDPOSTX_DIR_SUB}/xfms/str2standard.mat --cout=${BEDPOSTX_DIR_SUB}/xfms/str2standard_warp --config=T1_2_MNI152_2mm
	#standard to structural: non-linear
	invwarp -w ${BEDPOSTX_DIR_SUB}/xfms/str2standard_warp -o ${BEDPOSTX_DIR_SUB}/xfms/standard2str_warp -r ${T1W_3D_LPS_BC_MASKED_RPI}

	echo "Starting FNIRT: diff2standard.mat and standard2diff.mat"
	#diffusion to standard: non-linear
	convertwarp -o ${BEDPOSTX_DIR_SUB}/xfms/diff2standard -r ${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz --premat=${BEDPOSTX_DIR_SUB}/xfms/diff2str.mat --warp1=${BEDPOSTX_DIR_SUB}/xfms/str2standard_warp
	#standard to diffusion: non-linear
	convertwarp -o ${BEDPOSTX_DIR_SUB}/xfms/standard2diff -r ${BEDPOSTX_DIR_SUB}/nodif_brain.nii.gz --warp1=${BEDPOSTX_DIR_SUB}/xfms/standard2str_warp --postmat=${BEDPOSTX_DIR_SUB}/xfms/str2diff.mat





	echo -e "\nStart QC of registration"
	#check images
	mkdir ${BEDPOSTX_DIR_SUB}/xfms/reg_check

	echo "Starting diff2str check"
	flirt -in ${BEDPOSTX_DIR_SUB}/nodif_brain.nii.gz -ref ${T1W_3D_LPS_BC_MASKED_RPI} -init ${BEDPOSTX_DIR_SUB}/xfms/diff2str.mat -out ${BEDPOSTX_DIR_SUB}/xfms/reg_check/diff2str_check.nii.gz
	slicer ${T1W_3D_LPS_BC_MASKED_RPI} ${BEDPOSTX_DIR_SUB}/xfms/reg_check/diff2str_check.nii.gz -s 10 -a ${QC_DIFF2STR}/${SUBJECTID}_diff2str_check.ppm


	echo "Starting str2standard check"
	applywarp --in=${T1W_3D_LPS_BC_MASKED_RPI} --ref=${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz --warp=${BEDPOSTX_DIR_SUB}/xfms/str2standard_warp --out=${BEDPOSTX_DIR_SUB}/xfms/reg_check/str2standard_check.nii.gz
	slicer ${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz ${BEDPOSTX_DIR_SUB}/xfms/reg_check/str2standard_check.nii.gz -s 10 -a ${QC_STR2STANDARD}/${SUBJECTID}_str2standard_check.ppm


	echo "Starting diff2standard (warp & premat) check"
	applywarp --in=${BEDPOSTX_DIR_SUB}/nodif_brain.nii.gz --ref=${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz --warp=${BEDPOSTX_DIR_SUB}/xfms/str2standard_warp --premat=${BEDPOSTX_DIR_SUB}/xfms/diff2str.mat --out=${BEDPOSTX_DIR_SUB}/xfms/reg_check/diff2standard_check.nii.gz
	slicer ${FSLDIR}/data/standard/MNI152_T1_2mm_brain ${BEDPOSTX_DIR_SUB}/xfms/reg_check/diff2standard_check.nii.gz -s 10 -a ${QC_DIFF2STANDARD}/${SUBJECTID}_diff2standard_check.ppm


	echo "Starting convert warp (diff2standard as used in XTRACT using convertwarp) check"
	applywarp --in=${BEDPOSTX_DIR_SUB}/nodif_brain.nii.gz --ref=${FSLDIR}/data/standard/MNI152_T1_2mm_brain --warp=${BEDPOSTX_DIR_SUB}/xfms/diff2standard --out=${BEDPOSTX_DIR_SUB}/xfms/reg_check/diff2standard_check_applywarp.nii.gz
	slicer ${FSLDIR}/data/standard/MNI152_T1_2mm_brain ${BEDPOSTX_DIR_SUB}/xfms/reg_check/diff2standard_check_applywarp.nii.gz -s 10 -a ${QC_CONVERTWARP}/${SUBJECTID}_diff2standard_check_applywarp.ppm


	echo -e "\nFinished with Registration and QC"


fi



echo -e "\n-------------------------------------------------" && date && echo "-------------------------------------------------"
echo "V. Cross-Species Tractography using FSL's XTRACT : "$XTRACT_STEP

if [[ $XTRACT_STEP == "TODO" ]]; then

   	XTRACT_DIR_SUB=${OUTPUTBASE}/Connectivity/${SUBJECTID}/myxtract_gpu
	
	mkdir -p ${XTRACT_DIR_SUB}
	
   	#touch ${XTRACT_DIR_SUB}/xtract_options.txt
    echo "--nsamples=5000" > ${XTRACT_DIR_SUB}/xtract_options.txt
    singularity exec --nv /home/snoussi/software/Containers/fsl_6051.sif xtract -bpx ${BEDPOSTX_DIR_SUB} -out ${XTRACT_DIR_SUB} -species HUMAN -ptx_options ${XTRACT_DIR_SUB}/xtract_options.txt -gpu

    #xtract_viewer -dir myxtract -species HUMAN

fi



echo -e "\n-------------------------------------------------" && date && echo "-------------------------------------------------"
echo "VI. Extracting tract-wise summary statistics with FSL's XTRACT_STATS : "$XSTATS_STEP

if [[ $XSTATS_STEP == "TODO" ]]; then


	singularity exec /home/snoussi/software/Containers/fsl_6051.sif xtract_stats \
	-d ${CONNECTIVITY_DIR_SUB}/dtifit/dti_ \
	-xtract ${CONNECTIVITY_DIR_SUB}/myxtract_gpu \
	-w ${CONNECTIVITY_DIR_SUB}/diffusion.bedpostX/xfms/standard2diff.nii.gz \
	-r ${CONNECTIVITY_DIR_SUB}/dtifit/dti_FA.nii.gz \
	-out ${CONNECTIVITY_DIR_SUB}/myxtract_gpu/stats_dtifit.csv

	singularity exec /home/snoussi/software/Containers/fsl_6051.sif xtract_stats \
	-d ${CONNECTIVITY_DIR_SUB}/diffusion.bedpostX/mean_ \
	-xtract ${CONNECTIVITY_DIR_SUB}/myxtract_gpu \
	-w ${CONNECTIVITY_DIR_SUB}/diffusion.bedpostX/xfms/standard2diff \
	-r ${CONNECTIVITY_DIR_SUB}/dtifit/dti_FA.nii.gz \
	-meas vol,prob,length,f1samples,f2samples,f3samples \
	-out ${CONNECTIVITY_DIR_SUB}/myxtract_gpu/stats_bedpostX.csv

fi




echo -e "\n-------------------------------------------------" && date && echo "-------------------------------------------------"
echo "VII. Blueprints using FSL's xtract_blueprint : "$XBLUEP_STEP

if [[ $XBLUEP_STEP == "TODO" ]]; then

	# White surface (Left and  Right) into GIFTI
	mris_convert ${RECONALL_DIR_SUB}/surf/lh.white ${RECONALL_DIR_SUB}/surf/lh.white.surf.gii
	mris_convert ${RECONALL_DIR_SUB}/surf/rh.white ${RECONALL_DIR_SUB}/surf/rh.white.surf.gii


	singularity exec --nv /home/snoussi/software/Containers/fsl_6051.sif xtract_blueprint -bpx ${CONNECTIVITY_DIR_SUB}/diffusion.bedpostX \
	-out ${CONNECTIVITY_DIR_SUB}/myxtract_blueprint \
	-xtract ${CONNECTIVITY_DIR_SUB}/myxtract_gpu \
	-seeds ${RECONALL_DIR_SUB}/surf/lh.white.surf.gii,${RECONALL_DIR_SUB}/surf/rh.white.surf.gii \
	-warps ${FILES_FOR_FSL_DIR}/MNI152_T1_2mm_brain.nii.gz ${CONNECTIVITY_DIR_SUB}/diffusion.bedpostX/xfms/standard2diff.nii.gz ${CONNECTIVITY_DIR_SUB}/diffusion.bedpostX/xfms/diff2standard.nii.gz \
	-nsamples 50 \
	-res 7 \
	-gpu


fi
