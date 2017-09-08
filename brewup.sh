#!/usr/bin/env bash
###################
# Homebrew Update, Log, and List
#
# Runs `brew update' and saves the output to a dated logfile in your home directory. 
#
#####
# ChangeLog:
# ----------
# 2017-08-10  0.1.0      Initial creation
#

#
# APP DATA
#
readonly APP_AUTHOR='RuneImp <runeimp@gmail.com>'
readonly APP_LICENSE='MIT'
readonly APP_NAME='Homebrew Update, Log, and List'
readonly APP_VERSION='0.1.0'
readonly CLI_NAME='brew-up'

readonly APP_LABEL="$APP_NAME v$APP_VERSION"

if [[ $# -eq 0 ]]; then

	declare -r update_log="brew-update_$(date -j '+%Y-%m-%d_%H%M%S').txt"

	term-wipe
	echo "Updating Homebrew..."
	# brew update | tee "$update_log"
	update_result="$(brew update)"
	echo -e "$update_result"
	echo -e "$update_result" > "$update_log"
else
	until [[ $# -eq 0 ]]; do
		case "$1" in
			-l | 'last' | 'list')
				update_log=$(ls ~/brew-update_* | tail -1)
				echo "Viewing ~/${update_log}"
				cat "$update_log"
				;;
			*)
				echo "Hmm? '$1'" >&2
				;;
		esac

		shift
	done
fi
