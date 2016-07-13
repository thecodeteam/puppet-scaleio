# Configure ScaleIO Gateway service installation

class scaleio::gateway_server (
  $ensure       = 'present',  # present|absent - Install or remove Gateway service
  $mdm_ips      = undef,      # string - List of MDM IPs
  $password     = undef,      # string - Password for Gateway
  $port         = 4443,       # int - Port for gateway
  $im_port      = 8081,       # int - Port for IM
  )
{
  $gw_package = $::osfamily ? {
    'RedHat' => 'EMC-ScaleIO-gateway',
    'Debian' => 'emc-scaleio-gateway',
  }
  $provider = "${::osfamily}${::operatingsystemmajrelease}" ? {
    'RedHat6' => 'upstart',
    default  => undef,
  }

  if $ensure == 'absent' {
    package { $gw_package:
      ensure => absent,
    }
  }
  else {
    firewall { '001 for ScaleIO Gateway':
      dport  => [$port, $im_port],
      proto  => tcp,
      action => accept,
    }
    scaleio::common_server { 'install common packages for gateway': ensure_java=>'present' } ->
    package { $gw_package:
        ensure  => installed,
    } ->
    service { 'scaleio-gateway':
      ensure   => 'running',
      enable   => true,
      provider => $provider,
    }

    file_line { 'Set security bypass':
      ensure  => present,
      line    => 'security.bypass_certificate_check=true',
      path    => '/opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties',
      match   => '^security.bypass_certificate_check=',
      require => Package[$gw_package],
    } ->
    file_line { 'Set gateway port':
      ensure  => present,
      line    => "ssl.port=${port}",
      path    => '/opt/emc/scaleio/gateway/conf/catalina.properties',
      match   => '^ssl.port=',
    } ->
    file_line { 'Set IM web-app port':
      ensure  => present,
      line    => "http.port=${im_port}",
      path    => '/opt/emc/scaleio/gateway/conf/catalina.properties',
      match   => '^http.port=',
    }
    if $mdm_ips {
      $mdm_ips_str = join(split($mdm_ips,','), ';')
      file_line { 'Set MDM IP addresses':
        ensure  => present,
        line    => "mdm.ip.addresses=${mdm_ips_str}",
        path    => '/opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties',
        match   => '^mdm.ip.addresses=.*',
        require => Package[$gw_package],
      }
    }
    if $password {
      exec { 'Set gateway admin password':
        command     => "java -jar /opt/emc/scaleio/gateway/webapps/ROOT/resources/install-CLI.jar --reset_password '${password}' --config_file /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties",
        path        => '/etc/alternatives',
        refreshonly => true,
        notify      => Service['scaleio-gateway']
      }
    }

    File_line <| |> ~> Service['scaleio-gateway']
  }

  # TODO:
  # "absent" cleanup
  # try installing java by puppet install module puppetlabs-java - problem is Java in Ubuntu 14.04 is incompatible
}
