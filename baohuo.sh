#!/bin/bash
# Author: An Shen
# Date: 2023-01-30

. /etc/profile

function log(){
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] - $1"
}

function get_latest_info(){
    local latest_info_file='/tmp/NeverIdle-latest-info.json'
    wget -q -O ${latest_info_file} https://api.github.com/repos/layou233/NeverIdle/releases/latest
    [[ $? -ne 0 ]] && log "Failed to get latest info" && exit 1
    latest_version=$(grep tag_name ${latest_info_file} | cut -d '"' -f 4| sed 's/^v//g')
    latest_comments=$(grep body ${latest_info_file} | cut -d '"' -f 4)
    rm -f ${latest_info_file}
}

function download_and_run() {
    local base_download_url="https://github.com/layou233/NeverIdle/releases/download"
    local filename="NeverIdle-${platform}"
    local download_dir="/tmp"
    local download_url="${base_download_url}/${latest_version}/${filename}"
    
    mkdir -p $download_dir
    rm -f ${download_dir}/NeverIdle

    log "Downloading ${filename} to ${download_dir}/NeverIdle ..."
    wget -q -O ${download_dir}/NeverIdle ${download_url}
    [[ $? -ne 0 ]] && log "Download ${filename} failed" && exit 1

    chmod +x ${download_dir}/NeverIdle
    local mem_test='-m 5'
    if [[ $mem_total -lt 4 ]]
    then
        log "AMD doesn't need to test memory !"
        local mem_test=''
    elif [[ $mem_total -lt 13  ]]
    then
        log "The memory test size is 3G"
        local mem_test='-m 3'
    else
        log "The memory test size is 5G"
    fi
    nohup ${download_dir}/NeverIdle -c 1h18m28s ${mem_test} -n 3h > ${download_dir}/NeverIdle.log 2>&1 &
    local pid=$(pgrep NeverIdle)
    log "NeverIdle [${pid}] is running"
    log "run 'pkill NeverIdle' to stop it."
    log "log file: ${download_dir}/NeverIdle.log"
}

function init(){
    case $(uname -m) in
    "x86_64")
        platform="linux-amd64"
        ;;
    "aarch64")
        platform="linux-arm64"
        ;;
    *)
        log "Unsupported platform !"
        exit 1
        ;;
    esac
   mem_total=$(free -g | awk '/Mem/ {print $2}')
}

function main(){
    init
    get_latest_info
    download_and_run
}
main