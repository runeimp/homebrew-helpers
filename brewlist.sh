#!/usr/bin/env bash
###################
# BrewList
#
# @author RuneImp <runeimp@gmail.com>
# @licenses http://opensource.org/licenses/MIT
#
#####
# ChangeLog
# ---------
# 2018-03-18  0.5.0      Now lists dependencies as well as apps installed
# 2017-03-14  0.4.0      Added date to base_filename
# 2016-07-13  0.3.0      Updated filename generation with $USER
# 2016-05-12  0.2.0      Did something...
# 2016-00-00  0.1.0      Initial script creation
#
#####
# ToDo
# ----
# [] Use brew list and demark leaf items
#
#

#
# APP INFO
#
APP_NAME="BrewList"
APP_VERSION="0.5.0"
APP_LABEL="$APP_NAME v$APP_VERSION"


#
# VARIABLES
#
declare -i i=0
declare -i ref_time=$(date "+%s")
declare base_filename="${USER}-brew-list"
declare conf=""
declare datetime=""
declare file_ext=".md"
declare list=""
declare output=""
declare prefix=""
declare title="Brew List"
declare title_length=0
declare title_underline=""

output="${output}${title}"
title_length=${#title}


if [ "$(uname)" = 'Darwin' ]; then
	datetime=$(date -r"$ref_time" "+%Y-%m-%d_%H%M%S")
else
	datetime=$(date -d @"$ref_time" '+%Y-%m-%d_%H%M%S')
fi
base_filename="${base_filename}_${datetime}"

until [[ $# -eq 0 ]]; do
	case "$1" in
		-e | --ext | --extension)
			file_ext="$2"
			shift
			;;
		-f | --file)
			base_filename="$2"
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

filename="${prefix}${base_filename}${suffix}${file_ext}"

while [[ ${#title_underline} -lt $title_length ]]; do
	title_underline="${title_underline}="
done


declare -a all_list=( $(brew list) )
declare -a app_list=( $(brew leaves) )
declare -a dep_list
declare -i app_length=${#app_list[@]}
declare -i all_length=${#all_list[@]}
declare -i dep_length=0
declare -i i=0
declare -i j=0

# echo "\${#app_list[@]}: ${#app_list[@]}"
# echo "\${#all_list[@]}: ${#all_list[@]}"
echo "\$app_length: $app_length"
echo "\$all_length: $all_length"

while [[ $i -lt $all_length ]]; do
	j=0
	tmp_value="${all_list[i]}"

	while [[ $j -lt $app_length ]]; do
		if [[ "${all_list[i]}" = "${app_list[j]}" ]]; then
			tmp_value=""
		fi
		let "j += 1"
	done

	if [[ ${#tmp_value} -gt 0 ]]; then
		dep_list=( ${dep_list[@]} "$tmp_value" )
	fi
	let "i += 1"
done
dep_length=${#dep_list[@]}
echo "\$dep_length: $dep_length"
# exit 69

# for item in $(brew app_list); do
for item in ${app_list[@]}; do
	apps_list=$(printf "${apps_list}\n* %s" "$item")
done


for item in ${dep_list[@]}; do
	deps_list=$(printf "${deps_list}\n* %s" "$item")
done

# while read in $(brew config); do
# 	conf=$(printf "${conf}\n%s" "$item")
# done

while IFS='' read -r line || [[ -n "$line" ]]; do
    conf=$(printf "${conf}\n%s" "$line")
done <<< "$(brew config)"

template="%s\n%s\nApps Installed\n--------------%s\n\n### Dependencies\n%s\n\n\nBrew Config\n-----------\n\n\`\`\`%s\n\`\`\`\n"
output="$(printf "$template" "$title" "$title_underline" "$apps_list" "$deps_list" "$conf")"

# echo "$output"

echo "$output" > "$filename"
if [[ $? -eq 0 ]]; then
	echo "$filename created successfully."
else
	echo "Error writing $filename to the system."
fi

