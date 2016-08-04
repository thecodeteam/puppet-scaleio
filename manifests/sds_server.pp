# Configure ScaleIO SDS and ScaleIO XCache (rfcache) services installation

class scaleio::sds_server (
  $ensure = 'present',  # present|absent - Install or remove SDS service
  $xcache = 'present',  # present|absent - Install or remove XCache service
  $ftp    = 'default',  # string - 'default' or FTP with user and password
  )
{
  $sds_package = $::osfamily ? {
    'RedHat' => 'EMC-ScaleIO-sds',
    'Debian' => 'emc-scaleio-sds',
  }
  $xcache_package = $::osfamily ? {
    'RedHat' => 'EMC-ScaleIO-xcache',
    'Debian' => 'emc-scaleio-xcache',
  }
  firewall { '001 Open Port 7072 for ScaleIO SDS':
    dport  => [7072],
    proto  => tcp,
    action => accept,
  }
  $noop_devs = '`lsblk -d -o ROTA,KNAME | awk "/^ *0/ {print($2)}"`'
  $noop_set_cmd = 'if [ -f /sys/block/$i/queue/scheduler ]; then echo noop > /sys/block/$i/queue/scheduler; fi'

  scaleio::common_server { 'install common packages for SDS': } ->
  package { [$sds_package]:
    ensure => $ensure,
  } ->
  exec { 'Apply noop IO scheduler for SSD/flash disks':
    command => "bash -c 'for i in ${noop_devs} ; do ${noop_set_cmd} ; done'",
    path    => '/bin:/usr/bin',
  } ->
  file { 'Ensure noop IO scheduler persistent':
    content => 'ACTION=="add|change", KERNEL=="[a-z]*", ATTR{queue/rotational}=="0",ATTR{queue/scheduler}="noop"',
    path    => '/etc/udev/rules.d/60-scaleio-ssd-scheduler.rules',
  } ->

  package { [$xcache_package]:
    ensure => $xcache,
  }
  if $xcache == 'present' and $ftp and $ftp != '' {
    service { 'xcache':
      ensure => 'running',
    }
    scaleio::driver_sync { 'xcache driver sync':
      driver  => 'xcache',
      ftp     => $ftp,
      require => Package[$xcache_package],
    }
  }

  # TODO:
  # "absent" cleanup
}
