#!/bin/bash


# BEGIN CONFIGURATION ==========================================================

BACKUP_DIR="/home/`whoami`/site_backups"  # The directory in which you want backups placed
KEEP_MYSQL="14" # How many days worth of mysql dumps to keep
KEEP_SITES="2" # How many days worth of site tarballs to keep

MYSQL_HOST="localhost"
MYSQL_USER="root"
MYSQL_PASS=""
MYSQL_BACKUP_DIR="$BACKUP_DIR/mysql/"

SITES_DIR="/var/www/sites/"
SITES_BACKUP_DIR="$BACKUP_DIR/sites/"

SYNC="s3sync" # Either 's3sync', 'rsync', or 'none'

# See s3sync info in README
S3SYNC_PATH="/usr/local/s3sync/s3sync.rb"
S3_BUCKET="my-fancy-bucket"
AWS_ACCESS_KEY_ID="YourAWSAccessKey" # Log in to your Amazon AWS account to get this
AWS_SECRET_ACCESS_KEY="YourAWSSecretAccessKey" # Log in to your Amazon AWS account to get this
USE_SSL="true"
SSL_CERT_DIR="/etc/ssl/certs" # Where your Cert Authority keys live; for verification
SSL_CERT_FILE="" # If you have just one PEM file for CA verification

# If you don't want to use S3, you can rsync to another server
RSYNC_USER="user"
RSYNC_SERVER="other.server.com"
RSYNC_DIR="web_site_backups"
RSYNC_PORT="22" # Change this if you've customized the SSH port of your backup system

# You probably won't have to change these
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
$FIND_PATH $MYSQL_BACKUP_DIR*.sql.gz -mtime +$KEEP_MYSQL -exec rm {} +

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
$FIND_PATH $SITES_BACKUP_DIR*.tgz -mtime +$KEEP_SITES -exec rm {} +

# Rsync everything with another server
if [[ $SYNC == "rsync" ]]
  then
  echo "------------------------------------"
  echo "Sending backups to backup server..."
  $RSYNC_PATH --del -vaze "ssh -p $RSYNC_PORT" $BACKUP_DIR/ $RSYNC_USER@$RSYNC_SERVER:$RSYNC_DIR

# OR s3sync everything with Amazon S3
elif [[ $SYNC == "s3sync" ]]
  then
  export AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY
  export SSL_CERT_DIR
  export SSL_CERT_FILE
  if [[ $USE_SSL == "true" ]]
    then
    SSL_OPTION=' --ssl '
    else
    SSL_OPTION=''
  fi
  echo "------------------------------------"
  echo "Sending backups to s3..."
  $S3SYNC_PATH --delete -v $SSL_OPTION -r $BACKUP_DIR/ $S3_BUCKET:backups
fi

# Announce the completion time
echo "------------------------------------"
echo "Backup Completed: $(date)"
