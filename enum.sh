#!/bin/bash

# Colourise the output
RED='\033[0;31m' # Red
GRE='\033[1;32m' # Green
YEL='\033[1;33m'
BLU='\033[1;34m' # Yellow
NCL='\033[0m'    # No Color
# initialise the arrays to hold the desired stats

depth_counter=0

TOTAL_SIZE=0
DIR_NUM=0
FILE_NUM=0

ATTR_755=0
ATTR_777=0
ATTR_664=0
ATTR_655=0
OTH_ATTR_=0

total_stats() {
    printf "\n\n\n\t\t\t\t\t${RED}Enumerating Directory${NCL}\n\n"
    printf "\n\t\t\t${BLU}===================================================================${NCL}\n\n"
    printf "\t\t\t\t${GRE}Path: ${YEL}\t\t${1}\n"
    printf "\t\t\t\t${GRE}Depth: ${YEL}\t\t${2}\n"
    printf "\t\t\t\t${GRE}Total Size: ${YEL}\t$((${TOTAL_SIZE%% *} / 1024)) MB\n"
    printf "\t\t\t\t${GRE}Directories: ${YEL}\t$DIR_NUM\n"
    printf "\t\t\t\t${GRE}Files: ${YEL}\t\t$FILE_NUM\n\n\n"
}

file_specification() {
    FILE_NAME="$(basename "${entry}")"
    DIR="$(dirname "${entry}")"
    NAME="${FILE_NAME%.*}"
    EXT="${FILE_NAME##*.}"
    SIZE="$(du -s "${entry}" | cut -f1)"
    ATTR="$(stat -c "%a" "${entry}")"
    TOTAL_SIZE=$(("$(du -s "${entry}" | cut -f1)" + $TOTAL_SIZE))
    FILE_NUM=$((FILE_NUM + 1))
    printf "%*s${GRE}%s${NCL}\n" $((indent + 4)) '' "${entry}"
    printf "%*s\tFile name:\t${YEL}%s${NCL}\n" $((indent + 4)) '' "$FILE_NAME"
    printf "%*s\tDirectory:\t${YEL}%s${NCL}\n" $((indent + 4)) '' "$DIR"
    printf "%*s\tName only:\t${YEL}%s${NCL}\n" $((indent + 4)) '' "$NAME"
    printf "%*s\tExtension:\t${YEL}%s${NCL}\n" $((indent + 4)) '' "$EXT"
    printf "%*s\tFile size:\t${YEL}%s${NCL}\n" $((indent + 4)) '' "$SIZE"
    
    if [ $ATTR == "755" ]; then
        ATTR_755=$((ATTR_755 + 1))
        elif [ $ATTR == "777" ]; then
        ATTR_777=$((ATTR_777 + 1))
        printf "\t\t${RED}[IMPORTANT!]${YEL} This file has 777 ATTR_*ibutes -> ${RED}$file \n"
        elif [ $ATTR == "664" ]; then
        ATTR_664=$((ATTR_664 + 1))
        elif [ $ATTR == "655" ]; then
        ATTR_655=$((ATTR_655 + 1))
    else
        OTH_ATTR=$((OTH_ATTR + 1))
        
    fi
    
}

