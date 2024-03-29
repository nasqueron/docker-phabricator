#
# Nasqueron  - Phabricator image
#

FROM nasqueron/nginx-php-fpm
MAINTAINER Sébastien Santoro aka Dereckson <dereckson+nasqueron-docker@espace-win.org>

#
# Prepare the container
#

RUN apt-get update && apt-get install -y \
            mercurial subversion python3-pygments openssh-client \
            mariadb-client procps \
            --no-install-recommends && rm -r /var/lib/apt/lists/*
	
RUN cd /opt && \
    git clone https://github.com/phacility/arcanist.git && \
    git clone https://github.com/phacility/phabricator.git && \
    mkdir -p /var/tmp/phd && \
    chown app:app /var/tmp/phd

COPY files /

#
# Docker properties
#

VOLUME ["/opt/phabricator/conf/local", "/var/repo"]

WORKDIR /opt/phabricator
CMD ["/usr/local/sbin/init-container"]
