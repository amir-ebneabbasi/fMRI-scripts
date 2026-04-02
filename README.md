# fMRI ALFF Pipeline

A **bash-based pipeline** for computing ALFF (Amplitude of Low-Frequency Fluctuations) and fALFF from preprocessed fMRI data and registering the outputs to **FreeSurfer T1 template space**.

## Features

- Computes voxelwise **ALFF** and **fALFF** using **AFNI** and **FSL**.   
- Registers ALFF outputs to **FreeSurfer T1 template (antsdn.brain.mgz)**.  
- Generates parcellated **ALFF statistics** using FreeSurfer segmentations.  
- Detailed logging of processing steps for reproducibility.  

## Requirements

- **AFNI** (tested with version 17.0.00)  
- **FSL** (tested with version 6.0.5)  
- **FreeSurfer** (tested with version 7.3)  
- Bash shell environment  
