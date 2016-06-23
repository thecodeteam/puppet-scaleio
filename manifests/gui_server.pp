# Configure ScaleIO GUI installation

class scaleio::gui_server (
  $ensure = 'present',  # present|absent - Install or remove GUI
)
{
  if $ensure == 'absent'
  {
    package { 'emc_scaleio_gui':
      ensure    => absent,
      provider  => dpkg,
    }
  }
  else {
    Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }
    package { ['numactl', 'libaio1']:
      ensure  => installed,
    } ->
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
    } ->
    package { 'EMC_ScaleIO_GUI':
      ensure  => installed,
    }
  }

  # TODO:
  # "absent" cleanup
}
