#!/bin/sh
#set -x
##################################################################
# HP StorageWorks 3Par Info local install                        #
#                                                                #
# unix_local_install.sh                                          #
#                                                                #
# Usage: unix_local_install.sh                                   #
#                                                                #
# Version   : 1.6.0                                              #
# Copyright : (c) Copyright 2016 Hewlett-Packard Enterprise      #
##################################################################

CURRENT_VERSION=1.6
UPGRADE_MIN_VER=1.3
LOG_FILE=/tmp/HPE3parinfo.log

# This function will check versions.
compare_ver_numbers()
{
	#returns 0 for greater than
	#returns 1 for less than
	#returns 2 for equals
    #read the input parameters to the function
    log_To_File "INFO :: Compare version starts"
    version1=$1
    version2=$2
    i=1
	log_To_File "INFO :: Compare version Argument1 ::$version1 and Argument2 ::$version2"

    #zero pad the version strings
	version1=`echo $version1 | awk -F"." '{printf("%d.%d.%d.%d",$1,$2,$3,$4); }'`
	version2=`echo $version2 | awk -F"." '{printf("%d.%d.%d.%d",$1,$2,$3,$4); }'`

    #Use a while loop to compare the individual elements of the array
	#We are using bourne shell for compatibility across all flavours of unix.As a result of this, arrays are not supported in Bourne shell.
	#Hence we have to resort to the method which has been used.
	#Plan is to shift to korn shell in future releases.The code will be cleaned up later.

    while [ $i -le 4 ]
    do
        if [ $i -eq 1 ]
		then
			val1=`echo $version1 | awk -F"." '{print $1}'`
			val2=`echo $version2 | awk -F"." '{print $1}'`
		fi

		if [ $i -eq 2 ]
		then
			val1=`echo $version1 | awk -F"." '{print $2}'`
			val2=`echo $version2 | awk -F"." '{print $2}'`
		fi

		if [ $i -eq 3 ]
		then
			val1=`echo $version1 | awk -F"." '{print $3}'`
			val2=`echo $version2 | awk -F"." '{print $3}'`
		fi

		if [ $i -eq 4 ]
		then
			val1=`echo $version1 | awk -F"." '{print $4}'`
			val2=`echo $version2 | awk -F"." '{print $4}'`
		fi

        if [ $val1 -gt $val2 ]
        then
            log_To_File "INFO :: Compare version1:$val1 is greater than version2:$val2 and returns 0"
			return 0
        fi

        if [ $val1 -lt $val2  ] ; then
			log_To_File "INFO :: Compare version1:$val1 is less than version2:$val2 and returns 1"
            return 1
        fi
        i=`expr $i + 1`
    done

    #If the control reaches here, it means both of the versions are equal
	log_To_File "INFO :: Compare version1 is equal to version2 and returns 2"
    return 2
}

#Checks whether the OS is supported.
CheckForOS()
{
	case $OS_TYPE in
		*AIX*)
			OS_SUPPORTED="TRUE"
	  ;;
	  *Linux*)
			OS_SUPPORTED="TRUE"
	  ;;
		*HP-UX*)
			OS_SUPPORTED="TRUE"
	  ;;		
		*VMkernel*)
			OS_SUPPORTED="TRUE"
	  ;;
		*SunOS*)
			OS_SUPPORTED="TRUE"
	  ;;

    esac
}

# This function will check whether a process is running or not.
check_process()
{
        log_To_File "INFO :: check_process starts"
		# check the args
        if [ "$1" = "" ]
        then
            return 0
        fi
		if [ "$OS_TYPE" = "VMkernel" ]
		then
			PROCESS_NUM=`ps -P | grep "$1" | grep -v "grep" | wc -l`
		else
			PROCESS_NUM=`ps -ef | grep "$1" | grep -v "grep" | wc -l`
		fi

        if [ $PROCESS_NUM -ge 1 ]
        then
            return 1
        else
            return 0
        fi
		log_To_File "INFO :: check_process Ends"
}

