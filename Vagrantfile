# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

    config.vm.provider "virtualbox" do |v|
        v.memory = 1024
        v.cpus = 2
    end

    config.vm.define "emission" do |emission|
        emission.vm.box = "hashicorp/precise64"
        emission.vm.network :private_network, ip: "192.168.56.101"
        emission.vm.provision "shell", path: "emission-setup.sh"
        emission.vm.synced_folder ".", "/vagrant", type: "nfs"
        emission.vm.synced_folder "../Emission", "/emission", type: "nfs"
    end

end
