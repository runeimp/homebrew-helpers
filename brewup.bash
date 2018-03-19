#!/usr/bin/env bash
###################
# Homebrew Update, Log, and List
#
# Runs `brew update' and saves the output to a dated logfile in your home directory. 
#
#####
# ChangeLog:
# ----------
# 2018-03-18  0.2.0      Now removes logs that only have 'Already up-to-date'
#                        Now checks for $XDG_CONFIG_HOME and $HOME/.local
#                        directories and creates a brewup directory if one of
#                        those exists. Or creates $HOME/.brewup to store
#                        brewup logs.
# 2018-01-10  0.1.1      Updated the output a bit
# 2017-08-10  0.1.0      Initial creation
#

#
# APP DATA
#
readonly APP_AUTHOR='RuneImp <runeimp@gmail.com>'
readonly APP_LICENSE='MIT'
readonly APP_NAME='Homebrew Update, Log, and List'
readonly APP_VERSION='0.2.0'
readonly CLI_NAME='brew-up'

readonly APP_LABEL="$APP_NAME v$APP_VERSION"


term_wipe()
{
	osascript -e 'if application "Terminal" is frontmost or application "iTerm" is frontmost then tell application "System Events" to keystroke "k" using command down'
}

#
# Check for BREWUP_DIR
#
if [[ -d "${XDG_CONFIG_HOME}/brewup" ]]; then
	BREWUP_DIR="${XDG_CONFIG_HOME}/brewup"
elif [[ -d "${HOME}/.local/brewup" ]]; then
	BREWUP_DIR="${HOME}/.local/brewup"
elif [[ -d "${HOME}/.brewup" ]]; then
	BREWUP_DIR="${HOME}/.brewup"
else
	BREWUP_DIR=""
fi

if [[ ${#BREWUP_DIR} -eq 0 ]]; then
	if [[ "${#XDG_CONFIG_HOME}" -gt 0 ]]; then
		if [[ ! -d "${XDG_CONFIG_HOME}/brewup" ]]; then
			mkdir "${XDG_CONFIG_HOME}/brewup"
		fi
		BREWUP_DIR="${XDG_CONFIG_HOME}/brewup"
	elif [[ -d "${HOME}/.local" ]]; then
		if [[ ! -d "${HOME}/.local/brewup" ]]; then
			mkdir "${HOME}/.local/brewup"
		fi
		BREWUP_DIR="${HOME}/.local/brewup"
	else
		if [[ ! -d "${HOME}/.brewup" ]]; then
			mkdir "${HOME}/.brewup"
		fi
		BREWUP_DIR="${HOME}/.brewup"
	fi
fi


#
# MAIN ENTRYPOINT / OPTION PARSING
#
if [[ $# -eq 0 ]]; then
	declare -r UPDATE_LOG="${BREWUP_DIR}/brew-update_$(date -j '+%Y-%m-%d_%H%M%S').txt"

	term_wipe

	echo "Updating Homebrew..."
	brew update | tee -i "$UPDATE_LOG"

	content="$(cat $UPDATE_LOG)"
	if [[ "$content" = "Already up-to-date." ]]; then
		# echo "Deleting $UPDATE_LOG"
		rm $UPDATE_LOG
	fi
else
	until [[ $# -eq 0 ]]; do
		case "$1" in
			-l | 'last' | 'list')
				UPDATE_LOG=$(ls "${BREWUP_DIR}/brew-update_"* | tail -1)
				echo "Viewing ${UPDATE_LOG}"
				cat "$UPDATE_LOG"
				;;
			*)
				echo "The option '$1' has no meaning for this app." >&2
				;;
		esac

		shift
	done
fi
