# Configure ScaleIO GUI installation

class scaleio::gui_server (
  $ensure  = 'present',  # present|absent - Install or remove GUI
  $pkg_ftp = undef,      # string - URL where packages are placed (for example: ftp://ftp.emc.com/Ubuntu/2.0.10000.2072)
)
{
  if $ensure == 'absent' {
    scaleio::package { 'gui':
      ensure => absent,
    }
  }
  else {
    scaleio::common_server { 'install common packages for GUI': ensure_java=>'present' } ->
    scaleio::package { 'gui':
      ensure  => installed,
      pkg_ftp => $pkg_ftp,
    }
  }

  # TODO:
  # "absent" cleanup
}
