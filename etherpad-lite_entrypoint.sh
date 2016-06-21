#!/bin/bash
set -e

if [ -z "$MYSQL_NAME" ]; then
  echo "MYSQL_NAME not set. Please make sure you linked a MySQL container with the alias mysql!"
  exit 1
fi

if [ -z "$ETHERPAD_DB_PASSWORD" ]; then
  echo "ETHERPAD_DB_PASSWORD not set. Please supply a password for the new user!"
  exit 1
fi

if [ ! -z "$ADDITIONAL_PACKAGES" ]; then
	apt-get update; apt-get install -y $ADDITIONAL_PACKAGES; rm -r /var/lib/apt/lists/*
fi

: ${ETHERPAD_TITLE:=Etherpad}
: ${ETHERPAD_PORT:=9001}
: ${ETHERPAD_DB_USER:=etherpad}
: ${ETHERPAD_DB_NAME:=etherpad}
: ${ETHERPAD_MYSQL_SETUP_USER:=root}
: ${ETHERPAD_MYSQL_SETUP_PASSWORD:=$MYSQL_ENV_MYSQL_ROOT_PASSWORD}

# Check if database already exists
RESULT=$(mysql -u${ETHERPAD_MYSQL_SETUP_USER} -p${ETHERPAD_MYSQL_SETUP_PASSWORD} -hmysql --skip-column-names \
	-e "SHOW DATABASES LIKE '${ETHERPAD_DB_NAME}'")

if [ "$RESULT" != $ETHERPAD_DB_NAME ]; then
	# mysql database does not exist, create it
	echo "Creating database ${ETHERPAD_DB_NAME}"

	mysql -u${ETHERPAD_MYSQL_SETUP_USER} -p${ETHERPAD_MYSQL_SETUP_PASSWORD} -hmysql \
	    -e "create database ${ETHERPAD_DB_NAME}; grant all on ${ETHERPAD_DB_NAME}.* to '${ETHERPAD_DB_USER}'@'%' identified by '${ETHERPAD_DB_PASSWORD}' with grant option;"
fi

if [ ! -f $ETHERPAD_DATADIR/settings.json ]; then

	cat <<- EOF > $ETHERPAD_DATADIR/settings.json
	{
	  "title": "${ETHERPAD_TITLE}",
	  "ip": "0.0.0.0",
	  "port" : ${ETHERPAD_PORT},
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

chown -RL etherpad-lite:etherpad-lite $ETHERPAD_INSTALLDIR $ETHERPAD_DATADIR
exec start-stop-daemon --start --chuid etherpad-lite:etherpad-lite --exec $ETHERPAD_INSTALLDIR/bin/run.sh -- --settings $ETHERPAD_DATADIR/settings.json
