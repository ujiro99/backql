#!/bin/sh
# Syntax: backup.sh <mysql|pgsql> (<ssh|ftp> <user[:password]@host>|dropbox [configfile]) [remotedir]
set -e
TAG="$HOSTNAME_$(TZ=UTC date +%Y-%m-%d_%H:%M:%S_UTC)"
FILE="/tmp/$TAG.sql.gz"

[ "$3" ] || {
    echo "Please specfiy database type, transfer method and target."
    exit
}


case "$1" in
    mysql)
        mysqldump --all-databases | gzip > "$FILE"
        ;;
    pgsql)
        pg_dump | gzip > "$FILE"
        ;;
    data)
        FILENAME="$TAG.data.tar.gz"
        FILE="/tmp/$FILENAME"
        tar -C "$HOME" -czf "$FILE" "code/."
        ;;
    *)
        echo "Sorry, database type $1 is not supported."
        exit
        ;;
esac

case "$2" in
    ssh)
        scp -q -o BatchMode=yes "$FILE" "$3:$4"
        ;;
    ftp)
        curl -sST "$FILE" "ftp://$3/$4"
        ;;
    dropbox)
        dropper "$3" "$4" "$FILE"
        ;;
    *)
        echo "Sorry, transfer method $2 is not supported."
        exit
esac

SIZE="$(stat --printf %s "$FILE")"
echo "Backup $TAG completed. Its (compressed) size is $SIZE bytes."
rm -f "$FILE"
