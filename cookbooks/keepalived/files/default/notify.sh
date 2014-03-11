#!/usr/bin/env bash

action=$1
iface=$2
vip=$3
src=$4
mgmt=$5

ns="vips"
brif="vip-br"
nsif="vip-ns"

# VLAN interfaces use a "." separator
# sysctl uses a "/" within the interface, and "." component delimeters.
# these switch the "." for a "/", but don't touch the original variables
SYSCTL_iface=${iface//.//}
SYSCTL_brif=${brif//.//}

# Idempotently make sure namespace/veth/sysctls are setup
logger -t keepalived-notify-$action "Ensuring namespace, veth pair and sysctls"
ip netns add $ns
ip link add $brif type veth peer name $nsif netns $ns
ip link set $brif up
ip addr add 169.254.123.1/30 dev lo

ip netns exec $ns ip link set lo up
ip netns exec $ns ip addr add 169.254.123.2/30 dev $nsif
ip netns exec $ns sysctl net.ipv4.ip_forward=1
ip netns exec $ns sysctl net.ipv4.conf.${nsif}.arp_notify=1

sysctl net.ipv4.conf.${SYSCTL_iface}.proxy_arp=1
sysctl net.ipv4.conf.${SYSCTL_brif}.proxy_arp=1
sysctl net.ipv4.conf.lo.arp_ignore=1
sysctl net.ipv4.conf.lo.arp_announce=2
sysctl net.ipv4.ip_forward=1

case $action in
  add|haproxy)
    logger -t keepalived-notify-$action "Adding VIP address to namespace for $vip"
    ip netns exec $ns ip addr add $vip/32 dev $nsif

    logger -t keepalived-notify-$action "Adding VIP NATs to namespace for $vip"
    while ! ip netns exec $ns iptables -t nat -A PREROUTING -d $vip/32 -j DNAT --to-dest $src; do sleep 1; done
    while ! ip netns exec $ns iptables -t nat -A POSTROUTING -m conntrack --ctstate DNAT --ctorigdst $vip/32 -j SNAT --to-source $vip; do sleep 1; done

    logger -t keepalived-notify-$action "Gratarping namespaced interface for $vip"
    ip netns exec $ns ip link set $nsif down
    ip netns exec $ns ip link set $nsif up

    # Re-add default route since interface was cycled
    ip netns exec $ns ip route add default via 169.254.123.1 dev $nsif src 169.254.123.2

    logger -t keepalived-notify-$action "Gratarping management interface for $vip"
    arping -c 3 -A -I $iface $vip
    ;;& # Check remaining patterns
  add)
    logger -t keepalived-notify-$action "Adding VIP route for $vip"
    ip route add $vip/32 dev $brif src $src
    ;;
  haproxy)
    logger -t keepalived-notify-$action "Adding VIP route for $vip"
    ip route add $vip/32 dev $brif src $mgmt
    ;;
  del)
    logger -t keepalived-notify-$action "Deleting VIP route for $vip"
    if [[ -n $mgmt ]]; then
      ip route del $vip/32 dev $brif src $mgmt
    else
      ip route del $vip/32 dev $brif src $src
    fi

    logger -t keepalived-notify-$action "Deleting VIP address from namespace for $vip"
    ip netns exec $ns ip addr del $vip/32 dev $nsif

    logger -t keepalived-notify-$action "Deleting VIP NATs from namespace for $vip"
    ip netns exec $ns iptables -t nat -D PREROUTING -d $vip/32 -j DNAT --to-dest $src
    ip netns exec $ns iptables -t nat -D POSTROUTING -m conntrack --ctstate DNAT --ctorigdst $vip/32 -j SNAT --to-source $vip
    ;;
esac
