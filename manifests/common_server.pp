define scaleio::common_server (
  $java = 0,    # Install java
  $is_mdm = 0,  # Install additional MDM packages
  )
{
  if $::osfamily != 'RedHat' and $::osfamily != 'Debian' {
    fail("Unsupported OS family: ${::osfamily}")
  }

  package { 'numactl':
      ensure => installed,
  }

  $libaio_package = $::osfamily ? {
      'RedHat' => 'libaio',
      'Debian' => 'libaio1',
  }
  package { $libaio_package:
    ensure => installed,
  }

  if $is_mdm != 0 {
    package { ['mutt', 'python', 'python-paramiko']:
      ensure => installed,
    }
  }

  if $java != 0 {
    if $::osfamily == 'RedHat' {
      package { 'java-1.8.0-openjdk':
        ensure  => installed,
      }
    }
    elsif $::osfamily == 'Debian' {
      # Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] } ->
      # Below are a java 1.8 installation steps which shouldn't be required for newer Ubuntu versions
      exec { 'add java8 repo':
        command => 'add-apt-repository ppa:webupd8team/java && apt-get update',
      } ->
      exec { 'java license accepting step 1':
        command => 'echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections',
      } ->
      exec { 'java license accepting step 2':
        command => 'echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections',
      } ->
      package { 'oracle-java8-installer':
        ensure  => installed,
      }
    }
  }
}
