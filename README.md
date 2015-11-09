# nasqueron/phabricator Docker image

We maintain a Docker image for **Phabricator**, with MySQL and Aphlict  separation. We rely on nginx / php-fpm.

##What we offer

This container provides:

* a nginx / php-fpm installation
* Phabricator daemons
* a non-privileged account 'app' to run daemons and PHP application code
* starting configuration, so you can easily throw and recreate a new container

This container doesn't provide but rely on:

* a MySQL container linked as 'mysql' (`--link <your MySQL container>:mysql`),   which could be the official MySQL image or our nasqueron/mysql image, optimized for Phabricator.
* an Aphlict container if you wish to provide notifications (you don't need to link it), you can use our nasqueron/aphlict Node Docker Image.

## Launch a Phabricator container

Step 1. Run a MySQL container:

```
docker pull nasqueron/mysql
docker run -dt --name phabricator-mysql nasqueron/mysql
```

Step 2. Create a directory (or a Docker volume) to host repositories and config:
```

mkdir /data/phabricator
```

If you omit this step, the container will automatically use volumes.
In such case, remove the -v lines in step 3.

Step 3. Run the Phabricator container:

```
docker pull nasqueron/phabricator

docker run -t -d \
        --link phabricator-mysql:mysql \
        -v /data/phabricator/repo:/var/repo \
        -v /data/phabricator/conf:/opt/phabricator/conf \
        -p 80:80 \
        -e PHABRICATOR_URL=http://phabricator.domain.tld \
        -e PHABRICATOR_TITLE="Acme" \
        -e PHABRICATOR_ALT_FILE_DOMAIN="files-for-phabricator.anotherdomain.tld" \
        --name $INSTANCE_NAME nasqueron/phabricator
```

If you don't want to separate static files and main app domains, you can omit PHABRICATOR_ALT_FILE_DOMAIN.

Step 4. If you wish an Aphlict notification server:

```
docker pull nasqueron/aphlict
docker run -dt --name aphlict nasqueron/aphlict
```

It will listen to default ports 2280-22281.

**Note:** you only need one Aphlict container for several Phabricator instances.

## Advanced usage

If you need avanced features, we also provide tweaks to:

* add a service to run PhabricatorBot, the shipped IRC bot
* deploy your own Phabricator code

### Deploy your own Phabricator code

So we currently have a container with the upstream code in master branch. To deploy your own code, we need to pull from your private repository a specific branch.

We suggest you create a script with the following code to first log in to the server and so accept the server host SSH key, then clone the repository.

Put your keys in the conf volume. If you followed the default instructions, put them on the host in `/data/phabricator/conf/deploy-keys` folder.

```
setenv INSTANCE_NAME phabricator
setenv PHABRICATOR_PROD_REPO ssh://git@github.com/yourorganization/yourrepo.git
setenv PHABRICATOR_PROD_BRANCH production
REPO_LOGIN=git
REPO_HOST=bitbucket.org

docker exec $INSTANCE_NAME sh -c 'mkdir -p /root/.ssh && \
        cp /opt/phabricator/conf/deploy-keys/* /root/.ssh'
docker exec $INSTANCE_NAME ssh -o StrictHostKeyChecking=no ${REPO_LOGIN}@${REPO_HOST}
docker exec $INSTANCE_NAME sh -c 'cd /opt/phabricator && \
        git remote add private "$PHABRICATOR_PROD_REPO" && \
        git fetch --all && \
        git checkout $PHABRICATOR_PROD_BRANCH && \
        sv restart php-fpm'
```

### We're currently working on:

* an Arcanist container, so you can run Arc on any Docker engine machine
  where you don't want to install PHP
* to integrate tweaks to an image

Help us prioritize telling us if you need to test one of these features.

## Troubleshoot

### MySQL

Q. I got a Can't connect to root@localhost MySQL error

A. You don't link a MySQL container, or the linked container doesn't provide
   a MYSQL_ROOT_PASSWORD environment variable

Q. I use my MySQL server for several instances of Phabricator

A. Add to each container -e PHABRICATOR_STORAGE_NAMESPACE=<a different prefix>

   Instead to use databases phabricator/

Q. I want to connect to an external MySQL server

A. You can use bin/config to manually setup any setting you want:

```
docker exec -it nasqueron/phabricator sh
cd /opt/phabricator
bin/config set mysql.host mysql.domain.tld
bin/config set mysql.pass somesecureprivilegepassword
```
