function print_args() { # print collected arguments from arguments.sh, useful for debugging
	declare -A | grep 'A args=' | cut -d '=' -f2-
	[[ ${args["*"]} == true ]]  && echo "[*]=${args_wildcard[*]}"
}


###############
# INTERNAL
###############
print_global_help() {
echo "$(cat <<EOF
orb [script_name(default=d)] [function_name]

available scripts: $(echo ${scripts[*]} | sed 's/ /, /g')
EOF
)"
}

print_script_help() {
	output=
	for file in ${script_files[@]}; do
		output+="$(bold)$(basename $file | tr a-z A-Z)$(normal)\n"
		output+=$(grep "^[); ]*function" $script_dir/$file | sed 's/\(); \)*function //' | sed 's/().* {[ ]*//' | sed 's/^/  /')
		output+="\n\n"
	done
	# remove last 4 chars \n\n
	echo -e "${output::-4}" | column -tes '#'
}

print_function_help() {
	print_function_name_and_comment
	def=$(print_args_definition)
	[[ -n "$def" ]] && echo -e "\n$def"
}


print_args_definition() {
	[[ -z "${!args_declaration[@]}" ]] && exit
	props=('ARG' 'DESCRIPTION' 'DEFAULT' 'IN' 'REQUIRED')
	IFS=';'
	msg="$(bold)${props[*]}$(normal)\n"
	# IFS=''
	msg+=$(for key in "${!args_declaration[@]}"; do
		sub="$key"
		for prop in ${props[@]:1}; do
			val=
			if [[ "$prop" == 'REQUIRED' ]]; then
				is_required "$key" && val='true'
			else
				val="$(get_arg_prop "$key" "$prop")"
			fi

			sub+=";$([[ -n "$val" ]] && echo "$val" || echo '-')"
		done
		echo "$sub"
	done | sort)

	echo -e "$msg" | sed 's/^/  /' | column -t -s ';'
}

print_function_comment() {
	comment_line=$(grep -r --include \*.sh "function $function_name" "$script_dir")
	if [[ "$comment_line" != "${comment_line/\#/}" ]]; then
	 echo "$comment_line" | cut -d '#' -f2- | xargs
	fi
}

print_function_name_and_comment() {
	comment=$(print_function_comment)
	echo "$(bold)$function_name$(normal) $([[ -n "$comment" ]] && echo "- $comment")"
}
