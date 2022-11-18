#!/bin/zsh

# version 2.8, 15 November 2022

# !!! Terminal or process running this script will need Full Disk Access

# read the tcc.db and translate the following:
# service
# client
# auth_value
# auth_reason
# indirect_object_identifier
# last_modified

# see also:
# https://www.rainforestqa.com/blog/macos-tcc-db-deep-dive


if [ -z "${ZSH_VERSION}" ]; then
  >&2 echo "ERROR: This script is only compatible with Z shell (/bin/zsh). Invoke with 'zsh tcctool.sh'"
  exit 1
fi



# CSV Columns:
# Source - System, MDM, User
# Username - user shortname
# Client - app name
# ClientID - identifier
# ServiceName - eg "kTCCServiceAddressBook"
# ServiceFriendlyName - eg "Contacts"
# AuthValue - Denied, Unknown, Allowed, Limited
# AuthReason - User Set, System Set, etc
# Timestamp - UNIX epoch time
# FormattedTime - modified time ISO formatted (eg "2022-11-15T13:42:19-07:00")
# Coming Soon: IsInstalled - is client app installed boolean 0/1 
# Coming Soon: CodeSignReq

CSVArrayHeader="Source, Username, Client, ClientID, ServiceName, ServiceFriendlyName, AuthValue, AuthReason, Timestamp, FormattedTime"

typeset -A CSVArray
CSVArray=${CSVArrayHeader}


typeset -A RowArray
# each row in tcc.db builds a row in the CSV. RowArray holds the values, then those are echoed to a new line in CSVArray


# TCC Translator arrays

# service
typeset -A ServiceArray
ServiceArray[kTCCServiceAddressBook]="Contacts"
ServiceArray[kTCCServiceAppleEvents]="Apple Events"
ServiceArray[kTCCServiceBluetoothAlways]="Bluetooth"
ServiceArray[kTCCServiceCalendar]="Calendar"
ServiceArray[kTCCServiceCamera]="Camera"
ServiceArray[kTCCServiceContactsFull]="Full contacts information"
ServiceArray[kTCCServiceContactsLimited]="Basic contacts information"
ServiceArray[kTCCServiceFileProviderDomain]="Files managed by Apple Events"
ServiceArray[kTCCServiceFileProviderPresence]="See when files managed by client are in use"
ServiceArray[kTCCServiceLocation]="Current location"
ServiceArray[kTCCServiceMediaLibrary]="Apple Music, music and video activity, and media library"
ServiceArray[kTCCServiceMicrophone]="Microphone"
ServiceArray[kTCCServiceMotion]="Motion & Fitness Activity"
ServiceArray[kTCCServicePhotos]="Read Photos"
ServiceArray[kTCCServicePhotosAdd]="Add to Photos"
ServiceArray[kTCCServicePrototype3Rights]="Authorization Test Service Proto3Right"
ServiceArray[kTCCServicePrototype4Rights]="Authorization Test Service Proto4Right"
ServiceArray[kTCCServiceReminders]="Reminders"
ServiceArray[kTCCServiceScreenCapture]="Capture screen contents"
ServiceArray[kTCCServiceSiri]="Use Siri"
ServiceArray[kTCCServiceSpeechRecognition]="Speech Recognition"
ServiceArray[kTCCServiceSystemPolicyDesktopFolder]="Desktop folder"
ServiceArray[kTCCServiceSystemPolicyDeveloperFiles]="Files in Software Development"
ServiceArray[kTCCServiceSystemPolicyDocumentsFolder]="Files in Documents folder"
ServiceArray[kTCCServiceSystemPolicyDownloadsFolder]="Files in Downloads folder"
ServiceArray[kTCCServiceSystemPolicyNetworkVolumes]="Files on a network volume"
ServiceArray[kTCCServiceSystemPolicyRemovableVolumes]="Files on a removable volume"
ServiceArray[kTCCServiceSystemPolicySysAdminFiles]="Administer the computer"
ServiceArray[kTCCServiceWillow]="Home data"
ServiceArray[kTCCServiceSystemPolicyAllFiles]="Full Disk Access"
ServiceArray[kTCCServiceAccessibility]="Control the computer"
ServiceArray[kTCCServicePostEvent]="Send keystrokes"
ServiceArray[kTCCServiceListenEvent]="Monitor input from the keyboard"
ServiceArray[kTCCServiceDeveloperTool]="Run insecure software locally"
ServiceArray[kTCCServiceLiverpool]="Location services"
ServiceArray[kTCCServiceUbiquity]="iCloud"
ServiceArray[kTCCServiceShareKit]="Share features"
ServiceArray[kTCCServiceLinkedIn]="Share via LinkedIn"
ServiceArray[kTCCServiceTwitter]="Share via Twitter"
ServiceArray[kTCCServiceFacebook]="Share via Facebook"
ServiceArray[kTCCServiceSinaWeibo]="Share via Sina Weibo"
ServiceArray[kTCCServiceTencentWeibo]="Share via Tencent Weibo"

