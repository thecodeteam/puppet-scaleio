# Configure ScaleIO SDC service installation

class scaleio::sdc_server (
  $ensure               = 'present',  # present|absent - Install or remove SDC service
  $mdm_ip               = undef,      # string - List of MDM IPs
  $ftp                  = 'default',  # string - 'default' or FTP with user and password
  $ensure_properties    = 'present',  # present|absent - Add or remove SDS properties
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

  if $ensure == 'present' {
    service { 'scini':
      ensure => 'running',
    }

    if $ftp and $ftp != '' {
      scaleio::driver_sync { 'scini driver sync':
        driver  => 'scini',
        ftp     => $ftp,
        require => Package[$sdc_package],
      }
    }

    if $mdm_ip != undef and $mdm_ip != '' {
      if $ensure_properties == 'present' {
        file_line { 'Set MDM IP addresses in drv_cfg.txt':
          ensure  => present,
          line    => "mdm ${mdm_ip}",
          path    => '/bin/emc/scaleio/drv_cfg.txt',
          match   => '^mdm .*',
          require => Package[$sdc_package],
          notify  => Service['scini']
        }
      }
    } else {
      if $ensure_properties == 'absent' {
        file_line { 'Reset MDM IP addresses in drv_cfg.txt':
          ensure  => absent,
          line    => '',
          path    => '/bin/emc/scaleio/drv_cfg.txt',
          match   => '^mdm .*',
          match_for_absence => true,
          require => Package[$sdc_package],
          replace => false,
          notify  => Service['scini']
        }
      }
    }
  }

  # TODO:
  # "absent" cleanup
  # Rename mdm_ip to mdm_ips
}
