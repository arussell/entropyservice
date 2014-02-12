entropyservice
==============

Allow low entropy machines (eg Virtual Machines) to collect data from another host with high entropy (eg a real computer) via SSH, then stir it in to the kernel's random pool using rngd.

Uses a FIFO on the client to prevent draining the host's entropy more than necessary.

Inspired by the technique used by "starlight" on LWN: https://lwn.net/Articles/567731/

This solution isn't perfect. Pull requests, issues etc are welcomed.


Host Installation
-----------------

Ensure the host has an SSH server, then create a new (non-privileged) user (I'll use `mynewusername` in this example). This user doesn't even need access to `sudo`, just a basic unpriv'd user will do. You only need one user account no matter how many machines you want the host to serve. You could have more but it's kind of unnecessary. You might want to set the shell of this user to /bin/false or /sbin/nologin or something to prevent interactive sessions if you don't trust your entropy clients.

Ensure the `.ssh` directory exists and has the right permissions. Easiest way to do this is to `su - mynewusername` and then run `ssh-keygen -t rsa` and hit enter a bunch of times.

While still logged in as the new unprivileged user, create a new file called authorized_keys in the .ssh directory. With nano, you'd do this with `nano -w ~/.ssh/authorized_keys`. Paste in the SSH key you got from the client, then save and exit your editor.

Now SSH in from the client by hand once so that it gets to save the host key (otherwise it'll get stuck waiting for a response about whether to save the host's key). Once you're connected you can disconnect and you're good to fire up the client.


Client Installation
-------------------

This should work on any Ubuntu, Debian or CentOS box, but some steps will be a bit different as the distros each have their own nuances.

If you've not created SSH keys for the root user yet, `su -` up (Ubuntu users note: NOT `sudo` -- important for this step as the keys need to go in /root/.ssh, not your normal user's homedir!).

Once you're root, run `ssh-keygen -t rsa`. Hit enter past the passphrase confirmations without typing in a passphrase, they'll cause problems for this process if you enter one.

Grab your freshly generated public key with `cat /root/.ssh/id_rsa.pub` and copy it to your host (see "Host Installation" section below).

Run `./entropyservice-install.sh` on the client to install rngd using the system-provided package manager and to create the FIFO. Ensure you've copied the SSH public key for this client to the host before proceeding any further.

Edit `entropyservice-client.sh` and set the username and hostname you set up on your entropy host.

Run `./entropyservice-client.sh`, and you're done. Note that if the SSH tunnel breaks, rngd will probably stop as the FIFO will close and it'll get a `SIGPIPE`. The launcher probably needs to be improved so that it is monitored by Upstart + start-stop-daemon incase it falls over (or whatever the Debian/CentOS ways of doing things are).
