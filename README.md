# ScaleIO

## Overview

A Puppet module that installs and configures the ScaleIO 2.0 block storage service components.  The module currently supports Ubuntu 14.04.

## Module Description

ScaleIO is software that takes local storage from operating systems and configures them in a virtual SAN to deliver block services to operating systems via IP.  The module handles the configuration of ScaleIO components and the creation and mapping of volumes to hosts.

Most aspects of configuration of ScaleIO have been brought into Puppet.

## Setup

### What Puppet-ScaleIO affects

* Installs firewall (iptables) settings based on ScaleIO components installed
* Installs dependency packages such as numactl and libaio1
* Installs oracle-java8 for gateway

### Tested with

* Puppet 3.*, 4.*
* ScaleIO 2.0
* Ubuntu 14.04
* Linux kernel 4.2.0-30-generic and 3.13.0-*-generic

### Setup Requirements

* Requires ScaleIO packages available in apt repository (depending on the specific components you want to install)
  ```
  emc-scaleio-mdm
  emc-scaleio-sds
  emc-scaleio-sdc
  emc-scaleio-gateway
  emc_scaleio_gui
  ```

* Required modules to install
  ```
  puppet module install puppetlabs-stdlib
  puppet module install puppetlabs-firewall
  ```

### Beginning with scaleio
  ```
  puppet module install cloudscaling-scaleio
  ```

## Structure and specifics

All files reside in the root of manifests.

They consist of:

* NAME_server.pp files - containing installation of the services named with the "NAME". Should be invoked on the nodes where the service is to be installed.
* All other .pp files - configure ScaleIO cluster. Should be invoked on either current master MDM or with ``` FACTER_mdm_ips="ip1,ip2,..." ``` set can be invoked from anywhere.

Main parameter for addressing components in cluster is "name". Only SDC is addressed by "ip" for removal.
All resource declarations are idempotent - they can be repeated as many times as required with the same results. Any optional parameters can be specified later with the same resource declaration.

## Usage example

Example of deployment for 3 nodes MDM and 3 nodes SDS cluster is below:

It's possible to deploy from local directory by the command (replace <my_puppet_dir> with the place where your puppet is):
  ```
  puppet apply --modulepath="/<my_puppet_dir>:/etc/puppet/modules" -e "command"
  ```
  
0. You might want to make sure that kernel you have on the nodes for ScaleIO SDC installation (compute and cinder nodes in case of OpenStack deployment) is suitable for the drivers present here: ``` ftp://QNzgdxXix:Aw3wFAwAq3@ftp.emc.com/ ```. Look for something like ``` Ubuntu/2.0.5014.0/4.2.0-30-generic ```. Local kernel version can be found with ``` uname -a ``` command.

1. Deploy servers. Each puppet should be run on a machine where this service should reside (in any order or in parallel):

  Deploy master MDM and create 1-node cluster (can be run without name and ips to just install without cluster creation)
  ```
  host1> puppet apply "class { 'scaleio::mdm_server': master_mdm_name=>'master', mdm_ips=>'10.0.0.1', is_manager=>1 }"
  ```
  Deploy secondary MDM (can be rerun with is_manager=>0 to make it TieBreaker)
  ```
  host2> puppet apply "class { 'scaleio::mdm_server': is_manager=>1 }"
  ```
  Deploy TieBreaker (can be rerun with is_manager=>1 to make it Manager)
  ```
  host3> puppet apply "class { 'scaleio::mdm_server': is_manager=>0 }"
  ```

  Deploy 3 SDS server ()
  ```
  host1> puppet apply "class { 'scaleio::sds_server': }"
  host2> puppet apply "class { 'scaleio::sds_server': }"
  host3> puppet apply "class { 'scaleio::sds_server': }"
  ```

2. Configure the cluster (commands can be run from any node).

  Set FACTER_mdm_ips variable
  ```
  FACTER_mdm_ips='10.0.0.1,10.0.0.2'
  ```

  Change default cluster password
  ```
  puppet apply "scaleio::login {'login': password=>'admin'} -> scaleio::cluster { 'cluster': password=>'admin', new_password=>'password' }"
  ```

  Login to cluster
  ```
  puppet apply "scaleio::login {'login': password=>'password'}"
  ```

  Add standby MDMs
  ```
  puppet apply "scaleio::mdm { 'slave': sio_name=>'slave', ips=>'10.0.0.1', role=>'manager' }"
  puppet apply "scaleio::mdm { 'tb': sio_name=>'tb', ips=>'10.0.0.2', role=>'tb' }"
  ```

  Create Protection domain with 2 storage pools (fault_sets=>['fs1','fs2','fs3']  can also be specified here)
  ```
  puppet apply "scaleio::protection_domain { 'protection domain':
    sio_name=>'pd', storage_pools=>['sp1'] }"
  ```

  Add 3 SDSs to cluster (Storage pools and device paths in comma-separated lists should go in the same order)
  ```
  puppet apply "scaleio::sds { 'sds 1':
    sio_name=>'sds1', ips=>'10.0.0.1', ip_roles=>'all', protection_domain=>'pd', storage_pools=>'sp1', device_paths=>'/dev/sdb' }"
  puppet apply "scaleio::sds { 'sds 2':
    sio_name=>'sds2', ips=>'10.0.0.2', ip_roles=>'all', protection_domain=>'pd', storage_pools=>'sp1', device_paths=>'/dev/sdb' }"
  puppet apply "scaleio::sds { 'sds 3':
    sio_name=>'sds3', ips=>'10.0.0.3', ip_roles=>'all', protection_domain=>'pd', storage_pools=>'sp1', device_paths=>'/dev/sdb' }"
  ```

  Set password for user 'scaleio_client'
  ```
  puppet apply "scaleio::cluster { 'cluster': client_password=>'Client_Password' }"
  ```

3. Deploy clients (in any order or in parallel)

  Deploy SDC service (should be on the same nodes where volume are mapped to)
  ```
  host1> puppet apply "class { 'scaleio::sdc_server': mdm_ip=>'10.0.0.1,10.0.0.2' }"
  ```

  Deploy Gateway server (password and ips are optional, can be set later with the same command)
  ```
  host2> puppet apply "class { 'scaleio::gateway_server': mdm_ips=>'10.0.0.1,10.0.0.2', password=>'password' }"
  ```

  Deploy GUI (optional)
  ```
  host3> puppet apply "class { 'scaleio::gui_server': }"
  ```

## Performance tuning
* The manifest scaleio::sds_server sets noop scheduler for all SSD disks.
* The manifests scaleio::sdc and scaleio::sds apply high_performance profile for SDS and SDC. In order to use regular profile set the parameter performance_profile, e.g.

  ```
  puppet apply "scaleio::sds { 'sds 1':
    sio_name=>'sds1', ips=>'10.0.0.1', protection_domain=>'pd', storage_pools=>'sp1',
    device_paths=>'/dev/sdb', performance_profile=>'default' }"
  ```

## Reference

* puppetlabs-stdlib
* puppetlabs-firewall

## Limitations

This module currently only support ScaleIO 2.0 and presumes that linux kernel for OS to host the SDC service is suitable for the one in emc-scaleio-sdc package.
Alternatively after SDC deployment scini driver can be updated on the system according to ScaleIO 2.0 deployment guide.

No InstallationManager support is provided. Provisioning of LIA and CallHome is not available.

## Contact information

- [Project Bug Tracker](https://github.com/emccode/puppet-scaleio/issues)
