# Internal help functions
_print_global_namespace_help_intro() {
	local _def_namespace_msg

	if [[ -n $ORB_DEFAULT_NAMESPACE ]]; then
		_def_namespace_msg="Default namespace \$ORB_DEFAULT_NAMESPACE set to $(_bold)$ORB_DEFAULT_NAMESPACE$(_normal)"
	else
		_def_namespace_msg="Default namespace \$ORB_DEFAULT_NAMESPACE not set"
	fi

	local _intromsg="$_def_namespace_msg.\n\n"
	_intromsg+="Available namespaces listed below:\n\n"
	_intromsg+="  $(_join_by ', ' "${_namespaces[@]}").\n\n"
	_intromsg+="To list commands in a namespace, use \`orb \"namespace\" --help\`"
	echo -e "$_intromsg"
}

_print_namespace_help() {
	if $_global_help_requested; then
		_print_global_namespace_help_intro
	fi

	local _i=0 _file _current_dir
	for _file in ${_namespace_files[@]}; do
		if [[ "${_namespace_files_dir_tracker[$_i]}" != "$_current_dir" ]]; then
			_current_dir="${_namespace_files_dir_tracker[$_i]}"
			_output+="-----------------# $(_italic)${_current_dir}\n$(_normal)"
		fi

		_output+="$(_bold)$(_upcase $(basename $_file))$(_normal)\n"
		_output+=$(grep "^[); ]*function[ ]*[a-zA-Z_-]*[ ]*()[ ]*{" $_file | sed 's/\(); \)*function //' | sed 's/().* {[ ]*//' | sed 's/^/  /')
		_output+="\n\n"

		((_i+=1))
	done

	# remove last 4 chars \n\n
	echo -e "${_output::-4}" | column -tes '#'
}

_print_function_help() {
	_print_function_name_and_comment
	local _def=$(__print_args_explanation)
	[[ -n "$_def" ]] && echo -e "\n$_def"
}


__print_args_explanation() { # $1 optional args_declaration
	local _declaration_ref=${1-"_args_declaration"}
	declare -n _declaration="$_declaration_ref"

	[[ -z "${!_declaration[@]}" ]] && exit 1
	local _props=('ARG' 'DESCRIPTION' 'DEFAULT' 'IN' 'REQUIRED' 'OTHER')
	IFS=';'; local _msg="$(_bold)${_props[*]}$(_normal)\n"

	_msg+=$(for _key in "${!_declaration[@]}"; do
		_sub="$_key"
		for _prop in ${_props[@]:1}; do
			_val=
			if [[ "$_prop" == 'REQUIRED' ]]; then
				_is_required "$_key" "$_declaration_ref" && _val='true'
			elif [[ "$_prop" == 'OTHER' ]]; then
				_val=()
				_catches_any "$_key" "$_declaration_ref" && _val+=( CATCH_ANY )
				_catches_empty "$_key" "$_declaration_ref" && _val+=( CATCH_EMPTY )
				_val=$(_join_by ', ' ${_val[*]})
			else
				_val="$(_get_arg_prop "$_key" "$_prop" "$_declaration_ref")"
			fi

			_sub+=";$([[ -n "$_val" ]] && echo "$_val" || echo '-')"
		done
		echo "$_sub"
	done | sort)

	echo -e "$_msg" | sed 's/^/  /' | column -t -s ';'
}

_print_function_comment() {
	local _comment_line=$(grep -r "function $_function_name" "$_file_with_function")
	if [[ "$_comment_line" != "${_comment_line/\#/}" ]]; then
	 echo "$_comment_line" | cut -d '#' -f2- | xargs
	fi
}

_print_function_name_and_comment() {
	local _comment=$(_print_function_comment)
	echo "$(_bold)$_function_name$(_normal) $([[ -n "$_comment" ]] && echo "- $_comment")"
}

