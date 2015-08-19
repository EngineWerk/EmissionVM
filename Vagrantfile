# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

    config.vm.provider "virtualbox" do |emission|
         emission.memory = 3072
         emission.cpus = 2
    end

    config.vm.define "emission" do |emission|
        emission.vm.box = "hashicorp/precise64"
        emission.vm.network :private_network, ip: "192.168.200.101"
        emission.vm.hostname = "emission.local"
        emission.hostsupdater.aliases = [
            "emission.local"
        ]
        emission.vm.provision :hosts do |provisioner|
            provisioner.autoconfigure = true
            provisioner.add_host '192.168.200.101', ['emission.local']
        end
        emission.vm.provision "shell", path: "emission-setup.sh"
        emission.vm.synced_folder ".", "/vagrant", type: "nfs"
        emission.vm.synced_folder "../Emission", "/emission", type: "nfs"
    end

end