# This function will remove HPE3PARInfo files.
Uninstall_Product()
{
	echo "Uninstalling HPE3PARInfo ..."
	log_To_File "INFO :: Uninstalling HPE3PARInfo V$CURRENT_VERSION starts"

	if [ "$OS_TYPE" = "HP-UX" ]
    then
		swremove -x mount_all_filesystems=false hpe3parinfo 2>&1
		RETURN_VALUE=$?
		if [ $RETURN_VALUE != 0 ]
        then
			echo "Uninstallation of HPE3PARInfo HP-UX package Failure."
			log_To_File "ERROR :: Uninstallation of HPE3PARInfo HP-UX package Failure. Return value is ($RETURN_VALUE)"
			exit 0
		fi
	fi

	if [ "$OS_TYPE" = "Linux" ]
    then
		rpm -e hpe3parinfo 2>&1
		RETURN_VALUE=$?
		if [ $RETURN_VALUE != 0 ]
        then
			echo "Uninstallation of HPE3PARInfo Linux package Failure."
			log_To_File "ERROR :: Uninstallation of HPE3PARInfo Linux package Failure. Return value is ($RETURN_VALUE)"
			exit 0
		fi
	fi

	if [ "$OS_TYPE" = "AIX" ]
	then
		installp -u hpe3parinfo 2>&1
		RETURN_VALUE=$?
		if [ $RETURN_VALUE != 0 ]
        then
			echo "Uninstallation of HPE3PARInfo AIX package Failure."
			log_To_File "ERROR :: Uninstallation of HPE3PARInfo AIX package Failure. Return value is ($RETURN_VALUE)"
			exit 0
		fi
	fi
    
	if [ "$OS_TYPE" = "VMkernel" ]
	then
		rm -f /usr/bin/HP3PARInfo
		rm -f /usr/lib/libHP3PARInfoLogger.*
	fi

	if [ "$OS_TYPE" = "SunOS" ]
	then
		ADMIN_FILE=/var/tmp/hpe3parinfoadmin
        echo conflict=nocheck > $ADMIN_FILE
        echo action=nocheck >> $ADMIN_FILE
		pkgrm -a $ADMIN_FILE -n hpe3parinfo 2>&1
		RETURN_VALUE=$?
		if [ $RETURN_VALUE != 0 ]
        then
			echo "Uninstallation of HPE3PARInfo Solaris package Failure."
			log_To_File "ERROR :: Uninstallation of HPE3PARInfo Solaris package Failure. Return value is ($RETURN_VALUE)"
			exit 0
		fi

	fi
	log_To_File "INFO :: Uninstalling HPE3PARInfo V$CURRENT_VERSION Ends"
}

# This function will remove HPE3PARInfo log files.
remove_log_files()
{
   log_To_File "INFO :: Removing log files starts"
   if [ "$OS_TYPE" = "Linux" ] || [ "$OS_TYPE" = "AIX" ] || [ "$OS_TYPE" = "VMkernel" ] || [ "$OS_TYPE" = "SunOS" ]
   then
		echo "Deleting HPE3PARInfo log files"
		log_To_File "INFO :: Deleting HPE3PARInfo log files"
		rm -rf /var/log/HP3PARInfo
   elif [ "$OS_TYPE" = "HP-UX" ]
   then
		echo "Deleting HPE3PARInfo log files"
		log_To_File "INFO :: Deleting HPE3PARInfo log files"
		rm -rf /var/adm/HP3PARInfo
   fi
   log_To_File "INFO :: Removing log files ends"
}

