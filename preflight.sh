#!/bin/bash

# Bootstraps Workspace ONE UEM Intelligent Hub on macOS 10.15 and later
# This script is designed to be run as a preflight script in Airwatch
# or Jamf Pro. It will install the latest Workspace ONE Intelligent Hub
# and the latest version of Xcode Command Line Tools, Depnotify, 
# and install Rosetta if needed on Apple Silicon Macs.
# Author: Chris Mariano - GIT:xtian08
# Version: 1.0.0
# Date: 22/03/2023

#For use on New York University owned devices only.

exitcode=0

#Set timezone
sudo systemsetup -settimezone Asia/Dubai
# start logging
exec 5> /var/log/debug.log 
PS4='$LINENO: ' 
BASH_XTRACEFD="5" 

touch "/var/Log/ws1debug.log"
ws1log="/var/Log/ws1debug.log"
date >> $ws1log
echo "Starting WS1 Preflight Script" >> $ws1log

# Logging stuff starts here
LOGFOLDER="/private/var/log/"
LOG="${LOGFOLDER}ws1debug.log"

if [ ! -d "$LOGFOLDER" ]; then
    mkdir $LOGFOLDER
fi

function logme()
{
# Check to see if function has been called correctly
    if [ -z "$1" ] ; then
        echo "$(date) - logme function call error: no text passed to function! Please recheck code!"
        echo "$(date) - logme function call error: no text passed to function! Please recheck code!" >> $LOG
        exit 1
    fi

# Log the passed details
    echo -e "$(date) - $1" >> $LOG
    echo -e "$(date) - $1"
}

# Install Rosetta if needed
# Determine OS version
# Save current IFS state
echo "Determining OS Version" >> $ws1log

OLDIFS=$IFS

IFS='.' read osvers_major osvers_minor osvers_dot_version <<< "$(/usr/bin/sw_vers -productVersion)"

# restore IFS to previous state

IFS=$OLDIFS

# Check to see if the Mac is reporting itself as running macOS 11

if [[ ${osvers_major} -ge 11 ]]; then

  # Check to see if the Mac needs Rosetta installed by testing the processor

  processor=$(/usr/sbin/sysctl -n machdep.cpu.brand_string | grep -o "Intel")
  
  if [[ -n "$processor" ]]; then
    echo "$processor processor installed. No need to install Rosetta." >> $ws1log
  else

    # Check Rosetta LaunchDaemon. If no LaunchDaemon is found,
    # perform a non-interactive install of Rosetta.

    echo "Checking for Rosetta" >> $ws1log
    
    if [[ ! -f "/Library/Apple/System/Library/LaunchDaemons/com.apple.oahd.plist" ]]; then
        /usr/sbin/softwareupdate --install-rosetta --agree-to-license
       
        if [[ $? -eq 0 ]]; then
        	echo "Rosetta has been successfully installed." >> $ws1log
        else
        	echo "Rosetta installation failed!" >> $ws1log
        	exitcode=1
        fi
   
    else
    	echo "Rosetta is already installed. Nothing to do." >> $ws1log
    fi
  fi
  else
    echo "Mac is running macOS $osvers_major.$osvers_minor.$osvers_dot_version." >> $ws1log
    echo "No need to install Rosetta on this version of macOS." >> $ws1log   
fi

#NoMAD Prefereces

# Preference key reference
# https://gitlab.com/orchardandgrove-oss/NoMADLogin-AD/wikis/Configuration/preferences
domain="ad.nyu.edu"
background_image="/usr/local/nomadback.jpeg"
logo="/usr/local/nomadlogo.png"

# Set default AD domain
defaults write /Library/Preferences/menu.nomad.login.ad.plist ADDomain "$domain"

# Create user as Admin pref
defaults write /Library/Preferences/menu.nomad.login.ad.plist CreateAdminUser -bool Yes

# Set background image
defaults write /Library/Preferences/menu.nomad.login.ad.plist BackgroundImage "$background_image"

# Set login window logo
defaults write /Library/Preferences/menu.nomad.login.ad.plist LoginLogo "$logo"

# Set security authorization database mechanisms with authchanger
/usr/local/bin/authchanger -reset -AD

#Laps Preferences

# Managed Account Cred
defaults write /Library/Preferences/edu.psu.macoslaps.plist FirstPass "1234"

