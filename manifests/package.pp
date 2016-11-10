define scaleio::package (
  $ensure = undef,
  $pkg_src = undef,
  )
{
  $package = $::osfamily ? {
    'RedHat' => $title ? {
      'gateway' => 'EMC-ScaleIO-gateway',
      'gui'     => 'EMC-ScaleIO-gui',
      'mdm'     => 'EMC-ScaleIO-mdm',
      'sdc'     => 'EMC-ScaleIO-sdc',
      'sds'     => 'EMC-ScaleIO-sds',
      'xcache'  => 'EMC-ScaleIO-xcache',
    },
    'Debian' => $title ? {
      'gateway' => 'emc-scaleio-gateway',
      'gui'     => 'EMC_ScaleIO_GUI',
      'mdm'     => 'emc-scaleio-mdm',
      'sdc'     => 'emc-scaleio-sdc',
      'sds'     => 'emc-scaleio-sds',
      'xcache'  => 'emc-scaleio-xcache',
    },
  }

  if $ensure == 'absent' {
    package { $package:
      ensure => absent,
    }
  }
  elsif $pkg_src and $pkg_src != '' {
    $rel = $::operatingsystemmajrelease ? {
      '' => $::operatingsystemrelease,
      default => $::operatingsystemmajrelease
    }
    $version = $::osfamily ? {
      'RedHat' => "RHEL${rel}",
      'Debian' => "Ubuntu${rel}",
    }
    $provider = $::osfamily ? {
      'RedHat' => 'rpm',
      'Debian' => 'dpkg',
    }
    $pkg_ext = $::osfamily ? {
      'RedHat' => 'rpm',
      'Debian' => 'deb',
    }
    $ftp_url = "${pkg_src}/${version}"

    file { "ensure get_package.sh for ${title}":
      ensure => present,
      path   => "/root/get_package_${title}.sh",
      source => 'puppet:///modules/scaleio/get_package.sh',
      mode   => '0700',
      owner  => 'root',
      group  => 'root',
    } ->
    exec { "get_package ${title}":
      command => "/root/get_package_${title}.sh ${ftp_url} ${title}",
      path    => '/bin:/usr/bin',
    } ->
    package { $package:
      ensure   => $ensure,
      source   => "/tmp/${title}/${title}.${pkg_ext}",
      provider => $provider,
    }
  }
}