# This function will copy HPE3PARInfo files.
Install_Product()
{
	echo "Installing HPE3PARInfo v$CURRENT_VERSION..."

	log_To_File "INFO :: Installing HPE3PARInfo v$CURRENT_VERSION starts"
	if [ "$OS_TYPE" = "HP-UX" ]
	then
		ARCH=`uname -r`
		if [ "$ARCH" = "B.11.11" ]
		then
			BLD_DEPOT=HPE_3PARINFO_11.11.depot
		fi
		if [ "$ARCH" = "B.11.23" ]
		then
			BLD_DEPOT=HPE_3PARINFO_11.23.depot
		fi
		if [ "$ARCH" = "B.11.31" ]
		then
			BLD_DEPOT=HPE_3PARINFO_11.31.depot
		fi
		swinstall -x mount_all_filesystems=false -s ./$BLD_DEPOT hpe3parinfo
		RETURN_VALUE=$?
		if [ $RETURN_VALUE != 0 ]
        then
			echo "Installation of HPE3PARInfo HP-UX package Failure."
			log_To_File "ERROR :: Installation of HPE3PARInfo HP-UX package Failure. Return value is ($RETURN_VALUE)"
			exit 0
		fi
	fi

	if [ "$OS_TYPE" = "Linux" ]
	then
		ARCH=`uname -m`
		if [ "$ARCH" = "x86_64" ]
		then
			BLD_RPM=HPE3PARINFO_Linux_x64.rpm
		else
			BLD_RPM=HPE3PARINFO_Linux_x86.rpm
		fi
		rpm -U $BLD_RPM
		RETURN_VALUE=$?
		if [ $RETURN_VALUE != 0 ]
        then
			echo "Installation of HPE3PARInfo Linux package Failure."
			log_To_File "ERROR :: Installation of HPE3PARInfo Linux package Failure. Return value is ($RETURN_VALUE)"
			exit 0
		fi
	fi

	if [ "$OS_TYPE" = "AIX" ]
	then
		installp -ac -d ./HPE3PARInfo_AIX.bff hpe3parinfo
		RETURN_VALUE=$?
		if [ $RETURN_VALUE != 0 ]
        then
			echo "Installation of HPE3PARInfo AIX package Failure."
			log_To_File "ERROR :: Installation of HPE3PARInfo AIX package Failure. Return value is ($RETURN_VALUE)"
			exit 0
		fi
	fi

	if [ "$OS_TYPE" = "VMkernel" ]
	then
		rm -rf HPE3PARInfo-ESXi
		tar -xf HPE3PARInfo-ESXi.tar
		RETURN_VALUE=$?
		if [ $RETURN_VALUE != 0 ]
        then
			echo "Unable to extract HPE3PARInfo-ESXi.tar file."
			log_To_File "ERROR :: Unable to extract HPE3PARInfo-ESXi.tar file. Return value is ($RETURN_VALUE)"
			exit 0
		fi
		cp ./HPE3PARInfo-ESXi/bin/HP3PARInfo /usr/bin/
		cp -rp ./HPE3PARInfo-ESXi/lib/libHP3PARInfoLogger.* /usr/lib/
		FILES_NOT_COPIED=$?
		check_files_copied_sucessfully
	fi

	if [ "$OS_TYPE" = "SunOS" ]
    then
		ARCH=`uname -p`
		if [ "$ARCH" = "sparc" ]
		then
			BLD_PKG=HPE3PARInfo_SOLARIS_Sparc.pkg
		else
			BLD_PKG=HPE3PARInfo_SOLARIS_x86.pkg
		fi
		#
		# Non interactive installation
		#
		ADMIN_FILE=/var/tmp/hpe3parinfoadmin
		echo action=nocheck > $ADMIN_FILE
		echo conflict=nocheck >> $ADMIN_FILE
		echo instance=overwrite >> $ADMIN_FILE
		echo idepend=nocheck >> $ADMIN_FILE

		echo "Installing HPE 3PARInfo on Solaris $OS_VER ..."
		sleep 3
		pkgadd -a $ADMIN_FILE -n -d $BLD_PKG hpe3parinfo
		RETURN_VALUE=$?
		if [ $RETURN_VALUE != 0 ]
        then
			echo "Installation of HPE3PARInfo Solaris package Failure."
			log_To_File "ERROR :: Installation of HPE3PARInfo Solaris package Failure. Return value is ($RETURN_VALUE)"
			exit 0
		fi
	fi

	chmod +x /usr/bin/HP3PARInfo
	log_To_File "INFO :: Installing HPE3PARInfo V$CURRENT_VERSION Ends"
}

#This function checks whether files are present for installation in 
#the correct folder structure.
CheckInstallFiles()
{
	# Check if the file exists for all platform
	log_To_File "INFO :: Checking install files starts"
	if [ -f /usr/bin/HP3PARInfo ]
	then
		# File exists
		doNothing
	else
		echo "Unable to find install file, installer exiting."
		log_To_File "ERROR :: Unable to find install file HPE3PARInfo, installer exiting."
		exit 0
	fi
	if [ "$OS_TYPE" = "Linux" ]
	then
		ARCH=`uname -p`
		if [ "$ARCH" = "x86_64" ]
		then
			files=`ls /usr/lib64/libHP3PARInfoLogger.* 2> /dev/null | wc -l`
		else
			files=`ls /usr/lib/libHP3PARInfoLogger.* 2> /dev/null | wc -l`
		fi
	else
		files=`ls /usr/lib/libHP3PARInfoLogger.* 2> /dev/null | wc -l`
	fi
	log_To_File "INFO :: Files count :$files"
	if [ $files -ge 1 ]
	then
		# Files exists
		doNothing
	else
		echo "Unable to find library files, installer exiting."
		log_To_File "ERROR :: Unable to find library files libHP3PARInfoLogger, installer exiting."
		exit 0
	fi				
	
	log_To_File "INFO :: Checking install files Ends"
}

