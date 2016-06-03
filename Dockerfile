#
# Nasqueron  - Phabricator image
#

FROM nasqueron/nginx-php-fpm
MAINTAINER Sébastien Santoro aka Dereckson <dereckson+nasqueron-docker@espace-win.org>

#
# Prepare the container
#

RUN apt-get update && apt-get install -y \
            mercurial subversion python-pygments openssh-client openssh-server sendmail-bin \
            sudo mysql-client \
            --no-install-recommends && rm -r /var/lib/apt/lists/*
	
RUN cd /opt && \
    git clone https://github.com/phacility/libphutil.git && \
    git clone https://github.com/phacility/arcanist.git && \
    git clone https://github.com/phacility/phabricator.git && \
    mkdir -p /var/tmp/phd && \
    chown app:app /var/tmp/phd

RUN mkdir -p /var/run/sshd
RUN mkdir -p /usr/libexec

COPY files /
RUN chmod +x /usr/libexec/ssh-phabricator-hook
RUN chown -R root.root /usr/libexec

#
# Docker properties
#

VOLUME ["/opt/phabricator/conf/local", "/var/repo"]

WORKDIR /opt/phabricator
RUN adduser -q --disabled-password --gecos "Phabricator VCS User" vcs-user
RUN ./bin/config set phd.user app
RUN ./bin/config set diffusion.ssh-user vcs-user
RUN ./bin/config set diffusion.ssh-port 2222

CMD ["/usr/local/sbin/init-container"]