# Managed Account User
defaults write /Library/Preferences/edu.psu.macoslaps.plist LocalAdminAccount "itops"

# LDAP
defaults write /Library/Preferences/edu.psu.macoslaps.plist PreferredDC "$domain"

# Set security authorization database mechanisms with authchanger
/usr/local/bin/authchanger -reset -AD

#Install Nomad

echo "Installing Latest NoMAD" >> $ws1log
cd /tmp
curl -L -o nomadL.pkg https://files.nomad.menu/NoMAD-Login-AD.pkg
echo "Installing NoMAD" >> $ws1log
sudo -S installer -allowUntrusted -pkg "/tmp/nomadL.pkg" -target /;

        if [[ $? -eq 0 ]]; then
        	echo "NoMAD has been successfully installed." >> $ws1log
        else
        	echo "NoMAD installation failed!" >> $ws1log
        	exitcode=1
        fi

#Invoke Nomad UI
# Kill loginwindow process to force NoMAD Login to launch
#/usr/bin/killall -HUP loginwindow
echo "Nomand Login Loaded" >> $ws1log

#Install Latest WS1

echo "Installing Latest Workspace ONE" >> $ws1log
cd /tmp
curl -L -o ws1.pkg https://packages.vmware.com/wsone/VMwareWorkspaceONEIntelligentHub.pkg
echo "Installing Workspace ONE" >> $ws1log
#sudo -S installer -allowUntrusted -pkg "/tmp/ws1.pkg" -target /;

        if [[ $? -eq 0 ]]; then
        	echo "Workspace ONE has been successfully installed." >> $ws1log
        else
        	echo "Workspace ONE installation failed!" >> $ws1log
        	exitcode=1
        fi

#Install Latest DEPNotify

echo "Installing Latest DEPNotify" >> $ws1log
curl -L -o depnotify.pkg https://files.nomad.menu/DEPNotify.pkg
echo "Installing DEPNotify" >> $ws1log
sudo -S installer -allowUntrusted -pkg "/tmp/depnotify.pkg" -target /;

        if [[ $? -eq 0 ]]; then
        	echo "DEPNotify has been successfully installed." >> $ws1log
        else
        	echo "DEPNotify installation failed!" >> $ws1log
        	exitcode=1
        fi

# Install masoslaps
logme "Install masOSLAPS"
cd /tmp
curl -L -o laps.pkg 'https://github.com/joshua-d-miller/macOSLAPS/releases/download/3.0.4(781)/macOSLAPS-3.0.4.781.pkg'
echo "Installing macOSLAPS" >> $ws1log
sudo -S installer -allowUntrusted -pkg "/tmp/laps.pkg" -target /;
#install_dir=`dirname $0`
#/usr/sbin/installer -dumplog -verbose -pkg $install_dir/"macOSLAPS-3.0.4.781.pkg" -target /;

     if [[ $? -eq 0 ]]; then
        	echo "masOSLAPS has been successfully installed." >> $ws1log
        else
        	echo "masOSLAPS installation failed!" >> $ws1log
        	exitcode=1
        fi

# Install UMAD
logme "Install UMAD"
cd /tmp
curl -L -o umad.pkg 'https://github.com/NYUAD-IT/NYU-umad/releases/download/untagged-3cbcf9fa3cdd13351903/umad-2.0.pkg'
echo "Installing UMAD" >> $ws1log
sudo -S installer -allowUntrusted -pkg "/tmp/umad.pkg" -target /;

     if [[ $? -eq 0 ]]; then
        	echo "UMAD has been successfully installed." >> $ws1log
        else
        	echo "UMAD installation failed!" >> $ws1log
        	exitcode=1
        fi

# Install Command Line Tools for Xcode

echo "Checking Command Line Tools for Xcode" >> $ws1log
# Only run if the tools are not installed yet
# To check that try to print the SDK path
xcode-select -p &> /dev/null
if [ $? -ne 0 ]; then
  echo "Command Line Tools for Xcode not found. Installing from softwareupdate…"  >> $ws1log
# This temporary file prompts the 'softwareupdate' utility to list the Command Line Tools
  touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;
  PROD=$(softwareupdate -l | grep "\*.*Command Line" | tail -n 1 | sed 's/^[^C]* //')
  softwareupdate -i "$PROD" --verbose;
