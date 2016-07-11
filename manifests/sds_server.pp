# Configure ScaleIO SDS and ScaleIO XCache (rfcache) services installation

class scaleio::sds_server (
  $ensure = 'present',  # present|absent - Install or remove SDS service
  $xcache = 'present',  # present|absent - Install or remove XCache service
  $ftp    = 'default',  # string - 'default' or FTP with user and password
  )
{
  firewall { '001 Open Port 7072 for ScaleIO SDS':
    dport  => [7072],
    proto  => tcp,
    action => accept,
  }
  package { ['numactl', 'libaio1']:
    ensure => installed,
  } ->
  package { ['emc-scaleio-sds']:
    ensure => $ensure,
  } ->
  exec { 'Apply noop IO scheduler for SSD/flash disks':
    command => 'bash -c \'for i in `lsblk -d -o ROTA,KNAME | awk "/^ *0/ {print($2)}"` ; do if [ -f /sys/block/$i/queue/scheduler ]; then echo noop > /sys/block/$i/queue/scheduler; fi; done\'',
    path    => '/bin:/usr/bin',
  } ->
  file { 'Ensure noop IO scheduler persistent':
    content => 'ACTION=="add|change", KERNEL=="[a-z]*", ATTR{queue/rotational}=="0",ATTR{queue/scheduler}="noop"',
    path    => '/etc/udev/rules.d/60-scaleio-ssd-scheduler.rules',
  } ->

  package { ['emc-scaleio-xcache']:
    ensure => $xcache,
  }
  if $xcache == 'present' and $ftp {
    scaelio::driver_sync { 'xcache driver sync':
      driver  => 'xcache',
      ftp     => $ftp,
      require => Package['emc-scaleio-xcache'],
    }
  }

  # TODO:
  # "absent" cleanup
}