#This function checks whether files the plaform matches.
CheckPlatform()
{
    log_To_File "INFO :: Check platform Starts"
	if [ "$OS_TYPE" = "HP-UX" ] || [ "$OS_TYPE" = "Linux" ] || [ "$OS_TYPE" = "AIX" ] || [ "$OS_TYPE" = "VMkernel" ] || [ "$OS_TYPE" = "SunOS" ]
	then
		doNothing
	else   
		echo "The platform is not supported for installing HPE3PARInfo."
		log_To_File "ERROR :: The platform is not supported for installing HPE3PARInfo, installer exiting."
		exit 0
	fi
   log_To_File "INFO :: Check platform Ends"
}

#Place holder function.
doNothing()
{
	#Do nothing.
	TEMP_ARCH=`ls`
}

#This function checks files  are copied successfully.
check_files_copied_sucessfully()
{
	if [ $FILES_NOT_COPIED != 0 ]
	then
		echo "HPE3PARInfo: Error copying files, Installer is exiting."
		log_To_File "ERROR :: HPE3PARInfo: Error copying files, installer exiting."
		Uninstall_Product
		exit 0;
	fi
}

#This function log the information to file.
log_To_File()
{
	echo $1 >> $LOG_FILE
}
############## MAIN SCRIPT ###################

log_To_File "INFO :: -------------HPE3PARInfo $CURRENT_VERSION installation script starts------------"
OS_TYPE=`uname`
log_To_File "INFO :: Operating system Type is :$OS_TYPE"
echo "HPE3PARInfo installer is performing the prerequisite check, please wait..."
log_To_File "INFO :: Checking supported operating system starts"
CheckForOS

if [ "$OS_SUPPORTED" != "TRUE" ]
then
	echo "HPE3PARInfo is not supported in this operating system."
	log_To_File "ERROR :: HPE3PARInfo is not supported in this operating system."
	exit 1
fi

# check HPE3PARInfo process is on running state
check_process "HP3PARInfo"
process_executing=$?
if [ $process_executing -eq 1 ]
then
	log_To_File "ERROR :: HPE3PARInfo process is on running state"
	echo "HPE3PARInfo is being used now."
	echo "Please close the application and re-start installation."
	exit 1
fi

log_To_File "INFO :: Checking supported operating system ends"
if [ -f /usr/bin/HP3PARInfo ]; then
	INSTALLED_VERSION=`/usr/bin/HP3PARInfo -v | grep Version | awk -F\  '{print $4}'`
	log_To_File "INFO :: 3PARInfo Installed Version :$INSTALLED_VERSION"
	if [ "$INSTALLED_VERSION" = "Version" ]; then		
		INSTALLED_VERSION=`/usr/bin/HP3PARInfo -v | grep Version | awk -F\  '{print $5}'`
		log_To_File "INFO :: 3PARInfo Installed Version :$INSTALLED_VERSION"
	fi
else
	echo "HPE3PARInfo is not installed on this server"
	log_To_File "INFO :: HPE3PARInfo is not installed on this server"
	INSTALLED_VERSION=""
fi

# Compare current version and Installed version
compare_ver_numbers $CURRENT_VERSION  $INSTALLED_VERSION
return_ver_compare=$?
log_To_File "INFO :: Return value of version compare $CURRENT_VERSION  $INSTALLED_VERSION :$return_ver_compare"
log_To_File "INFO :: minimum upgrade support check starts"

# Compare current version and minimum upgrade support installed version
compare_ver_numbers $INSTALLED_VERSION  $UPGRADE_MIN_VER
return_ver_compare2=$?
log_To_File "INFO :: Return value of version compare $CURRENT_VERSION  $UPGRADE_MIN_VER :$return_ver_compare2"

