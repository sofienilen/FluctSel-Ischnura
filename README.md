# FluctSel-Ischnura

Bioinformatics pipeline for analyzing fluctuating selection in the Common Bluetail Damselfly (*Ischnura elegans*). This project uses low-coverage whole-genome sequencing (lcWGS) to investigate how selection operates across life stages (aquatic nymphs vs. terrestrial adults) and across generations to maintain genetic diversity in natural populations.

## Setup

### Environment Setup

This environment uses Snakemake v9.13.7 and Singularity v3.8.6. For complete environment specifications, see `doc/popglen-environment.yml`.

```bash
# Create mamba environment (-n names the environment, -c channels to use, -y auto selects yes to all prompts). If using conda, switch mamba to conda.
mamba create -n popglen -c conda-forge -c bioconda \
    snakemake=9.13.7 \
    snakedeploy \
    singularity \
    snakemake-executor-plugin-slurm \
    -y

# Activate environment
mamba activate popglen

# Download the PopGLen workflow
snakedeploy deploy-workflow https://github.com/zjnolen/PopGLen . --tag v0.4.2
```

### Known Issues & Fixes

#### Snakemake Version Issue
**As of 2025-12-15:** There is an error with the newest version of either `snakemake` or `snakemake-executor-plugin-slurm` that prevents job submission to SLURM. 

**Solution:** Downgrade to Snakemake v9.13.7 (from v9.14.4)

**References:**
- [Job submission with scheduler broken by #3850 · Issue #3853](https://github.com/snakemake/snakemake/issues/3853)
- [assert self.workflow.is_main_process AssertionError · Issue #3874](https://github.com/snakemake/snakemake/issues/3874)

#### Singularity/Apptainer Issue
**As of 2025-12-15:** The newest Singularity/Apptainer does not support the `--tmp-sandbox` flag.

**Solution:** Remove `--tmp-sandbox` from `singularity-args` in the Dardel profile.

**Before:**
```yaml
singularity-args: '--tmp-sandbox -B /cfs/klemming'
```

**After:**
```yaml
singularity-args: '-B /cfs/klemming'
```


## Configuration

### Dardel Profile Setup

Edit `profiles/dardel/config.v8+.yaml`:

```yaml
restart-times: 3
local-cores: 2
printshellcmds: true
use-conda: true
use-singularity: true
jobs: 999
keep-going: true
max-threads: 128
executor: slurm
singularity-args: '-B /cfs/klemming'
default-resources:
  - "mem_mb=(threads*1700)"
  - "runtime=60"
  - "slurm_account=naiss2025-22-1413"           # <-- Change this
  - "slurm_partition=shared"
  - "nodes=1"
  - "tmpdir='/cfs/klemming/scratch/a/andbou'"   # <-- Change this
```

**Note:** Update `slurm_account` and `tmpdir` paths for your system.

## Running the Pipeline

### Option 1: Interactive Node (Recommended for Testing)

```bash
# Request interactive job
salloc -n 1 -c 64 -t 02:30:00 -A naiss2025-22-1413 -p shared

# Activate environment
mamba activate popglen

# Run workflow
snakemake \
    --configfile config/config-full.yaml \
    --use-conda \
    --use-singularity \
    --default-resources "mem_mb=threads*1700" \
    --cores 64
```

### Option 2: Login Node with Screen (Recommended for Production)

```bash
# Start screen session (to run in background if terminal closes)
screen -S snakemake

# Activate environment
mamba activate popglen

# Run the pipeline
snakemake --profile profiles/dardel --configfile config/config-full.yaml

# Detach from screen: Ctrl+A, then D
# Reattach later: screen -r snakemake
```

### Option 3: SLURM Job Submission (Not Recommended)

Running Snakemake from within a SLURM job is not recommended and may lead to unexpected behavior such as failing to submit jobs.


> "You are running snakemake in a SLURM job context. This is not recommended, as it may lead to unexpected behavior. If possible, please run Snakemake directly on the login node."

> "Select jobs to execute... Failed to solve scheduling problem with ILP solver, falling back to greedy scheduler. You likely have to fix your ILP solver installation. Error message: PULP_CBC_CMD: Not Available (check permissions on cbc)"

**If you must use this approach:**

```bash
#!/bin/bash
#SBATCH --job-name=snakemake
#SBATCH -A naiss2025-22-1413
#SBATCH -p shared
#SBATCH -n 1
#SBATCH -c 4
#SBATCH --mem=8GB
#SBATCH -t 04:30:00
#SBATCH --output=SLURM-%j.out
#SBATCH --error=SLURM-%j.err

# Source .bashrc to init mamba
source /cfs/klemming/home/a/andbou/.bashrc
mamba activate popglen

snakemake --profile profiles/dardel --configfile config/config-full.yaml
```

## Useful Commands

### Check Pipeline Status

```bash
# Dry run (see what will be executed)
snakemake -n --profile profiles/dardel --configfile config/config-full.yaml

# Unlock directory after failed run
snakemake --unlock

# Rerun incomplete files (resume job)
snakemake --rerun-incomplete --profile profiles/dardel --configfile config/config-full.yaml
```

### Monitor Jobs

```bash
# Check SLURM logs
ls -lh .snakemake/slurm_logs/

# Monitor screen session
screen -ls
screen -r snakemake
```