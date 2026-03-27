#!/bin/bash

# This script registers processed fMRI-derived measures (e.g., ALFF) to the FreeSurfer T1 template space (antsdn.brain.mgz).
# Author: Amir Ebneabbasi

module load freesurfer

# Assign a unique SLURM_ARRAY_TASK_ID to each subject/session
ALFF=$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" ALFF_files_list.txt)

# Set FreeSurfer output path
REF_DIR=""

# Get the current date 
DATE=$(date +"%Y-%m-%d")

# Define log file 
LOG_FILE="${REF_DIR}/ALFF_Parc_log_${DATE}.log"

# Extract subject and session identifiers
SUB=$(echo "$ALFF" | grep -o 'sub-[0-9]\+' | head -n 1)
SES=$(echo "$ALFF" | grep -o 'ses-[0-9]\+' | head -n 1)

# Loop through all sequences, as each subject may have multiple MRIs per date
for MRI_SEQ in "${REF_DIR}/${SUB}_${SES}"*; do

    # Define ALFF_STATS output filename
    ALFF_STATS="${MRI_SEQ}/stats/ALFF_stats.sum"

    # If ALFF_STATS exists, skip further steps for this sequence
    if [ -f "${ALFF_STATS}" ]; then
        echo "ALFF_STATS already exists for ${SUB} ${SES}. Skipping..." >> "$LOG_FILE"
        continue
    fi 

    # Define reference T1 template and transformation files
    REF="${MRI_SEQ}/mri/antsdn.brain.mgz"
    REG_lta="${MRI_SEQ}/mri/transforms/ALFF_to_T1_reg.lta"
    REG_dat="${MRI_SEQ}/mri/transforms/ALFF_to_T1_reg.dat"

    # Remove existing transformation files if they exist
    if [ -f "${REG_lta}" ]; then
        echo "Removing ${REG_lta}"
        rm -f "${REG_lta}"
    fi

    if [ -f "${REG_dat}" ]; then
        echo "Removing ${REG_dat}"
        rm -f "${REG_dat}"
    fi

    # Perform co-registration of moving and reference images
    mri_coreg --mov "${ALFF}" --ref "${REF}" --reg "${REG_lta}"

    # Convert the transformation matrix suffix
    lta_convert --inlta "${REG_lta}" --outreg "${REG_dat}"

    # Define FreeSurfer's subject-specific segmentation file, HS lookup table, and normalised image
    SEG="${MRI_SEQ}/mri/Hammers_mith_subcotex_clean_and_cortex_and_aseg_cerebDC_and_brain-stem.mgz"
    LOOKUP="FreeSurferHammersColorLUT.txt"
    NORM="${MRI_SEQ}/mri/norm.mgz"

    # Generate statistics in FreeSurfer space
    mri_segstats --seg "${SEG}" \
                 --ctab "${LOOKUP}" \
                 --reg "${REG_dat}" \
                 --nonempty \
                 --excludeid 0 \
                 --in "${ALFF}" \
                 --pv "${NORM}" \
                 --sum "${ALFF_STATS}"

    echo "Processed $MRI_SEQ successfully" >> "$LOG_FILE"

done

echo "Stats calculation completed at $(date)" >> "$LOG_FILE"
