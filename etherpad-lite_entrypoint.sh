#!/bin/bash
set -e

if [ -z "$MYSQL_NAME" ]; then
  echo "MYSQL_NAME not set. Please make sure you linked a MySQL container with the alias mysql!"
  exit 1
fi

# if we're linked to MySQL, and we're using the root user, and our linked
# container has a default "root" password set up and passed through... :)
: ${ETHERPAD_DB_USER:=root}
if [ "$ETHERPAD_DB_USER" = 'root' ]; then
	: ${ETHERPAD_DB_PASSWORD:=$MYSQL_ENV_MYSQL_ROOT_PASSWORD}
fi
: ${ETHERPAD_DB_NAME:=etherpad}

ETHERPAD_DB_NAME=$( echo $ETHERPAD_DB_NAME | sed 's/\./_/g' )

if [ -z "$ETHERPAD_DB_PASSWORD" ]; then
	echo "ETHERPAD_DB_PASSWORD not set!"
	exit 1
fi

: ${ETHERPAD_TITLE:=Etherpad}
: ${ETHERPAD_PORT:=9001}
: ${ETHERPAD_SESSION_KEY:=$(
		node -p "require('crypto').randomBytes(32).toString('hex')")}

# Check if database already exists
RESULT=`mysql -u${ETHERPAD_DB_USER} -p${ETHERPAD_DB_PASSWORD} \
	-hmysql --skip-column-names \
	-e "SHOW DATABASES LIKE '${ETHERPAD_DB_NAME}'"`

if [ "$RESULT" != $ETHERPAD_DB_NAME ]; then
	# mysql database does not exist, create it
	echo "Creating database ${ETHERPAD_DB_NAME}"

	mysql -u${ETHERPAD_DB_USER} -p${ETHERPAD_DB_PASSWORD} -hmysql \
	      -e "create database ${ETHERPAD_DB_NAME}"
fi

if [ ! -f $ETHERPAD_DATADIR/settings.json ]; then

	cat <<- EOF > $ETHERPAD_DATADIR/settings.json
	{
	  "title": "${ETHERPAD_TITLE}",
	  "ip": "0.0.0.0",
	  "port" : ${ETHERPAD_PORT},
	  "sessionKey" : "${ETHERPAD_SESSION_KEY}",
	  "dbType" : "mysql",
	  "dbSettings" : {
			    "user"    : "${ETHERPAD_DB_USER}",
			    "host"    : "mysql",
			    "password": "${ETHERPAD_DB_PASSWORD}",
			    "database": "${ETHERPAD_DB_NAME}"
			  },
	EOF

	if [ $ETHERPAD_ADMIN_PASSWORD ]; then

		: ${ETHERPAD_ADMIN_USER:=admin}

		cat <<- EOF >> $ETHERPAD_DATADIR/settings.json
		  "users": {
		    "${ETHERPAD_ADMIN_USER}": {
		      "password": "${ETHERPAD_ADMIN_PASSWORD}",
		      "is_admin": true
		    }
		  },
		EOF
	fi

	cat <<- EOF >> $ETHERPAD_DATADIR/settings.json
	}
	EOF
fi

# Set correct ownership and start Teamspeak server
chown -RL etherpad-lite:etherpad-lite $ETHERPAD_INSTALLDIR $ETHERPAD_DATADIR
exec start-stop-daemon --start --chuid etherpad-lite:etherpad-lite --exec $TEAMSPEAK_INSTALLDIR/bin/run.sh -- --settings $ETHERPAD_DATADIR/settings.json