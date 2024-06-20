# -*- mode: ruby -*-
# vi: set ft=ruby :

#=> Note: First time run needs the --provision flag below. Subsequent runs can omit this.
#
#=> VAGRANT DEFAULT NUMBER of kubernetes NODES to provision (aside from the master node) = 1 (one)
#=> For more nodes there are 2 options:
# 	1=> The environment variable NODES must be set if you want more than 1 node
# 	    You can export it in .bashrc once only before running this script ( Simplest approach )
# 	2=> OR you can prefix the var before -every- vagrant command that involves >1 node, like below:
#
# 	NODES=<n> vagrant \
#	--masterIP=<IP of master node / control-plane hosting the api-server>
#	--podnetwork=<IP range of pod network> \
#	up
#	--provision
# OR
# 	NODES=2 vagrant status
# OR
# 	NODES=2 vagrant ssh node-2 
# You DON'T need to prefix the variable if the number of nodes = 1 !

require 'getoptlong'
require "ipaddr"

NODES=1
masterIP=''
podnetwork=''
IP=''
nodeIP=''
nodeIPnet=''
nodeIPip=0

opts = GetoptLong.new(
# options must be without embedded '-'
  [ '--masterIP',   GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--podnetwork', GetoptLong::OPTIONAL_ARGUMENT ],
  #[ '--nodes',  GetoptLong::OPTIONAL_ARGUMENT ]
)

opts.ordering=(GetoptLong::REQUIRE_ORDER)

opts.each do |opt, arg|
  case opt
    when '--masterIP'
      masterIP=arg
      nodeIPnet=arg[0...arg.rindex('.')]
      nodeIPip=arg.split('.')[3].to_i
      nodeIPip=nodeIPip+=1
      nodeIP=("#{nodeIPnet}"".""#{nodeIPip}")

    when '--podnetwork'
      podnetwork=arg

    #when '--nodes'
      #NODES=arg.to_i
      #puts("NODES=#{NODES}")
    end
end

# Master
Vagrant.configure('2') do |config|
  config.vm.define 'k8s-master' do |master|
    master.vm.box = 'centos/7'
    master.vm.hostname = 'k8s-master'
    # Use static IPs
    master.vm.network 'private_network', ip: masterIP
    # Min 2G+2 else kubeadm will warn.
    master.vm.provider 'virtualbox' do |vb|
      vb.memory = '2048'
      vb.cpus = 2
    end
    master.vm.provision 'file', source: "provision.sh", destination: "/tmp/provision.sh"
    master.vm.provision "shell" do |cmd|
	cmd.inline = "/bin/bash /tmp/provision.sh $*"
	cmd.args   = ["#{masterIP}","#{podnetwork}","master"]
    end
  end

#Nodes
  NODES=ENV.fetch("NODES", 1).to_i
  (1..NODES).each do |n|
    config.vm.define "node-#{n}" do |node|
      node.vm.box = 'centos/7'
      node.vm.hostname = "node-#{n}"
      node.vm.network 'private_network', ip: nodeIP
      nodeIPip=nodeIPip+=1
      nodeIP=("#{nodeIPnet}"".""#{nodeIPip}")
      node.vm.provider 'virtualbox' do |vb|
        vb.memory = '1024'
	vb.cpus =2
      end
      node.vm.provision 'file', source: "provision.sh", destination: "/tmp/provision.sh"
      node.vm.provision "shell" do |cmd|
	cmd.inline = "/bin/bash /tmp/provision.sh $1"
	cmd.args   = ["node"]
      end
    end
  end
end
