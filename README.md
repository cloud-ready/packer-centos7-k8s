# A centos 7 base image for vagrant k8s cluster - CentOS 7 minimal Vagrant Box using Ansible provisioner

**Current CentOS Version Used**: 7.6 (1810)

**Pre-built Vagrant Box**:

  - [`vagrant init topinfra/centos7-k8s`](https://vagrantcloud.com/topinfra/boxes/centos7-k8s)
  - See older versions: http://files.midwesternmac.com/

This example build configuration installs and configures CentOS 7 x86_64 minimal using Ansible, and then generates a Vagrant box file for VirtualBox.

The example can be modified to use more Ansible roles, plays, and included playbooks to fully configure (or partially) configure a box file suitable for deployment for development environments.

## Requirements

The following software must be installed/present on your local machine before you can use Packer to build the Vagrant box file:

  - [Packer](http://www.packer.io/)
  - [Vagrant](http://vagrantup.com/)
  - [VirtualBox](https://www.virtualbox.org/) (if you want to build the VirtualBox box)
  - [Ansible](http://docs.ansible.com/intro_installation.html)

## Usage

Make sure all the required software (listed above) is installed, then cd to the directory containing this README.md file, and run:

    $ packer build -force -var "version=1.0.0" -var "access_token=${VAGRANT_CLOUD_TOKEN}" centos7-k8s.json
    $ vagrant box remove topinfra/centos7-k8s
    $ vagrant box add builds/virtualbox-centos7-k8s.box --name topinfra/centos7-k8s

After a few minutes, Packer should tell you the box was generated successfully, and the box was uploaded to Vagrant Cloud.

> **Note**: This configuration includes a post-processor that pushes the built box to Vagrant Cloud (which requires a `VAGRANT_CLOUD_TOKEN` environment variable to be set); remove the `vagrant-cloud` post-processor from the Packer template to build the box locally and not push it to Vagrant Cloud. You don't need to specify a `version` variable either, if not using the `vagrant-cloud` post-processor.

## Testing built boxes

There's an included Vagrantfile that allows quick testing of the built Vagrant boxes. From this same directory, run one the following command after building the box:

    $ vagrant up
