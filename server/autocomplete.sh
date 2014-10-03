_eac_server_autocomplete()
{
	local cur prev

	COMPREPLY=()
	_get_comp_words_by_ref cur
	
	
	COMPREPLY=( $( compgen -W "$(server autocomplete ${COMP_WORDS[1]})" -- "$cur" ) )
# 	eac_server_commands=$(server commands)
# 	
# 	for eac_server_cmd in $eac_server_commands
# 	do
# 		if [ "${COMP_WORDS[1]}" = "$eac_server_cmd" ]
# 		then
# 			COMPREPLY=( $( compgen -W "$(server inline)" -- "$cur" ) )
# 			return 0
# 		fi
# 	done
# 
# 	COMPREPLY=( $( compgen -W "$eac_server_commands" -- "$cur" ) )
}
complete -F _eac_server_autocomplete server
