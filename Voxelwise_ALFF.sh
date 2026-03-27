#!/bin/bash

# The script uses afni and fsl to calculate voxelwise zALFF and zfALFF 
# Author: Amir Ebneabbasi

# Load required modules
module load afni/17.0.00 
module load fsl

# Define the base directory containing the subject data
base_dir=""

# Get the current date in YYYY-MM-DD format
current_date=$(date +"%Y-%m-%d")

# Define log file with date
log_file="${base_dir}/ALFF_${current_date}.log"

# Start logging
echo "Starting ALFF processing: $(date)" >> "$log_file"

# Loop through each subject and session
for subject_dir in ${base_dir}/sub-*; do
    subject=$(basename "${subject_dir}")

    for session_dir in ${subject_dir}/ses-*; do
        session=$(basename "${session_dir}")       
       
        # Define the paths to the outputs
        z_alff_output="${session_dir}/FUNCTIONAL.ica/Z_ALFF_fMRI.nii.gz"
        z_falff_output="${session_dir}/FUNCTIONAL.ica/Z_fALFF_fMRI.nii.gz"
        
        # Check if the Z_ALFF and Z_fALFF files already exist
        if [ -f "${z_alff_output}" ] && [ -f "${z_falff_output}" ]; then
            echo "Z_ALFF and Z_fALFF already exist for ${subject} ${session}. Skipping..." >> "$log_file"
            continue
        fi  

	# Remove outputs, if previously created
        rm -f "${session_dir}/FUNCTIONAL.ica/temp"*

	# Define the paths to the preprocessed fMRI
        bold="${session_dir}/FUNCTIONAL.ica/FUNCTIONAL_wds_std.nii.gz"

        # Check if the BOLD file exists
        if [ ! -f "$bold" ]; then
            echo "BOLD file not found for ${subject} ${session}" >> "$log_file"
            continue
        fi
	
	# Bandpass filtering
        bold_bp="${session_dir}/FUNCTIONAL.ica/temp_BP.nii.gz"
        3dBandpass -prefix "${bold_bp}" 0.01 0.08 "${bold}"

        # Compute the brain mask
        mask="${session_dir}/FUNCTIONAL.ica/temp_alff_mask.nii.gz"
       	3dAutomask -prefix "${mask}" "${bold}"

        # Compute ALFF
        alff_output="${session_dir}/FUNCTIONAL.ica/temp_alff.nii.gz"
       	3dTstat -stdev -mask "${mask}" -prefix "${alff_output}" "${bold_bp}"

        # Compute fALFF
        # step1
        bold_sd="${session_dir}/FUNCTIONAL.ica/temp_sd.nii.gz"
	3dTstat -stdev -mask "${mask}" -prefix "${bold_sd}" "${bold}"
        
	# step2
        falff_output="${session_dir}/FUNCTIONAL.ica/temp_falff.nii.gz"
	3dcalc -prefix "${falff_output}" -a "${mask}" -b "${alff_output}" -c "${bold_sd}" -expr '(1.0*bool(a))*((1.0*b)/(1.0*c))' -float

        # Compute z-scores for ALFF
        alff_mean_file="${session_dir}/FUNCTIONAL.ica/temp_mean_alff.txt"
        alff_sd_file="${session_dir}/FUNCTIONAL.ica/temp_sd_alff.txt"

        fslstats "${alff_output}" -k "${mask}" -m > "${alff_mean_file}"
        alff_mean=$(cat "${alff_mean_file}")

        fslstats "${alff_output}" -k "${mask}" -s > "${alff_sd_file}"
        alff_sd=$(cat "${alff_sd_file}")

        fslmaths "${alff_output}" -sub ${alff_mean} -div ${alff_sd} -mas "${mask}" "${z_alff_output}"
	
	# Compute z-scores for fALFF
        falff_mean_file="${session_dir}/FUNCTIONAL.ica/temp_mean_falff.txt"
        falff_sd_file="${session_dir}/FUNCTIONAL.ica/temp_sd_falff.txt"

        fslstats "${falff_output}" -k "${mask}" -m > "${falff_mean_file}"
        falff_mean=$(cat "${falff_mean_file}")

        fslstats "${falff_output}" -k "${mask}" -s > "${falff_sd_file}"
        falff_sd=$(cat "${falff_sd_file}")

        fslmaths "${falff_output}" -sub ${falff_mean} -div ${falff_sd} -mas "${mask}" "${z_falff_output}"

        # Remove temporary files
        rm -f "${session_dir}/FUNCTIONAL.ica/temp"*

        # Log the completion of processing for this session
        echo "Completed processing for ${subject}, ${session}" >> "${log_file}"
    done
done
