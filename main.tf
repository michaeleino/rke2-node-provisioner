

resource "time_sleep" "wait_3_seconds" {
  # depends_on = [null_resource.previous]

  create_duration = "10s"
}


resource "null_resource" "cis-node" {
  # depends_on = [ time_sleep.wait_3_seconds ] ## no need to wait for this one
  count = ( var.cis_enabled == true ? 1 : 0 )
  provisioner "remote-exec" {
    # inline = [ "#!/bin/bash", "${local.insecure_node_command} ${local.role} --node-name $(hostname)" ]
    inline = [<<-EOF
      set -x
      set -e
      sudo tee /etc/sysctl.d/60-rke2-cis.conf <<END
      vm.panic_on_oom=0
      vm.overcommit_memory=1
      kernel.panic=10
      kernel.panic_on_oops=1
      END
      sudo cat /etc/sysctl.d/60-rke2-cis.conf
      sudo sysctl --system
      sudo useradd -r -c "etcd user" -s /sbin/nologin -M etcd -U
    EOF
     ]
  }
  connection {
    type     = "ssh"
    user     = local.os_user
    agent       = true
    script_path = "/home/${local.os_user}/cis-node"
    # password = "${var.root_password}"
    host     = local.target_ip
  }
}

resource "null_resource" "register-node" {
  depends_on = [ time_sleep.wait_3_seconds, null_resource.cis-node ]
  provisioner "remote-exec" {
    # inline = [ "#!/bin/bash", "${local.insecure_node_command} ${local.role} --node-name $(hostname)" ]
    inline = [<<-EOF
      set -x
      set -e
      ${local.insecure_node_command} ${local.role} --node-name $(hostname)
    EOF
     ]
  }
  connection {
    type     = "ssh"
    user     = local.os_user
    agent       = true
    script_path = "/home/${local.os_user}/register-node"
    # password = "${var.root_password}"
    host     = local.target_ip
  }
}