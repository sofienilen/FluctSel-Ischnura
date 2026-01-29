#!/bin/bash

# =============================================================================
# Script: generate_samples_tsv.sh
# Description: Generates a samples.tsv file for Snakemake workflows by extracting
#              sample metadata from a metadata file.
#              OBS! In metadata, field 3 = population, field 11 = Tube_ID, 
#              and field 12 = sample (NGI ID used for matching).
# Output format: sample, population, time, depth
# Author: André Bourbonnais (ndreey, andbou95@gmail.com, 2026)
# =============================================================================

# Argument Parsing
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --samples)      SAMPLES_ID="$2"; shift ;;
        --meta)         META="$2"; shift ;;
        --outfile)      SAMPLES_OUT="$2"; shift ;;
        --time)         TIME="$2"; shift ;;
        --depth)        DEPTH="$2"; shift ;;
        -h|--help)
            echo "Usage: $0 --samples SAMPLES_FILE --meta METADATA_FILE --outfile OUTPUT_TSV --time TIME_VALUE --depth DEPTH_VALUE"
            echo ""
            echo "Arguments:"
            echo "  --samples     File containing sample IDs (one per line, NGI format e.g., P36454_209)"
            echo "  --meta        Metadata TSV file with sample and population information"
            echo "  --outfile     Output samples.tsv file path"
            echo "  --time        Time category for all samples (e.g., modern, historical)"
            echo "  --depth       Sequencing depth category for all samples (e.g., mean, high, low)"
            echo "  -h, --help    Show this help message and exit"
            echo ""
            echo "Example:"
            echo "  bash scripts/generate_samples_tsv.sh \\"
            echo "      --samples doc/test_samples_NGI_id.txt \\"
            echo "      --meta doc/MetaData_bioinfo.tsv \\"
            echo "      --outfile doc/samples.tsv \\"
            echo "      --time modern \\"
            echo "      --depth lc"
            exit 0 ;;
        *) echo "$(date) [ERROR]       Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Validate Required Arguments
if [[ -z $SAMPLES_ID || -z $META || -z $SAMPLES_OUT || -z $TIME || -z $DEPTH ]]; then
    echo "$(date) [ERROR]       Missing required arguments."
    echo "Usage: $0 --samples SAMPLES_FILE --meta METADATA_FILE --outfile OUTPUT_TSV --time TIME_VALUE --depth DEPTH_VALUE"
    exit 1
fi

# Check that input files exist
if [[ ! -f $SAMPLES_ID ]]; then
    echo "$(date) [ERROR]       Samples file does not exist: $SAMPLES_ID"
    exit 1
fi

if [[ ! -f $META ]]; then
    echo "$(date) [ERROR]       Metadata file does not exist: $META"
    exit 1
fi

# Setup
echo "$(date) [INFO]        Starting samples.tsv generation"
echo "$(date) [INFO]        Samples file: $SAMPLES_ID"
echo "$(date) [INFO]        Metadata file: $META"
echo "$(date) [INFO]        Output file: $SAMPLES_OUT"
echo "$(date) [INFO]        Time value: $TIME"
echo "$(date) [INFO]        Depth value: $DEPTH"

# Create output directory if it doesn't exist
OUTDIR=$(dirname "$SAMPLES_OUT")
mkdir -p "$OUTDIR"

# Initialize output file with header
echo -e "sample\tpopulation\ttime\tdepth" > "$SAMPLES_OUT"

# Process Each Sample
SAMPLE_COUNT=$(wc -l < "$SAMPLES_ID")
echo "$(date) [INFO]        Processing $SAMPLE_COUNT samples"
echo -e "\nStarting..."

for id in $(cat "$SAMPLES_ID"); do
    echo "$(date) [INFO]        Processing sample ID: $id"

    # Look up Tube_ID from metadata (column 11 where column 12 matches input ID)
    SAMP=$(awk -F'\t' -v id="$id" '$12 == id {print $11}' "$META" | tr -d ' ')

    # Look up population from metadata (column 3 where column 12 matches input ID)
    POP=$(awk -F'\t' -v id="$id" '$12 == id {print $3}' "$META" | tr -d ' ')

    # Check if we found a match
    if [[ -z $SAMP || -z $POP ]]; then
        echo "$(date) [WARN]        No metadata found for sample ID: $id"
        continue
    fi

    echo "$(date) [DEBUG]       Found: Tube_ID=$SAMP, Population=$POP"

    # Append to output file
    echo -e "$SAMP\t$POP\t$TIME\t$DEPTH" >> "$SAMPLES_OUT"
done

# Summary
ENTRY_COUNT=$(($(wc -l < "$SAMPLES_OUT") - 1))
echo ""
echo "$(date) [INFO]        Generated $ENTRY_COUNT entries in $SAMPLES_OUT"
echo "$(date) [INFO]        Script complete!"