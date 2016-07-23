# Configure ScaleIO SDC service installation

class scaleio::sdc_server (
  $ensure  = 'present',  # present|absent - Install or remove SDC service
  $mdm_ip  = undef,      # string - List of MDM IPs
  $ftp     = 'default'   # string - 'default' or FTP with user and password
  )
{
  $sdc_package = $::osfamily ? {
    'RedHat' => 'EMC-ScaleIO-sdc',
    'Debian' => 'emc-scaleio-sdc',
  }

  scaleio::common_server { 'install common packages for SDC': } ->
  package { [$sdc_package]:
    ensure => $ensure,
  }

  if $ensure == 'present' and $ftp and $ftp != '' {
    scaleio::driver_sync { 'scini driver sync':
      driver  => 'scini',
      ftp     => $ftp,
      require => Package[$sdc_package],
    }
  }

  if $mdm_ip != undef and $mdm_ip != '' {
    $ip_array = split($mdm_ip, ',')
    if $ensure == 'present' {
      scaleio::add_ip { $ip_array:
        require => Package[$sdc_package],
      }
    }
    file_line { 'Set MDM IP addresses in drv_cfg.txt':
      ensure  => present,
      line    => "mdm ${mdm_ip}",
      path    => '/bin/emc/scaleio/drv_cfg.txt',
      match   => '^mdm .*',
      require => Package[$sdc_package],
    }
  } else {
    file_line { 'Reset MDM IP addresses in drv_cfg.txt':
      ensure  => absent,
      line    => '',
      path    => '/bin/emc/scaleio/drv_cfg.txt',
      match   => '^mdm .*',
      match_for_absence => true,
      require => Package[$sdc_package],
      replace => false,
    }
  }

  # TODO:
  # "absent" cleanup
  # Rename mdm_ip to mdm_ips
}

define scaleio::add_ip {
  exec { "add ip ${title}":
    command  => "drv_cfg --add_mdm --ip ${title}",
    path     => '/opt/emc/scaleio/sdc/bin:/bin',
    unless   => "drv_cfg --query_mdms | grep ${title}"
  }
}
