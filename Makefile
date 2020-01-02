all:
	/usr/bin/docker build -t nasqueron/phabricator .
	docker pull nasqueron/aphlict
