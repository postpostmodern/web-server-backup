# Web Server Backup Script

This is a bash script for backing up multiple web sites and MySQL databases into a specified backups directory. It's a good idea to run it every night via cron.

Once configured (variables set within the script), it does this:

* Creates a directory for your site backups (if it doesn't exist)
* Creates a directory for your MySQL dumps (if it doesn't exist)
* Loops through all of your MySQL databases and dumps each one of them to a gzipped file
* Deletes database dumps older than a specified number of days from the backup directory
* Tars and gzips each folder within your sites directory (I keep my websites in /var/www/sites/)
* Deletes site archives older than a specified number of days from the backup directory
* Optionally rsyncs all backup files to a remote server

# BETA WARNING

___This script works fine for me (using Ubuntu 8.04 on Slicehost), but servers vary greatly. USE THIS SCRIPT AT YOUR OWN RISK!! There is always risk involved with running a script. I AM NOT RESPONSIBLE FOR DAMAGE CAUSED BY THIS SCRIPT.___

You may very well know more about bash scripting and archiving than I do. If you find any flaws with this script or have any recommendations as to how this script can be improved, please fork it and send me a pull request.

# Installation

* __MOST IMPORTANTLY:__ Open the backup.sh file in a text editor and set the configuration variables at the top (see below).
* Place the backup.sh file somewhere on your server (something like /usr/local/web-server-backup or ~/scripts).
* Make sure the backup.sh script is executable by you: `chmod 744 backup.sh`
* Optionally, set up an account on another server and configure it to connect using an SSH key.
* Preferably set up cron to run it every night (see below).
    
# Configuration

There are a bunch of variables that you can set to customize the way the script works. _Some of them __must__ be set before running the script!_

NOTE: The BACKUP\_DIR setting is preset to ~/site-backups. If you want to use something like /var/site-backups, you'll need to create the directory first and set it to be writable by you.

## General Settings:

* __BACKUP\_DIR__: The parent directory in which the backups will be placed. It's preset to: `"/home/`whoami`/site-backups"`
* __KEEP\_MYSQL__: How many days worth of mysql dumps to keep. It's preset to: `"14"`
* __KEEP\_SITES__: How many days worth of site tarballs to keep. It's preset to: `"2"`
* __THE\_DATE__: The date that will be appended to filenames. It's preset to: `"$(date '+%Y-%m-%d')"`

## MySQL Settings:

* __MYSQL\_HOST__: The MySQL hostname. It's preset to the standard: `"localhost"`
* __MYSQL\_USER__: The MySQL username. It's preset to the standard: `"root"`
* __MYSQL\_PASS__: The MySQL password. ___You'll need to set this yourself!___
* __MYSQL\_BACKUP\_DIR__: The directory in which the dumps will be placed. It's preset to: `"$BACKUP\_DIR/mysql/"`

## Web Site Settings:

* __SITES\_DIR__: This is the directory where you keep all of your web sites. It's preset to: `"/var/www/sites/"`
* __SITES\_BACKUP\_DIR__: The directory in which the archived site files will be placed. It's preset to: `"$BACKUP_DIR/sites/"`

## Rsync Settings:

* __RSYNC__: Whether or not you want to rsync the backups to another server. (Either "true" or "false") It's preset to: `"true"`
* __RSYNC\_USER__: The user account name on the remote server. Please note that there is no password setting. It is recommended that you use an SSH key. ___You'll need to set this yourself!___
* __RSYNC\_SERVER__: The server address of the remote server. ___You'll need to set this yourself!___ It's preset to: `"other.server.com"`
* __RSYNC\_DIR__: The directory on the remote server that will be synchronized with $BACKUP\_DIR. It's preset to: `"web_site_backups"`

## Paths to commands: (probably won't need to change these)

* __MYSQL\_PATH__: Path to mysql. It's preset to: `"$(which mysql)"`
* __MYSQLDUMP\_PATH__: Path to mysqldump. It's preset to: `"$(which mysqldump)"`
* __FIND\_PATH__: Path to find. It's preset to: `"$(which find)"`
* __TAR\_PATH__: Path to tar. It's preset to: `"$(which tar)"`
* __RSYNC\_PATH__: Path to rsync. It's preset to: `"$(which rsync)"`

# Running with cron

Once you've tested the script, I recommend setting it up to be run every night with cron. Here's a sample cron config:

    SHELL=/bin/bash
    PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin:/usr/local/sbin
    MAILTO=jason@example.com
    HOME=/home/jason

    30 4 * * * jason /home/jason/scripts/backup.sh
    
Assuming you are me (user account is 'jason'), that'll run the script (located in ~/scripts) at 4:30 every morning and email the output to jason@example.com.

So, take the above example, change the user account name, email address, home path, etc., save it to a text file, and place it in `/etc/cron.d/`. That should do it.
