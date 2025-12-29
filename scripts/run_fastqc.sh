#!/bin/bash

#SBATCH --job-name fastqc
#SBATCH -A naiss2025-22-1413
#SBATCH -p shared
#SBATCH -n 1
#SBATCH -c 34
#SBATCH --mem=68GB
#SBATCH -t 05:30:00
#SBATCH --output=slurm-logs/init-qc/fastqc-SLURM-%j.out
#SBATCH --error=slurm-logs/init-qc/fastqc-SLURM-%j.err
#SBATCH --mail-user=andbou95@gmail.com
#SBATCH --mail-type=ALL


echo "$(date) [INFO]        Script Start!"

# Load modules
ml load fastqc/0.12.1

# Arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --path)             PATH_FQ="$2"; shift ;;
        --outdir)           OUTDIR="$2"; shift ;;
        --tmp)              TMP_DIR="$2"; shift ;;
        -h|--help)
            echo "Usage: $0 --path PATH/TO/FASTQs --outdir PATH/TO/OUTDIR --tmp PATH/TO/SCRATCH"
            exit 0 ;;
        *) echo "[ERROR] Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Validate required arguments
if [[ -z $PATH_FQ || -z $OUTDIR || -z $TMP_DIR ]]; then
    echo "[ERROR] Missing required arguments."
    echo "Usage: $0 --path PATH/TO/FASTQs --outdir PATH/TO/OUTDIR --tmp PATH/TO/SCRATCH"
    exit 1
fi

CPU=34
FASTQ_FILES=$(find "$PATH_FQ" -name "*.fastq.gz" -type f)
# Remove trailing slashes
OUTDIR="${OUTDIR%/}"
mkdir -p $OUTDIR

echo "$(date) [INFO]        Found $(echo "$FASTQ_FILES" | wc -w) fastq files at $PATH_FQ"
echo "$(date) [INFO]        Output directory: $OUTDIR"
echo "$(date) [INFO]        Temp directory: $TMP_DIR"
echo "$(date) [INFO]        Threads: $CPU"

# Run FastQC
fastqc --dir $TMP_DIR --threads $CPU --outdir $OUTDIR $FASTQ_FILES


echo "$(date) [INFO]        Script Complete!"