# auth_reason 
typeset -A AuthReasonArray
AuthReasonArray[0]="Inherited/Unknown"
AuthReasonArray[1]="Error"
AuthReasonArray[2]="User Consent"
AuthReasonArray[3]="User Set"
AuthReasonArray[4]="System Set"
AuthReasonArray[5]="Service Policy"
AuthReasonArray[6]="MDM Policy"
AuthReasonArray[7]="Override Policy"
AuthReasonArray[8]="Missing usage string"
AuthReasonArray[9]="Prompt Timeout"
AuthReasonArray[10]="Preflight Unknown"
AuthReasonArray[11]="Entitled"
AuthReasonArray[12]="App Type Policy"

# auth_value
typeset -A AuthValueArray
AuthValueArray[0]="Denied"
AuthValueArray[1]="Unknown"
AuthValueArray[2]="Allowed"
AuthValueArray[3]="Limited"

CurrentClient=""


processRow() {
	TCCRow=$1
	RawClient=$(echo $TCCRow | cut -d',' -f1)

	RowArray[Client]=\"$( basename $RawClient)\"
	
	ClientType=$(echo $TCCRow | cut -d',' -f2)
	if [ $ClientType -eq 0 ]
	then
		Client=$(mdfind "kMDItemCFBundleIdentifier = $RawClient" | head -1)
		if [ -z $Client ]
		then
			Client=$RawClient
		fi
	else
		Client=$RawClient
		RowArray[ClientID]="\"$Client\""
	fi

		
	ServiceName=$(echo $TCCRow | cut -d',' -f3)
	AuthVal=$(echo $TCCRow | cut -d',' -f4)
	AuthReason=$(echo $TCCRow | cut -d',' -f5)
	DateAuthEpoch=$(echo $TCCRow | cut -d',' -f6)

	DateAuth=$(date -jI "hours" -r $DateAuthEpoch)

	RowArray[ServiceName]=$ServiceName
	RowArray[Timestamp]=$DateAuthEpoch
	RowArray[FormattedTime]=$DateAuth



	
	if [ "$Client" != "$CurrentClient" ]
	then
		CurrentClient=$Client
		ShortClient=$(basename $Client) # clean up paths a bit
#		printf "--- \n\n%s\n" $ShortClient
		CurrentAuthVal=""
	fi
 
	if [ "$AuthVal" != "$CurrentAuthVal" ]
	then
		CurrentAuthVal=$AuthVal
#		printf "\t%s:\n" $AuthValueArray[$AuthVal]
	fi
 
	# printf "\t\t%s (%s - %s)\n"	 $ServiceArray[$ServiceName] $AuthReasonArray[$AuthReason] $DateAuth

	RowArray[ServiceFriendlyName]=\"$ServiceArray[$ServiceName]\"
	RowArray[AuthValue]=$AuthValueArray[$AuthVal]
	RowArray[AuthReason]=\"$AuthReasonArray[$AuthReason]\"

}




# start with the system defaults:

# echo "======== [System Default Permissions]"

sqlite3 /Library/Application\ Support/com.apple.tcc/tcc.db -csv -noheader -nullvalue '-' \
'select client, client_type, service, auth_value, auth_reason, last_modified from access order by client, auth_value' 2>/dev/null \
| while read -r TCCRow
do
	# reset the RowArray
	RowArray[Source]="System"
	RowArray[Username]=""
	RowArray[Client]=""
	RowArray[ClientID]=""
	RowArray[ServiceName]=""
	RowArray[ServiceFriendlyName]=""
	RowArray[AuthValue]=""
	RowArray[AuthReason]=""
	RowArray[Timestamp]=""
	RowArray[FormattedTime]=""

	processRow "$TCCRow"

	RowString="${RowArray[Source]},\
${RowArray[Username]},\
${RowArray[Client]},\
${RowArray[ClientID]},\
${RowArray[ServiceName]},\
${RowArray[ServiceFriendlyName]},\
${RowArray[AuthValue]},\
${RowArray[AuthReason]},\
${RowArray[Timestamp]},\
${RowArray[FormattedTime]}"

	CSVArray+=(${RowString})
	
done

# 
# printf '%s\n' "${CSVArray[@]}"
# 

