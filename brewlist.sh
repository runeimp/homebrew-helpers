#!/usr/bin/env bash
###################
# brewlist v0.2.0
#
# @author RuneImp <runeimp@gmail.com>
# @licenses http://opensource.org/licenses/MIT
#
#

APP_NAME="BrewList"
APP_VERSION="0.2.0"
APP_LABEL="$APP_NAME v$APP_VERSION"

conf=""
file="brew-list"
file_ext=".md"
i=0
list=""
output=""
prefix=""
title="Brew List"
title_length=0
title_underline=""

output="${output}${title}"
title_length=${#title}

# i=0
# while [[ $i < $title_length ]]; do
# 	title_underline="${title_underline}="
# 	let "i += 1"
# done

until [[ $# -eq 0 ]]; do
	case "$1" in
		-e | --ext | --extension)
			file_ext="$2"
			shift
			;;
		-f | --file)
			file="$2"
			shift
			;;
		-p | --prefix)
			prefix="$2"
			shift
			;;
		-s | --suffix)
			suffix="$2"
			shift
			;;
		-V | --version)
			echo "$APP_LABEL"
			exit 0
			;;
		*)
			echo "Unknown option '$1'" 1>&2
			exit 1
			;;
	esac
	shift
done

filename="${prefix}${file}${suffix}${file_ext}"

# echo "\$filename: $filename"
# exit 69

while [[ ${#title_underline} < $title_length ]]; do
	title_underline="${title_underline}="
done


for item in $(brew leaves); do
	list=$(printf "${list}\n* %s" "$item")
done

# while read in $(brew config); do
# 	conf=$(printf "${conf}\n%s" "$item")
# done

while IFS='' read -r line || [[ -n "$line" ]]; do
    conf=$(printf "${conf}\n%s" "$line")
done <<< "$(brew config)"

output="$(printf "%s\n%s\n%s\n\n\nBrew Config\n-----------\n\n\`\`\`%s\n\`\`\`\n" "$title" "$title_underline" "$list" "$conf")"

# echo "$output"

echo "$output" > "$filename"
if [[ $? -eq 0 ]]; then
	echo "$filename created successfully."
else
	echo "Error writing $filename to the system."
fi

