variable "docker_image" {
  type    = string
  default = "devops"
}

variable "username" {
  type    = string
  default = env("USER")
}

variable "uid" {
  type    = string
  default = "1000"
}

variable "gid" {
  type    = string
  default = "1000"
}


locals {
  image_tag = "${formatdate("YYYYMMDD-hhmmss", timestamp())}"
}

packer {
  required_plugins {
    docker = {
      source  = "github.com/hashicorp/docker"
      version = "~> 1"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1"
    }
  }
}

source "docker" "ubuntu" {
  image  = "ubuntu:22.04"
  commit = true
    changes = [
      "LABEL maintainer='Oscar A. Mata T. <oscar.mata[at]gmail.com>'",
      "WORKDIR /home/${var.username}",
      "USER ${var.username}",
      "ENTRYPOINT [\"/opt/docker-entrypoint.sh\"]"
    ]
}

build {
  sources = ["source.docker.ubuntu"]
  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive"
    ]
    inline = [
      "apt-get update",
      "apt-get -o Dpkg::Options::=\"--force-confold\" install -qqy apt-utils python3-minimal sudo"
    ]
  }

  provisioner "ansible" {
    playbook_file = "./ansible/playbooks/devops.yml"
    extra_arguments = [
      "-e", "build_user=${var.username}",
      "-e", "build_group=${var.username}",
      "-e", "build_user_id=${var.uid}",
      "-e", "build_group_id=${var.gid}"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo find /home/ -type d -name '.ansible' -exec rm -rf '{}' +",
      "rm -rf '/~${var.username}'"
    ]
  }

  post-processors {
    post-processor "docker-tag" {
      repository = var.docker_image
      tags       = [local.image_tag, "latest"]
    }
  }
}
