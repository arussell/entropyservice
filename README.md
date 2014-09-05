# entropyservice

Version 1 copyright (c) 2013-2014 Aaron B. Russell <aaron@unadopted.co.uk>
Version 2 copyright (c) 2014 Raimonds Cicans <ray@apollo.lv>

Maintained by Aaron B. Russell <aaron@unadopted.co.uk>

Released under the GNU GPL v2

## Version 2 out now

Many thanks to Raimonds for his rewrite of this project, many improvements in this release, including:
* Scripts use only bare POSIX shell functionality (because on resource limited systems BASH is not available)
* Scripts start with `#!/bin/sh` (not `#!/bin/bash`)
* Scripts use only bare minimum functionality of related tools (no fancy command line parameters)
* Added support for Dropbear in addition to OpenSSH
* Added support for Gentoo in the installer

Version 2 is released under a different license, the GNU GPL v2, as Raimonds' changes were made available under that license.

Version 1 remains available under the BSD license and can be accessed here: https://github.com/arussell/entropyservice/tree/v1

## Contents

* [About](#about)
* [Configuration documentation](#configuration-documentation)
* [Limitations](#limitations)
* [Using multiple remote entropy sources](#using-multiple-remote-entropy-sources)

## About

Allow low entropy machines (eg Virtual Machines) to collect data from another host with high entropy (eg a real computer) via SSH, then stir it in to the kernel's random pool using rngd.

Originally inspired by the technique used by "starlight" on LWN: https://lwn.net/Articles/567731/

## Configuration documentation

The remainder of this document is comprised of the notes supplied by Raimonds along with his changes.

### On server

1) login as root

2) detect which ssh server is running (OpenSSH or DropBear)

run: `ps ax | grep -E '[s]shd|[d]ropbear'`

if output contains one or more lines containing sshd, then server uses OpenSSH server

if output contains one or more lines containing dropbear, then server uses DropBear server

if both above statements are true, then you use both servers and you should chose to which you want to connect

if both statements are false, then you do not run any ssh server and you should install and start OpenSSH or DropBear server (check your 
distribution documentation)

3) get server's fingerprint

[OpenSSH server] run: `echo /etc/ssh/ssh_host_*key.pub | xargs --max-args=1 ssh-keygen -l -f`

[DropBear server] run: `echo /etc/dropbear/dropbear_*_host_key | xargs --max-args=1 dropbearkey -y -f | grep Fingerprint`

Output will contain strings which look like this: `38:fc:04:2e:6b:ce:84:40:15:f9:cf:b1:51:b3:06:a8`

Copy this strings somewhere and/or print them

4) create unprivileged user myrng

run: `useradd -m -s /bin/false myrng`

parameters meaning:

`-m`: create home directory

`-s /bin/sh`: default shell (do not use /bin/false or /bin/nologin: it will not work)

`myrng`: user name

WARNING: some distributions do not have useradd command. On such distributions you should use other tools to create user (check your distribution documentation)

5) create .ssh folder in user's myrng home directory
run: `mkdir -p -m 0700 /home/myrng/.ssh`

6) create authorized_keys file in .ssh directory
run: `touch /home/myrng/.ssh/authorized_keys`

### On first client

7) login as root

8) create `/root/.ssh` directory
run: `mkdir -p -m 0700 /root/.ssh`

9) chose and install which ssh client you want to use: OpenSSH or DropBear (check your distribution documentation)

10) generate ssh keys for myrng user

[OpenSSH client] run: `ssh-keygen -t rsa -N '' -C 'myrng user key' -f /root/.ssh/myrng`

[DropBear client] run: `dropbearkey -t rsa -f /root/.ssh/myrng`

`dropbearkey -y -f /root/.ssh/myrng | grep "^ssh-rsa " > /root/.ssh/myrng.pub`

### On server

11) Add to `/home/myrng/.ssh/authorized_keys` file contents of file `/root/.ssh/myrng.pub` from first client (created at step 10.)

Edit `/home/myrng/.ssh/authorized_keys` file and at the beginning of added contents add following string:

```
command="cat /dev/random",no-pty,no-port-forwarding,no-X11-forwarding,no-agent-forwarding
```
Results should look something like this:
```
command="cat /dev/random",no-pty,no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-rsa AAAAB3NzaC1yc2EAA...
```

### On first client

12) Test connection

[OpenSSH client] run: `ssh -i /root/.ssh/myrng -p 22 myrng@servername "cat /dev/random"`

[DropBear client] run: `dbclient -i /root/.ssh/myrng -p 22 myrng@servername "cat /dev/random"`

On your client replace `22` with ssh server listening port and `servername` replace with ssh server's name

If you see garbage on your screen, then everything is Ok. Just stop ssh client by pressing Ctrl+c and move to next step

If you see complains about host not included in list of known hosts or something like that, then find line containing word "fingerprint" and find near this word string which looks like this: `73:2d:d7:42:b1:97:1f:4e:8d:39:d0:32:e2:ad:83:c6`

Try to find this string among strings we get on step 3.

If you can not find this string, then run again step 3. and then this step. If problem persist, then something went horribly wrong.

If you found string, then:

[OpenSSH client] type `yes` and press enter

[DropBear client] type `y` and press enter

Now you should see garbage on your screen. Stop ssh client by pressing Ctrl+c

13) Copy `entropyservice-client.sh` file to `/root/` directory

14) Add script `/root/entropyservice-client.sh` to system services (check your distribution documentation)

ATTENTION! If you have mixed environment, when some clients use OpenSSH and some DropBear then

first: you should run steps 7-14 on first client with OpenSSH

second: you should repeat steps 7-14 on first client with DropBear

