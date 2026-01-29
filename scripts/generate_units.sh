#!/bin/bash

# =============================================================================
# Script: generate_units_tsv.sh
# Description: Generates a units.tsv file for Snakemake workflows by parsing
#              FASTQ file paths and extracting metadata from a metadata file.
#              OBS! In metadata, field 11 = Tube_ID and field 14 = NGI_plateID.
# Output format: sample, unit, lib, platform, r1, r2
# Author: André Bourbonnais (ndreey, andbou95@gmail.com, 2026)
# =============================================================================

# Argument Parsing
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --seq-path)     SEQ_PATH="$2"; shift ;;
        --samples)      SAMPLES_ID="$2"; shift ;;
        --meta)         META="$2"; shift ;;
        --outfile)      UNITS="$2"; shift ;;
        -h|--help)
            echo "Usage: $0 --seq-path PATH/TO/FASTQ_DIR --samples SAMPLES_FILE --meta METADATA_FILE --outfile OUTPUT_TSV"
            echo ""
            echo "Arguments:"
            echo "  --seq-path    Path to the sequencing directory containing sample folders"
            echo "  --samples     File containing sample IDs (one per line)"
            echo "  --meta        Metadata TSV file with sample and library information"
            echo "  --outfile     Output units.tsv file path"
            echo "  -h, --help    Show this help message and exit"
            echo ""
            echo "Example:"
            echo "  bash scripts/generate_units_tsv.sh \\"
            echo "      --seq-path /cfs/klemming/projects/supr/snic2020-6-170/RawData/lcNGS_2025/files/P36454 \\"
            echo "      --samples doc/test_samples_NGI_id.txt \\"
            echo "      --meta doc/MetaData_bioinfo.tsv \\"
            echo "      --outfile doc/units.tsv"
            exit 0 ;;
        *) echo "$(date) [ERROR]       Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Validate Required Arguments
if [[ -z $SEQ_PATH || -z $SAMPLES_ID || -z $META || -z $UNITS ]]; then
    echo "$(date) [ERROR]       Missing required arguments."
    echo "Usage: $0 --seq-path PATH/TO/FASTQ_DIR --samples SAMPLES_FILE --meta METADATA_FILE --outfile OUTPUT_TSV"
    exit 1
fi

# Remove trailing slashes to avoid unwanted path parsing errors
SEQ_PATH="${SEQ_PATH%/}"


# Check that input files exist
if [[ ! -d $SEQ_PATH ]]; then
    echo "$(date) [ERROR]       Sequencing path does not exist: $SEQ_PATH"
    exit 1
fi

if [[ ! -f $SAMPLES_ID ]]; then
    echo "$(date) [ERROR]       Samples file does not exist: $SAMPLES_ID"
    exit 1
fi

if [[ ! -f $META ]]; then
    echo "$(date) [ERROR]       Metadata file does not exist: $META"
    exit 1
fi

# Setup
echo "$(date) [INFO]        Starting units.tsv generation"
echo "$(date) [INFO]        Sequencing path: $SEQ_PATH"
echo "$(date) [INFO]        Samples file: $SAMPLES_ID"
echo "$(date) [INFO]        Metadata file: $META"
echo "$(date) [INFO]        Output file: $UNITS"

# Create output directory if it doesn't exist
OUTDIR=$(dirname "$UNITS")
mkdir -p "$OUTDIR"

# Initialize output file with header
echo -e "sample\tunit\tlib\tplatform\tfq1\tfq2" > "$UNITS"

# Process Each Sample
SAMPLE_COUNT=$(wc -l < "$SAMPLES_ID")
echo "$(date) [INFO]        Processing $SAMPLE_COUNT samples"
echo -e "\nStarting..."


for id in $(cat "$SAMPLES_ID"); do
    echo "$(date) [INFO]        Processing sample ID: $id"

    # Find all R1 fastq files for this sample
    FSTQ=$(find "$SEQ_PATH/$id/" -name "*.fastq.gz" -type f 2>/dev/null)

    if [[ -z $FSTQ ]]; then
        echo "$(date) [WARN]        No FASTQ files found for sample: $id"
        continue
    fi

    # Process each R1 file
    for file in $(echo "$FSTQ" | tr " " "\n" | grep "_R1_"); do
        echo "$(date) [DEBUG]       Processing file: $file"

        # Extract unit name from path
        UNIT=$(echo "$file" | cut -f 11 -d "/")

        # Extract lane number and remove L00 prefix
        LANE=$(echo "$file" | cut -f 9 -d "_" | sed 's/L00//g')

        # Combine unit and lane for final unit identifier
        UNIT_FIN="${UNIT}.${LANE}"

        # Generate R2 filename by replacing R1 with R2
        R2=$(echo "$file" | sed 's/_R1_/_R2_/g')

        # Look up library ID from metadata (column 14 = NGI_plateID)
        LIB=$(awk -F'\t' -v unit="$UNIT" '$12 == unit {print $14}' "$META" | tr -d ' ')

        # Look up sample name from metadata (column 11 = Tube_ID)
        SAMP=$(awk -F'\t' -v unit="$UNIT" '$12 == unit {print $11}' "$META" | tr -d ' ')

        # Append to output file
        echo -e "$SAMP\t$UNIT_FIN\t$LIB\tILLUMINA\t$file\t$R2" >> "$UNITS"
    done
done

# Summary
ENTRY_COUNT=$(($(wc -l < "$UNITS") - 1))
echo ""
echo "$(date) [INFO]        Generated $ENTRY_COUNT entries in $UNITS"
echo "$(date) [INFO]        Script complete!"