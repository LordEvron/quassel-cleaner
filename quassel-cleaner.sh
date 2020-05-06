#!/bin/sh
# Taken from http://blog.encomiabile.it/2011/02/03/prune-quassel-database/

BAK_PATH="${HOME}/.config/quassel-irc.org/quassel-storage.sqlite.bak"
CURRENT_PATH="${HOME}/.config/quassel-irc.org/quassel-storage.sqlite"
# first day of data that will be maintained
# -7 day means that *every* chatline stored before 8 days ago and so on are going to be eliminated.
#	  only the last 7 days are keeped.
DATE_TO_PRUNE='-7 day'

die() {
	echo $@
	exit 1
}

# is quassel running?
is_quassel_running() {
	pgrep quassel > /dev/null
	echo $?
}

if [ $(is_quassel_running) -eq 0 ]; then
	echo "ERROR: quassel is running, stop it first!"
	exit 1;
fi

echo -n "Creating a backup and a temporary copy of the db .."

mv "$CURRENT_PATH" "$BAK_PATH" || die "unable to create a copy backup"
cp "$BAK_PATH" "$BAK_PATH.tmp" || die "unable to create a temporary copy of the db"
echo ".. done!"

echo -n "Cleaning up the database .."

# purge the db from old entry
sqlite3 $BAK_PATH.tmp "DELETE FROM backlog WHERE time < strftime('%s','now','${DATE_TO_PRUNE}');" || die "Purge failed"
echo ".. done!"

echo -n "Rebuilding database .."
# rebuild the db to save disk space (the db doesn't shrink automatically)
sqlite3 $BAK_PATH.tmp .dump | sqlite3 $CURRENT_PATH || die "Rebuild failed"
echo ".. done!"

echo -n "Deleting temporary files .."

# delete rubbish
rm "$BAK_PATH.tmp" || die "rm failed"
echo ".. done!"
