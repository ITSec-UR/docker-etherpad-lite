FROM debian:jessie
MAINTAINER Philipp Holler <philipp.holler93@googlemail.com>

ENV ETHERPAD_VERSION="1.5.7" \
	ETHERPAD_INSTALLDIR="/opt/etherpad-lite" \
	ETHERPAD_DATADIR="/var/lib/etherpad-lite"
	
RUN useradd -r -m etherpad-lite

RUN apt-get update \
 && apt-get install -y unzip gzip git curl python libssl-dev pkg-config build-essential nodejs npm mysql-client \
 && rm -r /var/lib/apt/lists/*

RUN mkdir ${ETHERPAD_INSTALLDIR} \
 && curl -SL https://github.com/ether/etherpad-lite/archive/${ETHERPAD_VERSION}.zip > etherpad.zip \
 && unzip etherpad -d ${ETHERPAD_INSTALLDIR} \
 && mv ${ETHERPAD_INSTALLDIR}/etherpad-lite-${ETHERPAD_VERSION}/* ${ETHERPAD_INSTALLDIR} \
 && rm -r etherpad.zip ${ETHERPAD_INSTALLDIR}/etherpad-lite-${ETHERPAD_VERSION} \
 && ln -s /usr/bin/nodejs /usr/bin/node

VOLUME ${ETHERPAD_DATADIR}

EXPOSE 9001

ADD /etherpad-lite_entrypoint.sh /
RUN chmod +x /etherpad-lite_entrypoint.sh
ENTRYPOINT ["/etherpad-lite_entrypoint.sh"]
