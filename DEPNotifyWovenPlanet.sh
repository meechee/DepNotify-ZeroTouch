#!/bin/bash

# Staging Install
#####################################################################################################
################### Created by Mitch to automate the new hire #######################################
################### onboarding process and educate them on our common systems #######################
#####################################################################################################
# Jamf / DEPNotify Variables
DEP_NOTIFY_APP="/Applications/Utilities/DEPNotify.app"
DEP_NOTIFY_CONFIG="/var/tmp/depnotify.log"
DEP_NOTIFY_DONE="/var/tmp/com.depnotify.provisioning.done"
DEP_NOTIFY_REG="/var/tmp/com.depnotify.registration.done"
TMP_DEBUG_LOG="/var/tmp/depNotifyDebug.log"
RosettaInstall="jamf policy -id 177"
CrowdstrikeInstall="jamf policy -id 187"
ChromeInstall="jamf policy -id 170"
SlackInstall="jamf policy -id 169"
LastPassInstall="jamf policy -id 225"
ZoomInstall="jamf policy -id 172"
GPInstall="jamf policy -id 179"
GoogleDriveInstall="jamf policy -id 171"
NessusInstall="jamf policy -id 186"
FileVaultInstall="jamf policy -id 205"
SETUP_ASSISTANT_PROCESS=$(pgrep -l "Setup Assistant")
FINDER_PROCESS=$(pgrep -l "Finder")
JSONdevice="/var/tmp/data.json"
JSONemail="/var/tmp/email.json"

#DEPImages

MicrosoftIcon="/Library/Application Support/WovenIT/DEP Notify Icons/Microsoft.png"
OktaIcon="/Library/Application Support/WovenIT/DEP Notify Icons/Okta.png"
SlackIcon="/Library/Application Support/WovenIT/DEP Notify Icons/Slack.png"
GoogleIcon="/Library/Application Support/WovenIT/DEP Notify Icons/Google.png"
VPNIcon="/Library/Application Support/WovenIT/DEP Notify Icons/VPN.png"
LastPassIcon="/Library/Application Support/WovenIT/DEP Notify Icons/LastPass.png"
LanguageIcon="/Library/Application Support/WovenIT/DEP Notify Icons/Language.png"
ITIcon="/Library/Application Support/WovenIT/DEP Notify Icons/IT.png"
InfoSecIcon="/Library/Application Support/WovenIT/DEP Notify Icons/InfoSec.png"
ECourseIcon="/Library/Application Support/WovenIT/DEP Notify Icons/eCourse.png"
ComplianceIcon="/Library/Application Support/WovenIT/DEP Notify Icons/Compliance.png"
MFAIcon="/Library/Application Support/WovenIT/DEP Notify Icons/2FA.png"
WovenPlanetLogo="/Library/Application Support/WovenIT/wovenplanet_45px_onwhite.png"

###############################################
# Testing Mode Set. true or false
Testing=true
###############################################
#DeviceSerialNumber=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')
# Rename the mac
#get username
user=`ls -la /dev/console | cut -d " " -f 4 | tr [:lower:] [:upper:] `

#Save the computer's serial number in a variable so it can be used in the next command.
serialNum=$(ioreg -l | awk '/IOPlatformSerialNumber/ { split($0, line, "\""); printf("%s\n", line[4]); }')
# Set the NetBIOS name as the serial number
#defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$serialNum"

# Bonjour name ending in .local
scutil --set LocalHostName "$serialNum-$user"
# Friendly name shown in System Preferences > Sharing
scutil --set ComputerName "$serialNum-$user"
# The name recognized by the hostname command
scutil --set HostName "$serialNum-$user"
sleep 3

# Wait for Setup Assistant to finish
until [ "$SETUP_ASSISTANT_PROCESS" = "" ]; do
	echo "$(date "+%a %h %d %H:%M:%S"): Setup Assistant Still Running. PID $SETUP_ASSISTANT_PROCESS." >> "$TMP_DEBUG_LOG"
	sleep 1
	SETUP_ASSISTANT_PROCESS=$(pgrep -l "Setup Assistant")