if [ $return_ver_compare2 -eq 1 ]
then
    log_To_File "ERROR :: An old version of HPE3PARInfo v$INSTALLED_VERSION is already installed"
	echo "An old version of HPE3PARInfo v$INSTALLED_VERSION is already installed,"
	echo "HPE3PARInfo upgrade is supported only from last two versions,"
    echo "please uninstall existing HPE3PARInfo v$INSTALLED_VERSION and start installation of HPE3PARInfo v$CURRENT_VERSION again."
    exit 1
fi

if [ "$INSTALLED_VERSION" = "" ]
then
	INSTALLED_STATE="FALSE"
	log_To_File "INFO :: 3PARInfo Not installed"
elif [ $return_ver_compare -eq 0 ]
then
	INSTALLED_STATE="UPGRADE"
	log_To_File "INFO :: 3PARInfo upgrade support version installed"
elif [ $return_ver_compare -eq 2 ]
then
	INSTALLED_STATE="TRUE"
	log_To_File "INFO :: 3PARInfo Same version installed"
elif [ $return_ver_compare -eq 1 ]
then
	INSTALLED_STATE="DOWNGRADE"
	log_To_File "INFO :: 3PARInfo downgrade installation"
fi

# This flow is for upgrade and fresh installation
if [ "$INSTALLED_STATE" = "UPGRADE" ] || [ "$INSTALLED_STATE" = "FALSE" ]
then
	if [ "$INSTALLED_STATE" = "UPGRADE" ]	
	then
		log_To_File "INFO :: Upgrade installation of HPE3PARInfo starts"
		echo "Would you like to upgrade HPE3PARInfo v$INSTALLED_VERSION to v$CURRENT_VERSION? y or n [y]:"; 
	else
		log_To_File "INFO :: Fresh installation of HPE3PARInfo starts"
		echo "Do you want to install HPE3PARInfo v$CURRENT_VERSION? y or n [y]:";
	fi
	read RESPONSE

	if [ "$RESPONSE" = "y" ] || [ "$RESPONSE" = "Y" ] || [ "$RESPONSE" = "yes" ] || [ "$RESPONSE" = "Yes" ] || [ "$RESPONSE" = "YES" ]
	then
		log_To_File "INFO :: upgrade /Install confirm yes option selected"
		echo "Installing HPE3PARInfo v$CURRENT_VERSION ..."
		Install_Product
		CheckInstallFiles
		echo "Successfully Installed HPE3PARInfo to v$CURRENT_VERSION"
		log_To_File "INFO :: Successfully Installed/upgraded HPE3PARInfo to v$CURRENT_VERSION"
	else
		log_To_File "INFO :: User confirmation no option selected"
		exit 1
	fi
elif [ "$INSTALLED_STATE" = "TRUE" ]
then
	log_To_File "INFO :: HPE3PARInfo already installed, modify installation starts"
	echo "HPE3PARInfo v$INSTALLED_VERSION is already installed."
	echo "Do you want to un-install HPE3PARInfo v$INSTALLED_VERSION? y or n [y]:"; 
	read RESPONSE	

	if [ "$RESPONSE" = "y" ] || [ "$RESPONSE" = "Y" ] || [ "$RESPONSE" = "yes" ] || [ "$RESPONSE" = "Yes" ] || [ "$RESPONSE" = "YES" ]
	then
		log_To_File "INFO :: HPE3PARInfo un-installation confirmation yes option selected"
		echo "Uninstalling HPE3PARInfo v$INSTALLED_VERSION ..."
		Uninstall_Product
		remove_log_files
		echo "Successfully uninstalled HPE3PARInfo v$INSTALLED_VERSION"
		log_To_File "INFO :: Successfully uninstalled HPE3PARInfo v$INSTALLED_VERSION"
	else
		log_To_File "INFO :: 3PARInfo un-installation confirmation No option selected"
		exit 1
	fi
elif [ "$INSTALLED_STATE" = "DOWNGRADE" ]
then

	log_To_File "INFO :: HPE3PARInfo v$INSTALLED_VERSION is already installed. Downgrade is not allowed to v$CURRENT_VERSION."; 
	echo "HPE3PARInfo v$INSTALLED_VERSION is already installed. Downgrade is not allowed to v$CURRENT_VERSION."; 
	exit 1
fi
log_To_File "INFO :: -------------HPE3PARInfo $CURRENT_VERSION Installation script Ends------------"