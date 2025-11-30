# KVM / Libvirt Live Migration 
# Bash Script for KVM virtual machine live migration 

This repository provides a fully automated script for **zero-downtime live migration of KVM virtual machines between Libvirt hosts**, supporting both:
- Shared storage (`--live`)
- Non-shared storage (`--copy-storage-all`)

The script wraps `virsh migrate`, adds bandwidth and downtime control, logging, and hostname rewriting.

## Features
 Live VM migration without downtime 
 Migration with shared storage 
 Migration with local storage copy 
 Progress logging 
 Auto-start on destination 
 Bandwidth throttling 
 Max downtime setting 

## Requirements (must be completed on both source & destination)

### KVM + QEMU + Libvirt Installed

# Steps to use

cd KVM-LIVE-MIGRATION-SCRIPT
chmod +x *.sh

Before performing copy the keys to destination server

# On Source Node Generate migration key (if not already exists):

mkdir -p /var/virtualizor/ssh-keys
ssh-keygen -t rsa -b 4096 -N "" -f /var/virtualizor/ssh-keys/id_rsa
chmod 600 /var/virtualizor/ssh-keys/id_rsa

# Copy public key to Destination Node
ssh-copy-id -i /var/livemig/ssh-keys/id_rsa.pub "root@DEST_IP -p DEST_PORT"

# Test (must not ask password)
ssh root@DEST_IP virsh list --all

# NVME Firmware / OVMF NVRAM (must sync for UEFI VMs)
mkdir -p /var/lib/libvirt/qemu/nvram
rsync -avz /var/lib/libvirt/qemu/nvram/ root@DEST_IP:/var/lib/libvirt/qemu/nvram/


# Command to run script

bash orchestrate_migration.sh \
VM1 \
NewVM1 \
192.168.1.44 \
22 \
2048 \
500 \
0 \
/var/log/migration.log

| Arg | Meaning                    |
| --- | -------------------------- |
| 1   | Source VM name             |
| 2   | New VM name on destination |
| 3   | Destination IP             |
| 4   | Destination SSH port       |
| 5   | Max bandwidth in Mbps      |
| 6   | Max downtime in ms         |
| 7   | Shared? 1=yes,0=no         |
| 8   | Log file                   |

📌 Recommended Monitoring Commands

# During migration on source
virsh domjobinfo VPS_NAME

# On destination
virsh list --all

# To cancel migration
virsh migrate-cancel VPS_NAME






