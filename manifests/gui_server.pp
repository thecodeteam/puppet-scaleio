# Configure ScaleIO GUI installation

class scaleio::gui_server (
  $ensure = 'present',  # present|absent - Install or remove GUI
)
{
  $gui_package = $::osfamily ? {
    'RedHat' => 'EMC-ScaleIO-gui',
    'Debian' => 'EMC_ScaleIO_GUI',
  }

  if $ensure == 'absent' {
    package { $gui_package:
      ensure => absent,
    }
  }
  else {
    scaleio::common_server { 'install common packages for GUI': ensure_java=>'present' } ->
    package { $gui_package:
      ensure  => installed,
    }
  }

  # TODO:
  # "absent" cleanup
}
