#!/bin/bash
cd "$(dirname "$0")"

# --- general settings
historyfile="eventtrigger.hst"  # keeps track of all alert (do not delete)
triggerfile="eventtrigger.conf" # here are all the alert triggers

# --- mail settings
sendalertmail="y"       	# send alert mail (y/n)
sender="alert@mail.com"   	# email sender
senderpwd="password"    # password for the sender
recipient="bert@mail.com"		# alert recipient
subject="kali alert"    	# alertmail subject

# --- begin script
touch $historyfile
touch $triggerfile

# check if ssmtp is installed
if ! [ -x "$(command -v ssmtp)" ] && [ sendalertmail == "y" ]; then
    echo "-----------------------------"
    echo "error: ssmtp is not installed"
    echo "after installation, plz configure 'etc/ssmtp/ssmtp.conf'"
    echo "-----------------------------"
    apt install ssmtp
    exit 1
fi

while read trigger; do  # read config file
    # split the file and the trigger
    inputfile="$(cut -d';' -f1 <<< $trigger)"
    trigger="$(cut -d';' -f2 <<< $trigger)"
    known1=0
    while read line; do # read inputfile
        if [[ $line == *"$trigger"* ]]; # if line contains trigger
        then
            known1=0
            while read hisline; do # read history
                # check if this a known alarm
                if [[ $hisline == "$line" ]];
                then
                    known1=1
                    echo "known issue"
                fi
            done < $historyfile 

            if [ $known1 == 0 ];
            then
                echo "new issue"
                echo "$line" >> $historyfile
                if [ $sendalertmail == "y" ];
                then
                    echo -e "Subject:$subject \n\n $line\n" | /usr/sbin/sendmail -au $sender -ap $senderpwd -f $sender $recipient
		    echo "send alert mail to: $recipient"
                fi
            fi
        fi
    done < $inputfile
done < $triggerfile
