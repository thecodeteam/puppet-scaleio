# Configure ScaleIO SDC service installation

class scaleio::sdc_server (
  $ensure            = 'present',  # present|absent - Install or remove SDC service
  $mdm_ip            = undef,      # string - List of MDM IPs
  $ensure_properties = 'present',  # present|absent - Add or remove SDS properties
  $ftp               = 'default',  # string - 'default' or FTP with user and password for driver_sync
  $pkg_src           = undef,      # string - URL where packages are placed (for example: ftp://ftp.emc.com/Ubuntu/2.0.10000.2072)
  )
{
  scaleio::common_server { 'install common packages for SDC': } ->
  scaleio::package { 'sdc':
    ensure  => $ensure,
    pkg_src => $pkg_src
  }

  if $ensure == 'present' {
    service { 'scini':
      ensure => 'running',
    }

    if $ftp and $ftp != '' {
      scaleio::driver_sync { 'scini driver sync':
        driver  => 'scini',
        ftp     => $ftp,
        require => Scaleio::Package['sdc'],
      }
    }

    if $mdm_ip != undef and $mdm_ip != '' {
      if $ensure_properties == 'present' {
        file_line { 'Set MDM IP addresses in drv_cfg.txt':
          ensure  => present,
          line    => "mdm ${mdm_ip}",
          path    => '/bin/emc/scaleio/drv_cfg.txt',
          match   => '^mdm .*',
          require => Scaleio::Package['sdc'],
          notify  => Service['scini']
        }
      }
    } else {
      if $ensure_properties == 'absent' {
        file_line { 'Reset MDM IP addresses in drv_cfg.txt':
          ensure            => absent,
          line              => '',
          path              => '/bin/emc/scaleio/drv_cfg.txt',
          match             => '^mdm .*',
          match_for_absence => true,
          require           => Scaleio::Package['sdc'],
          replace           => false,
          notify            => Service['scini']
        }
      }
    }
  }

  # TODO:
  # "absent" cleanup
  # Rename mdm_ip to mdm_ips
}
