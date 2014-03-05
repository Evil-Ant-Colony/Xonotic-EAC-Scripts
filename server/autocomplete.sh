_eac_server_autocomplete()
{
	local cur prev

	COMPREPLY=()
	_get_comp_words_by_ref cur

	case ${COMP_WORDS[1]} in
		ls|list|cmd|exec|irc|dump)
			COMPREPLY=( $( compgen -W "$(./server)" -- "$cur" ) )
			return 0
		;;
	esac

	COMPREPLY=( $( compgen -W 'inline ls list cmd exec irc view dump register' -- "$cur" ) )
}
complete -F _eac_server_autocomplete server