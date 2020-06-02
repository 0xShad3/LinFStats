#!/bin/bash

# Colourise the output
RED='\033[0;31m'        # Red
GRE='\033[1;32m'        # Green
YEL='\033[1;33m'
BLU='\033[1;34m'        # Yellow
NCL='\033[0m'           # No Color
# initialise the arrays to hold the desired stats

depth_counter=0

file_specification() {
    FILE_NAME="$(basename "${entry}")"
    DIR="$(dirname "${entry}")"
    NAME="${FILE_NAME%.*}"
    EXT="${FILE_NAME##*.}"
    SIZE="$(du -sh "${entry}" | cut -f1)"
    
    printf "%*s${GRE}%s${NCL}\n"                    $((indent+4)) '' "${entry}"
    printf "%*s\tFile name:\t${YEL}%s${NCL}\n"      $((indent+4)) '' "$FILE_NAME"
    printf "%*s\tDirectory:\t${YEL}%s${NCL}\n"      $((indent+4)) '' "$DIR"
    printf "%*s\tName only:\t${YEL}%s${NCL}\n"      $((indent+4)) '' "$NAME"
    printf "%*s\tExtension:\t${YEL}%s${NCL}\n"      $((indent+4)) '' "$EXT"
    printf "%*s\tFile size:\t${YEL}%s${NCL}\n"      $((indent+4)) '' "$SIZE"
    
}

walk() {
    local indent="${2:-0}"
    printf "\n%*s${RED}%s${NCL}\n\n" "$indent" '' "$1"
    
    # If the entry is a file do some operations
    for entry in "$1"/*; do [[ -f "$entry" ]] && file_specification; done
    # If the entry is a directory call walk() == create recursion
    depth=$((depth+1))
    for entry in "$1"/*; do [[ -d "$entry" ]] && [[  "$depth_counter" -le ${DEPTH} ]] && walk "$entry" $((indent+4)); done
}


file_permissions() {
    
    total_files=`find ${1} -maxdepth ${2} -not -path '*/\.*' -type f`
    total_no_of_files=`echo "$total_files" | wc -l`
    attr_755=0
    attr_777=0
    attr_664=0
    attr_655=0
    other_attr=0
    printf "\n\t\t\t\t\t${RED}File Permissions!${NCL}\n\n"
    printf "\n\t\t\t${BLU}===================================================================${NCL}\n\n"
    for file in $total_files; do
        if [ $(stat -c "%a" "$file") == "755" ]; then
            attr_755=$((attr_755 + 1))
            elif [ $(stat -c "%a" "$file") == "777" ]; then
            attr_777=$((attr_777 + 1))
            printf "\t\t${RED}[IMPORTANT!]${YEL} This file has 777 attributes -> ${RED}$file \n"
            elif [ $(stat -c "%a" "$file") == "664" ]; then
            attr_664=$((attr_664 + 1))
            elif [ $(stat -c "%a" "$file") == "655" ]; then
            attr_655=$((attr_655 + 1))
        else
            other_attr=$((other_attr + 1))
            
        fi
        
    done
    
    #attr_644=$(( ( $attr_644 / total_no_of_files ) * 100 ))
    perc_777=$((attr_777*100/total_no_of_files))
    perc_755=$((attr_755*100/total_no_of_files))
    perc_655=$((attr_655*100/total_no_of_files))
    perc_664=$((attr_664*100/total_no_of_files))
    perc_other=$((other_attr*100/total_no_of_files))
    
    printf "\n\n\t\t\t\t${YEL}Total Files\t777\t755\t655\t664\tOther${NCL}\n"
    printf "\t\t\t\t${GRE}$total_no_of_files\t\t$attr_777\t$attr_755\t$attr_655\t$attr_664\t$other_attr\n\n"
    printf "\t\t\t\t${GRE}100 %% \t\t$perc_777%%\t$perc_755%%\t$perc_655%%\t$perc_664%%\t$perc_other%% ${NCL}\n\n"
    
    
}

# Prints the 5 last modified files in the folder specified
# as the first argument of the function
# as a second parameter the depth of the look is specified

lastly_modified(){
    
    printf "\n\n\t\t\t\t\t${RED}Five lastly modified files!${NCL}\n\n"
    printf "\n\t\t\t${BLU}===================================================================${NCL}\n\n"
    printf "\n\t\t\t${GRE}Time\t\tEpoch Time\t\tAbsolute Path${YEL}\n"
    
    find ${1} -maxdepth ${2} -not -path '*/\.*' -type f -exec stat --format ':%y %n' "{}" \; | sort -nr | cut -d: -f2- | head -5 |  awk '{ printf "\n\t\t\t"$1"\t"$2"\t"$4"\t"}' 
    
}

# Prints information about the system
system_info(){
    printf "\n\n\n\t\t\t\t\t${RED} System information${NCL}\n"
    printf "\n\t\t\t${BLU}===================================================================${NCL}\n\n"
    unameinfo=`uname -a 2>/dev/null`
    if [ "$unameinfo" ]; then
        printf "\n\n\t\t${GRE}Kernel information:${YEL}\t\t $unameinfo \n"
    fi
    
    release=`cat /etc/*-release 2>/dev/null`
    if [ "$release" ]; then
        printf "\n\t\t${GRE}Specific release information:${YEL}\n"
        
        for each in $release; do
            printf "\n\t\t $each"
        done
        
    fi
    
    hostname=`hostname 2>/dev/null`
    if [ "$hostname" ]; then
        printf "\n\n\t\t${GRE}Hostname:${YEL}\t\t $hostname \n"
        
    fi
    
}
# ENTRY POINT
# If the path is empty use the current, otherwise convert relative to absolute; Exec walk()
[[ -z "${1}" ]] && ABS_PATH="${PWD}" || cd "${1}" && ABS_PATH="${PWD}" && DEPTH=${2}
printf "\n\n\n\t\t\t\t\t${RED}Enumerating Directory${NCL}\n\n"
printf "\n\t\t\t${BLU}===================================================================${NCL}\n\n"
printf "\t\t\t${GRE}\t${ABS_PATH}\n\n"
walk "${ABS_PATH}"
file_permissions "${ABS_PATH}" "${DEPTH}"
lastly_modified "${ABS_PATH}" "${DEPTH}"
system_info

printf "\n\n\n\t\t\t\t\t${RED}Disk Sizes!${NCL}\n\n"
printf "\n\t\t\t${BLU}===================================================================${NCL}\n\n"
printf "\t\t\t\t${YEL}Disk Sector\tSize\tUsed\tAvailable\tPercentage${NCL}\n"
df -h | grep "/dev/sda*" | awk '{ printf "\n\t\t\t\t"$1"\t\033[1;34m" $2"\t\033[0;31m"$3"\t\033[1;32m"$4"\t\t\033[0;31m"$5"\033[0m"}'


printf "\n\n\t\t\t\t\t${RED}Five largest files!${NCL}\n\n"
printf "\n\t\t\t${BLU}===================================================================${NCL}\n\n"
printf "\n\t${RED}    Size in Bytes\t\t${GRE}Absolute Paths to the files${NCL}\n\n"
find "${ABS_PATH}" -type f -printf "\t\t%s\t${YEL}%p${NCL}\n" | sort -n | tail -5


printf "\n\n\t\t\t\t\t${RED}Five largest folders!${NCL}\n\n"
printf "\n\t\t\t${BLU}===================================================================${NCL}\n\n"


printf "\n\t\t\t\t${RED} Execution finished !!!${NCL}\n\n"