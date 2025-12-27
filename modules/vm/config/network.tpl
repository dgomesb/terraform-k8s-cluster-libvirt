---
network:
  version: 2
  renderer: networkd
  ethernets:
    enp2s0:
%{ if ip_addr == "" }
      dhcp4: true
%{ else }
      addresses:
        - ${ip_addr}/${ip_mask}
      routes:
        - to: default
          via: ${ip_gw}
      nameservers:
        search:
          - ${net_domain}
          - home.lan
        addresses:
          - ${ip_gw}
          - 1.1.1.1
          - 8.8.8.8
%{ endif }

# https://documentation.ubuntu.com/server/explanation/networking/configuring-networks/
