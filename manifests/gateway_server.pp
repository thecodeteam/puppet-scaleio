# Configure ScaleIO Gateway service installation

class scaleio::gateway_server (
  $ensure   = 'present',  # present|absent - Install or remove Gateway service
  $mdm_ips  = undef,      # string - List of MDM IPs
  $password = undef,      # string - Password for Gateway
  $port     = 4443,       # int - Port for gateway
  $im_port  = 8081,       # int - Port for IM
  $pkg_ftp  = undef,      # string - URL where packages are placed (for example: ftp://ftp.emc.com/Ubuntu/2.0.10000.2072)
  $pkg_path = undef,      # string - location of ScaleIO RPMs on local filesystem
  )
{
  $provider = "${::osfamily}${::operatingsystemmajrelease}" ? {
    'RedHat6' => 'upstart',
    default   => undef,
  }

  if $ensure == 'absent' {
    scaleio::package { 'gateway':
      ensure => absent
    }
  }
  else {
    firewall { '001 for ScaleIO Gateway':
      dport  => [$port, $im_port],
      proto  => tcp,
      action => accept,
    }
    scaleio::common_server { 'install common packages for gateway':
      ensure_java=>'present'
    } ->
    scaleio::package { 'gateway':
      ensure  => installed,
      pkg_ftp => $pkg_ftp,
      pkg_path => $pkg_path
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
      require => Scaleio::Package['gateway'],
    } ->
    file_line { 'Set gateway port':
      ensure => present,
      line   => "ssl.port=${port}",
      path   => '/opt/emc/scaleio/gateway/conf/catalina.properties',
      match  => '^ssl.port=',
    } ->
    file_line { 'Set IM web-app port':
      ensure => present,
      line   => "http.port=${im_port}",
      path   => '/opt/emc/scaleio/gateway/conf/catalina.properties',
      match  => '^http.port=',
    }
    if $mdm_ips {
      $mdm_ips_str = join(split($mdm_ips,','), ';')
      file_line { 'Set MDM IP addresses':
        ensure  => present,
        line    => "mdm.ip.addresses=${mdm_ips_str}",
        path    => '/opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties',
        match   => '^mdm.ip.addresses=.*',
        require => Scaleio::Package['gateway'],
      }
    }
    if $password {
      $jar_path = '/opt/emc/scaleio/gateway/webapps/ROOT'
      $opts = "--reset_password --password '${password}' --config_file ${jar_path}/WEB-INF/classes/gatewayUser.properties"
      exec { 'Set gateway admin password':
        command     => "java -jar ${jar_path}/resources/SioGWTool.jar ${opts}",
        path        => '/etc/alternatives',
        refreshonly => true,
        notify      => Service['scaleio-gateway']
      }
    }

    File_line<| |> ~> Service['scaleio-gateway']
  }

  # TODO:
  # "absent" cleanup
  # try installing java by puppet install module puppetlabs-java - problem is Java in Ubuntu 14.04 is incompatible
}
