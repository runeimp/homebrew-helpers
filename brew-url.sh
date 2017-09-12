#!/usr/bin/env bash
#####
# Homebrew URL Launcher
#
# @see [Starting browser (Firefox, Safari, Opera, Chrome) from batch/bash script - Tonjoo Studio]: https://tonjoostudio.com/starting-browser-firefox-safari-opera-chrome-from-batchbash-script/
#
#####
# ChangeLog:
# ----------
# 2017-03-15  1.1.0      Added -c and -d options and smarter parsing. 
# 2016-05-25  1.0.0      Initial script creation?
#

browser='Google Chrome'
declare -i caskroom=1

# echo "\$@: $@"

until [[ $# -eq 0 ]]; do
	case "$1" in
		-c)
			browser='Google Chrome'
			;;
		-d)
			browser=Safari
			;;
		[Cc]askroom*)
			caskroom=0
			;;
		*)
			app="$1"
			;;
	esac

	shift
done

# echo "browser: $browser"
# echo "caskroom: $caskroom"
# echo "app: $app"

result=$(brew info "$app" 2>&1)
exit_code=$?

# echo "result: $result"
# echo "exit_code: $exit_code"

if [[ $exit_code -gt 0 ]]; then
	result=$(brew cask info "$app" 2>&1)
	exit_code=$?
	# echo "result: $result"
	# echo "exit_code: $exit_code"
fi

if [[ $exit_code -gt 0 ]]; then
	echo "Couldn't find app in Homebrew" 1>&2
else
	url=$(echo "$result" | grep -v caskroom | egrep ^https?:.* )
	open -a "$browser" "$url"
fi


# app="$1"

# case "${app:0:8}" in
# 	[Cc]askroom)
# 		open -a 'Google Chrome' $(brew cask info $app | grep -v caskroom | egrep ^https?:.*)
# 		;;
# 	*)
# 		open -a 'Google Chrome' $(brew info $app | egrep ^https?:.*)
# 		;;
# esac
