#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Usage: $0 <logfile> [output.txt]" >&2
    exit 1
fi

logfile="$1"
outfile="${2:-}"

if [[ ! -f "$logfile" ]]; then
    echo "Error: file not found:" >&2
    echo "$logfile" >&2
    exit 1
fi

# Get the absolute path.
filepath="$(readlink -f "$logfile" 2>/dev/null || realpath "$logfile" 2>/dev/null || echo "$logfile")"

# Find the data line.
# The data line starts with the wall-clock time in seconds.
data=$(awk '
    $1 ~ /^[0-9]+(\.[0-9]+)?$/ &&
    $2 ~ /^[0-9]+:[0-9][0-9]:[0-9][0-9]$/ &&
    NF >= 10 {
        print
        exit
    }
' "$logfile")

if [[ -z "$data" ]]; then
    echo "Error: could not find benchmark data in:" >&2
    echo "$filepath" >&2
    exit 1
fi

# Read the 10 values.
read -r wall_seconds wall_hms max_rss max_vms max_uss max_pss io_in io_out mean_load cpu_time <<< "$data"

report() {
    echo "# Benchmark report: $filepath"
    echo

    printf "%-32s %s seconds\n" \
        "Wall clock time" "$wall_seconds"

    printf "%-32s %s\n" \
        "Wall clock time" "$wall_hms"

    printf "%-32s %s MB\n" \
        "Maximum RSS memory" "$max_rss"

    printf "%-32s %s MB\n" \
        "Maximum VMS memory" "$max_vms"

    printf "%-32s %s MB\n" \
        "Maximum USS memory" "$max_uss"

    printf "%-32s %s MB\n" \
        "Maximum PSS memory" "$max_pss"

    printf "%-32s %s bytes\n" \
        "I/O read" "$io_in"

    printf "%-32s %s bytes\n" \
        "I/O written" "$io_out"

    printf "%-32s %s CPU cores\n" \
        "Mean CPU load" "$mean_load"

    printf "%-32s %s seconds\n" \
        "CPU time (user + system)" "$cpu_time"
}

if [[ -n "$outfile" ]]; then
    mkdir -p "$(dirname "$outfile")"
    report | tee "$outfile"
else
    report
fi
