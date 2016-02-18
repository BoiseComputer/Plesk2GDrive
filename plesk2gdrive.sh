#!/bin/bash
# ---------------------------------------------------------------------------
#
# Copyright 2014
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License at <http://www.gnu.org/licenses/> for
# more details.
#
# Usage: plesk2gdrive.sh [-c day : Set day of week] [-d ID : Delete specific Backup] [-v : Verify settings] [-r : Performs Backup] [-l : Lists Backups] [-h : Detailed Help Page]
#
# Revision history:
# 0.1 - Initial version
# 0.2 - Fixed comment type and adjusted path to be compatible with CentOS.
#
# 10-1-2014 Created by Brian Aldridge - www.BiteOfTech.com
# ---------------------------------------------------------------------------
clear
export TERM=${TERM:-dumb}
PROGNAME=${0##*/}

#Grab path that is compatible with various distros.
PRODUCT_ROOT_D=`grep PRODUCT_ROOT_D /etc/psa/psa.conf | awk '{print $2}'`

##Future setting - If you un-comment singledomain you need to switch the comment tags around line 170
#singledomain="biteoftech.com"

#Setting colors for display.
red="\033[31m";yellow="\033[33m";green="\033[32m";nocolor="\033[0m"

#Finds the day of the week.
currentday="$(date +"%A")"

#Change to the temporary folder to store your backup file.
backuplocation="/var/backups" #CHANGEME

#This is the usual location of the Plesk backup files.
backupsource="/var/lib/psa/dumps"

#Finds the most recent server backup created in Plesk.
currentbackup="$(ls -Art $backupsource/*.xml | tail -n 1)"

#Gets just the filename for display purposes.
backupname="$(ls -1 $currentbackup | sed 's/^.*\\/\//')"

#Set architecture of machine.
MACHINE_TYPE=`uname -m`
if [ ${MACHINE_TYPE} == 'x86_64' ]; then
        ARCH="amd64"
elif [ ${MACHINE_TYPE} == 'i386' ]; then
    ARCH="386"
else
        echo -e "Your machine architecture is not recognized."
	exit
fi

#Finding  ID of folder on Google Drive.
declare -i FOLDERINFO=($(~/drive-linux-$ARCH list -q "title = 'plesk2gdrive' and  mimeType='application/vnd.google-apps.folder'"))
FOLDERID=${FOLDERINFO[4]}

#Displays Help
usage()
{
echo -e "Usage: $PROGNAME [${red}-c day${nocolor} : Set day of week] [${red}-d ID${nocolor} : Delete specific Backup] [${red}-v${nocolor} : Verify settings] [${red}-r${nocolor} : Performs Backup] [${red}-l${nocolor} : Lists Backups] [${red}-h${nocolor} : Detailed Help Page]"
 }

#Catch options
while getopts "c:d:vrlh" opt; do
  case $opt in
    (c) #Set custom day. Useful when looking up existing backups or forcing backup to another day.
	customday=$OPTARG;
        customday="$(tr '[:lower:]' '[:upper:]' <<< ${customday:0:1})${customday:1}";
	echo -e "${green}SUCCESS:${nocolor} The day of the week is set to $customday."
        if [ ! -z "$customday" ]; then
                [[ ! $customday =~ Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday ]] && {
                    echo -e "Incorrect day of the week provided"
                    exit 1
                }
                currentday=$customday
        fi
     ;;
    (d) #Delete backup files individually if needed.
    echo -e "${red}Are you sure you want to delete the file with the following information?"
	echo -e ${yellow}
	echo -e "$(~/drive-linux-$ARCH info -i $OPTARG)"
	echo -e ${red}
	read -p "Are you sure? (Y/N) " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]
		then
		echo DELETING FILE!
		~/drive-linux-$ARCH delete -i $OPTARG
	fi
	echo -e ${nocolor}
	
     ;;
    (v) #Verifies settings, downloads application, and creates folder if necessary.
        #Check if Backup Location directory exists
        if [ -d $backuplocation ]; then
                echo -e "${green}SUCCESS:${nocolor} The Backup Location directory exists"
        else
                echo -e "${red}ERROR:${nocolor} The Backup Location directory does not exist"
        fi

	#Check to see if gdrive executable exists.
	FILE=~/drive-linux-$ARCH
	if [ -f $FILE ]; then
		echo -e "${green}SUCCESS:${nocolor} The Google Drive App Exists."
	else
		echo -e "File $FILE does not exist."
	        if [ ${ARCH}   == 'amd64' ]; then
			echo -e "Downloading the 64 bit version of the Google Drive app for Linux."
			wget www.biteoftech.com/gdrive/drive-linux-amd64 -O ~/drive-linux-amd64
			chmod +x ~/drive-linux-amd64
			#Run first time to prompt linking of Google Drive account.
			~/drive-linux-amd64
	        elif [ ${ARCH} == '386' ]; then
	                echo -e "Downloading the 32 bit version of the Google Drive app for Linux."
	                wget www.biteoftech.com/gdrive/drive-linux-386 -O ~/drive-linux-386
	                chmod +x ~/drive-linux-386
			#Run first time to prompt linking of Google Drive account.
			~/drive-linux-386
	        else
	        echo -e "Error downloading file."
	        exit
	        fi
	fi

	#If plesk2gdrive folder does not exist on Google Drive it will be created.
	if [ -z "$FOLDERID" ]; then
		echo -e "The plesk2gdrive folder does not exist in your Google Drive account. Creating now."
		~/drive-linux-$ARCH folder -t plesk2gdrive
	else
		echo -e "${green}SUCCESS:${nocolor} The plesk2gdrive folder exists on your Google Drive account."
	fi

	#Check if Backup Source directory exist
    if [ -d $backupsource ]; then
        echo -e "${green}SUCCESS:${nocolor} The Backup Source directory exists"
    else
        echo -e "${red}ERROR:${nocolor} The Backup Source directory does not exist"
    fi
		
    #Information output
    echo
	echo -e "The backup named ${yellow}$backupname${nocolor} will be exported to Google Drive under the filename ${yellow}$currentday.tar${nocolor}"
	echo
    echo -e "Current Backup   : "${red}$currentbackup${nocolor}
    echo -e "Backup Name      : "${red}$backupname${nocolor}
    echo -e "Backup Location  : "${red}$backuplocation${nocolor}
    echo -e "Backup Source    : "${red}$backupsource${nocolor}
    echo -e "Specified Day    : "${red}$currentday${nocolor}
	echo
	
    #Removing --no-gzip did not seem to shrink the filesize of the backup.
    echo -e "Example Output: ${yellow}/usr/bin/perl $PRODUCT_ROOT_D/admin/bin/plesk_agent_manager export-dump-as-file --dump-file-name=$currentbackup --output-file=$backuplocation/$currentday.tar --no-gzip${nocolor}"
    #.gz is not on the end of the file since this is not gzipped.
	echo
	echo -e "Specified Days Backups Already on Google Drive:"
	~/drive-linux-$ARCH list -q "title='$currentday.tar'"
    ;;
    (r) #Performs backup.
    echo -e "${yellow}Exporting backup to TAR file.${nocolor}"
	#Exports a full system backup.
	/usr/bin/perl $PRODUCT_ROOT_D/admin/bin/plesk_agent_manager export-dump-as-file --dump-file-name=$currentbackup --output-file=$backuplocation/$currentday.tar --no-gzip
	##Commenting out the previous line and uncommenting the following line would change the backup to a single domain backup. Might be better for some people. Possibly integrate command line arguments in future to accommodate.
	#/usr/bin/perl $PRODUCT_ROOT_D/admin/bin/plesk_agent_manager domains-name $singledomain --dump-file-name=$currentbackup --output-file=$backuplocation/$currentday.tar --no-gzip
	echo -e "Export done."
	echo -e "Removing existing backups on Google Drive with identical name."
	declare -a RESULT=($(~/drive-linux-$ARCH list -q "title='$currentday.tar'"))
	tlines=$(~/drive-linux-$ARCH list -q "title='$currentday.tar'"| tee /dev/null |(wc -l))
	declare -i backups=$tlines-1
	echo -e "${yellow}Removing $backups for: ${red}$currentday${nocolor}"
	firstbackup=${RESULT[4]}

	#Loops to delete backups until non are left.
    while [ ! -z  $firstbackup ]; do
	    echo -e "${yellow}Deleting Backup: ${red}$firstbackup${nocolor}"
		~/drive-linux-$ARCH delete -i $firstbackup
		RESULT=($(~/drive-linux-$ARCH list -q "title='$currentday.tar'"))
        firstbackup=${RESULT[4]}
    done
	echo -e "${yellow}Copying file to Google Drive.${nocolor}"
	#Uploading backup to Google Drive
	~/drive-linux-$ARCH upload -f $backuplocation/$currentday.tar -p $FOLDERID
	echo -e "${yellow}Upload done. Removing local temporary backup file.${nocolor}"
	#Removing temporary file used for backup.
	rm $backuplocation/$currentday.tar
	echo -e "${yellow}Temporary file deleted.${nocolor}"
     ;;
    (l)	#List backups for set day.
        echo -e "${yellow}Working with backup for day:${red} $currentday${nocolor}"
	declare -i RESULT=($(~/drive-linux-$ARCH list -q "title='$currentday.tar'"))
	tlines=$(~/drive-linux-$ARCH list -q "title='$currentday.tar'"| tee /dev/null |(wc -l))
	declare -i backups=$tlines-1
	echo -e "${yellow}Total Backups for today?: ${red}$backups${nocolor}"
	declare -i addresult=4
	declare -i COUNTER=0
	while [  $COUNTER -lt $backups ]; do
        declare -i currentbackup=$COUNTER+1
        echo -e "${yellow}Backup #$currentbackup: ${red}${RESULT[$addresult]}${nocolor}"
        addresult=addresult+6
                let COUNTER=COUNTER+1
    done
     ;;		
    (h) #Displays help screen.
    usage
    echo
    echo -e " ${red}-c <day>${nocolor} : ${yellow}Choose day of the week to manage.${nocolor}"
	echo -e "	    ${yellow}Example${nocolor} :${red} -c Sunday${nocolor}"
	echo
	echo -e " ${red}-d <ID>${nocolor}  : ${yellow}Delete specific backup file. Use -v to find ID of file on Google Drive.${nocolor}"
    echo -e "            ${yellow}Example${nocolor} :${red} -d 0B3oLpdWVoonmemtxQklFYXBTZHM${nocolor}"
	echo
    echo -e " ${red}-v${nocolor}       : ${yellow}Verifies settings and file locations. Also lists backups for selected day.${nocolor}"
	echo
    echo -e " ${red}-r${nocolor}	  : ${yellow}Performs backup. Must be set for backup to be performed and uploaded.${nocolor}"
	echo
    echo -e " ${red}-l${nocolor}       : ${yellow}Lists backups for specified day.${nocolor}"
	echo
    echo -e " ${red}-h${nocolor}       : ${yellow}Displays this help page.${nocolor}"
	echo
    echo -e "This script was developed by Brian Aldridge. For updates and contact information please visit http://www.BiteOfTech.com"
     ;;
    (\?) #If invalid option is entered it forces exit.
    echo -e "Invalid Option"
    usage
    exit;;
  esac
done

# Checking for no attribute.
if [ -z "$1" ]
 then
  usage
  exit 1
 fi
