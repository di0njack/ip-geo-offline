#!/bin/bash
#Author: Di0nj@ck - 12/12/19
#Version: 1.0

# Basic bash 1-line IP Geolocator using free Maxmind DB
#*******************************************************************************************************************

#CONFIG VARIABLES
APP_VERSION=1.0
APP_DIR=$(pwd)
SCRIPT_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S")

#GLOBAL VARIABLES
report_file="geo_data.txt"
maxmind_db_path="$1"
ip_file="$2"
ips_list=()
geo_data_results=()

#************************************************************************************

#LOAD FILE INTO ARRAY
function load_file_into_array {
    
    readarray -t ips_list < "$1"
}


#GEOLOCATE IP USING FREE LOCAL MAXMIND DB
function geolocate {

    cnt=${#ips_list[@]}
    i=0

    for an_ip in "${ips_list[@]}";do
        printf '    [%d/%d] Geolocating IP: %s\n' "$((i + 1))" "$cnt" "$an_ip"
        geo_data=$(mmdblookup --file $maxmind_db_path --ip $an_ip location) 
        if [[ "$geo_data" == *"metro_code"* ]];then #NOT ALL MAXMIND RESULTS INCLUDE METRO_CODE TAG
            geo_result=$(echo $geo_data | tr -d '{}"' | tr '\n' ' ' | awk '{print $14}')
        else
            geo_result=$(echo $geo_data | tr -d '{}"' | tr '\n' ' ' | awk '{print $11}')
        fi

        printf '        * City: %s\n\n' "$geo_result"
        result=$(printf 'IP: %s\nCity:%s' "$an_ip" "$geo_result")
        geo_data_results+=( "$result" ) 
        i=$i+1
    done
}


#PARSE WHOIS RESULTS AND SAVE ON FILE
function output_results {
    exec 3<> "$report_file"
    SAVEIFS=$IFS   # Save current IFS
    IFS=$'\n'
    
    #STORE EACH GEO DATA RESULT INTO OUR REPORT FILE
    for geo_data in "${geo_data_results[@]}";do
        printf '%s\n'"$geo_data" >&3
    done

    #SUMMARY OF KEY FINDINGS
    printf '[*] Extracting a summary of key findings...\n'
    printf '\n\n%s\n\n%s\n' "*** SUMMARY OF KEY FINDINGS *** (sorted)" "      - Most frequent locations:" >&3

    results=$(cat $report_file | grep -i "City:" | sort | uniq -c | sort -n)
    printf '%s\n\n' "$results" >&3

    IFS=$SAVEIFS
}

#************************************************************************************
#**** MAIN CODE ****

#READ INPUT FILE WITH TARGET IPs INTO AN ARRAY
printf '[*] Loading input file of IPs...\n'
load_file_into_array "$2"

#GEOLOCATE THE IPs
printf '[*] Performing IP Geolocating queries to local Free Maxmind DB...\n'
geolocate

#SAVE RESULTS
printf '[*] Saving results into a file...\n'
output_results

printf '[*] FINISHED. ALL DONE!\n'