walk() {
    local indent="${2:-0}"
    printf "\n%*s${RED}%s${NCL}\n\n" "$indent" '' "$1"
    
    # If the entry is a file do some operations
    for entry in "$1"/*; do
        if [[ -f "$entry" ]]; then
            file_specification
        fi
    done
    # If the entry is a directory call walk() == create recursion
    depth=$((depth + 1))
    
    for entry in "$1"/*; do
        if [[ -d "$entry" ]] && [[ "$depth_counter" -le ${DEPTH} ]]; then
            walk "$entry" $((indent + 4))
            DIR_NUM=$((DIR_NUM + 1))
        fi
    done
}

file_permissions() {
    
    printf "\n\t\t\t\t\t${RED}File Permissions!${NCL}\n\n"
    printf "\n\t\t\t${BLU}===================================================================${NCL}\n\n"
    #ATTR_*644=$(( ( $ATTR_*644 / FILE_NUM ) * 100 ))
    perc_777=$((ATTR_777 * 100 / FILE_NUM))
    perc_755=$((ATTR_755 * 100 / FILE_NUM))
    perc_655=$((ATTR_655 * 100 / FILE_NUM))
    perc_664=$((ATTR_664 * 100 / FILE_NUM))
    perc_other=$((OTH_ATTR * 100 / FILE_NUM))
    
    printf "\n\n\t\t\t\t${YEL}Total Files\t777\t755\t655\t664\tOther${NCL}\n\n"
    printf "\t\t\t\t${GRE}$FILE_NUM\t\t$ATTR_777\t$ATTR_755\t$ATTR_655\t$ATTR_664\t$OTH_ATTR\n\n"
    printf "\t\t\t\t${GRE}100 %% \t\t$perc_777%%\t$perc_755%%\t$perc_655%%\t$perc_664%%\t$perc_other%% ${NCL}\n\n"
    
}

lastly_created() {
    printf "\n\n\t\t\t\t\t${RED}Five lastly created files!${NCL}\n\n"
    printf "\n\t\t\t${BLU}===================================================================${NCL}\n\n"
    # printf "\n\t\t\t${GRE}Time\t\tMonth\t\Name${YEL}\n"
    
    for i in {2..6}; do
        ls -tl | head -6 | awk '{print $9}' | sed "${i}q;d"
        ls -tl | head -6 | awk '{print $8}' | sed "${i}q;d"
        ls -tl | head -6 | awk '{print $7}' | sed "${i}q;d"
        
        printf "${BLU}========================\n${NCL}"
    done
}

largest_files() {
    printf "\n\n\t\t\t\t\t${RED}Five largest files!${NCL}\n\n"
    printf "\n\t\t\t${BLU}===================================================================${NCL}\n\n"
    printf "\n\t\t${GRE}    Size in Bytes\t\t${GRE}Absolute Paths to the files${NCL}\n\n"
    find "${1}" -maxdepth "${2}" -not -path "*/\.*" -type f -printf "\t\t\t${YEL}%s\t%p${NCL}\n" | sort -nr | head -5
}

dir_files() {
    printf "\n\n\t\t\t\t\t${RED}Directories with most files!${NCL}\n\n"
    printf "\n\t\t\t${BLU}===================================================================${NCL}\n\n"
    printf "\n\t\t${GRE}    Number of files\t\t${GRE}Absolute Paths to the directories${NCL}\n\n"
    
    find ${1} -maxdepth ${2} -type d | while read -r dir; do
        NUM=$(ls "$dir" -lAh | grep -v '^d' | wc -l)
        [ -d "$dir" ] && printf "\n\t\t\t${NCL}${YEL} $NUM\t\t%s\t" "$dir"
    done | sort -k2nr | head -5
}

dir_size() {
    printf "\n\n\t\t\t\t\t${RED}Directories with largest size!${NCL}\n\n"
    printf "\n\t\t\t${BLU}===================================================================${NCL}\n\n"
    printf "\n\t\t${GRE}    Size of directories\t\t${GRE}Absolute Paths to the directories${NCL}\n\n"
    
    find ${1} -maxdepth ${2} -type d | while read -r dir; do
        NUM=$(du -h -d 1 "$dir")
        [ -d "$dir" ] && printf "\n\t\t\t${YEL} $NUM\t\t%s:\t ${NCL}" "$dir"
    done | sort -k2hr | head -5
}
# Prints the 5 last modified files in the folder specified
# as the first argument of the function
# as a second parameter the depth of the look is specified

