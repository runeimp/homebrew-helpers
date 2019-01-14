#!/usr/bin/env bash
###################
# brew-note.bash
#
#
#####
# ChangeLog:
# ----------
# 2018-12-10  1.4.2      Fixed bug in list_has function.
# 2018-12-09  1.4.1      Fixed bug in list_edit function.
# 2018-12-09  1.4.0      Added list_has function for testing if the app is already noted.
# 2018-12-09  1.3.0      Added edit list option: -e | -edit | --edit-list
# 2018-09-25  1.2.0      Note HTML encoding app descriptions with Python 3
#                        and minor help update.
# 2018-08-05  1.1.0      Added options as subcommands.
#                        Added remove command/option.
# 2018-07-07  1.0.1      Added unique to sort
# 2018-05-24  1.0.0      Initial creation
#


#
# APP INFO
#
APP_AUTHOR="RuneImp <runeimp@gmail.com>"
APP_DESC="Keeps noteworty app info to review at a later time."
APP_NAME="Homebrew Notes"
CLI_NAME="brew-notes"
APP_VERSION="1.4.2"
APP_LICENSES="http://opensource.org/licenses/MIT"

#
# CONSTANTS
#
APP_LABEL="$APP_NAME v$APP_VERSION
License(s): $APP_LICENSES"
CASK_APP_RE='^caskroom/.+'


#
# VARIABLES
#
declare -a ARGS
declare -i arg_loops=0


#
# FUNCTIONS
#

get_desc()
{
	local app="$1"
	local result=""

	if [[ "$app" =~ $CASK_APP_RE ]]; then
		# echo "\${BASH_REMATCH[@]} ${BASH_REMATCH[@]}"
		# echo "\${#BASH_REMATCH[@]} ${#BASH_REMATCH[@]}"
		# echo "\${BASH_REMATCH[1]} ${BASH_REMATCH[1]}"
		result="$(brew cask info "$app" | python3 -c 'import html, sys; [print(html.escape(l), end="") for l in sys.stdin]' | head -1 2> /dev/null) (Homebrew Cask App)"
	else
		# result="$(brew info "$app" | tail +2 | head -1 2> /dev/null)"
		result="$(brew desc "$app" | python3 -c 'import html, sys; [print(html.escape(l), end="") for l in sys.stdin]' | cut -d: -f2- | xargs 2> /dev/null)"
	fi
	# result="$(echo $result | python3 -c 'import html, sys; [print(html.escape(l), end="") for l in sys.stdin]')"
	echo "$result"
}

get_deps()
{
	local app="$1"
	local result=""

	result="$(brew deps "$app" --1)"
}

get_md_link()
{
	local app="$1"
	url="$(get_url "$app")"
	echo "[${app}](${url})"
}

get_md_list_link()
{
	local app="$1"

	desc="$(get_desc "$app")"
	url="$(get_url "$app")"

	echo "- [${app}](${url}): ${desc}"
}

get_url()
{
	local app="$1"
	local result=""

	if [[ "$app" =~ $CASK_APP_RE ]]; then
		result="$(brew cask info "$app" | tail +2 | head -1 2> /dev/null)"
	else
		result="$(brew info "$app" | tail +3 | head -1 2> /dev/null)"
	fi
	echo "$result"
}

