# Configure ScaleIO SDS and ScaleIO XCache (rfcache) services installation

class scaleio::sds_server (
  $ensure  = 'present',  # present|absent - Install or remove SDS service
  $xcache  = 'present',  # present|absent - Install or remove XCache service
  $ftp     = 'default',  # string - 'default' or FTP with user and password for driver_sync
  $pkg_ftp = undef,      # string - URL where packages are placed (for example: ftp://ftp.emc.com/Ubuntu/2.0.10000.2072)
  $pkg_path = undef
  )
{
  firewall { '001 Open Port 7072 for ScaleIO SDS':
    dport  => [7072],
    proto  => tcp,
    action => accept,
  }
  $noop_devs = '`lsblk -d -o ROTA,KNAME | awk "/^ *0/ {print($2)}"`'
  $noop_set_cmd = 'if [ -f /sys/block/$i/queue/scheduler ]; then echo noop > /sys/block/$i/queue/scheduler; fi'

  scaleio::common_server { 'install common packages for SDS': } ->
  scaleio::package { 'sds':
    ensure  => $ensure,
    pkg_ftp => $pkg_ftp,
    pkg_path => $pkg_path
  } ->
  exec { 'Apply noop IO scheduler for SSD/flash disks':
    command => "bash -c 'for i in ${noop_devs} ; do ${noop_set_cmd} ; done'",
    path    => '/bin:/usr/bin',
  } ->
  file { 'Ensure noop IO scheduler persistent':
    content => 'ACTION=="add|change", KERNEL=="[a-z]*", ATTR{queue/rotational}=="0",ATTR{queue/scheduler}="noop"',
    path    => '/etc/udev/rules.d/60-scaleio-ssd-scheduler.rules',
  } ->

  scaleio::package { 'xcache':
    ensure  => $xcache,
    pkg_ftp => $pkg_ftp,
    pkg_path => $pkg_path,
    require => Scaleio::Common_server['install common packages for SDS']
  }
  if $xcache == 'present' {
    service { 'xcache':
      ensure => 'running',
    }
  }

  # TODO:
  # "absent" cleanup
}
