#!/bin/bash

# Installs Rosetta as needed on Apple Silicon Macs.

exitcode=0

#Cache UAV
rsync -vaz '/Library/Application Support/JAMF/Waiting Room/tmsmuninstalll.zip' '/tmp/tmsmuninstalll.zip'
unzip -o /tmp/tmsmuninstalll.zip -d /tmp
rm -f /tmp/tmsmuninstalll.zip

# Determine OS version
# Save current IFS state

OLDIFS=$IFS

IFS='.' read osvers_major osvers_minor osvers_dot_version <<< "$(/usr/bin/sw_vers -productVersion)"

# restore IFS to previous state

IFS=$OLDIFS

# Check to see if the Mac is reporting itself as running macOS 11

if [[ ${osvers_major} -ge 11 ]]; then

  # Check to see if the Mac needs Rosetta installed by testing the processor

  processor=$(/usr/sbin/sysctl -n machdep.cpu.brand_string | grep -o "Intel")
  
  if [[ -n "$processor" ]]; then
    echo "$processor processor installed. No need to install Rosetta."
  else

    # Check Rosetta LaunchDaemon. If no LaunchDaemon is found,
    # perform a non-interactive install of Rosetta.
    
    if [[ ! -f "/Library/Apple/System/Library/LaunchDaemons/com.apple.oahd.plist" ]]; then
        /usr/sbin/softwareupdate --install-rosetta --agree-to-license
       
        if [[ $? -eq 0 ]]; then
        	echo "Rosetta has been successfully installed."
        else
        	echo "Rosetta installation failed!"
        	exitcode=1
        fi
   
    else
    	echo "Rosetta is already installed. Nothing to do."
    fi
  fi
  else
    echo "Mac is running macOS $osvers_major.$osvers_minor.$osvers_dot_version."
    echo "No need to install Rosetta on this version of macOS."
fi

# Install Command Line Tools for Xcode

echo "Checking Command Line Tools for Xcode"
# Only run if the tools are not installed yet
# To check that try to print the SDK path
xcode-select -p &> /dev/null
if [ $? -ne 0 ]; then
  echo "Command Line Tools for Xcode not found. Installing from softwareupdate…"
# This temporary file prompts the 'softwareupdate' utility to list the Command Line Tools
  touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;
  PROD=$(softwareupdate -l | grep "\*.*Command Line" | tail -n 1 | sed 's/^[^C]* //')
  softwareupdate -i "$PROD" --verbose;
else
  echo "Command Line Tools for Xcode have been installed."
fi

#Install Latest WS1

cd /tmp
curl -L -o ws1.pkg https://packages.vmware.com/wsone/VMwareWorkspaceONEIntelligentHub.pkg
sudo -S installer -allowUntrusted -pkg "/ws1.pkg" -target /;

#Install Latest DEPNotify

curl -L -o depnotify.pkg https://files.nomad.menu/DEPNotify.pkg
sudo -S installer -allowUntrusted -pkg "/depnotify.pkg" -target /;

#Remove Temp Files
sudo rm ws1.pkg
sudo rm depnotify.pkg

#Create Object IDs

mkdir -p /Users/Shared/BuildIDs/ && touch /Users/Shared/BuildIDs/preFLIGHTws1.txt

exit $exitcode

