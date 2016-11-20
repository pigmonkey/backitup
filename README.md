# backitup.sh

Execute a user-specified command if a certain amount of time has passed.

If the specified command exits successfully (ie, with an exit code of zero) the
current timestamp is saved in a file. Every time the script runs, it checks the
timestamp stored in the file. If the timestamp is greater than a user-specified
period, the specified command is executed.

See source for configuration.

## Usage

I want to perform daily backups of a laptop to a USB drive using
[rsnapshot](http://rsnapshot.org/). I only want to perform the backup once per
day. The drive is only plugged in when I'm at my desk. By calling this script
every hour via cron, there is a high likelyhood of completing a backup each
day, but I'm guaranteed to never complete more than one backup per day.

    @hourly backitup.sh -l ~/.rsnapshot-monthly -b "/usr/bin/rsnapshot monthly" -p MONTHLY
    @hourly backitup.sh -l ~/.rsnapshot-weekly -b "/usr/bin/rsnapshot weekly" -p WEEKLY
    @hourly backitup.sh -l ~/.rsnapshot-daily -b "/usr/bin/rsnapshot daily"

While the script was written to execute backups, it can be used to call any
command.

## Periods

The desired period may be specified either in seconds or as `DAILY`, `WEEKLY`
or `MONTHLY`.

Note that the latter options will result in different behaviour than using the
equivalent seconds. For instance, a period of `DAILY` may result in the command
being executed twice in a 24-hour period (but on separate calendar days), where
a period of `86400` will guarantee the command will never be executed more than
once in a 24-hour period.
