#!/bin/bash
# Get IP, gateway, netmask, and hostname
    # Show all interfaces
    echo "Available interfaces:"
    interfaces=($(ip -o link show | awk -F': ' '{print $2}'))

    # Filter out the 'lo' interface
    non_lo_interfaces=()
    for interface in "${interfaces[@]}"; do
        if [ "$interface" != "lo" ]; then
            non_lo_interfaces+=("$interface")
        fi
    done

    echo "Exclude iface lo"
    # Choose the interface automatically if only one non-loopback interface exists
    if [ ${#non_lo_interfaces[@]} -eq 1 ]; then
        interface=${non_lo_interfaces[0]}
        echo "Only one interface available: $interface"
    else
        echo "Multiple interfaces available. Please select:"
        select interface in "${non_lo_interfaces[@]}"; do
            if [ "$interface" ]; then
                break
            else
                echo "Invalid selection. Please try again."
            fi
        done
    fi

    # Get IP and netmask for the chosen interface
    ip_info=$(ip -o -f inet addr show $interface | awk '{print $4}')
    ip=$(echo $ip_info | awk -F'[/ ]+' '{print $1}')
    netmask_cidr=$(echo $ip_info | awk -F'[/ ]+' '{print $2}')
    MASK=$(( 0xffffffff ^ ((1 << (32 - netmask_cidr)) - 1) ))
    subnet_mask=$(printf "%d.%d.%d.%d\n" $(( MASK >> 24 & 255 )) $(( MASK >> 16 & 255 )) $(( MASK >> 8 & 255 )) $(( MASK & 255 )))

    echo "IP Address for $interface: $ip"
    echo "Netmask (CIDR) for $interface: $netmask_cidr"
    echo "Netmask (Subnet Mask) for $interface: $subnet_mask"

    # Get default gateway
    gateway=$(ip route show default | awk '/default/ {print $3}')
    echo "Default Gateway: $gateway"

    # Get hostname
    hostname=$(hostname)
    echo "Hostname: $hostname"
