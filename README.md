
**Install and run a complete multi-node Kubernetes cluster using Containerd (not Docker) on Vagrant.**

  

Why Containerd?

Post March 2024 and after kubernetes version 1.24, most of the examples on the internet providing ways to run k8s using Docker as it's default CRI became obsolete after the k8s team decided to remove dependancy of dockershim (https://kubernetes.io/docs/tasks/administer-cluster/migrating-from-dockershim/)

  

Many of the examples which showed how to set up k8s on Vagrant were also not updated.

  

I have written this example that uses containerd as k8s' CRI and you will be able to run k8s on a multi-node cluster

without needing the change the Vagrantfile. Instead, the master (control-plane/apiserver-ip), pod-network and number

of worker/minion nodes can all be put directly into the command line to bring it all up and running in a few minutes.

  

k8s master node name:  k8s-master

k8s worker node name(s):  node-1, node-2,...

  

When specifying the number of worker nodes, you must put the number (If >1) outside the Vagrantfile

Why? See: See: https://github.com/hashicorp/vagrant/issues/10369

  

**Usage**

  

DEFAULT NUMBER of kubernetes NODES to provision (aside from the master node) = 1 (one)

  

If you have just 1 worker node to provision, then you don't need to specify the NODES variable below.

  

But For more nodes there are 2 options:

(1) The environment variable NODES must be set if you want more than 1 node

You can export it in .bashrc once only before running this script ( Simplest approach )

For example if you want 2 workers aside from the master,

\# **export NODES=2**

Then run:

**\# vagrant --masterIP=<IP of master control plane node> --podnetwork=<IP range of pod network> up --provision**

  

(2) If you don't want to set this variable, you can prefix the var before -every- vagrant command that involves >1 node,

For example:

run:

**\# NODES=<n> vagrant --masterIP=<IP of master control plane node> --podnetwork=<IP range of pod network> up --provision**

  

(Note that in this case you must prefix all related Vagrant commands with the variable as well)

**\# NODES=2 vagrant status**

OR

**\# NODES=2 vagrant ssh node-2**

You DON'T need to prefix the variable if the number of nodes = 1 !

  

Note: First time runs need the --provision flag above. Subsequent runs can omit this.

> Written with [StackEdit](https://stackedit.io/).