list_edit()
{
	local -r ENV_ERR='The environment variables $VISUAL and $EDITOR were note defined.'

	# echo "list_edit() | EDITOR: $EDITOR (${#EDITOR})"
	# echo "list_edit() | VISUAL: $VISUAL (${#VISUAL})"
	# echo "list_edit() | EDITOR: $HOMEBREW_EDITOR (${#HOMEBREW_EDITOR})"
	# echo "list_edit() | HOMEBREW_VISUAL: $HOMEBREW_VISUAL (${#HOMEBREW_VISUAL})"
	# echo "list_edit() | which vi: $(which vi)"
	# env | sort

	if [[ ${#VISUAL} -gt 0 ]]; then
		$VISUAL	"$LINKS_PATH"
	elif [[ ${#HOMEBREW_VISUAL} -gt 0 ]]; then
		$HOMEBREW_VISUAL	"$LINKS_PATH"
	elif [[ ${#EDITOR} -gt 0 ]]; then
		$EDITOR	"$LINKS_PATH"
	elif [[ ${#HOMEBREW_EDITOR} -gt 0 ]]; then
		$HOMEBREW_EDITOR	"$LINKS_PATH"
	elif [[ -x "$(which vi)" ]]; then
		vi	"$LINKS_PATH"
	elif [[ -e "$(which vi)" ]]; then
		echo $ENV_ERR 1>&2
		echo "And vi found but not executable by this user."
	else
		echo $ENV_ERR 1>&2
		echo "And iv not found on this system."
	fi
}

list_has()
{
	local app_name="$1"
	local -i has_app=1
	cat "$LINKS_PATH" | grep '^- \['"$app_name"']' > /dev/null
	has_app=$?
	# echo "list_has() | \$has_app: $has_app"

	return $has_app
}

note_add()
{
	local app="$1"
	local link
	local has_app

	list_has "$app"
	has_app=$?

	# echo "note_add() | \$app: $app"
	# echo "note_add() | \$has_app: $has_app"
	# exit 0
	if [[ $has_app -eq 0 ]]; then
		echo "$APP_NAME has already noted: \"$(brew desc "$app")\""
	else
		link="$(get_md_list_link "$app")"

		if [[ "$link" != '- [](): ' ]]; then
			cat "$LINKS_PATH" > "$CONFIG_PATH/links.tmp"
			echo "$(get_md_list_link "$app")" >> "$CONFIG_PATH/links.tmp"
			cat "$CONFIG_PATH/links.tmp" | sort -u > "$LINKS_PATH"
			open "$LINKS_PATH"
		else
			echo "Link error" 1>&2
			exit 2
		fi
	fi
}

note_list()
{
	cat "$TEMPLATE_HEADER" > "$NOTES_PATH"
	cat "$LINKS_PATH" >> "$NOTES_PATH"
	template="$(eval "echo \"$(<"$TEMPLATE_FOOTER")\"" 2> /dev/null)"
	echo "$template" >> "$NOTES_PATH"
	if [[ "$(uname -s)" = 'Darwin' ]]; then
		open "$NOTES_PATH"
	else
		cat "$NOTES_PATH"
	fi
	exit 0
}

note_remove()
{
	local app="$1"
	local link="$(get_md_list_link "$app")"

	echo "note_remove() | \$link: $link"
	exit 0

	if [[ "$link" != '- [](): ' ]]; then
		cat "$LINKS_PATH" > "$CONFIG_PATH/links.tmp"
		echo "$(get_md_list_link "$app")" >> "$CONFIG_PATH/links.tmp"
		cat "$CONFIG_PATH/links.tmp" | sort -u > "$LINKS_PATH"
		open "$LINKS_PATH"
	else
		echo "Link error" 1>&2
		exit 2
	fi
}

note_version()
{
	echo "$APP_LABEL"
	exit 0
}

show_help()
{
	cat <<-EOH
	$APP_LABEL

	$APP_DESC

	$CLI_NAME [OPTIONS] ...

	OPTIONS:
	  -a | -add  | --add-note    Add a note
	  -e | -edit | --edit-list   Edit the list
	  -H | -help | --note-help   Display this help info
	  -l | -list | --list-notes  List notes
	  -r | -rm   | --remove      Remove note
	  -v | -ver  | --version     Display this version info

EOH
	exit 0
}

#
# CONFIG
#
if [[ ${#XDG_CONFIG_HOME} -gt 0 ]] && [[ -d "${XDG_CONFIG_HOME}" ]]; then
	CONFIG_PATH="${XDG_CONFIG_HOME}/brew-note"
elif [[ -d ~/.config ]]; then
	CONFIG_PATH=~/.config/brew-note
elif [[ ${#XDG_DATA_HOME} -gt 0 ]] && [[ -d "${XDG_DATA_HOME}" ]]; then
	CONFIG_PATH="${XDG_DATA_HOME}/brew-note"
elif [[ -d ~/.local ]]; then
	if [[ -d ~/.local/share ]]; then
		CONFIG_PATH=~/.local/share/brew-note
	else
		CONFIG_PATH=~/.local/brew-note
	fi
else
	CONFIG_PATH=~/.brew-note
fi
if [[ ! -d "${CONFIG_PATH}" ]]; then
	printf "Creating $APP_NAME configuration directory at:\n    $CONFIG_PATH"
	mkdir -p "${CONFIG_PATH}"
fi
LINKS_PATH="${CONFIG_PATH}/links.md"
NOTES_PATH="${CONFIG_PATH}/notes.md"
TEMPLATE_FOOTER="${CONFIG_PATH}/template-footer.md"
TEMPLATE_HEADER="${CONFIG_PATH}/template-header.md"
# echo "LINKS_PATH: $LINKS_PATH"
# echo "NOTES_PATH: $NOTES_PATH"

# - [aptly](https://www.aptly.info/)
# - [dbxml](https://www.oracle.com/database/berkeley-db/xml.html)
# - [kitchen-sync](https://github.com/willbryant/kitchen_sync)

#
# OPTION PARSING
#
if [[ $# -eq 0 ]]; then
	# show_help
	note_list
	exit 0
else
	until [[ $# -eq 0 ]]; do
		let "arg_loops += 1"
		case "$1" in
		-a | -add | --add-note)
			note_add "$2"
			shift
			;;
		add)
			if [[ $arg_loops -eq 1 ]]; then
				note_add "$2"
				shift
			else
				ARGS=( "${ARGS[@]}" "$1" )
			fi
			;;
		-e | -edit | --edit-list)
			list_edit
			;;
		-l | -list | --list-notes)
			note_list
			;;
		list)
			if [[ $arg_loops -eq 1 ]]; then
				note_list
			else
				ARGS=( "${ARGS[@]}" "$1" )
			fi
			;;
		-H | -help | --note-help)
			show_help
			;;
		help)
			if [[ $arg_loops -eq 1 ]]; then
				show_help
			else
				ARGS=( "${ARGS[@]}" "$1" )
			fi
			;;
		-r | -rm | --remove)
			note_remove "$2"
			shift
			;;
		remove)
			if [[ $arg_loops -eq 1 ]]; then
				note_remove "$2"
				shift
			else
				ARGS=( "${ARGS[@]}" "$1" )
			fi
			;;
		-v | -ver | --version)
			note_version
			;;
		version)
			if [[ $arg_loops -eq 1 ]]; then
				note_version
			else
				ARGS=( "${ARGS[@]}" "$1" )
			fi
			;;
		*)
			ARGS=( "${ARGS[@]}" "$1" )
			;;
		esac

		shift
	done
fi


if [[ ${#ARGS[@]} -gt 0 ]]; then
	if [[ ${#ARGS[@]} -eq 1 ]]; then
		note_add ${ARGS[0]}
	else
		echo "Don't know what to do with: ${ARGS[@]}"
	fi
fi

