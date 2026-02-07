# Cluster Kubernetes

Creates a local cluster with `terraform` using the [`libvirt`](https://registry.terraform.io/providers/dmacvicar/libvirt/latest) provider made by [dmacvicar](https://registry.terraform.io/namespaces/dmacvicar) and [`cloud-init`](https://cloudinit.readthedocs.io/en/latest/index.html)

If everything works, you'll get:

```bash
ubuntu@server01:~$ kubctl get nodes -owide
NAME       STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
server01   Ready    control-plane   3m   v1.35.0   10.10.10.11   <none>        Ubuntu 24.04.3 LTS   6.8.0-90-generic   containerd://1.7.28
worker01   Ready    <none>          2m   v1.35.0   10.10.10.21   <none>        Ubuntu 24.04.3 LTS   6.8.0-90-generic   containerd://1.7.28
worker02   Ready    <none>          2m   v1.35.0   10.10.10.22   <none>        Ubuntu 24.04.3 LTS   6.8.0-90-generic   containerd://1.7.28

ubuntu@server01:~$ kubctl get pods -A -owide
NAMESPACE        NAME                               READY   STATUS    RESTARTS   AGE   IP            NODE       NOMINATED NODE   READINESS GATES
kube-flannel     kube-flannel-ds-dj9ph              1/1     Running   0          11m   10.10.10.22   worker02   <none>           <none>
kube-flannel     kube-flannel-ds-q2pc9              1/1     Running   0          11m   10.10.10.11   server01   <none>           <none>
kube-flannel     kube-flannel-ds-smcnr              1/1     Running   0          11m   10.10.10.21   worker01   <none>           <none>
kube-system      coredns-7d764666f9-8bvgt           1/1     Running   0          11m   10.244.0.3    server01   <none>           <none>
kube-system      coredns-7d764666f9-dp8w5           1/1     Running   0          11m   10.244.0.2    server01   <none>           <none>
kube-system      etcd-server01                      1/1     Running   0          11m   10.10.10.11   server01   <none>           <none>
kube-system      kube-apiserver-server01            1/1     Running   0          11m   10.10.10.11   server01   <none>           <none>
kube-system      kube-controller-manager-server01   1/1     Running   0          11m   10.10.10.11   server01   <none>           <none>
kube-system      kube-proxy-4fdpr                   1/1     Running   0          11m   10.10.10.11   server01   <none>           <none>
kube-system      kube-proxy-xx5hx                   1/1     Running   0          11m   10.10.10.22   worker02   <none>           <none>
kube-system      kube-proxy-zpq8r                   1/1     Running   0          11m   10.10.10.21   worker01   <none>           <none>
kube-system      kube-scheduler-server01            1/1     Running   0          11m   10.10.10.11   server01   <none>           <none>
metallb-system   controller-66bdd896c6-pzdgm        1/1     Running   0          11m   10.244.1.2    worker01   <none>           <none>
metallb-system   speaker-69gcl                      1/1     Running   0          11m   10.10.10.22   worker02   <none>           <none>
metallb-system   speaker-b5m82                      1/1     Running   0          11m   10.10.10.11   server01   <none>           <none>
metallb-system   speaker-w42pp                      1/1     Running   0          11m   10.10.10.21   worker01   <none>           <none>
```

## [my] Recommendations

- Set a password for the new user..
- Have a `public` ssh key.
- Override variables value using `terraform.tfvars` if needed
  - example:

```terraform
user_passwd = "$6$1wCs5CIgGweH0...zRDgDynm"  ## ex.: openssl passwd -6 "password"

shared_config = {
  user_ssh_pub = "ssh-ed25519 AAAAC3Nz...nf15wip4iJdcB"
  timezone     = "America/Sao_Paulo"
}
```

- By default, the `libvirt_volume.base_os` resource can download images from the internet, but these are deleted during a `terraform destroy`. To avoid re-downloading large images, you can either store the `.img` file locally or manually import it into your storage pool. Since `terraform-provider-libvirt` v0.9.1 lacks a native Data Source to locate existing volumes, the `external.get_vol` data source is used as a workaround to retrieve the disk's path.

```terraform
create = {
  content = {
    ## from internet
    #url = "https://cloud-images.ubuntu.com/releases/noble/release/ubuntu-24.04-server-cloudimg-amd64.img"

    ## from local
    url = "file://ubuntu-24.04-server-cloudimg-amd64.img"
  }
}
```

- Configure local `kubectl` access by transferring the kubeconfig file from the Control Plane node. **_CAUTION_**: This action will overwrite any existing `~/.kube/config` file, resulting in the loss of previous cluster settings."

```bash
mkdir ~/.kube
scp ubuntu@10.10.10.11:/home/ubuntu/.kube/config ~/.kube/config
```

### Notes

- The CNI [`weave-net`](https://github.com/weaveworks/weave) uses `10.32.0.0/12` as default pod network CIDR ignoring the `--pod-network-cidr=${CIDR}` defined on the `kubeadm init`.
  - Weave-net repository was archived by the owner on Jun 20, 2024. It is now read-only. The last version was released back in 2021

How to check "pre-defined" pods CIDR:

```bash
kubectl logs -n kube-system weave-net-(ID) | grep ipalloc-range
```

- Using [`flannel`](https://github.com/flannel-io/flannel) + [`Metallb`](https://github.com/metallb/metallb) instead

### To Be Done

- [ ] Script automation when building more than one `Control Plane`.
- [x] Utilize `backing_store` in the `libvirt_volume.disk` resource to set a native disk capacity independently of the base image size.

---

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_external"></a> [external](#requirement\_external) | 2.3.5 |
| <a name="requirement_libvirt"></a> [libvirt](#requirement\_libvirt) | 0.9.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_external"></a> [external](#provider\_external) | 2.3.5 |
| <a name="provider_libvirt"></a> [libvirt](#provider\_libvirt) | 0.9.2 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_k8s_network"></a> [k8s\_network](#module\_k8s\_network) | ./modules/network | n/a |
| <a name="module_k8s_servers"></a> [k8s\_servers](#module\_k8s\_servers) | ./modules/vm | n/a |
| <a name="module_k8s_workers"></a> [k8s\_workers](#module\_k8s\_workers) | ./modules/vm | n/a |

## Resources

| Name | Type |
|------|------|
| [libvirt_volume.base_os](https://registry.terraform.io/providers/dmacvicar/libvirt/0.9.2/docs/resources/volume) | resource |
| [external_external.get_vol](https://registry.terraform.io/providers/hashicorp/external/2.3.5/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_count_server"></a> [count\_server](#input\_count\_server) | Number of control plane(s) | `number` | `1` | no |
| <a name="input_count_worker"></a> [count\_worker](#input\_count\_worker) | Number of worker(s) | `number` | `2` | no |
| <a name="input_pod_cidr"></a> [pod\_cidr](#input\_pod\_cidr) | Default Flannel CIDR | `string` | `"10.244.0.0/16"` | no |
| <a name="input_shared_config"></a> [shared\_config](#input\_shared\_config) | common variables shared among virtual machines | <pre>object({<br/>    shared_dir    = optional(string, null) ## from locals<br/>    dynamic_hosts = optional(string, null) ## from locals<br/>    main_cp_ip    = optional(string, null) ## First control plane IP<br/>    # virtual network<br/>    vn_name = optional(string, null) ## from locals<br/>    vn_cidr = optional(string, null) ## from locals<br/>    # storage<br/>    storage_name = optional(string, null) ## from locals<br/>    base_os_name = optional(string, "noble-server-cloudimg-amd64.img")<br/>    # userdata.tpl<br/>    user_name       = optional(string, "ubuntu") ## User name to be created in the nodes<br/>    user_passwd     = optional(string, "")       ## from locals (to keep it sensitive)<br/>    user_ssh_pub    = optional(string, "")       ## PUBLIC ssh key<br/>    timezone        = optional(string, "UTC")    ## Set the system timezone<br/>    locale          = optional(string, "en_US")  ## Configure the system locale and apply it system-wide<br/>    kubeadm_version = optional(string, "1.35")   ## Define major.minor and the newest patch will be installed<br/>    # network.tpl<br/>    net_domain = optional(string, "local.k8s") ## VMs FQDN<br/>  })</pre> | `{}` | no |
| <a name="input_start_server_ip"></a> [start\_server\_ip](#input\_start\_server\_ip) | When count\_server > 1, the first server will get this IP | `number` | `11` | no |
| <a name="input_start_worker_ip"></a> [start\_worker\_ip](#input\_start\_worker\_ip) | When count\_worker > 1, the first worker will get this IP | `number` | `21` | no |
| <a name="input_storage_name"></a> [storage\_name](#input\_storage\_name) | Storage name where the volumes/disks will be created into.<br/>If you are not sure about the storage name on your machine,<br/>then run pool-list.sh within scripts folder. | `string` | `"default"` | no |
| <a name="input_user_passwd"></a> [user\_passwd](#input\_user\_passwd) | Hashed password | `string` | `""` | no |
| <a name="input_vn_cidr"></a> [vn\_cidr](#input\_vn\_cidr) | CIDR of the NEW virtual network. You can use net-list.sh<br/>within scripts folder to check current CIDRs | `string` | `"10.10.10.0/24"` | no |
| <a name="input_vn_name"></a> [vn\_name](#input\_vn\_name) | A new Virtual Network will be created | `string` | `"k8s"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_custom_hosts_file"></a> [custom\_hosts\_file](#output\_custom\_hosts\_file) | Will be appended to /etc/hosts in the VMs |
| <a name="output_k8s_server_ips"></a> [k8s\_server\_ips](#output\_k8s\_server\_ips) | Control Plane(s) IP |
| <a name="output_k8s_worker_ips"></a> [k8s\_worker\_ips](#output\_k8s\_worker\_ips) | Worker(s) IP |
<!-- END_TF_DOCS -->
