#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Created by Sepie Moinipanah
# January 5, 2018
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Standard Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

# Determines currently logged in user and assigns variable for output
loggedInUser=`python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");'`
# Determines console user and assigns variable for output
consoleUser="$(ls -l /dev/console | awk '{print $3}')"
# Determines if screen saver is active and assigns variable for output
screenSaver="$(pgrep ScreenSaverEngine)"
# Determines macOS version and assigns variable for output
macOSVersion=$(/usr/bin/sw_vers -productVersion)
# Determines macOS version and assigns variable for output
macOSVersionShort=$(/usr/bin/sw_vers -productVersion | awk -F "." '{ print $3 }')
# Determines macOS build and assigns variable for output
macOSBuild=$(/usr/bin/sw_vers -buildVersion)
# Value specified for variable
# Recently assigned variables are returned in a string
echo "$(date): Currently Installed: $macOSVersion Build $macOSBuild."

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Software Update Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

SWUL=$(softwareupdate -l | awk '{printf "%s", $0}')
SWULER=$(softwareupdate -l 2>&1 | head -1)
NoRestartUpdates=$(softwareupdate -l | grep -v restart | grep -B1 recommended | grep -v recommended | awk '{print $2}' | awk '{printf "%s ", $0}')

if [[ "$SWULER" == "No new software available." ]]; then
	echo "$(date): $SWULER; now exiting..."
	exit 0
else
	echo "$(date): Update(s) detected..."
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# jamfHelper Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

# The location of Jamf Helper is assigned to a variable 
jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
# Window type is specified (i.e. hud, fs, utility)
windowType="hud"
# Description or body of Jamf Helper, various variable assignment
description="Your computer is in need of being updated. A restart may be required.

• To proceed, select 'Update.'

• To defer, select 'Cancel.' 

If you have any questions or require assistance, please contact the Helpdesk by phone at +1 (XXX) XXX-HELP or by email at help@me.now."
description1="Please wait while software updates are prepared."
description2="Updates have downloaded and are ready to be installed."
description3="Your computer has been successfully updated! A system restart will commence momentarily."
description4="Your computer has been successfully updated! No restart is required."
# Icon for Jamf Helper window is specified
icon="/Applications/App Store.app/Contents/Resources/AppIcon.icns"
# Title for Jamf Helper window is specified
title="REQUIRED: Software Updates"
# Alignment of description for Jamf Helper window is specified
alignDescription="left" 
# Alignment of heading for Jamf Helper window is specified
alignHeading="center"
# Text and button settings for Jamf Helper window are specified
button1="Update"
button2="Cancel"
alignDescription="left" 
alignHeading="center"
defaultButton="2"
cancelButton="2"
timeout="300"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Self Service Check
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

if ls -1 /Applications/Self\ Service.app &>/dev/null; then
	echo "$(date): Self Service is installed!"
else
	echo "$(date): Self Service is NOT installed! Now exiting..."
	exit 0
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# System Checks
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

dockStatus=`pgrep Dock`

until [[ $dockStatus ]]
do
	sleep 5
	dockStatus=`pgrep Dock`
done

echo "$(date): Dock is active! Let's keep this going..."

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# jamfHelper Window
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

userChoice=$("$jamfHelper" -windowType "$windowType" -lockHUD -title "$title" -defaultButton \
"$defaultButton" -cancelButton "$cancelButton" -icon "$icon" -description "$description" \
-alignDescription "$alignDescription" -alignHeading "$alignHeading" -button1 "$button1" \
-button2 "$button2" -timeout "$timeout")
echo "$(date): Jamf Helper was launched!"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Software Updates Check & Prompt
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ "$userChoice" == "0" ]] && [[ "$SWUL" == *"[restart]"* ]]; then
	echo "$(date): User clicked Update. Installing all updates..."
	button1="OK"
	defaultButton="1"
	cancelButton="1"

	initialPrompt=$("$jamfHelper" -windowType "$windowType" -lockHUD -icon "$icon" -title "$title" -description "$description1" -alignDescription "$alignDescription" -alignHeading "$alignHeading" -windowPosition ll -defaultButton "$defaultButton" -button1 "$button1" -cancelButton "$cancelButton" -timeout 10) &
	softwareupdate -d -a
	sleep 5

	userChoice1=$("$jamfHelper" -windowType "$windowType" -lockHUD -icon "$icon" -title "$title" -description "$description2" -alignDescription "$alignDescription" -alignHeading "$alignHeading" -windowPosition ll -defaultButton "$defaultButton" -button1 "$button1" -cancelButton "$cancelButton" -timeout 10) &
	softwareupdate -i -a
	sleep 5

	restartPrompt=$("$jamfHelper" -windowType "$windowType" -lockHUD -icon "$icon" -title "$title" -description "$description3" -alignDescription "$alignDescription" -alignHeading "$alignHeading" -windowPosition ll -defaultButton "$defaultButton" -button1 "$button1" -cancelButton "$cancelButton" -timeout 10) &
	echo "$(date): Standard restart will take place now..."
	sleep 5
	shutdown -r now
elif [[ "$userChoice" == "0" ]] && [[ "$SWUL" == *"[recommended]"* ]] && [[ "$SWUL" != *"[restart]"* ]]; then
	echo "$(date): Installing updates that do not require restart."
	echo "$(date): User clicked Update. Installing all updates..."
	button1="OK"
	defaultButton="1"
	cancelButton="1"

	initialPrompt=$("$jamfHelper" -windowType "$windowType" -lockHUD -icon "$icon" -title "$title" -description "$description1" -alignDescription "$alignDescription" -alignHeading "$alignHeading" -windowPosition ll -defaultButton "$defaultButton" -button1 "$button1" -cancelButton "$cancelButton" -timeout 10) &
	softwareupdate -d -$NoRestartUpdates
	sleep 5

	userChoice1=$("$jamfHelper" -windowType "$windowType" -lockHUD -icon "$icon" -title "$title" -description "$description2" -alignDescription "$alignDescription" -alignHeading "$alignHeading" -windowPosition ll -defaultButton "$defaultButton" -button1 "$button1" -cancelButton "$cancelButton" -timeout 10) &
	softwareupdate -i -$NoRestartUpdates
	sleep 5

	NoRestartPrompt=$("$jamfHelper" -windowType "$windowType" -lockHUD -icon "$icon" -title "$title" -description "$description4" -alignDescription "$alignDescription" -alignHeading "$alignHeading" -windowPosition ll -defaultButton "$defaultButton" -button1 "$button1" -cancelButton "$cancelButton" -timeout 10) &
	echo "$(date): Completed! No restart needed; now exiting..."
	exit 0
elif [[ "$userChoice" == "2" ]]; then
    echo "$(date): User clicked Cancel or timeout was reached; now exiting."
    exit 0
fi
