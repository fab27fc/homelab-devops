# Homelab Network Design

## Overview

This document describes the network architecture used in the DevOps and SRE homelab environment.

The network was designed to simulate enterprise connectivity using:

- Firewall segmentation
- NAT
- Routing
- Internal DNS
- Linux and Windows infrastructure

---

# Network Topology

```text
                    Internet
                       |
                       |
                ISP Router
              192.168.100.1
                       |
                       |
                 FortiGate VM
                       |
                10.10.10.1/24
                       |
              Homelab Network
               10.10.10.0/24
                       |
 -------------------------------------------------
 |                      |                        |

10.10.10.10        10.10.10.20            10.10.10.30

Windows Server     Ubuntu MGMT            RHEL K8S

AD / DNS           DevOps Tools           Kubernetes
                                      Monitoring Stack
```

---

# IP Addressing

| Device | IP Address | Role |
|---|---|---|
| FortiGate LAN | 10.10.10.1 | Default Gateway |
| Windows Server | 10.10.10.10 | Active Directory / DNS |
| LAB-UBU-MGMT-01 | 10.10.10.20 | DevOps Management |
| LAB-RHEL-K8S-01 | 10.10.10.30 | Kubernetes Platform |

---

# FortiGate Configuration

## Interfaces


### WAN Interface

Purpose:

Internet connectivity


Network:

```text
192.168.100.0/24
```


Gateway:

```text
192.168.100.1
```


---

## LAN Interface

Purpose:

Internal homelab network


Configuration:

```text
Interface IP:
10.10.10.1/24
```


Network:

```text
10.10.10.0/24
```


---

# Routing

## Default Route

Destination:

```text
0.0.0.0/0
```

Next Hop:

```text
ISP Router
192.168.100.1
```

Purpose:

Allow internal servers to reach the Internet.

---

# Firewall Policies


## LAN to WAN Policy


Source:

```text
10.10.10.0/24
```


Destination:

```text
Internet
```


Services:

```text
ALL
```


NAT:

```text
Enabled
```


Purpose:

Allow homelab servers to access external resources.

---

# DNS Design


Primary DNS:

```text
10.10.10.10
Windows Server DNS
```


External DNS Forwarders:

```text
8.8.8.8
1.1.1.1
```


---

# Connectivity Tests


## Gateway Test

Command:

```bash
ping 10.10.10.1
```


## Internet Test

Command:

```bash
ping 8.8.8.8
```


## DNS Test

Command:

```bash
nslookup google.com
```


## SSH Test

Ubuntu MGMT to RHEL:

```bash
ssh fabian@10.10.10.30
```


---

# Future Improvements

Planned enterprise network segmentation:


| VLAN | Network | Purpose |
|-|-|-|
| VLAN10 | 10.10.10.0/24 | Management |
| VLAN20 | 10.10.20.0/24 | Kubernetes |
| VLAN30 | 10.10.30.0/24 | Monitoring |
| VLAN40 | 10.10.40.0/24 | DevOps |

Future goals:

- Inter-VLAN routing
- Firewall security policies
- Kubernetes network isolation
- Site-to-Site VPN with AWS
