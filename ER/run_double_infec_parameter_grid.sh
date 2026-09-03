#!/usr/bin/env bash

set -euo pipefail

a_parameter_values=('0.01' '0.2' '0.5' '0.8' '0.99')
c_parameter_values=('0.01' '0.2' '0.5' '0.8' '1')

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
if [[ -f "${script_dir}/double_infec" ]]; then
    executable="${script_dir}/double_infec"
    executable_name='double_infec'
elif [[ -f "${script_dir}/double_infec.exe" ]]; then
    executable="${script_dir}/double_infec.exe"
    executable_name='double_infec.exe'
else
    printf 'Executable not found: %s (or double_infec.exe)\n' \
        "${script_dir}/double_infec" >&2
    exit 1
fi

cd -- "$script_dir"

total_runs=$(( ${#a_parameter_values[@]} * ${#c_parameter_values[@]} ))
run_number=0
batch_pids=()

wait_for_active_processes() {
    local exit_status=$?
    local pid

    trap - EXIT
    set +e
    for pid in "${batch_pids[@]}"; do
        wait "$pid" 2>/dev/null
    done
    exit "$exit_status"
}

trap wait_for_active_processes EXIT

for a_a in "${a_parameter_values[@]}"; do
    batch_pids=()
    batch_c_values=()

    printf 'Starting %d processes in parallel for a=%s...\n' \
        "${#c_parameter_values[@]}" "$a_a"

    for a_c in "${c_parameter_values[@]}"; do
        b_a=$a_a
        b_c=$a_c
        ((run_number += 1))

        printf '[%d/%d] ./%s 0 10 %s %s %s %s\n' \
            "$run_number" "$total_runs" "$executable_name" \
            "$a_a" "$a_c" "$b_a" "$b_c"
        "$executable" 0 10 "$a_a" "$a_c" "$b_a" "$b_c" &
        batch_pids+=("$!")
        batch_c_values+=("$a_c")
    done

    failure_details=()
    for i in "${!batch_pids[@]}"; do
        if wait "${batch_pids[$i]}"; then
            exit_code=0
        else
            exit_code=$?
        fi

        if (( exit_code != 0 )); then
            a_c=${batch_c_values[$i]}
            failure_details+=(
                "exit code ${exit_code} (A_a=${a_a}, A_c=${a_c}, B_a=${a_a}, B_c=${a_c})"
            )
        fi
    done
    batch_pids=()

    if (( ${#failure_details[@]} > 0 )); then
        printf '%s failed:\n' "$executable_name" >&2
        printf '%s\n' "${failure_details[@]}" >&2
        exit 1
    fi

    printf 'Completed all c values for a=%s.\n' "$a_a"
done

printf 'Completed all %d ER parameter combinations.\n' "$total_runs"