done

# Wait for Finder - Helps if user is not DEP enrolled and has to log in
until [ "$FINDER_PROCESS" != "" ]; do
	echo "$(date "+%a %h %d %H:%M:%S"): Finder process not found. Assuming device is at login screen." >> "$TMP_DEBUG_LOG"
	sleep 1
	FINDER_PROCESS=$(pgrep -l "Finder")
done

# Getting current logged in user
loggedInUser=$( scutil <<< "show State:/Users/ConsoleUser" | awk -F': ' '/[[:space:]]+Name[[:space:]]:/ { if ( $2 != "loginwindow" ) { print $2 }}' )
	
	# Remove old configs if they exist
	if [ -f "$DEP_NOTIFY_CONFIG" ]; then
		rm "$DEP_NOTIFY_CONFIG"
	fi
	if [ -f "$DEP_NOTIFY_REG" ]; then
		rm "$DEP_NOTIFY_REG"
	fi
	
	# Check if testing mode is true, if so then don't check for finish file.
	
	if [ $Testing = false ]; then
		Check if finish file is installed. If so, then quit script.
			if [ -f "$DEP_NOTIFY_DONE" ]; then
				/bin/rm -Rf $DEP_NOTIFY_CONFIG
				/bin/rm -Rf $DEP_NOTIFY_APP
				/bin/rm -Rf $DEP_NOTIFY_REG
				/bin/rm -Rf /var/tmp/icons/
				/bin/rm -Rf /Library/LaunchDaemons/com.aag.launchdep.plist
				/bin/rm -Rf /var/tmp/depinstall
				exit 0
			fi
	fi
	
	# Let's not go to sleep
	caffeinate -d -i -m -s -u &
	caffeinatepid=$!
	
	# Disable Software Updates during imaging and wait for user to be fully logged on
	softwareupdate --schedule off
	
	# Set a main image
	echo Command: WindowStyle: "Activate" >> $DEP_NOTIFY_CONFIG
	echo Command: Image: $WovenPlanetLogo >> $DEP_NOTIFY_CONFIG
	echo Command: MainTitle: "Welcome To The Woven Planet Team!" >> $DEP_NOTIFY_CONFIG
	echo Command: MainText: "Thanks for joining our Mac team! We want you to have a few applications and settings configured before you get started with your new Mac. This process should take 10 to 20 minutes to complete depending on your internet speed. \n \n If you need additional software or help, please visit the Self Service app in your Applications folder or on your Dock." >> $DEP_NOTIFY_CONFIG
	#echo "Command: Determinate: 10" >> $DEP_NOTIFY_CONFIG
	#echo "Command: DeterminateOff:" >> $DEP_NOTIFY_CONFIG
	echo Status:  "Starting Installs" >> $DEP_NOTIFY_CONFIG
	
	
