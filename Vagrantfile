default_box = 'generic/centos9s'
cmd_disable_firewall = %q{
  systemctl stop firewalld
  systemctl disable firewalld
}
vms=[
  {
    :hostname => "ovprimary.local",
    :ip    => "192.168.2.10",
    :box   => default_box,
    :ram   => 4000,
    :cpus  => 2,
    :cmds  => [cmd_disable_firewall],
    :files => {}
  },
  {
    :hostname => "ovcompiler1.local",
    :ip   => "192.168.2.11",
    :box  => default_box,
    :ram  => 4000,
    :cpus => 2,
    :cmds => [cmd_disable_firewall],
    :files => {}
  },
  {
    :hostname => "ovcompiler2.local",
    :ip   => "192.168.2.12",
    :box  => default_box,
    :ram  => 4000,
    :cpus => 2,
    :cmds => [cmd_disable_firewall],
    :files => {}
  },
  {
    :hostname => "ovagent1.local",
    :ip    => "192.168.2.21",
    :box   => default_box,
    :ram   => 2000,
    :cpus  => 2,
    :cmds  => [cmd_disable_firewall],
    :files => {}
  }
]
  
Vagrant.configure(2) do |config|
  vms.each do |vm|
    config.vm.define vm[:hostname] do |node|
      node.vm.provider 'virtualbox' do |vb|
        vb.customize ['modifyvm', :id, '--uart1', '0x3F8', '4']
        vb.customize ['modifyvm', :id, '--uartmode1', 'file', File::NULL]
        vb.customize ['modifyvm', :id, '--nestedpaging', 'on']
        vb.customize ['modifyvm', :id, '--memory', vm[:ram]]
        vb.customize ['modifyvm', :id, '--cpus', vm[:cpus]]
        vb.customize ['modifyvm', :id, '--cableconnected1', 'on']
        vb.customize ['modifyvm', :id, '--cpuexecutioncap', '80']
        vb.customize ['modifyvm', :id, '--accelerate3d', 'off']
        vb.customize ['modifyvm', :id, '--graphicscontroller', 'vboxvga']
        vb.customize ['storagectl', :id, '--name', 'SATA Controller', '--hostiocache', 'on']
      end
      node.vbguest.auto_update = false
      node.vm.box_check_update = false
      node.vm.box = vm[:box]
      node.vm.hostname = vm[:hostname]
      node.vm.network "private_network", ip: vm[:ip]
      node.vm.synced_folder "vagrant", "/vagrant", disabled: true
      vm[:files].each do | source, destination | 
        node.vm.provision "file", source: source, destination: destination
      end
      node.vm.provision :hosts do |provisioner|
        provisioner.autoconfigure = true
        provisioner.sync_hosts = true
        provisioner.add_host vm[:ip], [vm['hostname']]
      end
      vm[:cmds].each do | cmd |
        node.vm.provision "shell", inline: cmd
      end
    end
  end
end