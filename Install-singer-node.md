# Overview

**Cronicle** is a multi-server task scheduler and runner, with a web based front-end UI.  It handles both scheduled, repeating and on-demand jobs, targeting any number of worker servers, with real-time stats and live log viewer.  It's basically a fancy [Cron](https://en.wikipedia.org/wiki/Cron) replacement written in [Node.js](https://nodejs.org/).  You can give it simple shell commands, or write Plugins in virtually any language.

![Main Screenshot](https://pixlcore.com/software/cronicle/screenshots-new/job-details-complete.png)

## Features at a Glance

* Single or multi-server setup.
* Automated failover to backup servers.
* Auto-discovery of nearby servers.
* Real-time job status with live log viewer.
* Plugins can be written in any language.
* Schedule events in multiple timezones.
* Optionally queue up long-running events.
* Track CPU and memory usage for each job.
* Historical stats with performance graphs.
* Simple JSON messaging system for Plugins.
* Web hooks for external notification systems.
* Simple REST API for scheduling and running events.
* API Keys for authenticating remote apps.

## Documentation

The Cronicle documentation is split up across these files:

- &rarr; **[Installation & Setup](https://github.com/jhuckaby/Cronicle/blob/master/docs/Setup.md)**
- &rarr; **[Configuration](https://github.com/jhuckaby/Cronicle/blob/master/docs/Configuration.md)**
- &rarr; **[Setup](https://github.com/jhuckaby/Cronicle/blob/master/docs/Setup.md)**
- &rarr; **[Web UI](https://github.com/jhuckaby/Cronicle/blob/master/docs/WebUI.md)**
- &rarr; **[Plugins](https://github.com/jhuckaby/Cronicle/blob/master/docs/Plugins.md)**
- &rarr; **[Command Line](https://github.com/jhuckaby/Cronicle/blob/master/docs/CommandLine.md)**
- &rarr; **[Inner Workings](https://github.com/jhuckaby/Cronicle/blob/master/docs/InnerWorkings.md)**
- &rarr; **[API Reference](https://github.com/jhuckaby/Cronicle/blob/master/docs/APIReference.md)**
- &rarr; **[Development](https://github.com/jhuckaby/Cronicle/blob/master/docs/Development.md)**

# 1.Install nodejs
```shell
cd /opt/ && apt update
apt install nodejs
node --version
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
nvm install 16
node --version
```
result 
```shell
Checksums matched!
Now using node v16.20.2 (npm v8.19.4)

```

## check version js
```shell
curl -s https://raw.githubusercontent.com/jhuckaby/Cronicle/master/bin/install.js | node

```
result 
```shell
Cronicle Installer v1.5
Copyright (c) 2015 - 2022 PixlCore.com. MIT Licensed.
Log File: /opt/cronicle/logs/install.log

Fetching release list...

Version 0.9.51 is already installed, and is the latest.

```

# 2.Install Cronicle
```shell
source ~/.bashrc
cd /opt/ && curl -s https://raw.githubusercontent.com/jhuckaby/Cronicle/master/bin/install.js | node
```
Welcome to Cronicle!
First time installing?  You should configure your settings in '/opt/cronicle/conf/config.json'.
Next, if this is a master server, type: '/opt/cronicle/bin/control.sh setup' to init storage.
Then, to start the service, type: '/opt/cronicle/bin/control.sh start'.
For full docs, please visit: http://github.com/jhuckaby/Cronicle
Enjoy!

Installation complete.

# 3.Setup Cronicle
```shell
 bin/control.sh setup
 bin/control.sh start
 ss -pltn | grep "Cronicle Server"
```
LISTEN 0      511                *:3012            *:*    users:(("Cronicle Server",pid=6942,fd=19))

acess link : http://192.168.0.240:3012/#Schedule

account: admin / admin