#!/bin/bash

#SBATCH --job-name snakemake
#SBATCH -A naiss2025-22-1413
#SBATCH -p shared
#SBATCH -n 1
#SBATCH -c 4
#SBATCH --mem=8GB
#SBATCH -t 04:30:00
#SBATCH --output=SLURM-%j.out
#SBATCH --error=SLURM-%j.err
#SBATCH --mail-user=andbou95@gmail.com
#SBATCH --mail-type=ALL


# Load in the r-arena mamba environment
source /cfs/klemming/home/a/andbou/.bashrc
mamba activate popglen

module load PDC singularity


snakemake --profile profiles/dardel --configfile config/config-full.yaml --rerun-incomplete