#	echo Command: ContinueButton: "Begin Setup Process" >> $DEP_NOTIFY_CONFIG
	
	
	
	
	# Open DepNotify
	sudo -u "$loggedInUser" open -a "$DEP_NOTIFY_APP" --args -fullScreen

	
	# Check internet connection
	sleep 8
	if ping -q -c 1 -W 1 8.8.8.8 >/dev/null; then
		echo "Command: MainText: Internet Connection is good!" >> "$DEP_NOTIFY_CONFIG"
	else
		echo "Status: Please check your internet connection" >> "$DEP_NOTIFY_CONFIG"
		echo "Command: MainText: No Network Connection Found. If connected to AGGuest, make sure to make that default wireless and to connect automatically. Close this program by hitting command-control-x or waiting 30 seconds when it closes on it's own then check connection" >> "$DEP_NOTIFY_CONFIG"
		sleep 30
		echo "Command: Quit" >>  "$DEP_NOTIFY_CONFIG"
	fi
	sleep 2
	#begin setup
	#echo "Command: DeterminateManualStep: 1" >> $DEP_NOTIFY_CONFIG
	echo Command: MainTitle: "Installing Applications" >> $DEP_NOTIFY_CONFIG
	echo Command: MainText: "This should take around 15 minutes or less to finish depending on connection" >> $DEP_NOTIFY_CONFIG
	echo Status: "Beginning the install process..." >> $DEP_NOTIFY_CONFIG
	sleep 6
	#echo "Command: DeterminateManualStep: 2" >> $DEP_NOTIFY_CONFIG
	$RosettaInstall
	sleep 2
	
	# start crowdstrike install
	
	#echo "Command: DeterminateManualStep: 3" >> $DEP_NOTIFY_CONFIG
	echo Command: Image: $MicrosoftIcon >> $DEP_NOTIFY_CONFIG
	echo Command: MainTitle: "Microsoft Azure" >> $DEP_NOTIFY_CONFIG
	echo Command: MainText: "A comprehensive identity service that provides single sign-on and multifactor authentication to Woven Planet users. \n \n If you’re prompted to log in to a Microsoft account, simply enter your Woven Planet username and password (located in your welcome email)" >> $DEP_NOTIFY_CONFIG
	sleep 5
	#echo Status: "We are still working don't worry...this is just a larger application..." >> $DEP_NOTIFY_CONFIG
	echo Status: "Hang tight and read up on our common systems we will list above!" >> $DEP_NOTIFY_CONFIG
	$CrowdstrikeInstall
	sleep 2
	
	# start chrome install
	
	echo Command: Image: $OktaIcon >> $DEP_NOTIFY_CONFIG
	echo Command: MainTitle: "Okta" >> $DEP_NOTIFY_CONFIG
	echo Command: MainText: "An identity and access management tool. Sign in to various enterprise applications (like GitHub and Confluence) with a single login. \n \n Access your apps dashboard at https://tri-ad.okta.com/." >> $DEP_NOTIFY_CONFIG
	echo Status: "Making some good progress..." >> $DEP_NOTIFY_CONFIG
	#echo "Command: DeterminateManualStep: 4" >> $DEP_NOTIFY_CONFIG
	sleep 2
	$ChromeInstall
	sleep 2
	
	# start slack Install
	echo Command: Image: $GoogleIcon >> $DEP_NOTIFY_CONFIG
	echo Command: MainTitle: "Google Workspace" >> $DEP_NOTIFY_CONFIG
	echo Command: MainText: "Woven Planet uses GWS for business activities, communication and collaboration. This suite of productivity tools gives you easy access to email, meetings, event scheduling, file sharing, and more. \n \n Launch the Chrome browser and login to Gmail with your Woven Planet credentials to get started." >> $DEP_NOTIFY_CONFIG
	sleep 2
	$SlackInstall
	sleep 2
	
	# Start Zoom Install
	
	echo Command: Image: $SlackIcon >> $DEP_NOTIFY_CONFIG
	echo Command: MainTitle: "Slack" >> $DEP_NOTIFY_CONFIG
	echo Command: MainText: "An instant messaging application that you'll use to communicate with any and everyone at Woven Planet. \n \n The platform has its own internal apps, bots, and integrations to help you work across your entire tech stack—without opening a million browser tabs." >> $DEP_NOTIFY_CONFIG
	echo Status: "About half way there!..." >> $DEP_NOTIFY_CONFIG
	#echo "Command: DeterminateManualStep: 5" >> $DEP_NOTIFY_CONFIG
	sleep 2
		$ZoomInstall
	sleep 2
	
		# Start LastPass Install
		
		echo Command: Image: $LastPassIcon >> $DEP_NOTIFY_CONFIG
		echo Command: MainTitle: "LastPass" >> $DEP_NOTIFY_CONFIG
		echo Command: MainText: "LastPass is a browser-based password management tool that you’ll use to securely share credentials with your team. \n \n If you can’t access your vault, your credentials may have expired. Contact IT support to get this resolved." >> $DEP_NOTIFY_CONFIG
		echo Status: "Hope your first day is going well so far!" >> $DEP_NOTIFY_CONFIG
		$LastPassInstall
		sleep 2
		echo Command: Image: $MFAIcon >> $DEP_NOTIFY_CONFIG
		echo Command: MainTitle: "2-Factor Authentication" >> $DEP_NOTIFY_CONFIG
		echo Command: MainText: "2nd Factor Authentication (2FA) is an additional layer of protection beyond a username and password that you can use to secure your account. Your username and password are the first factor. Your second factor can be a PIN number, a mobile phone, a fingerprint scan, or something else. \n \n You’ll set up 2FA for your Microsoft account. If you’re having trouble, your credentials may have expired, and you’ll need to contact IT support to have them reissued." >> $DEP_NOTIFY_CONFIG
		sleep 10
	# Start Global Protect Install
	
	echo Command: Image: $ITIcon >> $DEP_NOTIFY_CONFIG
	echo Command: MainTitle: "IT Support?" >> $DEP_NOTIFY_CONFIG
	echo Command: MainText: "Experiencing technical difficulties? Reach out to the IT team for help. \n \n Email it-support@woven-planet.global, or submit a support ticket request in the ServiceNow portal." >> $DEP_NOTIFY_CONFIG
	sleep 2
	$GPInstall
	sleep 3
		echo Command: Image: $VPNIcon >> $DEP_NOTIFY_CONFIG
		echo Command: MainTitle: "GlobalProtect VPN" >> $DEP_NOTIFY_CONFIG
		echo Command: MainText: "Can’t access Jira, Confluence, GitHub, or another enterprise application? You won’t be able to access them if the VPN is not activated. \n \n The GlobalProtect VPN ensures a secure connection to certain company assets. We’ll connect to it for you the first time, and later you’ll see steps on how to ensure the activation on your own." >> $DEP_NOTIFY_CONFIG
	# Start Google Drive Install
	$GoogleDriveInstall
	sleep 2
	
	echo Command: Image: $LanguageIcon >> $DEP_NOTIFY_CONFIG
	echo Command: MainTitle: "Language Programs" >> $DEP_NOTIFY_CONFIG
	echo Command: MainText: "You’re likely to encounter two main languages in your day-to-day operations: English and Japanese. \n \n If you’re interested in sharpening your skills in either language, then the Woven Dojo is the place to go for 1-on-1 private lessons." >> $DEP_NOTIFY_CONFIG
	echo Status: "You're doing great, just a few more min..." >> $DEP_NOTIFY_CONFIG
	#echo "Command: DeterminateManualStep: 6" >> $DEP_NOTIFY_CONFIG	
	sleep 10
	# Start Nessus Install
	
	echo Command: Image: $InfoSecIcon >> $DEP_NOTIFY_CONFIG
	echo Command: MainTitle: "Security & Privacy" >> $DEP_NOTIFY_CONFIG
	echo Command: MainText: "Wondering whether to download that browser extension? Or whether you can log in to your Woven Planet Gmail on your personal computer? \n \n Woven Security’s mission is to enable secure product development and the protection of intellectual properties. Visit https://security.woven-planet.tech to learn more." >> $DEP_NOTIFY_CONFIG
	$NessusInstall
	sleep 4
	#echo "Command: DeterminateManualStep: 7" >> $DEP_NOTIFY_CONFIG

	# Start FileVault Encryption 
	echo Command: Image: $ComplianceIcon >> $DEP_NOTIFY_CONFIG
	echo Command: MainTitle: "Compliance Training" >> $DEP_NOTIFY_CONFIG
	echo Command: MainText: "You might be hard-pressed to find one who enjoys wading through dense legal terminology (lawyers included!), but this is a necessary step in the protection of you, your colleagues, and the organization as a whole. \n \n You’ll need to complete your compliance training within the first 30 days of employment. Visit https://academy.woven-dojo.com to learn more." >> $DEP_NOTIFY_CONFIG
	sleep 2
		
	# Finished downloading everything... now just showing the user some more info...
	
	sleep 12
	echo Command: Image: $ECourseIcon >> $DEP_NOTIFY_CONFIG
	echo Command: MainTitle: "IT Onboarding Course" >> $DEP_NOTIFY_CONFIG
	echo Command: MainText: "Feeling overwhelmed? There’s a lot to take in! Don’t worry about taking notes right now—you’ll see all this information again in your onboarding course. \n \n You should have received a link to the course in your personal email. Contact IT support if you need further assistance." >> $DEP_NOTIFY_CONFIG
	sleep 12
	echo Command: Image: $WovenPlanetLogo >> $DEP_NOTIFY_CONFIG
	echo Command: MainText: "All Applications have completed installation!" >> $DEP_NOTIFY_CONFIG
	echo Status: "All Set!" >> $DEP_NOTIFY_CONFIG
	#echo "Command: DeterminateManualStep: 8" >> $DEP_NOTIFY_CONFIG

	
	sleep 10
	# We are done with the info part.
	# Final steps
	echo "Command: MainTitle: Wrapping things up" >> $DEP_NOTIFY_CONFIG
	echo "Command: MainText: The last step is to encrypt your mac. Once this Window close shortly. You'll be forced to restart in 15 minutes, which will complete the setup process." >> $DEP_NOTIFY_CONFIG
	echo Status: "Please report any issues with this build process to Woven Planet IT Team" >> $DEP_NOTIFY_CONFIG
	#echo "Command: DeterminateManualStep: 9" >> $DEP_NOTIFY_CONFIG
		# enable filevault
		$FileVaultInstall
		# filevaul enabled 

	sleep 5


	
	# Flush DNS (It's never DNS until it's DNS)
	dscacheutil -flushcache
	
	# Create file to confirm DEPNotify completion
	/usr/bin/touch /var/tmp/com.depnotify.provisioning.done
	
	# Remove the Launch Daemon
	/bin/rm -Rf /Library/LaunchDaemons/com.aag.launchdep.plist
	
	# Wake back up
	kill "$caffeinatepid"
	
	# Renable software Updates
	softwareupdate --schedule on
	
	# Quit
	echo "Command: MainTitle: All Done!" >> $DEP_NOTIFY_CONFIG
	echo "Command: MainText: Closing this application to prompt a reboot." >> $DEP_NOTIFY_CONFIG
	echo "Status: triggering reboot timer now" >> $DEP_NOTIFY_CONFIG
	#echo "Command: DeterminateManualStep: 10"
	sleep 5
	#echo "Command: ContinueButton: " >> $DEP_NOTIFY_CONFIG
	echo "Command: Quit" >>  $DEP_NOTIFY_CONFIG
	
	sleep 2
	
	# Remove DEPNotify and the logs
	/bin/rm -Rf $DEP_NOTIFY_CONFIG
	/bin/rm -Rf $DEP_NOTIFY_APP
	/bin/rm -Rf $DEP_NOTIFY_REG
	
	sleep 2
	# Open Chrome, set default browser, and open 4 tabs.
		open -a Google\ Chrome --args --make-default-browser
		sleep 10
		open -a Google\ Chrome "https://mail.google.com"
		open -a Google\ Chrome "https://calendar.google.com"
		open -a Google\ Chrome "https://woven-planet-it-ops.rise.com/learn/my-learning"
		open -a Google\ Chrome "https://docs.google.com/forms/d/1Hpz9kw_BrRgcefGZOshAQytQDtF4YAb5I0sLxOANBH8/edit"
		
	# Beginning Restart Timer with Jamf Policy	
	jamf policy -event restart15min
	exit 0