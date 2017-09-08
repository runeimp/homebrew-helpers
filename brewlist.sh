#!/usr/bin/env bash
###################
# brewlist v0.1.0
#
# @author RuneImp <runeimp@gmail.com>
# @licenses http://opensource.org/licenses/MIT
#
#

conf=""
file="brew-list.md"
i=0
list=""
output=""
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


while [[ ${#title_underline} < $title_length ]]; do
	title_underline="${title_underline}="
done


for item in $(brew list); do
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

echo "$output" > "$file"
if [[ $? = 0 ]]; then
	echo "$file created successfully."
else
	echo "Error writing $file to the system."
fi

