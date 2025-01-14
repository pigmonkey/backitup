#!/bin/bash
#
# Execute a user-specified command if a certain amount of time has passed.
# 
# If the specified command exits successfully (ie, with an exit code of zero) the
# current timestamp is saved in a file. Every time the script runs, it checks the
# timestamp stored in the file. If the timestamp is greater than a user-specified
# period, the specified command is executed.
#
# Hey yo but wait, back it up, hup, easy back it up
#
# Author:   Pig Monkey (pm@pig-monkey.com)
# Website:  https://github.com/pigmonkey/backups
#
###############################################################################

# Define the file that will hold the timestamp of the last successful backup.
# It is recommended that this file be *inside* the directory to be backed up.
LASTRUN="$HOME/documents/.lastrun"

# Define the backup command.
BACKUP="$HOME/bin/tarsnapper.py"

# Define the command to be executed if the file which holds the time of the
# previous backup does not exist. The default behaviour here is to simply
# create the file, which will then cause the backup to be executed. If the
# directory you specified above is a mount point, the file not existing may
# indicate that the filesystem is not mounted. In that case, you would place
# your mount command in this string. If you want the script to exit when the
# file does not exist, simply set this to a blank string.
NOFILE='touch $LASTRUN'

# Define the period, in seconds, for backups to attempt to execute.
# Hourly:   3600
# Daily:    86400
# Weekly:   604800
# The period may also be set to the string 'DAILY', 'WEEKLY' or 'MONTHLY'.
# Note that this will result in behaviour that is different from setting the
# period to the equivalent seconds.
PERIOD='DAILY'

# Define whether the backup should only be attempted on AC power.
ACONLY='False'

# Set the default verbosity level.
VERBOSITY=1

# End configuration here.
###############################################################################

usage() {
    echo "Usage: backitup.sh [OPTION...]
Note that any command line arguments overwrite variables defined in the source.

Options:
    -p      the period for which backups should attempt to be executed
            (integer seconds or 'DAILY', 'WEEKLY' or 'MONTHLY')
    -b      the backup command to execute; note that this should be quoted if it contains a space
    -l      the location of the file that holds the timestamp of the last successful backup
    -n      the command to be executed if the above file does not exist
    -a      only attempt to execute when on AC power
    -v      be verbose
    -q      be quiet"
}

log() {
    if [ "$1" -le "$VERBOSITY" ]; then
        echo "$2"
    fi
}

backup() {
    # Execute the backup.
    log 1 "Executing program: $BACKUP"
    $BACKUP
    # If the backup was succesful, store the current time.
    if [ $? -eq 0 ]; then
        log 2 'Program completed.'
        date "$timeformat" > "$LASTRUN"
    else
        log 2 'Program failed.'
    fi
    exit
}

on_battery() {
    if [ -d "/sys/class/power_supply/ACAD" ]; then
        ac_status="/sys/class/power_supply/ACAD/online"
    else
        ac_status="/sys/class/power_supply/AC/online"
    fi
    local result=false # Assume negative unless proven otherwise
    if [ -e "$ac_status" ]; then
        if [ "$(cat $ac_status)" = "0" ] ;then
            result=true
        fi
    fi
    echo "$result"
}

# Get any arguments.
while getopts ":p:b:l:n:h:avq" opt; do
    case $opt in
        p)
            PERIOD=$OPTARG
            ;;
        b)
            BACKUP=$OPTARG
            ;;
        l)
            LASTRUN=$OPTARG
            ;;
        n)
            NOFILE=$OPTARG
            ;;
        v)
            VERBOSITY=2
            ;;
        q)
            VERBOSITY=0
            ;;
        a)
            ACONLY=true
            ;;
        h)
            usage
            exit
            ;;
        :)
            echo "Option -$OPTARG requires an argument.
            "
            usage
            exit
            ;;
    esac
done

# Bail out if on battery power and we only want to run on AC.
if [ "$(on_battery)" = true ] && [ "$ACONLY" = true ]; then
    log 2 "On battery power. Bailing out."
    exit
fi

# Set the format of the time string to store.
if [ "$PERIOD" == "DAILY" ]; then
    timeformat='+%Y%m%d'
elif [ "$PERIOD" == "WEEKLY" ]; then
    timeformat='+%G-W%W'
elif [ "$PERIOD" == "MONTHLY" ]; then
    timeformat='+%Y%m'
else
    timeformat='+%s'
fi

# If the file does not exist, perform the user requested action. If no action
# was specified, exit.
if [ ! -e "$LASTRUN" ]; then
    if [ -n "$NOFILE" ]; then
        eval $NOFILE
    else
        exit
    fi
fi

# If the file exists and is not empty, get the timestamp contained within it.
if [ -s "$LASTRUN" ]; then
    timestamp=$(eval cat \$LASTRUN)

    # If the backup period is daily, weekly or monthly, perform the backup if
    # the stored timestamp is not equal to the current date in the same format.
    if [ "$PERIOD" == "DAILY" ] || [ "$PERIOD" == "WEEKLY" ] || [ "$PERIOD" == "MONTHLY" ]; then
        if [ "$timestamp" != $(date "$timeformat") ]; then
            backup
        else
            log 2 "Already executed once for period $PERIOD. Exiting."
            exit
        fi

    # If the backup period is not daily, perform the backup if the difference
    # between the stored timestamp and the current time is greater than the
    # defined period.
    else
        diff=$(( $(date "$timeformat") - timestamp))
        if [ "$diff" -gt "$PERIOD" ]; then
            backup
        else
            log 2 "Executed less than $PERIOD seconds ago. Exiting."
            exit
        fi
    fi
fi

# If the file exists but is empty, the script has never been run before.
# Execute the backup.
if [ -e "$LASTRUN" ]; then
    backup
fi
