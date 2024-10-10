#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Update the system and install the necessary SELinux packages
echo "Updating the system and installing SELinux packages..."
dnf update -y
dnf install -y selinux-policy-targeted policycoreutils setroubleshoot setools

# Check if SELinux is enabled
sestatus | grep "SELinux status" | grep -q "enabled"
if [ $? -eq 0 ]; then
    echo "SELinux is already enabled."
else
    echo "SELinux is not enabled. Enabling SELinux..."
    
    # Set SELinux to enforcing mode in the config file
    sed -i 's/^SELINUX=.*$/SELINUX=enforcing/' /etc/selinux/config
    
    # Reboot the system to apply the changes
    echo "SELinux has been enabled in the configuration. A reboot is required."
    echo "Rebooting the system now..."
    reboot
fi

# Check if the system has rebooted and SELinux is enforcing
echo "Verifying SELinux status after reboot..."

# Check SELinux status
sestatus

# Verify the necessary parameters
if [[ $(sestatus | grep "SELinux status") == *"enabled"* ]] && \
   [[ $(sestatus | grep "Current mode") == *"enforcing"* ]] && \
   [[ $(sestatus | grep "Loaded policy name") == *"targeted"* ]] && \
   [[ $(sestatus | grep "Policy MLS status") == *"enabled"* ]] && \
   [[ $(sestatus | grep "Policy deny_unknown status") == *"allowed"* ]] && \
   [[ $(sestatus | grep "Max kernel policy version") == *"33"* ]]; then
    echo "SELinux has been successfully configured with the required parameters."
else
    echo "There was an issue configuring SELinux. Please check the output above."
fi
