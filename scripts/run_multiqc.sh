#!/bin/bash

#SBATCH --job-name multiqc
#SBATCH -A naiss2025-22-1413
#SBATCH -p shared
#SBATCH -n 1
#SBATCH -c 2
#SBATCH --mem=10GB
#SBATCH -t 00:30:00
#SBATCH --output=slurm-logs/init-qc/multiqc-SLURM-%j.out
#SBATCH --error=slurm-logs/init-qc/multiqc-SLURM-%j.err
#SBATCH --mail-user=andbou95@gmail.com
#SBATCH --mail-type=ALL


echo "$(date) [INFO]        Script Start!"

# Load modules
ml load multiqc/1.30

# Arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --path)             INPUTS="$2"; shift ;;
        --outdir)           OUTDIR="$2"; shift ;;
        -h|--help)
            echo "Usage: $0 --path PATH/TO/ --outdir PATH/TO/OUTDIR"
            exit 0 ;;
        *) echo "[ERROR] Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Validate required arguments
if [[ -z $INPUTS || -z $OUTDIR ]]; then
    echo "[ERROR] Missing required arguments."
    echo "Usage: $0 --path PATH/TO/ --outdir PATH/TO/OUTDIR"
    exit 1
fi

CPU=2

# Remove trailing slashes
OUTDIR="${OUTDIR%/}"
mkdir -p $OUTDIR

echo "$(date) [INFO]        Output directory: $OUTDIR"

# Run multiqc
multiqc --outdir $OUTDIR $INPUTS


echo "$(date) [INFO]        Script Complete!"