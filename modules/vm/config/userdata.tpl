#cloud-config
# vim: syntax=yaml
# examples:
# https://cloudinit.readthedocs.io/en/latest/topics/examples.html
---
package_update: true
package_upgrade: true

hostname: ${hostname}
fqdn: ${fqdn}
create_hostname_file: true
prefer_fqdn_over_hostname: true

timezone: ${timezone}
locale: ${locale}

ssh_pwauth: true
disable_root: false
chpasswd:
  list: |
    root:password
  expire: false

users:
  - name: ${user_name}
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, admin
    home: /home/${user_name}
    shell: /bin/bash
    passwd: ${user_passwd}
    lock_passwd: false
    ssh-authorized-keys:
      - ${user_ssh_pub}

mounts:
  - [shared_dir, /shared, 9p, defaults, "0", "0"]

apt:
  preserve_source_list: true
  sources:
    kubernetes:
      filename: kubernetes.list
      source: deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${kubeadm_version}/deb/ /
      append: false

packages:
  - containerd
  - apt-transport-https
  - ca-certificates
  - curl
  - gpg

write_files:
  - path: /etc/modules-load.d/k8s.conf
    content: |
      overlay
      br_netfilter
    owner: root:root
    permissions: "0644"

  - path: /etc/sysctl.d/k8s.conf
    content: |
      net.bridge.bridge-nf-call-iptables = 1
      net.bridge.bridge-nf-call-ip6tables = 1
      net.ipv4.ip_forward = 1
    owner: root:root
    permissions: "0644"

  - path: /etc/hosts
    content: |
      ## Managed by terraform
      127.0.0.1  ${hostname}  ${fqdn}
      ${dynamic_hosts}
    append: true

  - path: /usr/local/bin/myKubeadm
    content: |
      ${myKubeadm}
    permissions: "0755"

runcmd:
  - test -e /usr/bin/containerd && mkdir /etc/containerd ; containerd config default > /etc/containerd/config.toml
  - test -f /etc/containerd/config.toml && sed -i 's/\(SystemdCgroup = \).*/\1true/' /etc/containerd/config.toml
  - curl -fsSL https://pkgs.k8s.io/core:/stable:/v${kubeadm_version}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  - apt update && apt install -y kubelet kubeadm kubectl
  - apt-mark hold kubelet kubeadm kubectl
  - apt clean all
  - su - ubuntu -c '(crontab -l 2>/dev/null; echo "@reboot /usr/local/bin/myKubeadm") | crontab -'

final_message: cloud-init is awesome

power_state:
  #delay: 1
  mode: reboot
  condition: grep "cloud-init is awesome" /var/log/cloud-init.log
