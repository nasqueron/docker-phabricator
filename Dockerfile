#
# Nasqueron  - Phabricator image
#

FROM nasqueron/nginx-php-fpm
MAINTAINER Sébastien Santoro aka Dereckson <dereckson+nasqueron-docker@espace-win.org>

#
# Prepare the container
#

RUN apt-get update && apt-get install -y \
    git mercurial subversion python-pygments openssh-client mysql-client \
    --no-install-recommends && rm -r /var/lib/apt/lists/*

RUN cd /opt && \
    git clone https://github.com/phacility/libphutil.git && \
    git clone https://github.com/phacility/arcanist.git && \
    git clone https://github.com/phacility/phabricator.git && \
    rm /etc/nginx/sites-enabled/default

COPY files /

#
# Docker properties
#

VOLUME ["/opt/phabricator/conf/local", "/var/repo"]

#INIT
