#!/bin/bash

fct_usage() {
    echo "Usage: $(basename $0) -l <latest> -p <previous> [-d|-n] [-L <LANG>] [-F <folder>]"
    echo "    -l: Latest version"
    echo "    -p: Previous version"
    echo "    -d: Display only the modified cards"
    echo "    -n: Display only the new cards"
    echo "    -L: Define the langage of the collections (Default: enUS)"
    echo "    -F: Set the folder to download the collections (Default: /tmp)"
    exit 1
}

while getopts ":dl:np:L:F:" opt; do
  case ${opt} in
    d)
      Diff_only=True
      ;;
    l)
      Latest=$OPTARG
      ;;
    n)
      New_only=True
      ;;
    p)
      Oldest=$OPTARG
      ;;
    F)
      Local_folder=${OPTARG}
      ;;
    L)
      URL_LANG=${OPTARG}
      ;;
    *) fct_usage
      ;;
  esac
done
if [[ $New_only == "True" && $Diff_only == "True" ]]
then
    echo "You cannot mixed the 2 options -d and -n"
    fct_usage
fi
URL_LANG=${URL_LANG:-'enUS'}
JSON_URL='https://api.hearthstonejson.com/v1'
Online_latest=$(curl -s $JSON_URL | grep href | cut -d'"' -f2 | cut -d'/' -f3 | sort -nu | tail -1)
Latest=${Latest:-$Online_latest}
Local_folder=${Local_folder:-/tmp}
if [[ ! -d $Local_folder ]]
then
    echo "Folder ${Local_folder} does not exist"
    echo "Please ensure to use a valid folder"
    exit 5
fi
if [[ -z ${Latest} ]] || [[ -z ${Oldest} ]]
then
    echo "Missing Parameter(s)."
    fct_usage
fi

Oldest_file=${Local_folder}/cards_${Oldest}_${URL_LANG}.json
if [[ ! -f ${Oldest_file} ]] || [[ ! -s ${Oldest_file} ]]
then
    echo "Download ${Oldest} (${URL_LANG}) to ${Oldest_file}"
    /usr/bin/curl -s -k -L "${JSON_URL}/${Oldest}/${URL_LANG}/cards.json" | jq -r '.' > ${Oldest_file} 2>/dev/null
    if [[ $? != 0 ]] || [[ ! -f ${Oldest_file} ]] || [[ ! -s ${Oldest_file} ]]
    then
        echo "[Error] Unable to download JSON patch ${Latest} from: ${JSON_URL}/${Latest}/${URL_LANG}/cards.json"
        exit 10
    fi
fi

Latest_file=${Local_folder}/cards_${Latest}_${URL_LANG}.json
if [[ ! -f ${Latest_file} ]] || [[ ! -s ${Latest_file} ]]
then
    echo "Download ${Latest} (${URL_LANG}) to ${Latest_file}"
    /usr/bin/curl -s -k -L "${JSON_URL}/${Latest}/${URL_LANG}/cards.json" | jq -r '.' > ${Latest_file} 2>/dev/null
    if [[ $? != 0 ]] || [[ ! -f ${Latest_file} ]] || [[ ! -s ${Latest_file} ]]
    then
        echo "[Error] Unable to download JSON patch ${Latest} from: ${JSON_URL}/${Latest}/${URL_LANG}/cards.json"
        exit 10
    fi
fi

# Sort the data by dbfId
OLD_DATA=$(jq -c 'sort_by(.dbfId) | .[]' ${Oldest_file})
NEW_DATA=$(jq -c 'sort_by(.dbfId) | .[]' ${Latest_file} | sed -e "s/ /~!@/g")
NB_IDs=$(echo "${NEW_DATA}" | wc -l | awk '{print $1}')
MAX_ID=$(echo "${NEW_DATA}" | jq -r '.dbfId' | tail -1)
Group_max=0
if [[ ${URL_LANG} == all ]]
then
    Group_size=500
else
    Group_size=$[MAX_ID * 100 / $NB_IDs ]
    Group_size=700
fi
Count=0
Count_mod=0
Count_add=0
while [[ ${Count} -lt ${NB_IDs} ]]
do
    # Split the data in small groups to avoid to compare with to much data
    Group_min=$Group_max
    Group_max=$[Group_max + Group_size ]
    SIZED_NEW=$(echo "${NEW_DATA}" | jq -c "select((.dbfId >= ${Group_min}) and (.dbfId < ${Group_max}))")
    SIZED_OLD=$(echo "${OLD_DATA}" | jq -c "select((.dbfId >= ${Group_min}) and (.dbfId < ${Group_max}))")
    for raw_data in $SIZED_NEW
    do
        New_data=$(echo ${raw_data} | sed -e "s/~!@/ /g" | jq -r '.')
        dbfid=$(echo "${New_data}" | jq -r '.dbfId')
        Old_data=$(echo "${SIZED_OLD}" | jq -r "select(.dbfId == ${dbfid})")
        if [[ "${New_data}" != "${Old_data}" ]]
        then
            if [[ -z ${Old_data} ]] && [[ $Diff_only != "True" ]]
            then
                Count_add=$[Count_add + 1]
                if [[ $New_only != "True" ]]
                then
                    echo "########################################"
                fi
                echo "${New_data}"
                if [[ $New_only != "True" ]]
                then
                    echo "New entry"
                fi
            else
                if [[ ! -z ${Old_data} ]] && [[ $New_only != "True" ]]
                then
                    Count_mod=$[Count_mod + 1]
                    echo "########################################"
                    echo "${New_data}"
                    echo "------------------------"
                    diff <(echo "${New_data}") <(echo "${Old_data}")| grep -E '^>|^<'
                fi
            fi
        fi
        Count=$[Count + 1]
        # Display a status
        if [[ $New_only != "True" ]]
        then
            echo -ne "Items analyzed: ${Count}/${NB_IDs} ($[Count * 100 / $NB_IDs]%) \033[0K\r" >&2
        fi
    done
done
# Display a summary
echo -e "\n########################################"

if [[ $Diff_only != "True" ]]
then
    echo "Number of items added: ${Count_add}"
fi
if [[ $New_only != "True" ]]
then
    echo "Number of items modified: ${Count_mod}"
fi