else
  echo "Command Line Tools for Xcode have been installed." >> $ws1log
fi

# Set up variables and functions here
consoleuser="$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "
");')"

if [[ -e /usr/local/bin/brew ]]; then
    su -l "$consoleuser" -c "/usr/local/bin/brew update"
    exit 0
fi

# are we in the right group
check_grp=$(groups ${consoleuser} | grep -c '_developer')
if [[ $check_grp != 1 ]]; then
    /usr/sbin/dseditgroup -o edit -a "${consoleuser}" -t user _developer
fi

# Check Brew and start logging
logme "Homebrew Installation"

# Have the xcode command line tools been installed?
logme "Checking for Xcode Command Line Tools installation"
check=$( pkgutil --pkgs | grep -c "CLTools_Executables" )

if [[ "$check" != 1 ]]; then
    logme "Installing Xcode Command Tools"
    # This temporary file prompts the 'softwareupdate' utility to list the Command Line Tools
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    clt=$(softwareupdate -l | grep -B 1 -E "Command Line (Developer|Tools)" | awk -F"*" '/^ +\*/ {print $2}' | sed 's/^ *//' | tail -n1)
    # the above don't work in Catalina so ...
    if [[ -z $clt ]]; then
        clt=$(softwareupdate -l | grep  "Label: Command" | tail -1 | sed 's#* Label: (.*)#1#')
    fi
    softwareupdate -i "$clt"
    rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    /usr/bin/xcode-select --switch /Library/Developer/CommandLineTools
fi

# Is homebrew already installed?
if [[ ! -e /usr/local/bin/brew ]]; then
    # Install Homebrew. This doesn't like being run as root so we must do this manually.
    logme "Installing Homebrew"

    mkdir -p /usr/local/Homebrew
    # Curl down the latest tarball and install to /usr/local
    curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C /usr/local/Homebrew

    # Manually make all the appropriate directories and set permissions
    mkdir -p /usr/local/Cellar /usr/local/Homebrew mkdir /usr/local/Caskroom /usr/local/Frameworks /usr/local/bin
    mkdir -p /usr/local/include /usr/local/lib /usr/local/opt /usr/local/etc /usr/local/sbin
    mkdir -p /usr/local/share/zsh/site-functions /usr/local/var
    mkdir -p /usr/local/share/doc /usr/local/man/man1 /usr/local/share/man/man1
    chown -R "${consoleuser}":_developer /usr/local/*
    chmod -R g+rwx /usr/local/*
    chmod 755 /usr/local/share/zsh /usr/local/share/zsh/site-functions

    # Create a system wide cache folder  
    mkdir -p /Library/Caches/Homebrew
    chmod g+rwx /Library/Caches/Homebrew
    chown "${consoleuser}:_developer" /Library/Caches/Homebrew

    # put brew where we can find it
    ln -s /usr/local/Homebrew/bin/brew /usr/local/bin/brew

    # Install the MD5 checker or the recipes will fail
    su -l "$consoleuser" -c "/usr/local/bin/brew install md5sha1sum"
    echo 'export PATH="/usr/local/opt/openssl/bin:$PATH"' | 
    tee -a /Users/${consoleuser}/.bash_profile /Users/${consoleuser}/.zshrc
    chown ${consoleuser} /Users/${consoleuser}/.bash_profile /Users/${consoleuser}/.zshrc

    # clean some directory stuff for Catalina
    chown -R root:wheel /private/tmp
    chmod 777 /private/tmp
    chmod +t /private/tmp
fi

# Make sure everything is up to date
logme "Updating Homebrew"
su -l "$consoleuser" -c "/usr/local/bin/brew update" 2>&1 | tee -a ${LOG}

# logme user that all is completed
logme "Homebrew installation complete"

#Create Object IDs
echo "Creating Object IDs" >> $ws1log
mkdir -p /Users/Shared/BuildIDs/ && touch /Users/Shared/BuildIDs/preFLIGHT.ws1

#Cleanup pkg files
echo "Cleaning up pkg files" >> $ws1log
rm -rf /tmp/*.pkg

#Exitcode
echo "Exiting with code $exitcode" >> $ws1log 2>&1
exit $exitcode

