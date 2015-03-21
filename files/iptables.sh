#!/bin/bash
# -------
# Script to set up iptables for Alfresco use
# 
# Copyright 2013 Loftux AB, Peter Löen
#!/bin/bash
# -------
# Script to set up iptables for Alfresco use
# 
# Copyright 2013 Loftux AB, Peter Löen
# Distributed under the Creative Commons Attribution-ShareAlike 3.0 Unported License (CC BY-SA 3.0)
# -------

# Change to public ip-adress on alfresco server
export IPADDRESS=`hostname -I`

    # redirect FROM TO PROTOCOL
    # setup port redirect using iptables
    redirect() {
	    echo "Redirecting port $1 to $2 ($3)"
	    iptables -t nat -A PREROUTING -p $3 --dport $1 -j REDIRECT --to-ports $2
	    iptables -t nat -A OUTPUT -d localhost -p $3 --dport $1 -j REDIRECT --to-ports $2
	    # Add all your local ip adresses here that you need port forwarding for
      for ip in $IPADDRESS
      do
	      iptables -t nat -A OUTPUT -d $ip -p $3 --dport $1 -j REDIRECT --to-ports $2
      done
    }

    block() {
      echo "Blocking port $1"
      for ip in $IPADDRESS localhost
      do
        iptables -A INPUT -p tcp --dport $1 -d $ip -j ACCEPT
      done
      iptables -A INPUT -p tcp --dport $1 -j DROP
    }

    #
    # setup_iptables
    # setup iptables for redirection of CIFS and FTP
    setup_iptables () {

	    echo "1" >/proc/sys/net/ipv4/ip_forward

	    # Clear NATing tables
	    iptables -t nat -F
	    iptables -P INPUT ACCEPT
	    iptables -P FORWARD ACCEPT
	    iptables -P OUTPUT ACCEPT

	    # FTP NATing
	    redirect 21 2021 tcp

	    # CIFS NATing
	    redirect 445 1445 tcp
	    redirect 139 1139 tcp
	    redirect 137 1137 udp
	    redirect 138 1138 udp
	   
	    # IMAP NATing
	    redirect 143 8143 tcp
	    redirect 143 8143 udp
		    
	    # Forward http
	    #redirect 80 8080 tcp
    
      # Block 8080
      block 8080
    }
    remove_iptables () {

	    echo "0" >/proc/sys/net/ipv4/ip_forward
	    # Clear NATing tables
	    iptables -t nat -F
	    iptables -P INPUT ACCEPT
	    iptables -P FORWARD ACCEPT
	    iptables -P OUTPUT ACCEPT

    }
    # start, debug, stop, and status functions
    start() {
		echo "Setting up iptables for Alfresco"
		setup_iptables
    }

    stop() {
    	echo "Removing iptables"
    	remove_iptables

    }

    case "$1" in
      start)
            start
            ;;
      stop)
            stop
            ;;
      restart)
            stop
            start
            ;;
      *)
            echo "Usage: $0 {start|stop|restart}"
            exit 1
    esac

    exit $RETVAL
