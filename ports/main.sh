#!/bin/bash
set -e
DATA_ARRAY_SIZE=30000
data_arr=
program_arr=
declare -i data_ptr=0
declare -i program_ptr=0
declare -i program_size=0

# $1 = status
terminate() {
	data_arr=
	program_arr=
	exit $1
}

handle_next_cell() {
	data_ptr=$((data_ptr + 1))
	if [[ "${data_ptr}" -ge "${DATA_ARRAY_SIZE}" ]]; then
		echo -e "\nerror: data pointer out of bounds" 1>&2
		terminate 1
	fi
}

handle_prev_cell() {
	data_ptr=$((data_ptr - 1))
	if [[ "${data_ptr}" -lt 0 ]]; then
		echo -e "\nerror: data pointer out of bounds" 1>&2
		terminate 1
	fi
}

handle_incr_cell() {
	declare -i cell="${data_arr[${data_ptr}]}"
	cell=$((cell + 1))
	data_arr[${data_ptr}]="${cell}"
}

handle_decr_cell() {
	declare -i cell="${data_arr[${data_ptr}]}"
	cell=$((cell - 1))
	data_arr[${data_ptr}]="${cell}"
}

handle_output_cell() {
	# convert to hex then use hex literals
	printf "\x$(printf "%x" "${data_arr[${data_ptr}]}")"
}

handle_input_cell() {
	if ! read -N 1 -r c; then
		# EOF
		return
	fi
	local ord=$(printf "%d" "'${c}")
	if [[ "${ord}" == "4" ]]; then
		# CTRL + D
		return
	fi
	data_arr[${data_ptr}]="${ord}"
}

handle_fwd_jump() {
	declare -i cell="${data_arr[${data_ptr}]}"
	if [[ $cell -ne 0 ]]; then
		return
	fi
	program_ptr=$((program_ptr - 1))
	
	declare -i loop=1
	while [[ "${loop}" -gt 0 ]]; do
		if [[ $((program_ptr + 1)) -ge "${program_size}" ]]; then
			echo -e "\nerror: unmatched [" 1>&2
			terminate 1
		fi
		program_ptr=$((program_ptr + 1))
		local c="${program_arr[$program_ptr]}"
		if [[ "${c}" == "[" ]]; then
			loop=$((loop + 1))
		fi
		if [[ "${c}" == "]" ]]; then
			loop=$((loop - 1))
		fi
	done
}

handle_bwd_jump() {
	declare -i cell="${data_arr[${data_ptr}]}"
	if [[ $cell -eq 0 ]]; then
		return
	fi
	program_ptr=$((program_ptr - 1))
	
	declare -i loop=1
	while [[ "${loop}" -gt 0 ]]; do
		if [[ $((program_ptr - 1)) -lt 0 ]]; then
			echo -e "\nerror: unmatched ]" 1>&2
			terminate 1
		fi
		program_ptr=$((program_ptr - 1))
		local c="${program_arr[$program_ptr]}"
		if [[ "${c}" == "]" ]]; then
			loop=$((loop + 1))
		fi
		if [[ "${c}" == "[" ]]; then
			loop=$((loop - 1))
		fi
	done
}

# $1 = op
opcode_handler() {
	case "$1" in
		">")
			handle_next_cell
			;;
			
		"<")
			handle_prev_cell
			;;
		
		"+")
			handle_incr_cell
			;;
		
		"-")
			handle_decr_cell
			;;
			
		".")
			handle_output_cell
			;;
			
		",")
			handle_input_cell
			;;
			
		"[")
			handle_fwd_jump
			;;
			
		"]")
			handle_bwd_jump
			;;
			
		*)
			# Ignore invalid opcodes
			;;
	esac
}

# $1 = file name
read_program() {
	program_arr=()
	if [[ ! -e "$1" ]]; then
		return 1
	fi
	while LANG=C IFS= read -r -N 1 c; do
		if [[ "${c}" ]]; then
			program_size+=1
			program_arr+=("${c}")
		fi
	done < "$1"
	echo "loaded program, size: ${program_size}" 1>&2
	return 0;
}

interrupt_handler() {
	echo -e "\naborted" 1>&2
	terminate 0
}

# $@ = args
main() {
	if [[ $# -lt 1 ]]; then
		echo "usage: $0 <file>" 1>&2
		exit 1
	fi
	
	if ! read_program "$1"; then
		echo "error: could not open $1" 1>&2
		exit 1
	fi
	data_arr=($(for ((i = 1; i <= $DATA_ARRAY_SIZE; i++)); do echo 0; done))
	
	trap "interrupt_handler" SIGINT
	echo "running, press ctrl+c to abort, press ctrl+d EOF" 1>&2
	
	local startTime=$(( $(date +%s%N) / 1000000 ))
	while [[ $program_ptr -lt $program_size ]]; do
		local op="${program_arr[$program_ptr]}"
		program_ptr+=1
		opcode_handler "${op}"
	done
	
	local execTime=$(( $(($(date +%s%N)/1000000)) - $startTime ))
	echo -e "\ndone, took: ${execTime}" 1>&2
	terminate 0
}

main "$@"