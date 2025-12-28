resource "random_integer" "serial" {
  min = 1000000
  max = 9999999
}

resource "libvirt_domain" "vm" {

  count = var.vm_count

  name        = format("%s%02d", var.hostname, count.index + 1)
  running     = true
  autostart   = true
  type        = "kvm"
  memory      = var.memory
  memory_unit = "MiB"
  vcpu        = var.vcpu
  cpu         = { mode = "host-passthrough" }

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
  }

  devices = {
    filesystems = [{
      source      = { mount = { dir = var.shared_config.shared_dir } }
      target      = { dir = "shared_dir" }
      access_mode = "mapped" # to test "passthrough"
      read_only   = false
    }]
    serials = [{ type = "pty", target_port = "0", target_type = "isa-serial" }]
    channels = [
      {
        source = { unix = { mode = "bind" } }
        target = { virt_io = { name = "org.qemu.guest_agent.0" } }
      },
      {
        source = { spice_vmc = true }
        target = { virt_io = { name = "com.redhat.spice.0" } }
      }
    ]
    rngs = [{ model = "virtio", backend = { random = "/dev/urandom" } }]
    # https://libvirt.org/formatdomain.html#video-devices
    videos = [{
      model = {
        type    = "virtio"
        heads   = 1
        primary = "yes"
        accel   = { accel3d = "no" }
      }
    }]
    graphics = [{ spice = { auto_port = true } }]
    inputs   = [{ type = "tablet", bus = "usb" }]
    disks = [
      {
        device = "disk"
        driver = { name = "qemu", type = "qcow2" }
        source = { file = { file = libvirt_volume.disk[count.index].path } }
        target = { dev = "vda", bus = "virtio" }
        serial = random_integer.serial.result + count.index
      },
      {
        device    = "cdrom"
        driver    = { name = "qemu", type = "raw" }
        source    = { file = { file = libvirt_volume.cloudinit[count.index].path } }
        target    = { dev = "sda", bus = "sata" }
        read_only = true
      }
    ]
    interfaces = [{
      model  = { type = "virtio" }
      source = { network = { network = var.shared_config.vn_name } }
      #wait_for_ip = { source = "any", timeout = 90 }
    }]
  }

}
