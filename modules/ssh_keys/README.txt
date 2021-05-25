This SRM module copies any public keys found in its directory to the
authorized_keys file of the SystemRescue root user.
Additionally, it allows ssh traffic through the host-firewall, provided
that the iptables SRM module is also enabled.

