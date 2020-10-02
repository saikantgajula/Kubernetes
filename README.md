# Kubernetes 
## kubernetes_install.sh 
Script installs a single node kubernetes cluster. This single node can be used to create user pod also.
By default kubernetes doesn't allow users to schedule user pod on master nodes. For this we untaint master node so that user pod can be scheduled on this node.

Script has below functions.
```
kubernetes_prereq
install_kubernetes_rpm
initialize_cluster
install_weave_network
verify_cluster_install_untaint_master
install_dashboard
#uninstall_kubernetes
```

Please note script has a function "uninstall_kubernetes". This is commented. For kubernetes uninstall, you can uncomment this function and comment all other functions and run script. This will uninstall kuberentes from your node.
