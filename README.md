# nasqueron/phabricator Docker image

We maintain a Docker image for **Phabricator**, with MySQL and Aphlict separation. We rely on nginx / php-fpm.

##What we offer

This container provides:

* a nginx / php-fpm installation
* Phabricator daemons
* a non-privileged account 'app' to run daemons and PHP application code
* starting configuration, so you can easily throw and recreate a new container

This container doesn't provide but rely on:

* a MySQL container linked as 'mysql' (`--link <your MySQL container>:mysql`), which could be the official MySQL image or our [nasqueron/mysql](https://hub.docker.com/r/nasqueron/mysql/) image, optimized for Phabricator.
* an Aphlict container if you wish to provide notifications (you don't need to link it), you can use our [nasqueron/aphlict](https://hub.docker.com/r/nasqueron/aphlict/) Node Docker Image.

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
        -e PHABRICATOR_URL="http://phabricator.domain.tld" \
        -e PHABRICATOR_TITLE="Acme" \
        -e PHABRICATOR_ALT_FILE_DOMAIN="files-for-phabricator.anotherdomain.tld" \
        --name $INSTANCE_NAME nasqueron/phabricator
```

Parts of the command line with `-e` parameters allow to declare environment variables. The container initialization script will then configure Phabricator accordingly.

See below for the list of them.

### Step 4. If you wish an Aphlict notification server:

Desktop and in app notifications could be handy to let know your Phabricator users of what's going on in real time.

A Node.js notification servers called Aphlict is shipped with Phabricator. We provide it as a separate container.

You only have to run it, without any linking need.

```
docker pull nasqueron/aphlict
docker run -dt --name aphlict nasqueron/aphlict
```

It will listen to default ports 2280-22281.

Then, you can configure this server through the Phabricator web interface at /config/group/notification/:

 - **notification.enabled:** true
 - **notification.client-uri:** http://aphlictserver.domain.tld:22280/
 - **notification.server-uri:** http://aphlictserver.domain.tld:22281/

**Note:** you only need one Aphlict container for several Phabricator instances.

## Advanced usage

If you need advanced features, we also provide tweaks to:

* add a service to run PhabricatorBot, the shipped IRC bot
* deploy your own Phabricator code

### Environment variables

You can tweak your Phabricator installation through the following environment variables.

Pass them at `docker run` time with `-e VAR="value"` syntax.

Environment you should pass at `docker run` time:

Variable                      | Phabricator config variable     | Description
------------------------------|---------------------------------|------------
PHABRICATOR_ALT_FILE_DOMAIN   | security.alternate-file-domain  | If set, static files are served through another domain.
PHABRICATOR_DOMAIN            | /                               | Domain of your instance, matching PHABRICATOR_URL, will be used in the future in our Docker maintenance Phabricator application.
PHABRICATOR_NO_INSTALL        | /                               | If set, the installation and configuration step will be skipped. Recommended if you deploy your own code to bypass the `bin/storage upgrade` step.
PHABRICATOR_STORAGE_NAMESPACE | storage.default-namespace       | If set, MySQL databases won't start by phabricator_ but by your namespace, followed by an _.
PHABRICATOR_TITLE             | /                               | Title of your instance, will be used in the future in our Docker maintenance Phabricator application.
PHABRICATOR_URL               | phabricator.base-uri            | If set, Phabricator will use it as canonical URL, and will serve Phabricator application to requests for this URL. Mandatory if you use static files separation or Phame.

Environment you should pass if you use the recommended Mailgun mail adapter:

Variable                      | Phabricator config variable     | Description
------------------------------|---------------------------------|------------
PHABRICATOR_USE_MAILGUN       | metamta.mail-adapter            | If set, use Mailgun as mail adapter
PHABRICATOR_DOMAIN            | mailgun.domain                  | The domain of the Phabricator instance
PHABRICATOR_MAILGUN_APIKEY    | mailgun.api-key                 | Your Mailgun API key

Environment from linked containers:

Variable                      | Phabricator config variable     | Description
------------------------------|---------------------------------|------------
MYSQL_ENV_MYSQL_ROOT_PASSWORD | mysql.pass                      | The root password for MySQL.

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

### What about Arcanist?

We also provide a separate [nasqueron/arcanist image](https://hub.docker.com/r/nasqueron/arcanist/), so you can run Arcanist where you have a Docker client, but not PHP installed. We use it to run `arc diff` on our Docker testing server to send changes to review.

### We're currently working on:

* to integrate tweaks directly to an image
* to ease SSL configuration workflow

Help us prioritize telling us if you need to test one of these features.

## Troubleshoot

### MySQL

**Q. I got a Can't connect to root@localhost MySQL error**

A. You don't link a MySQL container, or the linked container doesn't provide a MYSQL_ROOT_PASSWORD environment variable

**Q. I use my MySQL server for several instances of Phabricator**

A. Add to each container -e PHABRICATOR_STORAGE_NAMESPACE=<a different prefix>

Instead to use phabricator_ as database prefix, it will use a specific and different prefix for each instance.

**Q. I want to connect to an external MySQL server**

A. You can use bin/config to manually setup any setting you want:

```
docker exec -it nasqueron/phabricator sh
cd /opt/phabricator
bin/config set mysql.host mysql.domain.tld
bin/config set mysql.pass somesecureprivilegepassword
```

## Team

This image has been crafted by [Sébastien Santoro aka Dereckson](http://www.dereckson.be/) and [Kaliiixx](https://github.com/kaliiixx) at the [Nasqueron Docker images project](http://docker.nasqueron.org/).

## Acknowledgement

To [Evan Priestley](https://twitter.com/evanpriestley), to have first developed Phabricator. To [Yvonnick Esnault](https://github.com/yesnault) to have provided a comprehensive Docker image we've taken as the base of our work.