lastly_modified() {
    
    printf "\n\n\t\t\t\t\t${RED}Five lastly modified files!${NCL}\n\n"
    printf "\n\t\t\t${BLU}===================================================================${NCL}\n\n"
    printf "\n\t\t\t${GRE}Time\t\tEpoch Time\t\tAbsolute Path${YEL}\n"
    
    find ${1} -maxdepth ${2} -not -path '*/\.*' -type f -exec stat --format ':%y %n' "{}" \; | sort -nr | cut -d: -f2- | head -5 | awk '{ printf "\n\t\t\t"$1"\t"$2"\t"$4"\t"}'
    
}

lastly_accessed() {
    
    printf "\n\n\t\t\t\t\t${RED}Five lastly accessed files!${NCL}\n\n"
    printf "\n\t\t\t${BLU}===================================================================${NCL}\n\n"
    printf "\n\t\t\t${GRE}Time\t\tEpoch Time\t\tAbsolute Path${YEL}\n"
    
    find ${1} -maxdepth ${2} -not -path '*/\.*' -type f -exec stat --format ':%x %n' "{}" \; | sort -nr | cut -d: -f2- | head -5 | awk '{ printf "\n\t\t\t"$1"\t"$2"\t"$4"\t"}'
}

# Prints information about the system
system_info() {
    printf "\n\n\n\t\t\t\t\t${RED} System information${NCL}\n"
    printf "\n\t\t\t${BLU}===================================================================${NCL}\n\n"
    unameinfo=$(uname -a 2>/dev/null)
    if [ "$unameinfo" ]; then
        printf "\n\n\t\t\t${GRE}Kernel information:${YEL}\t\t $unameinfo \n"
    fi
    
    release=$(cat /etc/*-release 2>/dev/null)
    if [ "$release" ]; then
        printf "\n\t\t\t${GRE}Specific release information:${YEL}\n"
        
        for each in $release; do
            printf "\n\t\t\t $each"
        done
        
    fi
    
    hostname=$(hostname 2>/dev/null)
    if [ "$hostname" ]; then
        printf "\n\n\t\t\t${GRE}Hostname:${YEL}\t\t $hostname \n"
        
    fi
    printf "\n\n\n\t\t\t\t\t${RED}Disk Sizes!${NCL}\n\n"
    printf "\n\t\t\t${BLU}===================================================================${NCL}\n\n"
    printf "\t\t\t\t${YEL}Disk Sector\tSize\tUsed\tAvailable\tPercentage${NCL}\n"
    df -h | grep "/dev/sda*" | awk '{ printf "\n\t\t\t\t"$1"\t\033[1;34m" $2"\t\033[0;31m"$3"\t\033[1;32m"$4"\t\t\033[0;31m"$5"\033[0m"}' 
    
}
# ENTRY POINT
# If the path is empty use the current, otherwise convert relative to absolute; Exec walk()
[[ -z "${1}" ]] && ABS_PATH="${PWD}" || cd "${1}" && ABS_PATH="${PWD}" || [[ -z "${2}" ]] && DEPTH=2 || DEPTH="${2}"

walk "${ABS_PATH}"
total_stats "${ABS_PATH}" "${DEPTH}"
file_permissions "${ABS_PATH}" "${DEPTH}"
lastly_modified "${ABS_PATH}" "${DEPTH}"
lastly_accessed "${ABS_PATH}" "${DEPTH}"
largest_files "${ABS_PATH}" "${DEPTH}"
dir_files "${ABS_PATH}" "${DEPTH}"
dir_size "${ABS_PATH}" "${DEPTH}"
system_info

# printf "\n\n\t\t\t\t\t${RED}Five largest folders!${NCL}\n\n"
# printf "\n\t\t\t${BLU}===================================================================${NCL}\n\n"

printf "\n\n\n\n\t\t\t\t${RED} Execution finished !!!${NCL}\n"
printf "\n\t\t\t\t${RED} Execution finished !!!${NCL}\n"
printf "\n\t\t\t\t${RED} Execution finished !!!${NCL}\n"
printf "\n\t\t\t\t${RED} Execution finished !!!${NCL}\n\n\n"
