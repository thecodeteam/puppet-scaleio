define scaleio::common_server (
  $ensure_java = undef
  )
{
  if $::osfamily == 'RedHat' {
    package { ['libaio', 'numactl', 'wget']:
      ensure => installed,
    }
    if $ensure_java == 'present' {
      package { 'java-1.8.0-openjdk':
        ensure  => installed,
      }
    }
  }
  elsif $::osfamily == 'Debian' {
    package { ['libaio1', 'numactl', 'wget']:
      ensure => installed,
    }
    if $ensure_java == 'present' {
      Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }
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
  else {
    fail("Unsupported OS family: ${::osfamily}")
  }
}
