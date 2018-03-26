# Weekly Minecraft

### Prerequisites

* Sign up for ROUTE53 and configure a domain name.
* Create some SSH keypair called weekly-mc
* Install [terraform](https://www.terraform.io/).
* Build a Spigot executable with `./buildtools.sh`
* Set up your files in s3 like this:

```
.
├── data
├── jars
│  └── spigot.jar
└── plugins
   ├── Essentials.jar
   └── OtherPlugin.jar
```

* `data` should be empty.  
* `jars` should contain a file named `spigot.jar`
* `plugins` should contain jars that match the list found in `vars.sh -> ENABLED_PLUGINS`

### Create infrastructure 

* Edit `user_data_thin.sh` with your personal details.  This will be `user_data.sh` for your EC2 instance.
* Create all the infrastructure you need: run `terraform up` from within the terraform directory.
* Set up scheduling with [AWS EC2 Scheduler](https://docs.aws.amazon.com/solutions/latest/instance-scheduler/welcome.html)
  * Documentation for this is poor.  See my notes below.

# Scheduling

Your cron schedule in `vars.sh` must match the schedule you set up with EC2 scheduler.  I configure EC2 scheduler to start 15 min before my crontab wakes the actual minecraft server to give initialization enough time to fire up.  Likewise, I allow 15 min for cleanup before the scheduler kills the EC2 instance.

For example:

1. Start ec2 at 7:45
2. Start minecraft with cron in `vars.sh` at 8:00
3. Stop minecraft with cron in `vars.sh` at 9:30
4. Stop ec2 at 9:45

# Plugins

Plugins are supported.  Put your plugin config into `plugins/` - if you omit a configuration file, it will simply live with the world backup instead of being managed by git.  Put your plugin jar files in s3 as documented above.

# Config

* `vars.sh` - controls server start and stop, and provides config for the scripts.
* `config/` - configuration for the actual minecraft server.
* `plugins/` - configuration for whatever mc plugins you have.

The standard config files in `config/` will be updated on the server at the beginning of each session.  These should be updated in git.  You may add any of the files you generally expect to be in the root directory of the server data, such as:

* `server.properties`
* `permissions.yml`

To untrack a file, simply remove it from this repo and it will become part of the worlddata backup.  You may wish to do this with `whitelist.json` if you manage an online server and typically add new users through the minecraft console.


# Testing with Docker

You can test this all with docker.

First, edit `vars.sh` and set `AUTOSTART=true` 

Then build the docker image.

```
docker build -t mc .
```

Then run the image.  Get your AWS Access Key and Secret from the AWS console.

```sh
docker run --rm -it \
	--name mc \
	-p "25565:25565" \
	-e AWS_ACCESS_KEY_ID=CHANGEME \
	-e AWS_SECRET_ACCESS_KEY=CHANGEME
	mc
```

You should now be able to connect to a running minecraft server via `localhost`

# Debugging and logging

Logs are written to `/var/log/mc`.  There are separate logs per event, such as boot, begin, and end session.