# echo "======== [Per-user Permissions Overrides]"


# list all Users' home directories (uses dscl in the rare instance they're not in /Users/*)
USERHOMES=$(dscl /Local/Default -list /Users NFSHomeDirectory | grep -v "/var/empty" | awk '$2 ~ /^\// { print $2 }' )

for USERHOME in ${=USERHOMES}
do

	if [ -f "${USERHOME}/Library/Application Support/com.apple.tcc/tcc.db" ]
	then
	
#		echo "================ [ ${USERHOME} ]"
		UserShortName=$( basename $USERHOME )

		sqlite3 ${USERHOME}/Library/Application\ Support/com.apple.tcc/tcc.db -csv -noheader -nullvalue '-' \
		'select client, client_type, service, auth_value, auth_reason, last_modified from access order by client, auth_value'  2>/dev/null \
		| while read -r TCCRow
		do
			# reset the RowArray
			RowArray[Source]="User"
			RowArray[Username]=$UserShortName
			RowArray[Client]=""
			RowArray[ClientID]=""
			RowArray[ServiceName]=""
			RowArray[ServiceFriendlyName]=""
			RowArray[AuthValue]=""
			RowArray[AuthReason]=""
			RowArray[Timestamp]=""
			RowArray[FormattedTime]=""

			processRow "$TCCRow"

			RowString="${RowArray[Source]},\
${RowArray[Username]},\
${RowArray[Client]},\
${RowArray[ClientID]},\
${RowArray[ServiceName]},\
${RowArray[ServiceFriendlyName]},\
${RowArray[AuthValue]},\
${RowArray[AuthReason]},\
${RowArray[Timestamp]},\
${RowArray[FormattedTime]}"

			CSVArray+=(${RowString})
	
		done
		
	fi

done


printf '%s\n' "${CSVArray[@]}"




# MDM profile overrides

if [ -f "/Library/Application Support/com.apple.TCC/MDMOverrides.plist" ]
then
#	echo "======== [ MDM TCC Profiles ]"

	FullMDMOverrides=$(plutil -convert xml1 -o - /Library/Application\ Support/com.apple.TCC/MDMOverrides.plist)

	MDMOverrides=$(echo $FullMDMOverrides | xmllint --xpath "/*/dict[*]/key" - | sed 's/<[^>]*>/ /g')

	Index=1

	for Identifier in ${=MDMOverrides}
	do
		# printf "--- \n%s\n" $Identifier
		
		IdentifierXML=$(echo $FullMDMOverrides | xmllint --xpath "/*/dict[*]/dict[$Index]" -)

		AllServiceNames="$(echo $IdentifierXML | xmllint --xpath '/dict[1]/key' - | sed 's/<[^>]*>/\n/g')"

		ServiceIndex=1
		
		for ServiceName in ${=AllServiceNames}
		do
			if [ $ServiceName = "kTCCServiceAppleEvents" ]
			then			
				if $(echo $IdentifierXML | xmllint --xpath "/dict[$ServiceIndex]//true" - &> /dev/null)
				then
					AuthVal="Allowed"
				else
					AuthVal="Denied"
				fi
			else 
				AuthVal="$(echo $IdentifierXML | xmllint --xpath "/dict/dict[$ServiceIndex]/key[1]" - | sed 's/<[^>]*>//g')"	
			fi

# 			printf "\t%s:\n" $AuthVal
# 			printf "\t\t%s\n" $ServiceArray[$ServiceName]
			((ServiceIndex++))

			# reset the RowArray
			RowArray[Source]="MDM"
			RowArray[Username]=""
			RowArray[Client]=""
			RowArray[ClientID]=""
			RowArray[ServiceName]=$ServiceName
			RowArray[AuthValue]=$AuthVal
			RowArray[AuthReason]="MDM"
			RowArray[Timestamp]=""
			RowArray[FormattedTime]=""

			RowArray[ServiceFriendlyName]=\"$ServiceArray[$ServiceName]\"
			RowArray[AuthReason]=\"$AuthReasonArray[$AuthReason]\"

			RowString="${RowArray[Source]},\
${RowArray[Username]},\
${RowArray[Client]},\
${RowArray[ClientID]},\
${RowArray[ServiceName]},\
${RowArray[ServiceFriendlyName]},\
${RowArray[AuthValue]},\
${RowArray[AuthReason]},\
${RowArray[Timestamp]},\
${RowArray[FormattedTime]}"

			CSVArray+=(${RowString})



		done

		((Index++))
	done


else 
#	echo "======== [ No MDM TCC Profiles found ]"
fi	

