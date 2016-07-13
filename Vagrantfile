# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = '2'

[
  'vagrant-triggers',
  'landrush',
  'vagrant-auto_network'
].each do |plugin|
  unless Vagrant.has_plugin?(plugin || ARGV[0] == 'plugin')
    exec("vagrant plugin install #{plugin}; vagrant #{ARGV.join(' ')}")
  end
end

provision = <<-EOS
  sudo apt-get update -yq
  sudo apt-get upgrade -yq
  sudo apt-get install -yq git zsh rake ruby-dev
  sudo locale-gen en_CA.UTF-8
  sudo chsh -s/bin/zsh vagrant
  sudo apt-get autoremove -y
EOS

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = 'ubuntu/trusty64'
  config.vm.provision :shell, inline: provision

  config.landrush.enabled = true
  config.ssh.forward_agent = true
end
