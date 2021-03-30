#!/bin/bash

# Created by: Alexander Belikov
# Mount UNC path, filter files by datafilter, prepare data and export into clickhouse

# Required 2 arguments: 1- unc path, 2- data filter
if test -z "$1" || test -z "$2"
then
    echo "argument 1 - unc-path: \$1 or 2 - datefilter:  \$2 is empty " 1>&2
    exit 1
fi


# Init variables
# sudo mkdir /mnt/MessageTrackingLog
mount_path=/mnt/MessageTrackingLog
root_dir=$(dirname $0)
mtl_path=$1
date_filter=$2
mtl_path_slashed="${mtl_path//\\//}"
mtl_csv_path="$root_dir/csv/mtl.csv"
mtl_report_csv_path="$root_dir/csv/mtl_report.csv"
skip_lines_default=5
echo "$mtl_path"

# Export to $mtl_report_csv_path max file row id when any log_path like $mtl_path_re
mtl_path_re="^$mtl_path\\MSGTRK(MD|MS)$date_filter"
mtl_path_re="${mtl_path_re//\\/\\\\\\\\}"
mtl_path_re="${mtl_path_re//\$/\\\\\\\$}"

log_exists=$(clickhouse-client -u log_robot --query="SELECT 1 FROM MSE.B13_MESSAGE_TRACKING_LOG A WHERE match(A.log_path,'$mtl_path_re') LIMIT 1")
exit_status=$?
if [[ $exit_status != 0 ]]
then 
    echo "clickhouse-client exit_status: $exit_status"
    exit $exit_status 
fi

# echo "log_exists: $log_exists"
if [[ $log_exists ]]
then 
    echo -n "?"
    rm -f "$mtl_report_csv_path"
    clickhouse-client -u log_robot --query="SELECT A.log_path, MAX(A.log_row_id) FROM MSE.B13_MESSAGE_TRACKING_LOG A WHERE match(A.log_path,'$mtl_path_re') GROUP BY A.log_path INTO OUTFILE '$mtl_report_csv_path' FORMAT CSV"
    exit_status=$?
    if [[ $exit_status != 0 ]]
    then 
        echo "clickhouse-client exit_status: $exit_status"
        exit $exit_status 
    fi
fi


# Mount unc path
sudo mount -t drvfs "$mtl_path_slashed" $mount_path

# Upload each match data filter file into clickhouse
find "$mount_path" -maxdepth 1 -type f -regextype posix-extended -iregex ".*/MSGTRK(MD|MS)$date_filter.*.LOG" -print0 | while IFS= read -r -d '' file; do
    # echo "$file"
    skip_lines=$((skip_lines_default+1))
    original_file_path=${file/$mount_path/$mtl_path}
    original_file_path=${original_file_path//\//\\}
    original_file_path=${original_file_path//\\/\\\\}
    is_append=false


    # Skip file when it already uploaded, or upload from last uploaded row
    if [[ $log_exists ]]
    then 
        db_log_row_id=$(cat "$mtl_report_csv_path" | grep -i "$original_file_path" | awk -F',' '{print $NF}')
        # echo "db_log_row_id: $db_log_row_id"
        if [[ $db_log_row_id ]]
        then 
            file_rows_count=$(cat $file | wc -l)
            # echo "file_rows_count: $file_rows_count"
            if [[ $file_rows_count -gt $db_log_row_id ]]
            then 
                # echo "file_rows_count > db_log_row_id"
                skip_lines=$((db_log_row_id+1))
                is_append=true
                # echo -n "+"
            else
                # echo "file_rows_count <= db_log_row_id"
                file_status="skip"
                echo -n "-"
                continue
            fi
        fi
    fi
    # echo "skip_lines: $skip_lines"


    # Prepare log file: 
    # 1 - insert fields: log_path, log_row_id
    # 2 - append 3 empty column then log version is 15.00
    # 3 - Double quote every column
    # 4 - Skip header or exists in DB rows 
    # 5 - Exit if unknown log version
    rm -f "$mtl_csv_path"

    Version=$(sed -n 2p "$file")
    if [[ $Version == '#Version: 15.00.'* ]]
    then
        sed '=' $file | sed "s/^/$original_file_path,/;N;s/\n/,/;s/\r$/,,,/" | tail -n +$skip_lines | python3 "$root_dir/csvquote.py" > "$mtl_csv_path"
    else
        if [[ $Version == '#Version: 15.02.'* ]]
        then
            sed '=' $file | sed "s/^/$original_file_path,/;N;s/\n/,/" | tail -n +$skip_lines | python3 "$root_dir/csvquote.py" > "$mtl_csv_path"
        else
            echo "Unknown log version $Version file $file " 1>&2
            exit 1
        fi
    fi

    # Upload log file if it is not empty
    if [[ -s ${mtl_csv_path} ]]
    then
        cat "$mtl_csv_path" | clickhouse-client -u log_robot --query="INSERT INTO MSE.B13_MESSAGE_TRACKING_LOG FORMAT CSV"
        if $is_append
        then 
            echo -n "+"
        else
            echo -n "#"
        fi
        exit_status=$?
        if [[ $exit_status != 0 ]]
        then 
            echo "clickhouse-client exit_status: $exit_status"
        fi
    else
        file_status="empty"
        echo -n "O"
    fi


done
echo ""


# Umount unc path
sudo umount $mount_path

