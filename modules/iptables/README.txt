This SRM module modifies the iptables startup script, to make it easier
for other modules to modify the host firewall rules.
The original SystemRescue /etc/iptables/iptables.rules are applied first.
Then rules in /etc/iptables/iptables[0-9][0-9]-*.rules are applied
in order.

This module is static. I.e. only the existing contents of the srm
directory are copied and there is no bootstrap.sh to be run.