### On next client

15) Login as root

16) Create /root/.ssh directory

run: `mkdir -p -m 0700 /root/.ssh`

17) Chose and install which ssh client you want to use: OpenSSH or DropBear (check your distribution documentation)

18) copy file `/root/.ssh/myrng` from first client to `/root/.ssh/myrng`

[OpenSSH client] copy file from first OpenSSH client!

[DropBear client] copy file from first DropBear client!

19) Test connection

[OpenSSH client] run: `ssh -i /root/.ssh/myrng -p 22 myrng@servername "cat /dev/random"`

[DropBear client] run: `dbclient -i /root/.ssh/myrng -p 22 myrng@servername "cat /dev/random"`

On your client replace 22 with ssh server listening port and servername replace with ssh server's name

If you see garbage on your screen, then everything is Ok. Just stop ssh client by pressing Ctrl+c and move to next step

If you see complains about host not included in list of known hosts or something like that, then find line containing word "fingerprint" and find near this word string which looks like this: `73:2d:d7:42:b1:97:1f:4e:8d:39:d0:32:e2:ad:83:c6`

Try to find this string among strings we get on step 3.

If you can not find this string, then something went horribly wrong.

If you found string, then:

[OpenSSH client] type `yes` and press enter

[DropBear client] type `y` and press enter

Now you should see garbage on your screen. Stop ssh client by pressing Ctrl+c

20) Copy `entropyservice-client.sh` file to `/root/` directory

21) Add script `/root/entropyservice-client.sh` to system services (check your distribution documentation)

Repeat steps 15-21 on all additional clients.

HINT: if you want to limit `/dev/random` read rate on server, then install pv command (http://www.ivarch.com/programs/pv.shtml) and in file `/home/myrng/.ssh/authorized_keys` replace string `command="cat /dev/random"` with string `command="cat /dev/random | pv -q -L 1024"`. This will limit `/dev/random` read rate to 1024 bytes per second per client connection


## Limitations

1) on server you MUST use some kind of hardware RNG device, because performance of default `/dev/random` is very low (few random bytes per second)

2) impossible to limit number of concurrent connections per client. As consequence if root account on one client is compromised, then attacker can run DOS attack against server by running bunch of ssh connections to server which will empty /dev/random device and block services depending on this device.

In case clients have poor performance of built in /dev/random (for example virtualized clients) it will also block services using /dev/random on clients

Unverified theoretical ways to mitigate this problem:

### Method A
1) install on server pv command (http://www.ivarch.com/programs/pv.shtml)

2) measure on server performance of `/dev/random` by running following command: `pv --average-rate < /dev/random > /dev/null`

3) calculate average rate per client = (measured rate) / (clients count + 1 (for server itself))
example: measured rate = 1000 clients count = 3  average rate per client = 1000 / (3 + 1) = 1000 / 4 = 250

4) on server in file `/home/myrng/.ssh/authorized_keys` replace  string `command="cat /dev/random" with string command="cat /dev/random | pv -q -L 250"`

replace `250` with your calculated average rate per client

5) on server add iptables 'recent' rules, something like that:
```
iptables -N ssh_brute_check
iptables -A ssh_brute_check -m conntrack --ctstate NEW -m recent --update --seconds 86400 --hitcount 1 -j DROP
iptables -A ssh_brute_check -m recent --set -j ACCEPT
iptables -A INPUT -m conntrack --ctstate NEW -p tcp --dport 22 -j ssh_brute_check
```
this will limit to one SSH connection per client per 24 hours

#### Disadvantages of this method:

a) you can run from client exactly one SSH connection to server, you can not for example run entropyservice and login as ordinary user

b) if for some reason connection to server get lost client will be able to reconnect only when 24 hours limit pases

### Method B
1) Treat each client as a first one. This mean: for each client repeat installation steps 1.-14. and for each client create different user

For example: client1 - myrng1, client2 - myrng2, client3 - myrng3 ...

This mean at all installation steps you must replace myrng with myrng1 or myrng2 or myrng3 ...

2) install on server pv command (http://www.ivarch.com/programs/pv.shtml)

3) measure on server performance of /dev/random by running following command: `pv --average-rate < /dev/random > /dev/null`

4) calculate average rate per client = (measured rate) / (clients count + 1 (for server itself))

example: measured rate = 1000 clients count = 3  average rate per client = 1000 / (3 + 1) = 1000 / 4 = 250

5) on server in _ALL_ `authorized_keys` files replace  string `command="cat /dev/random"` with string `command="cat /dev/random | pv -q -L 250"`

replace 250 with your calculated average rate per client

6) If on server you use OpenSSH server then add `UsePAM yes` to configuration file `/etc/ssh/sshd_config` and restart OpenSSH server.

7) Add to /etc/security/limits.conf following lines:
```
myrng1 - maxlogins 1
myrng2 - maxlogins 1
myrng3 - maxlogins 1
...
```

#### Disadvantages of this method:

a) more complex installation

b) may not work with DropBear SSH server

## Using multiple remote entropy sources

It is possible to create more than one instance of this script to support multiple servers. After doing the other configuration, do the following:
```
cd /etc/conf.d
cp entropyservice-client entropyservice-client.server1
edit server parameters in file entropyservice-client.server1
cp entropyservice-client entropyservice-client.server2
edit server parameters in file entropyservice-client.server2
cd /etc/init.d
ln -sf entropyservice-client entropyservice-client.server1
rc-update add entropyservice-client.server1 default
./entropyservice-client.server1 start
ln -sf entropyservice-client entropyservice-client.server2
rc-update add entropyservice-client.server2 default
./entropyservice-client.server2 start
```
