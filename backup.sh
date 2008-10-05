#!/bin/bash


# BEGIN CONFIGURATION ==========================================================

BACKUP_DIR="~/site-backups"  # The directory in which you want backups placed
KEEP_MYSQL="14" # How many days worth of mysql dumps to keep
KEEP_SITES="2" # How many days worth of site tarballs to keep

MYSQL_HOST="localhost"
MYSQL_USER="root"
MYSQL_PASS=""
MYSQL_BACKUP_DIR="$BACKUP_DIR/mysql/"

SITES_DIR="/var/www/sites/"
SITES_BACKUP_DIR="$BACKUP_DIR/sites/"

RSYNC="true" # Set to "false" if you don't want the rsync performed
RSYNC_USER="user"
RSYNC_SERVER="other.server.com"
RSYNC_DIR="web_site_backups"

THE_DATE="$(date '+%Y-%m-%d')"

MYSQL_PATH="$(which mysql)"
MYSQLDUMP_PATH="$(which mysqldump)"
FIND_PATH="$(which find)"
TAR_PATH="$(which tar)"
RSYNC_PATH="$(which rsync)"

# END CONFIGURATION ============================================================



# Announce the backup time
echo "Backup Started: $(date)"

# Create the backup dirs if they don't exist
if [[ ! -d $BACKUP_DIR ]]
  then
  mkdir -p "$BACKUP_DIR"
fi
if [[ ! -d $MYSQL_BACKUP_DIR ]]
  then
  mkdir -p "$MYSQL_BACKUP_DIR"
fi
if [[ ! -d $SITES_BACKUP_DIR ]]
  then
  mkdir -p "$SITES_BACKUP_DIR"
fi

# Get a list of mysql databases and dump them one by one
echo "------------------------------------"
DBS="$($MYSQL_PATH -h $MYSQL_HOST -u$MYSQL_USER -p$MYSQL_PASS -Bse 'show databases')"
for db in $DBS
do
  echo "Dumping: $db..."
  $MYSQLDUMP_PATH -u $MYSQL_USER -p$MYSQL_PASS $db | gzip > $MYSQL_BACKUP_DIR$db\_$THE_DATE.sql.gz
done

# Delete old dumps
echo "------------------------------------"
echo "Deleting old backups..."
# List dumps to be deleted to stdout (for report)
$FIND_PATH $MYSQL_BACKUP_DIR*.sql.gz -mtime +$KEEP_MYSQL
# Delete dumps older than specified number of days
$FIND_PATH $MYSQL_BACKUP_DIR*.sql.gz -mtime +$KEEP_MYSQL -delete

# Get a list of files in the sites directory and tar them one by one
echo "------------------------------------"
cd $SITES_DIR
for d in *
do
  echo "Archiving $d..."
  $TAR_PATH --exclude="*/log" -C $SITES_DIR -czf $SITES_BACKUP_DIR/$d\_$THE_DATE.tgz $d
done

# Delete old site backups
echo "------------------------------------"
echo "Deleting old backups..."
# List files to be deleted to stdout (for report)
$FIND_PATH $SITES_BACKUP_DIR*.tgz -mtime +$KEEP_SITES
# Delete files older than specified number of days
$FIND_PATH $SITES_BACKUP_DIR*.tgz -mtime +$KEEP_SITES -delete

# Rsync everything with another server
if [[ $RSYNC == "true" ]]
  then
  echo "------------------------------------"
  echo "Sending backups to backup server..."
  $RSYNC_PATH --del -vaze ssh $BACKUP_DIR/ $RSYNC_USER@$RSYNC_SERVER:$RSYNC_DIR
fi
# Announce the completion time
echo "------------------------------------"
echo "Backup Completed: $(date)"
